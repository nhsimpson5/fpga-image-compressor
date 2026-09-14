library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity haar_butterfly_wide_tb is
end haar_butterfly_wide_tb;

architecture behave of haar_butterfly_wide_tb is 
    --inputs
    signal a_in: std_logic_vector(8 downto 0);
    signal b_in: std_logic_vector(8 downto 0);
    --outputs
    signal d_out: std_logic_vector(9 downto 0); 
    signal s_out: std_logic_vector(8 downto 0);

    component haar_butterfly_wide is
        port(
            a_in    : in std_logic_vector(8 downto 0); 
            b_in    : in std_logic_vector(8 downto 0);
            d_out   : out std_logic_vector(9 downto 0); 
            s_out   : out std_logic_vector(8 downto 0) 
        );
        end component haar_butterfly_wide;
    
    -- test arrays
    type test_vector is array (natural range <>) of integer;

    constant test_vector_a : test_vector := (
        255, -255, 255, -255, 0, 255, -255, 1
    );
    constant test_vector_b : test_vector := (
        -255, 255, 255, -255, 0, 0, 0, 3
    );
    constant test_vector_d : test_vector := (
        510, -510, 0, 0, 0, 255, -255, -2
    );
    constant test_vector_s : test_vector := (
        0, 0, 255, -255, 0, 127, -128, 2
    );
    
begin
    uut: haar_butterfly_wide
    port map(
        a_in => a_in,
        b_in => b_in,
        d_out => d_out,
        s_out => s_out
    );

    process is
    begin
    for i in 0 to test_vector_a'length - 1 loop
        a_in <= std_logic_vector(to_signed(test_vector_a(i), 9));
        b_in <= std_logic_vector(to_signed(test_vector_b(i), 9));
        wait for 1 ns;
        assert d_out = std_logic_vector(to_signed(test_vector_d(i), 10))
        report "test vector " & integer'image(i + 1) & " failed: gave d = " & integer'image(to_integer(signed(d_out))) & ", should have given d = " & integer'image(test_vector_d(i))
        severity error;
        assert s_out = std_logic_vector(to_signed(test_vector_s(i), 9))
        report "test vector " & integer'image(i + 1) & " failed: gave s = " & integer'image(to_integer(signed(s_out))) & ", should have given s = " & integer'image(test_vector_s(i))
        severity error;
    end loop;
    report"tests complete";
    wait;
    end process;
end behave;
