library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity haar_butterfly_tb is
end haar_butterfly_tb;

architecture behave of haar_butterfly_tb is 
    --inputs
    signal a_in: std_logic_vector(7 downto 0);
    signal b_in: std_logic_vector(7 downto 0);
    --outputs
    signal d_out: std_logic_vector(8 downto 0); --signed, extra bit
    signal s_out: std_logic_vector(7 downto 0);

    component haar_butterfly is
        port(
            a_in    : in std_logic_vector(7 downto 0); 
            b_in    : in std_logic_vector(7 downto 0);
            d_out   : out std_logic_vector(8 downto 0); --signed, extra bit
            s_out   : out std_logic_vector(7 downto 0) 
        );
        end component haar_butterfly;

    type test_array is array (natural range <>) of integer;
    -- test arrays
    constant test_array_a : test_array := (
        12, 13, 100, 255, 0, 255, 0, 200
    );
    constant test_array_b : test_array := (
        14, 14, 100, 0, 255, 255, 0, 3
    );
    constant test_array_d : test_array := (
        -2, -1, 0, 255, -255, 0, 0, 197
    );
    constant test_array_s : test_array := (
        13, 13, 100, 127, 127, 255, 0, 101
    );
    
begin
    uut: haar_butterfly
    port map(
        a_in => a_in,
        b_in => b_in,
        d_out => d_out,
        s_out => s_out
    );

    process is
    begin
    for i in 0 to test_array_a'length - 1 loop
        a_in <= std_logic_vector(to_unsigned(test_array_a(i), 8));
        b_in <= std_logic_vector(to_unsigned(test_array_b(i), 8));
        wait for 1 ns;
        assert d_out = std_logic_vector(to_signed(test_array_d(i), 9))
        report "test vector " & integer'image(i + 1) & " failed: gave d = " & integer'image(to_integer(signed(d_out))) & ", should have given d = " & integer'image(test_array_d(i))
        severity error;
        assert s_out = std_logic_vector(to_unsigned(test_array_s(i), 8))
        report "test vector " & integer'image(i + 1) & " failed: gave s = " & integer'image(to_integer(unsigned(s_out))) & ", should have given s = " & integer'image(test_array_s(i))
        severity error;
    end loop;
    report"tests complete";
    wait;
    end process;
end behave;
