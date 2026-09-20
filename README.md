# FPGA Image Compressor

A from-scratch FPGA-based image compressor, written in VHDL and verified in simulation with GHDL. This is a personal project built to demonstrate hardware design skills, it's deliberately treated as an honest work-in-progress rather than a polished, finished product, with design decisions, dead ends, and trade-offs documented as they happen.

## Overview

The pipeline reads a real greyscale image, decomposes and compresses it in hardware, and (eventually) reconstructs it — with compression ratio and image quality (PSNR) measured as part of the evaluation. Two compression approaches are being built and compared:

- **Run-Length Encoding (RLE)** — the baseline/fallback deliverable, simple and cheap in hardware, but with no real understanding of image structure beyond adjacent-pixel repetition.
- **Haar wavelet transform (DWT)** — the main target: a 2D separable transform that decomposes the image into approximation and detail subbands, followed by quantization, intended to compress meaningfully better than RLE while still being tractable in hardware.

Everything is written and verified module-by-module in simulation before anything touches real hardware, with self-checking (assert-based) testbenches and deliberate mutation testing (breaking the design on purpose to confirm the testbench actually catches it) used as the bar for "verified."

## Project status

**Current stage: Stage 3 (Haar wavelet transform), in progress.**

| Stage | Goal | Status |
|---|---|---|
| 1 | Read a real image into simulation and write it back out unchanged (PGM + TEXTIO) | [x] Done |
| 2 | Run-Length Encoding, verified in simulation | [x] Done |
| 3 | Haar wavelet transform-based compressor (quantize, measure ratio/PSNR) | [ ] In progress |
| 4 | Block-based DCT compressor, for comparison (stretch) | [ ] Not started |
| 5 | Run the working compressor on real FPGA hardware | [ ] Not started |
| 6 | Full write-up: diagrams, before/after images, ratio/PSNR numbers | [ ] Ongoing |

Within Stage 3: the single-level 2D Haar transform and quantization are complete and independently verified. Work in progress is wiring the quantized coefficient output into the RLE encoder to get a first honest end-to-end compression ratio, followed by multi-level recursion (recursing the transform over the LL subband), handling of odd-sized images, and PSNR measurement.

## Architecture

