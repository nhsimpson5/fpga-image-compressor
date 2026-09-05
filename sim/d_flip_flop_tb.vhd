library ieee;
use ieee.std_logic_1164.all;

entity d_flip_flop_tb is
end d_flip_flop_tb;

architecture behave of d_flip_flop_tb is
    --Inputs
    signal CLK  : std_logic := '0';
    signal D    : std_logic;
    --Outputs
    signal Q    :std_logic;

    component d_flip_flop is 
        port(
            clk : in  std_logic;
            d   : in  std_logic;
            q   : out std_logic);
    end component d_flip_flop;
    
begin
    uut: d_flip_flop
        port map (
            clk => CLK,
            d => D,
            q => Q
        );

    CLK <= not CLK after 10 ns;

    process is
    begin
        D <= '1';
        wait until rising_edge(CLK);
        wait for 1 ns;
        assert D = Q
        report "D flip flop produced wrong result"
        severity error;
        wait for 10 ns;
        D <= '0';
        wait until rising_edge(CLK);
        wait for 1 ns;
        assert D = Q
        report "D flip flop produced wrong result"
        severity error;
        wait;
    end process;
end behave;