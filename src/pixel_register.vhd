library ieee;
use ieee.std_logic_1164.all;

entity pixel_register is
    port(
        clk : in  std_logic;
        d   : in  std_logic_vector(7 downto 0);
        q   : out std_logic_vector(7 downto 0)
    );
end pixel_register;

architecture rtl of pixel_register is
begin
    process(clk)
    begin 
        if rising_edge(clk) then
        q <= d;
        end if;
    end process;
end rtl;