library ieee;
use ieee.std_logic_1164.all;

entity and_gate is
    port(
        input_a, input_b    : in std_logic;
        and_result          : out std_logic
    );
    end and_gate;

architecture rtl of and_gate is
    signal result : std_logic;
begin 
        result <= input_a and input_b;
        and_result <= result;
end rtl;
