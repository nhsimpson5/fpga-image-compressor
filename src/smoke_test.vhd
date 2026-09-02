entity smoke_test is
end entity smoke_test;

architecture sim of smoke_test is
begin
  process
  begin
    report "GHDL is working";
    wait;
  end process;
end architecture sim;