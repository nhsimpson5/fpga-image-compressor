library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity image_io_tb is
end image_io_tb;

architecture behave of image_io_tb is
  --constants 
  constant MAX_WIDTH : integer := 16;
  constant COUNT_BITS : integer := 5;
  --signals
  signal CLK : std_logic := '0';
  signal row_width : integer range 0 to MAX_WIDTH;
  signal pixel_in  : std_logic_vector(7 downto 0);
  signal value_out : std_logic_vector(7 downto 0);
  signal count_out : std_logic_vector(COUNT_BITS - 1 downto 0);
  signal out_valid : std_logic;

  component rle_encoder is
    generic (
      MAX_WIDTH  : integer;
      COUNT_BITS : integer 
    );
    port(
    clk       : in  std_logic;
    row_width : in  integer range 0 to MAX_WIDTH;
    pixel_in  : in  std_logic_vector(7 downto 0);
    value_out : out std_logic_vector(7 downto 0);
    count_out : out std_logic_vector(COUNT_BITS - 1 downto 0);
    out_valid : out std_logic
    );
  end component rle_encoder;

  procedure write_rle(
    variable out_line   : inout line;
    constant value_out  : in std_logic_vector(7 downto 0);
    constant count_out  : in std_logic_vector(COUNT_BITS - 1 downto 0)
  ) is
  begin
    write(out_line, to_integer(unsigned(count_out)));
    write(out_line, string'(" "));
    write(out_line, to_integer(unsigned(value_out)));
    write(out_line, string'(" "));
  end procedure;

begin

  uut: rle_encoder
    generic map (
      MAX_WIDTH => MAX_WIDTH,
      COUNT_BITS => COUNT_BITS
    )
    port map (
      clk => CLK,
      row_width => row_width,
      pixel_in => pixel_in,
      value_out => value_out,
      count_out => count_out,
      out_valid => out_valid
    );

  CLK <= not CLK after 10 ns;

  process is
    file input_file             : text;
    file output_file            : text;
    variable in_status          : file_open_status;
    variable out_status         : file_open_status;
    variable l                  : line;
    variable out_line           : line;
    variable width              : integer;
    variable height             : integer;
    variable maxval             : integer;
    variable pixel_value        : integer;
    variable compression_ratio  : real;
    variable pair_total         : integer := 0;
  begin

    file_open(in_status, input_file, "images/gradient_8x8.pgm", read_mode);
    assert in_status = open_ok report "Failed to open input file" severity failure;

    file_open(out_status, output_file, "sim/output/gradient_8x8.rle", write_mode);
    assert out_status = open_ok report "Failed to open output file" severity failure;

    readline(input_file, l);
    readline(input_file, l);
    read(l, width);
    row_width <= width;
    read(l, height);

    readline(input_file, l);
    read(l, maxval);

    write(out_line, string'("RLE1"));
    writeline(output_file, out_line);

    write(out_line, width);
    write(out_line, string'(" "));
    write(out_line, height);
    writeline(output_file, out_line);

    write(out_line, maxval);
    writeline(output_file, out_line);

    for row in 0 to height - 1 loop
      readline(input_file, l);
      for col in 0 to width - 1 loop
        read(l, pixel_value);
        pixel_in <= std_logic_vector(to_unsigned(pixel_value, pixel_in'length));
        wait until rising_edge(CLK);
        wait for 1 ns;
        if out_valid = '1' then
          write_rle(out_line, value_out, count_out);
          pair_total := pair_total + 1;
        end if;
      end loop;
      wait until rising_edge(CLK);
      wait for 1 ns;
      if out_valid = '1' then
          write_rle(out_line, value_out, count_out);
          pair_total := pair_total + 1;
      end if;
      writeline(output_file, out_line); 
    end loop;

    compression_ratio := real(width*height*8) / real(pair_total*13); --8 bits per pixel, 5 bits per count
    report "compression ratio: " & real'image(compression_ratio);
    report "image dimensions processed";

    file_close(input_file);
    file_close(output_file);
    wait;
  end process;
end behave;