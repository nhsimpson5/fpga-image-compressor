library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rle_encoder_tb is
end rle_encoder_tb;

architecture behave of rle_encoder_tb is

    constant MAX_WIDTH  : integer := 4;
    constant COUNT_BITS : integer := 5;
    constant DATA_WIDTH : integer := 10;

    signal clk       : std_logic := '0';
    signal row_width : integer range 0 to MAX_WIDTH := MAX_WIDTH;
    signal value_in  : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal valid_in  : std_logic := '0';
    signal value_out : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal count_out : std_logic_vector(COUNT_BITS - 1 downto 0);
    signal out_valid : std_logic;
    signal pairs_seen : integer := 0;

    type test_row    is array (0 to MAX_WIDTH - 1) of integer;
    type test_vector is array (natural range <>) of test_row;
    type int_array   is array (natural range <>) of integer;

    constant input_values : test_vector := (
        (0,0,0,0),
        (0,0,0,0),
        (-18,-18,0,0),
        (-18,-18,0,0),
        (32,32,20,40),
        (32,32,20,40),
        (32,32,32,32),
        (32,32,32,32)
    );


    --                                       row0   row1   row2        row3        row4          row5          row6  row7
    constant expected_values : int_array := (0,     0,     -18,0,      -18,0,      32,20,40,     32,20,40,     32,   32);
    constant expected_counts : int_array := (4,     4,     2,2,        2,2,        2,1,1,        2,1,1,        4,    4);

begin

    uut: entity work.rle_encoder
    generic map (
        MAX_WIDTH  => MAX_WIDTH,
        COUNT_BITS => COUNT_BITS,
        DATA_WIDTH => DATA_WIDTH
    )
    port map (
        clk       => clk,
        row_width => row_width,
        value_in  => value_in,
        valid_in  => valid_in,
        value_out => value_out,
        count_out => count_out,
        out_valid => out_valid
    );

    clk <= not clk after 10 ns;

    stimulus: process
    begin
        valid_in <= '1';
        for i in input_values'range loop
            for j in 0 to row_width - 1 loop
                value_in <= std_logic_vector(to_signed(input_values(i)(j), DATA_WIDTH));
                wait until rising_edge(clk);
                wait until falling_edge(clk);
            end loop;
        end loop;
        valid_in <= '0';
        wait;
    end process;

    check_output: process
        variable result_index : integer := 0;
    begin
        wait until rising_edge(clk);
        wait until falling_edge(clk);
        if out_valid = '1' then
            assert to_integer(signed(value_out)) = expected_values(result_index)
            report "pair (" & integer'image(result_index) & ") value failed: got " & integer'image(to_integer(signed(value_out))) & ", expected " & integer'image(expected_values(result_index))
            severity error;
            assert to_integer(unsigned(count_out)) = expected_counts(result_index)
            report "pair (" & integer'image(result_index) & ") count failed: got " & integer'image(to_integer(unsigned(count_out))) & ", expected " & integer'image(expected_counts(result_index))
            severity error;
            result_index := result_index + 1;
            pairs_seen   <= result_index;
            if result_index = expected_values'length then
                wait;
            end if;
        end if;
    end process;

    final_check: process
    begin
        wait for (input_values'length * MAX_WIDTH + 10) * 20 ns;
        assert pairs_seen = expected_values'length
        report "only received " & integer'image(pairs_seen) & " of the expected " & integer'image(expected_values'length) & " RLE pairs"
        severity error;
        wait;
    end process;

end behave;