library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity subband_transpose_buffer_tb is
end subband_transpose_buffer_tb;

architecture tb of subband_transpose_buffer_tb is

    constant MAX_WIDTH      : integer := 4;
    constant MAX_HEIGHT     : integer := 4;

    signal clk              : std_logic := '0';
    signal row_width        : integer range 0 to MAX_WIDTH  := MAX_WIDTH;
    signal column_height    : integer range 0 to MAX_HEIGHT := MAX_HEIGHT;
    signal data_in          : std_logic_vector(9 downto 0);
    signal valid_in         : std_logic := '0';
    signal data_out         : std_logic_vector(9 downto 0);
    signal valid_out        : std_logic;

    component subband_transpose_buffer is
        generic (
            MAX_WIDTH       : integer := 8;
            MAX_HEIGHT      : integer := 8
        );
        port (
            clk             : in  std_logic;
            row_width       : in  integer range 0 to MAX_WIDTH;
            column_height   : in  integer range 0 to MAX_HEIGHT;
            data_in         : in  std_logic_vector(9 downto 0);
            valid_in        : in  std_logic;
            data_out        : out std_logic_vector(9 downto 0);
            valid_out       : out std_logic
        );
    end component subband_transpose_buffer;

    type test_row is array (0 to MAX_WIDTH - 1) of integer;
    type test_vector is array (natural range <>) of test_row;
    
    constant test_values_pass1        : test_vector := (
        (0,0,-18,-18),
        (0,0,-18,-18),
        (0,0,0,0),
        (0,0,0,0)
    );
    constant expected_values_pass1    : test_vector := (
        (0,0,0,0),
        (0,0,0,0),
        (-18,-18,0,0),
        (-18,-18,0,0)
    );
    constant test_values_pass2     : test_vector := (
        (32,32,32,32),
        (32,32,32,32),
        (20,20,32,32),
        (40,40,32,32)
    );
    constant expected_values_pass2 : test_vector := (
        (32,32,20,40),
        (32,32,20,40),
        (32,32,32,32),
        (32,32,32,32)
    );

begin

    uut: subband_transpose_buffer
    generic map (
        MAX_WIDTH       => MAX_WIDTH,
        MAX_HEIGHT      => MAX_HEIGHT
    )
    port map (
        clk             => clk,
        row_width       => row_width,
        column_height   => column_height,
        data_in         => data_in,
        valid_in        => valid_in,
        data_out        => data_out,
        valid_out       => valid_out
    );

    clk <= not clk after 10 ns;

    stimulus: process
    begin
        for i in 0 to column_height - 1 loop
            for j in 0 to row_width - 1 loop
                data_in <= std_logic_vector(to_signed(test_values_pass1(i)(j), 10));
                valid_in <= '1';
                wait until rising_edge(clk);
                wait for 1 ns;
                valid_in <= '0';
            end loop; 
        end loop;
        for i in 0 to row_width*column_height -1 loop
            wait until rising_edge(clk) and valid_out = '1';
        end loop;
        for i in 0 to column_height - 1 loop
            for j in 0 to row_width - 1 loop
                data_in <= std_logic_vector(to_signed(test_values_pass2(i)(j), 10));
                valid_in <= '1';
                wait until rising_edge(clk);
                wait for 1 ns;
                valid_in <= '0';
            end loop; 
        end loop;
        wait;
    end process;

    check_output: process
        variable pass           : integer   := 1;
        variable row_index      : integer   := 0;
        variable column_index   : integer   := 0;
    begin
        wait until rising_edge(clk);
        wait for 1 ns;
        if valid_out = '1' and pass = 1 then
            assert to_integer(signed(data_out)) = expected_values_pass1(row_index)(column_index)
            report "first pass result (" & integer'image(row_index) & ")(" & integer'image(column_index) & ") failed: result = " & integer'image(to_integer(signed(data_out))) & ", expected " & integer'image(expected_values_pass1(row_index)(column_index))
            severity error;

            if column_index = row_width - 1 then
                column_index    := 0;
                row_index       := row_index + 1;
            else
                column_index    := column_index + 1;
            end if;

            if row_index = column_height then
                row_index       := 0;
                column_index    := 0;
                pass            := 2;
            end if;

        elsif valid_out = '1' and pass = 2 then
            assert to_integer(signed(data_out)) = expected_values_pass2(row_index)(column_index)
            report "second pass result (" & integer'image(row_index) & ")(" & integer'image(column_index) & ") failed: result = " & integer'image(to_integer(signed(data_out))) & ", expected " & integer'image(expected_values_pass2(row_index)(column_index))
            severity error;

            if column_index = row_width - 1 then
                column_index    := 0;
                row_index       := row_index + 1;
            else
                column_index    := column_index + 1;
            end if;

            if row_index = column_height then
                row_index       := 0;
                column_index    := 0;
                pass            := 1;
                wait;
            end if;
        end if;
    end process;

end tb;