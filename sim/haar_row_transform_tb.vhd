library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity haar_row_transform_tb is
end haar_row_transform_tb;

architecture behave of haar_row_transform_tb is
    --constants
    constant MAX_WIDTH  : integer := 8;
    --inputs
    signal CLK          : std_logic := '0';
    signal row_width    : integer range 0 to MAX_WIDTH; 
    signal pixel_in     : std_logic_vector(7 downto 0);
    --outputs
    signal d_out        : std_logic_vector(8 downto 0); 
    signal s_out        : std_logic_vector(7 downto 0);
    signal out_valid    : std_logic;

    component haar_row_transform is
        generic (
            MAX_WIDTH   : integer := 8 --pixels per row
        );
        port(
            clk         : in  std_logic;
            row_width   : in  integer range 0 to MAX_WIDTH;
            pixel_in    : in  std_logic_vector(7 downto 0);
            d_out       : out std_logic_vector(8 downto 0); 
            s_out       : out std_logic_vector(7 downto 0);
            out_valid   : out std_logic
        );
    end component haar_row_transform;

    --test vectors
    type test_vector is array (natural range <>) of integer;

    --input test vectors
    constant test_row_a : test_vector := (
        10, 20, 100, 50, 0, 255, 128, 130
    );
    constant test_row_b : test_vector := (
        5, 15, 200, 50
    );
    constant test_row_c : test_vector := (
        77, 77, 77, 77, 77, 77, 77, 77 
    );
    constant test_row_d : test_vector := (
        1, 3, 5, 7, 9, 11, 13, 15
    );

    --expected results for test vectors
    constant expected_row_a : test_vector := (
        -10, 15, 50, 75, -255, 127, -2, 129 
    );
    constant expected_row_b : test_vector := (
        -10, 10, 150, 125
    );
    constant expected_row_c : test_vector := (
        0, 77, 0, 77, 0, 77, 0, 77
    );
    constant expected_row_d : test_vector := (
        -2, 2, -2, 6, -2, 10, -2, 14 
    );

    procedure test_row (
        constant test_row       : in test_vector;
        constant expected_row   : in test_vector;
        signal clk              : in std_logic;
        signal row_width        : out integer range 0 to MAX_WIDTH;
        signal pixel_in         : out std_logic_vector(7 downto 0);
        signal d_out            : in std_logic_vector(8 downto 0); 
        signal s_out            : in std_logic_vector(7 downto 0);
        signal out_valid        : in std_logic
    ) is 
        variable pair_index     : integer := 0;
    begin
        row_width <= test_row'length;
        for i in 0 to test_row'length - 1 loop
            pixel_in <= std_logic_vector(to_unsigned(test_row(i), 8));
            wait until rising_edge(clk);
            wait until falling_edge(clk);
            if out_valid = '1' then
                assert d_out = std_logic_vector(to_signed(expected_row(pair_index*2), 9))
                report "pair " & integer'image(i + 1) & " failed : d = " & integer'image(to_integer(signed(d_out))) & ", expected " & integer'image(expected_row(pair_index*2))
                severity error;
                assert s_out = std_logic_vector(to_unsigned(expected_row(pair_index*2 + 1), 8))
                report "pair " & integer'image(i + 1) & " failed : s = " & integer'image(to_integer(unsigned(s_out))) & ", expected " & integer'image(expected_row(pair_index*2 + 1))
                severity error;
                pair_index := pair_index + 1;
            end if;
        end loop;
    end procedure;

begin
    uut: haar_row_transform
    generic map(
        MAX_WIDTH => MAX_WIDTH
    )
    port map(
        clk       => CLK,
        row_width => row_width,
        pixel_in  => pixel_in,
        d_out     => d_out,
        s_out     => s_out, 
        out_valid => out_valid
    );

    CLK <= not CLK after 10 ns;
process is 
begin
    test_row(test_row_a, expected_row_a, CLK, row_width, pixel_in, d_out, s_out, out_valid);
    report "test a complete";
    test_row(test_row_b, expected_row_b, CLK, row_width, pixel_in, d_out, s_out, out_valid);
    report "test b complete";
    test_row(test_row_c, expected_row_c, CLK, row_width, pixel_in, d_out, s_out, out_valid);
    report "test c complete";
    test_row(test_row_d, expected_row_d, CLK, row_width, pixel_in, d_out, s_out, out_valid);
    report "test d complete";
    wait;
end process;
end behave;

