library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity haar_butterfly is
    port (
        a_in    : in std_logic_vector(7 downto 0);
        b_in    : in std_Logic_vector(7 downto 0);
        d_out   : out std_logic_vector(8 downto 0); --signed, extra bit
        s_out   : out std_logic_vector(7 downto 0)
    );
end haar_butterfly;

architecture rtl of haar_butterfly is 
    signal a    : signed(8 downto 0);
    signal b    : signed(8 downto 0);
    signal d    : signed(8 downto 0);
    signal s    : unsigned(7 downto 0);
begin
    a <= signed(resize(unsigned(a_in), 9));
    b <= signed(resize(unsigned(b_in), 9));
    d <= a - b;
    s <= resize(unsigned(b + shift_right(signed(d), 1)), 8);
    d_out <= std_logic_vector(d);
    s_out <= std_logic_vector(s);
end rtl;