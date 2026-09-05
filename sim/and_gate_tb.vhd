library ieee;
use ieee.std_logic_1164.all;

entity and_gate_tb is
end and_gate_tb;

architecture behave of and_gate_tb is
    --Inputs
    signal SIG1     : std_logic := '0';
    signal SIG2     : std_logic := '0';
    --Outputs
    signal RESULT   : std_logic;

component and_gate is
    port (
      input_a    : in  std_logic;
      input_b    : in  std_logic;
      and_result : out std_logic);
  end component and_gate;
   
begin
   
  uut: and_gate
    port map(
      input_a => SIG1,
      input_b => SIG2,
      and_result => RESULT
    );

  process is
  begin
    SIG1 <= '0';
    SIG2 <= '0';
    wait for 10 ns;
    assert RESULT = (SIG1 and SIG2)
    report "AND gate produced wrong result"
    severity ERROR;
    SIG1 <= '0';
    SIG2 <= '1';
    wait for 10 ns;
    assert RESULT = (SIG1 and SIG2)
    report "AND gate produced wrong result"
    severity ERROR;
    SIG1 <= '1';
    SIG2 <= '0';
    wait for 10 ns;
    assert RESULT = (SIG1 and SIG2)
    report "AND gate produced wrong result"
    severity ERROR;
    SIG1 <= '1';
    SIG2 <= '1';
    wait for 10 ns; 
    assert RESULT = (SIG1 and SIG2)
    report "AND gate produced wrong result"
    severity ERROR;  
    wait;
  end process;
     
end behave;