library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity haar_column_transform_tb is
end haar_column_transform_tb;

architecture behave of haar_column_transform_tb is
    --constants
    constant MAX_HEIGHT     : integer := 8; 
    --inputs
    signal CLK              : std_logic := '0';
    signal column_height    : integer range 0 to MAX_HEIGHT; 
    signal coeff_in         : std_logic_vector(8 downto 0);
    --outputs
    signal d_out            : std_logic_vector(9 downto 0); 
    signal s_out            : std_logic_vector(8 downto 0);
    signal out_valid        : std_logic;

    component haar_column_transform is
        generic (
            MAX_HEIGHT      : integer := 8 --coefficients per column
        );
        port(
            clk             : in  std_logic;
            column_height   : in  integer range 0 to MAX_HEIGHT;
            coeff_in        : in  std_logic_vector(8 downto 0);
            d_out           : out std_logic_vector(9 downto 0); 
            s_out           : out std_logic_vector(8 downto 0);
            out_valid       : out std_logic
        );
    end component haar_column_transform;

    --test vectors
    type test_vector is array (natural range <>) of integer;

    --input test vectors
    constant test_column_a : test_vector := (
        255, -255, 0, 100, -100, 50, 30, -30
    );
    constant test_column_b : test_vector := (
        30, -30, 150, -150
    );
    constant test_column_c : test_vector := (
        -77, -77, -77, -77, -77, -77, -77, -77 
    );
    constant test_column_d : test_vector := (
        10, 8, 6, 4, 2, 0, -2, -4
    );

    --expected results for test vectors
    constant expected_column_a : test_vector := (
        510, 0, -100, 50, -150, -25, 60, 0    
    );
    constant expected_column_b : test_vector := (
        60, 0, 300, 0
    );
    constant expected_column_c : test_vector := (
        0, -77, 0, -77, 0, -77, 0, -77  
    );
    constant expected_column_d : test_vector := (
        2, 9, 2, 5, 2, 1, 2, -3
    );

    procedure test_column (
        constant test_column        : in test_vector;
        constant expected_column    : in test_vector;
        signal clk                  : in std_logic;
        signal column_height        : out integer range 0 to MAX_HEIGHT;
        signal coeff_in             : out std_logic_vector(8 downto 0);
        signal d_out                : in std_logic_vector(9 downto 0); 
        signal s_out                : in std_logic_vector(8 downto 0);
        signal out_valid            : in std_logic
    ) is 
        variable pair_index         : integer := 0;
    begin
        column_height <= test_column'length;
        for i in 0 to test_column'length - 1 loop
            coeff_in <= std_logic_vector(to_signed(test_column(i), 9));
            wait until rising_edge(clk);
            wait until falling_edge(clk);
            if out_valid = '1' then
                assert d_out = std_logic_vector(to_signed(expected_column(pair_index*2), 10))
                report "pair " & integer'image(i + 1) & " failed : d = " & integer'image(to_integer(signed(d_out))) & ", expected " & integer'image(expected_column(pair_index*2))
                severity error;
                assert s_out = std_logic_vector(to_signed(expected_column(pair_index*2 + 1), 9))
                report "pair " & integer'image(i + 1) & " failed : s = " & integer'image(to_integer(unsigned(s_out))) & ", expected " & integer'image(expected_column(pair_index*2 + 1))
                severity error;
                pair_index := pair_index + 1;
            end if;
        end loop;
    end procedure;

begin
    uut: haar_column_transform
    generic map(
        MAX_HEIGHT => MAX_HEIGHT
    )
    port map(
        clk       => CLK,
        column_height => column_height,
        coeff_in  => coeff_in,
        d_out     => d_out,
        s_out     => s_out, 
        out_valid => out_valid
    );

    CLK <= not CLK after 10 ns;
process is 
begin
    test_column(test_column_a, expected_column_a, CLK, column_height, coeff_in, d_out, s_out, out_valid);
    report "test a complete";
    test_column(test_column_b, expected_column_b, CLK, column_height, coeff_in, d_out, s_out, out_valid);
    report "test b complete";
    test_column(test_column_c, expected_column_c, CLK, column_height, coeff_in, d_out, s_out, out_valid);
    report "test c complete";
    test_column(test_column_d, expected_column_d, CLK, column_height, coeff_in, d_out, s_out, out_valid);
    report "test d complete";
    wait;
end process;
end behave;