![Architecture diagram: a .pgm image is read via TEXTIO and streamed through haar_2d_encoder's row pass, column pass, and two quantizers, producing LH/HH detail and LL/HL approximation subbands; these still need to be wired into rle_encoder (shown dashed) to produce the .rle output](architecture.svg)

*(Dashed arrows mark the RLE hookup that's still being wired in — see [Known gaps](#known-gaps--next-steps).)*

Each row/column transform pass is built from a small combinational **butterfly** unit implementing the Haar lifting scheme (`d = a - b`, `s = b + floor(d/2)`), wrapped in a streaming sequential shell that feeds it a continuous pixel/coefficient stream. The two passes are chained through a small buffer inside `haar_2d_encoder`, which also owns the two quantizer instances and the four independent output streams.

## Repository structure

```
fpga-image-compressor/
├── src/                  # design sources (one entity per file)
│   ├── pixel_register.vhd
│   ├── rle_encoder.vhd
│   ├── haar_butterfly.vhd
│   ├── haar_butterfly_wide.vhd
│   ├── haar_row_transform.vhd
│   ├── haar_column_transform.vhd
│   ├── haar_quantizer.vhd
│   └── haar_2d_encoder.vhd
├── sim/                  # testbenches (one <module>_tb.vhd per src module)
│   ├── images/           # test .pgm images (plain ASCII, P2)
│   └── output/           # generated .rle output (from image_io_tb)
├── build/                # GHDL work library (generated, gitignored)
├── run_tb.sh             # generic per-module testbench runner
├── rle_results.md        # RLE compression ratio results & findings
└── README.md
```

Naming convention: `src/<module>.vhd` pairs with `sim/<module>_tb.vhd`.

## Toolchain

- **Language:** VHDL
- **Simulator:** [GHDL](https://ghdl.github.io/ghdl/)
- **Shell:** Git Bash / MINGW64 on Windows
- **Test image format:** PGM, plain ASCII (P2)

### Running the testbenches

Each module has a self-checking testbench runnable via the generic script:

```bash
./run_tb.sh <module_name> [stop_time]

# e.g.
./run_tb.sh haar_butterfly
./run_tb.sh haar_2d_encoder 2000ns
```

This compiles the design and testbench into `build/` with GHDL, elaborates, and runs, using `--workdir=build` throughout (necessary — running GHDL commands from inconsistent directories otherwise produces spurious "is not bound" warnings and assertion failures).

The image I/O testbench (which reads a real `.pgm` file, drives it through the encoder under test, and writes output) is run separately from the `sim/` directory, since it opens `images/<file>.pgm` and `output/<file>.rle` as relative paths:

```bash
cd sim
../run_image_io_tb.sh   # ghdl -a / -e / -r on image_io_tb
```

## Module reference

| Module | Stage | Description |
|---|---|---|
| `pixel_register` | 1 | Single-cycle 8-bit pixel register, used as a placeholder stage in the image I/O pipeline. |
| `image_io_tb` | 1–2 | Testbench harness: reads a `.pgm` file via TEXTIO, streams pixels through the module under test, and writes a result file. Currently wired to `rle_encoder`, producing a custom `RLE1`-tagged `.rle` text format and reporting compression ratio in bits. |
| `rle_encoder` | 2 | Runtime-configurable run-length encoder. `MAX_WIDTH` (generic) sets the maximum row capacity the hardware supports; `row_width` (runtime port) sets the actual row length in use; `COUNT_BITS` (generic) sizes the run-length field. Flushes `(count, value)` pairs on a value change, a run-length overflow, or end-of-row. |
| `haar_butterfly` | 3 | Combinational Haar lifting-scheme core. Takes two 8-bit unsigned pixels, outputs a 9-bit signed difference `d` and an 8-bit unsigned sum `s = b + floor(d/2)` (floor via arithmetic right shift on two's complement). |
| `haar_row_transform` | 3 | Streaming sequential wrapper: pairs adjacent pixels in a row through `haar_butterfly` as they arrive. Has an `enable` input to hold the module's internal phase until its consumer is ready. |
| `haar_butterfly_wide` | 3 | Butterfly variant for the column pass — takes two already-9-bit-signed coefficients (row-pass outputs), producing a 10-bit signed `d` and 9-bit signed `s`. |
| `haar_column_transform` | 3 | Streaming sequential wrapper mirroring `haar_row_transform`, applying `haar_butterfly_wide` down a column of row-pass coefficients. |
| `haar_quantizer` | 3 | Combinational quantizer: arithmetic right shift of a signed coefficient by a runtime `shift` amount (a runtime port rather than a generic, so quantization level can be swept per data point without re-synthesizing). |
| `haar_2d_encoder` | 3 | Top-level orchestrator. A 2-state FSM (`ROW_PASS` / `COLUMN_PASS`) runs the row pass then the column pass across a full image, buffers intermediate coefficients, quantizes the results, and emits four independent, individually-valid subband streams: `ll_out`, `lh_out`, `hl_out`, `hh_out` (10-bit signed each). |

Every module above has a matching `_tb.vhd` testbench with self-checking asserts, validated by deliberately reintroducing bad data and confirming the testbench flags it.

## Results so far

### RLE (Stage 2)

Compression ratio is measured in bits, not text-file bytes: original size is `width × height × 8` bits (one byte per pixel); compressed size is `pairs × (COUNT_BITS + 8)` bits, where `COUNT_BITS = 5` in these tests.

| Image | Dimensions | Pairs produced | Compression ratio | Notes |
|---|---|---|---|---|
| `plus_16x16` | 16×16 | 40 | **3.94 : 1** | Large uniform regions (background + cross shape) compress well. |
| `gradient_8x8` | 8×8 | 64 | **0.615 : 1** | Worst case — every pixel differs from its horizontal neighbour, so every pixel becomes its own run. 62.5% *larger* than the original. |
| `checkerboard_8x8` | 8×8 | 64 | **0.615 : 1** | Same worst-case mechanism as the gradient, despite looking completely different to a human eye. |

**Key finding:** RLE's compression ratio depends entirely on horizontal adjacent-pixel repetition — it has no concept of visual structure beyond that. The gradient and checkerboard images are visually unrelated but functionally identical to this encoder, both hitting the exact same worst case. This is a genuine, demonstrated limitation of RLE rather than a bug, and useful comparison evidence against the wavelet-based compressor once that's fully wired up.

### Haar wavelet transform (Stage 3)

Transform and quantization are verified correct against hand-derived test vectors; an end-to-end compression ratio (feeding quantized coefficients through RLE) is the current work in progress.

## Known gaps / next steps

- **RLE hookup for wavelet coefficients (in progress).** `rle_encoder` currently expects one 8-bit *unsigned* pixel per cycle in a continuous stream, but `haar_2d_encoder` produces four separate, intermittent, signed 10-bit coefficient streams (two arriving simultaneously per valid pulse). Needs a decision on subband ordering, on generalizing `rle_encoder` for wider signed data, and on whether one instance is time-multiplexed across subbands or several instances run in parallel.
- **No RLE decoder yet** — correctness has been checked by hand for one test image rather than via an automated round-trip.
- **Multi-level recursion not yet implemented.** `enable` on the row/column transforms is currently a *pause*, not a *reset*, which is fine for a single pass from power-on but not for feeding a sub-image back through a second time. This needs resolving before the recursion wrapper can be written.
- **Odd-sized rows/columns aren't handled yet** — both transform passes currently assume even width/height.
- **PSNR measurement not yet started.**
- **No real hardware yet** — everything so far is simulation-only (GHDL); Stage 5 targets running a stored test image through real FPGA hardware.
