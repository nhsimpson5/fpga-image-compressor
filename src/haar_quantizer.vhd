library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity haar_quantizer is
    port (
        value_in    : in std_logic_vector(9 downto 0);
        shift       : in integer := 0;
        value_out   : out std_logic_vector(9 downto 0)
    );
end haar_quantizer;

architecture rtl of haar_quantizer is 
    signal shifted_value : signed(9 downto 0);
begin
    shifted_value   <= signed(shift_right(signed(value_in), shift));
    value_out       <= std_logic_vector(shifted_value); 
end rtl;