library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity image_io_tb is
end image_io_tb;

architecture behave of image_io_tb is

  signal CLK : std_logic := '0';
  signal D   : std_logic_vector(7 downto 0);
  signal Q   : std_logic_vector(7 downto 0);

  component pixel_register is
    port(
      clk : in  std_logic;
      d   : in  std_logic_vector(7 downto 0);
      q   : out std_logic_vector(7 downto 0)
    );
  end component pixel_register;

begin

  uut: pixel_register
    port map (
      clk => CLK,
      d   => D,
      q   => Q
    );

  CLK <= not CLK after 10 ns;

  process is
    file input_file      : text;
    file output_file     : text;
    variable in_status    : file_open_status;
    variable out_status   : file_open_status;
    variable l            : line;
    variable out_line     : line;
    variable magic        : string(1 to 2);
    variable width        : integer;
    variable height       : integer;
    variable maxval       : integer;
    variable pixel_value  : integer;
    variable output_pixel : integer;
  begin

    file_open(in_status, input_file, "images/gradient_8x8.pgm", read_mode);
    assert in_status = open_ok report "Failed to open input file" severity failure;

    file_open(out_status, output_file, "sim/output/gradient_8x8_out.pgm", write_mode);
    assert out_status = open_ok report "Failed to open output file" severity failure;

    readline(input_file, l);
    read(l, magic);

    readline(input_file, l);
    read(l, width);
    read(l, height);

    readline(input_file, l);
    read(l, maxval);

    write(out_line, magic);
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
        D <= std_logic_vector(to_unsigned(pixel_value, D'length));
        wait until rising_edge(CLK);
        wait for 1 ns;
        output_pixel := to_integer(unsigned(Q));
        assert output_pixel = pixel_value
        report "output_pixel(" & integer'image(output_pixel) & ") doesn't equal pixel_value (" & integer'image(pixel_value) & ")" 
        severity error;
        write(out_line, output_pixel);
        write(out_line, string'(" "));
      end loop;
      writeline(output_file, out_line);
    end loop;
    
    report "image dimensions processed";

    file_close(input_file);
    file_close(output_file);

    wait;
  end process;

end behave;