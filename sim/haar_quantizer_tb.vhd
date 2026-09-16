library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity haar_quantizer_tb is 
end entity haar_quantizer_tb;

architecture behave of haar_quantizer_tb is
    signal value_in     : std_logic_vector(9 downto 0); 
    signal shift        : integer := 0;
    signal value_out    : std_logic_vector(9 downto 0);

    component haar_quantizer is
        port(
            value_in    : in std_logic_vector(9 downto 0);
            shift       : in integer := 0;
            value_out   : out std_logic_vector(9 downto 0)
        );
    end component haar_quantizer;

    type test_vector is array (natural range <>) of integer;

    constant test_value : test_vector := (
        100,-100,100,100,-100,-100,3,-1,-1,0,511,-512,-512,200
    );

    constant test_shift : test_vector := (
        0,0,1,3,1,3,2,1,9,5,1,1,9,9
    );

    constant expected_value : test_vector := (
        100,-100,50,12,-50,-13,0,-1,-1,0,255,-256,-1,0
    );

begin
    uut: haar_quantizer 
        port map(
            value_in    => value_in,
            shift       => shift,
            value_out   => value_out
        );

process is
begin
    for i in 0 to test_value'length - 1 loop
        value_in    <= std_logic_vector(to_signed(test_value(i), 10));
        shift       <= test_shift(i);
        wait for 1 ns;
        assert to_integer(signed(value_out)) = expected_value(i)
        report "returned: value_out = " & integer'image(to_integer(signed(value_out))) & ", expected " & integer'image(expected_value(i))
        severity error;
    end loop; 
end process;
end behave;
