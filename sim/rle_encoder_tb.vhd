library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
 
entity rle_encoder_tb is
end rle_encoder_tb;
 
architecture behave of rle_encoder_tb is
    --constants
    constant COUNT_BITS : integer := 5;
    --inputs
    signal CLK          : std_logic := '0';
    signal pixel_in     : std_logic_vector(7 downto 0);
    --outputs
    signal value_out    : std_logic_vector(7 downto 0);
    signal count_out    : std_logic_vector(COUNT_BITS - 1 downto 0);
    signal out_valid    : std_logic;
 
    component rle_encoder is
        generic( 
            MAX_WIDTH   : integer; 
            COUNT_BITS  : integer
        );
        port(
            clk         : in std_logic;
            row_width   : in integer range 0 to MAX_WIDTH;
            pixel_in    : in std_logic_vector(7 downto 0);
            value_out   : out std_logic_vector(7 downto 0);
            count_out   : out std_logic_vector(COUNT_BITS - 1 downto 0);
            out_valid   : out std_logic
        );
    end component rle_encoder;
 
    type pixel_array is array (natural range <>) of std_logic_vector(7 downto 0);
    type int_array is array (natural range <>) of integer;
 
    --tests
    constant input_row_generic      : pixel_array := (
        std_logic_vector(to_unsigned(5, 8)),
        std_logic_vector(to_unsigned(5, 8)),
        std_logic_vector(to_unsigned(5, 8)),
        std_logic_vector(to_unsigned(7, 8))
    );
    constant expected_values_generic : int_array := (5,7);
    constant expected_counts_generic : int_array := (3,1);
 
    constant input_row_overflow     : pixel_array := (
        std_logic_vector(to_unsigned(5, 8)),
        std_logic_vector(to_unsigned(5, 8)),
        std_logic_vector(to_unsigned(5, 8)),
        std_logic_vector(to_unsigned(5, 8)),
        std_logic_vector(to_unsigned(5, 8)),
        std_logic_vector(to_unsigned(5, 8)),
        std_logic_vector(to_unsigned(5, 8)),
        std_logic_vector(to_unsigned(5, 8)),
        std_logic_vector(to_unsigned(5, 8)),
        std_logic_vector(to_unsigned(5, 8)),
        std_logic_vector(to_unsigned(5, 8)),
        std_logic_vector(to_unsigned(5, 8)),
        std_logic_vector(to_unsigned(5, 8)),
        std_logic_vector(to_unsigned(5, 8)),
        std_logic_vector(to_unsigned(5, 8)),
        std_logic_vector(to_unsigned(5, 8)),
        std_logic_vector(to_unsigned(5, 8)),
        std_logic_vector(to_unsigned(5, 8)),
        std_logic_vector(to_unsigned(5, 8)),
        std_logic_vector(to_unsigned(5, 8)),
        std_logic_vector(to_unsigned(5, 8)),
        std_logic_vector(to_unsigned(5, 8)),
        std_logic_vector(to_unsigned(5, 8)),
        std_logic_vector(to_unsigned(5, 8)),
        std_logic_vector(to_unsigned(5, 8)),
        std_logic_vector(to_unsigned(5, 8)),
        std_logic_vector(to_unsigned(5, 8)),
        std_logic_vector(to_unsigned(5, 8)),
        std_logic_vector(to_unsigned(5, 8)),
        std_logic_vector(to_unsigned(5, 8)),
        std_logic_vector(to_unsigned(5, 8)),
        std_logic_vector(to_unsigned(5, 8)),
        std_logic_vector(to_unsigned(5, 8)),
        std_logic_vector(to_unsigned(5, 8)),
        std_logic_vector(to_unsigned(5, 8)),
        std_logic_vector(to_unsigned(5, 8)),
        std_logic_vector(to_unsigned(5, 8)),
        std_logic_vector(to_unsigned(5, 8)),
        std_logic_vector(to_unsigned(5, 8)),
        std_logic_vector(to_unsigned(5, 8)),
        std_logic_vector(to_unsigned(5, 8)),
        std_logic_vector(to_unsigned(5, 8)),
        std_logic_vector(to_unsigned(5, 8)),
        std_logic_vector(to_unsigned(5, 8)),
        std_logic_vector(to_unsigned(5, 8)),
        std_logic_vector(to_unsigned(5, 8)),
        std_logic_vector(to_unsigned(5, 8)),
        std_logic_vector(to_unsigned(5, 8))
    );
    constant expected_values_overflow : int_array := (5,5);
    constant expected_counts_overflow : int_array := (31,17);
 
    constant input_row_single_value : pixel_array := (
        std_logic_vector(to_unsigned(5, 8)),
        std_logic_vector(to_unsigned(5, 8)),
        std_logic_vector(to_unsigned(5, 8)),
        std_logic_vector(to_unsigned(5, 8))
    );
    constant expected_values_single_value : int_array := (0 => 5);
    constant expected_counts_single_value : int_array := (0 => 4);
 
    --constants
    constant MAX_WIDTH  : integer := input_row_overflow'length;
    --inputs
    signal row_width    : integer range 0 to MAX_WIDTH := 0;

    procedure check_row(
        signal   clk        : in  std_logic;
        signal   pixel_in   : out std_logic_vector(7 downto 0);
        signal   row_width  : out integer;
        signal   out_valid  : in  std_logic;
        signal   count_out  : in  std_logic_vector(COUNT_BITS - 1 downto 0);
        signal   value_out  : in  std_logic_vector(7 downto 0);
        constant pixels     : in  pixel_array;
        constant exp_counts : in  int_array;
        constant exp_values : in  int_array
    ) is
        variable result_index : integer := 0;
    begin
        row_width <= pixels'length;
        for j in pixels'range loop
            pixel_in <= pixels(j);
            wait until rising_edge(clk);
            wait for 1 ns;
            if out_valid = '1' then
                assert to_integer(unsigned(count_out)) = exp_counts(result_index)
                report "Mismatch at index " & integer'image(result_index) & ": expected count " & integer'image(exp_counts(result_index)) & ", got " & integer'image(to_integer(unsigned(count_out)))
                severity error;
                assert to_integer(unsigned(value_out)) = exp_values(result_index)
                report "Mismatch at index " & integer'image(result_index) & ": expected value " & integer'image(exp_values(result_index)) & ", got " & integer'image(to_integer(unsigned(value_out)))
                severity error;
                result_index := result_index + 1;
            end if;
        end loop;
        -- one extra clock edge to catch the ROW_END flush, which lands
        -- one cycle after the last pixel was driven
        wait until rising_edge(clk);
        wait for 1 ns;
        assert to_integer(unsigned(count_out)) = exp_counts(result_index)
        report "Mismatch at index " & integer'image(result_index) & ": expected count " & integer'image(exp_counts(result_index)) & ", got " & integer'image(to_integer(unsigned(count_out)))
        severity error;
        assert to_integer(unsigned(value_out)) = exp_values(result_index)
        report "Mismatch at index " & integer'image(result_index) & ": expected value " & integer'image(exp_values(result_index)) & ", got " & integer'image(to_integer(unsigned(value_out)))
        severity error;
        result_index := result_index + 1;
        assert result_index = exp_counts'length
        report "number of RLE results (" & integer'image(result_index) & ") doesnt match expected number of RLE results (" & integer'image(exp_counts'length) & ")"
        severity error;
    end procedure;
 
begin
 
    uut: rle_encoder 
    generic map( 
        MAX_WIDTH => MAX_WIDTH, 
        COUNT_BITS => COUNT_BITS
    )
    port map(
        clk => CLK,
        row_width => row_width, 
        pixel_in => pixel_in, 
        value_out => value_out,
        count_out => count_out,
        out_valid => out_valid 
    );
  
    CLK <= not CLK after 10 ns;
 
    process is
    begin
        check_row(CLK, pixel_in, row_width, out_valid, count_out, value_out,
                  input_row_generic, expected_counts_generic, expected_values_generic);
 
        check_row(CLK, pixel_in, row_width, out_valid, count_out, value_out,
                  input_row_overflow, expected_counts_overflow, expected_values_overflow);
 
        check_row(CLK, pixel_in, row_width, out_valid, count_out, value_out,
                  input_row_single_value, expected_counts_single_value, expected_values_single_value);
 
        wait;
    end process;
end behave;
 
