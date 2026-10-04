library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity haar_compressor_tb is
end haar_compressor_tb;

architecture behave of haar_compressor_tb is

    constant MAX_WIDTH  : integer := 8;
    constant MAX_HEIGHT : integer := 8;
    constant COUNT_BITS : integer := 5;

    signal clk                                          : std_logic := '0';
    signal row_width                                    : integer range 0 to MAX_WIDTH  := MAX_WIDTH;
    signal column_height                                : integer range 0 to MAX_HEIGHT := MAX_HEIGHT;
    signal pixel_in                                     : std_logic_vector(7 downto 0);
    signal lh_shift, ll_shift, hh_shift, hl_shift       : integer := 0;

    signal lh_value_out   : std_logic_vector(9 downto 0);
    signal lh_count_out   : std_logic_vector(COUNT_BITS - 1 downto 0);
    signal lh_out_valid   : std_logic;

    signal ll_value_out   : std_logic_vector(9 downto 0);
    signal ll_count_out   : std_logic_vector(COUNT_BITS - 1 downto 0);
    signal ll_out_valid   : std_logic;

    signal hh_value_out   : std_logic_vector(9 downto 0);
    signal hh_count_out   : std_logic_vector(COUNT_BITS - 1 downto 0);
    signal hh_out_valid   : std_logic;

    signal hl_value_out   : std_logic_vector(9 downto 0);
    signal hl_count_out   : std_logic_vector(COUNT_BITS - 1 downto 0);
    signal hl_out_valid   : std_logic;

    type test_row is array (0 to 7) of integer;
    type test_vector is array (0 to 7) of test_row;
    type int_Array is array (natural range <>) of integer;

    constant src : test_vector := (
        (128,128,128,128, 60,100,140,180),
        (128,128,128,128, 60,100,140,180),
        (128,128,128,128, 60,100,140,180),
        (128,128,128,128, 60,100,140,180),
        (60,60,60,60,     60,200,60,200),
        (200,200,200,200, 200,60,200,60),
        (60,60,60,60,     60,200,60,200),
        (200,200,200,200, 200,60,200,60)
    );

    constant expected_lh_values : int_array := (0,     0,     -18,0,       -18,0);
    constant expected_lh_counts : int_array := (4,     4,     2,2,         2,2);

    constant expected_ll_values : int_array := (32,20,40,  32,20,40,  32,   32);
    constant expected_ll_counts : int_array := (2,1,1,     2,1,1,     4,    4);

    constant expected_hh_values : int_array := (0,     0,     0,-18,       0,-18);
    constant expected_hh_counts : int_array := (4,     4,     2,2,        2,2);

    constant expected_hl_values : int_array := (0,-5,      0,-5,      0,    0);
    constant expected_hl_counts : int_array := (2,2,       2,2,       4,    4);

begin

    uut: entity work.haar_compressor
    generic map (
        MAX_WIDTH  => MAX_WIDTH,
        MAX_HEIGHT => MAX_HEIGHT,
        COUNT_BITS => COUNT_BITS
    )
    port map (
        clk           => clk,
        row_width     => row_width,
        column_height => column_height,
        pixel_in      => pixel_in,
        lh_shift      => lh_shift,
        ll_shift      => ll_shift,
        hh_shift      => hh_shift,
        hl_shift      => hl_shift,

        lh_value_out  => lh_value_out,
        lh_count_out  => lh_count_out,
        lh_out_valid  => lh_out_valid,

        ll_value_out  => ll_value_out,
        ll_count_out  => ll_count_out,
        ll_out_valid  => ll_out_valid,

        hh_value_out  => hh_value_out,
        hh_count_out  => hh_count_out,
        hh_out_valid  => hh_out_valid,

        hl_value_out  => hl_value_out,
        hl_count_out  => hl_count_out,
        hl_out_valid  => hl_out_valid
    );

    clk <= not clk after 10 ns;

    --set subband shift values
    lh_shift <= 3;
    ll_shift <= 2;
    hl_shift <= 4;
    hh_shift <= 3;
    
    stimulus: process
    begin
        for i in 0 to column_height-1 loop
            for j in 0 to row_width-1 loop
                pixel_in <= std_logic_vector(to_unsigned(src(i)(j), 8));
                wait until rising_edge(clk);
                wait until falling_edge(clk);
            end loop;
        end loop; 
        wait;
    end process;

    lh_check: process
        variable index : integer:= 0;
    begin
        wait until rising_edge(clk);
        wait until falling_edge(clk);
        if lh_out_valid = '1' and index < expected_lh_values'length then
            assert to_integer(signed(lh_value_out)) = expected_lh_values(index)
            report "LH value " & integer'image(index) & " failed: expected " & integer'image(expected_lh_values(index)) & ", got " & integer'image(to_integer(signed(lh_value_out)))
            severity error;
            assert to_integer(signed(lh_count_out)) = expected_lh_counts(index)
            report "LH count " & integer'image(index) & " failed: expected " & integer'image(expected_lh_counts(index)) & ", got " & integer'image(to_integer(signed(lh_count_out)))
            severity error;
            index := index + 1;
        end if;
    end process;

    ll_check: process
        variable index : integer:= 0;
    begin
        wait until rising_edge(clk);
        wait until falling_edge(clk);
        if ll_out_valid = '1' and index < expected_ll_values'length then
            assert to_integer(signed(ll_value_out)) = expected_ll_values(index)
            report "LL value " & integer'image(index) & " failed: expected " & integer'image(expected_ll_values(index)) & ", got " & integer'image(to_integer(signed(ll_value_out)))
            severity error;
            assert to_integer(signed(ll_count_out)) = expected_ll_counts(index)
            report "LL count " & integer'image(index) & " failed: expected " & integer'image(expected_ll_counts(index)) & ", got " & integer'image(to_integer(signed(ll_count_out)))
            severity error;
            index := index + 1;
        end if;
    end process;

    hl_check: process
        variable index : integer:= 0;
    begin
        wait until rising_edge(clk);
        wait until falling_edge(clk);
        if hl_out_valid = '1' and index < expected_hl_values'length then
            assert to_integer(signed(hl_value_out)) = expected_hl_values(index)
            report "HL value " & integer'image(index) & " failed: expected " & integer'image(expected_hl_values(index)) & ", got " & integer'image(to_integer(signed(hl_value_out)))
            severity error;
            assert to_integer(signed(hl_count_out)) = expected_hl_counts(index)
            report "HL count " & integer'image(index) & " failed: expected " & integer'image(expected_hl_counts(index)) & ", got " & integer'image(to_integer(signed(hl_count_out)))
            severity error;
            index := index + 1;
        end if;
    end process;

    hh_check: process
        variable index : integer:= 0;
    begin
        wait until rising_edge(clk);
        wait until falling_edge(clk);
        if hh_out_valid = '1' and index < expected_hh_values'length then
            assert to_integer(signed(hh_value_out)) = expected_hh_values(index)
            report "HH value " & integer'image(index) & " failed: expected " & integer'image(expected_hh_values(index)) & ", got " & integer'image(to_integer(signed(hh_value_out)))
            severity error;
            assert to_integer(signed(hh_count_out)) = expected_hh_counts(index)
            report "HH count " & integer'image(index) & " failed: expected " & integer'image(expected_hh_counts(index)) & ", got " & integer'image(to_integer(signed(hh_count_out)))
            severity error;
            index := index + 1;
        end if;
    end process;

end behave;