library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pixel_register_tb is
end pixel_register_tb;

architecture behave of pixel_register_tb is
    --Inputs
    signal CLK  : std_logic := '0';
    signal D    : std_logic_vector(7 downto 0);
    --Outputs
    signal Q    :std_logic_vector(7 downto 0);
    --Tests
    type test_array is array (natural range <>) of std_logic_vector(7 downto 0);
    constant test_vectors : test_array := (
    "00000000", "00000001", "00000010", "00000100", "00001000",
    "00010000", "00100000", "01000000", "10000000", "11111111"
    );
    component pixel_register is 
        port(
            clk : in  std_logic;
            d   : in  std_logic_vector(7 downto 0);
            q   : out std_logic_vector(7 downto 0));
    end component pixel_register;
    
begin
    uut: pixel_register
        port map (
            clk => CLK,
            d => D,
            q => Q
        );

    CLK <= not CLK after 10 ns;

    process is
    begin
        for i in test_vectors'range loop
            D <= test_vectors(i); 
            wait until rising_edge(CLK);
            wait for 1 ns;
            assert D = Q
            report "Pixel register produced wrong result for vector: " & integer'image(to_integer(unsigned(test_vectors(i))))
            severity error;
            wait for 10 ns;
        end loop;
        wait;
    end process;
end behave;