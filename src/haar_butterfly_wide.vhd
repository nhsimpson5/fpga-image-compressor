library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity haar_butterfly_wide is
    port (
        a_in    : in std_logic_vector(8 downto 0);
        b_in    : in std_Logic_vector(8 downto 0);
        d_out   : out std_logic_vector(9 downto 0); 
        s_out   : out std_logic_vector(8 downto 0)
    );
end haar_butterfly_wide;

architecture rtl of haar_butterfly_wide is 
    signal a    : signed(9 downto 0);
    signal b    : signed(9 downto 0);
    signal d    : signed(9 downto 0);
    signal s    : signed(8 downto 0);
begin
    a <= signed(resize(signed(a_in), 10));
    b <= signed(resize(signed(b_in), 10));
    d <= a - b;
    s <= resize(signed(b + shift_right(signed(d), 1)), 9);
    d_out <= std_logic_vector(d);
    s_out <= std_logic_vector(s);
end rtl;