# RLE Encoder: Results & Findings

## Setup

- `rle_encoder` (generic `MAX_WIDTH`, `COUNT_BITS = 5`) wired into `image_io_tb.vhd` in place of `pixel_register`, driven by real pixel data read via TEXTIO from `.pgm` test images.
- Encoded output written as a custom `.rle` text format: `"RLE1"` magic line, `width height` line, `maxval` line, then one line per image row containing that row's flushed `(count, value)` pairs as space-separated decimal numbers.
- Verified correct by hand: compared `plus_16x16`'s `.rle` output directly against the real source `.pgm` pixel values — every run boundary and count matched exactly.

## Compression ratio methodology

Ratio is computed in bits, not text-file bytes (writing decimal digits as ASCII text would give a meaningless/misleading number):

- Original size = `width * height * 8` bits (one byte per pixel).
- Compressed size = `pair_total * (COUNT_BITS + 8)` = `pair_total * 13` bits, where `pair_total` is the actual number of `(count, value)` pairs the encoder flushed (`out_valid = '1'` events) across the whole image.
- `compression_ratio = original_bits / compressed_bits` (as a `real`, via explicit `real()` conversion — integer `/` would truncate).

## Results

| Image | Dimensions | Pairs produced | Compression ratio | Notes |
|---|---|---|---|---|
| `plus_16x16` | 16×16 | 40 | **3.94 : 1** (2048/520) | Large uniform regions (background + cross shape) compress well. |
| `gradient_8x8` | 8×8 | 64 (one per pixel) | **0.615 : 1** = 8/13 (512/832) | Worst case: every pixel differs from its horizontal neighbour, so every pixel becomes its own `count = 1` run. Output is 62.5% *larger* than the original. |
| `checkerboard_8x8` | 8×8 | 64 (one per pixel) | **0.615 : 1** = 8/13 (identical to gradient) | Same worst-case mechanism as the gradient, despite looking like a completely different pattern to a human eye. |

## Key finding

RLE's compression ratio depends entirely on one narrow property: whether horizontally-adjacent pixels repeat the same value. It has no concept of visual "pattern" or structure beyond that. The gradient and checkerboard images look nothing alike to a human, but are functionally identical to this encoder — both have zero adjacent-pixel repetition, so both hit the exact same worst case (`8/13`, derivable directly from `8 bits / (COUNT_BITS + 8) bits` whenever every pixel becomes its own run). This is a genuine, demonstrated limitation of RLE, not a bug — useful evidence for comparing against the wavelet/DCT compressors in later stages, and for the Stage 6 write-up.

## Known gap

There is currently no decoder — correctness for `plus_16x16` was verified by manually comparing the `.rle` output against the source `.pgm`. A decoder that reverses the encoding and reconstructs the original pixels would let the testbench assert correctness automatically instead.