library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity haar_2d_encoder_tb is
end haar_2d_encoder_tb;

architecture behave of haar_2d_encoder_tb is
    constant MAX_WIDTH      : integer := 8;
    constant MAX_HEIGHT     : integer := 8;

    signal clk              : std_logic := '0';
    signal row_width        : integer range 0 to MAX_WIDTH  := 8;
    signal column_height    : integer range 0 to MAX_HEIGHT := 8;
    signal pixel_in         : std_logic_vector(7 downto 0);
    signal lh_shift         : integer := 0;
    signal ll_shift         : integer := 0;
    signal hh_shift         : integer := 0;
    signal hl_shift         : integer := 0;
    signal lh_out           : std_logic_vector(9 downto 0);
    signal ll_out           : std_logic_vector(9 downto 0);
    signal hh_out           : std_logic_vector(9 downto 0);
    signal hl_out           : std_logic_vector(9 downto 0);
    signal lh_valid         : std_logic;
    signal ll_valid         : std_logic;
    signal hh_valid         : std_logic;
    signal hl_valid         : std_logic;

    component haar_2d_encoder is
        generic (
            MAX_WIDTH       : integer := 8; MAX_HEIGHT : integer := 8
        );
        port (
            clk             : in  std_logic;
            row_width       : in  integer range 0 to MAX_WIDTH;
            column_height   : in  integer range 0 to MAX_HEIGHT;
            pixel_in        : in  std_logic_vector(7 downto 0);
            lh_shift        : in  integer; 
            ll_shift        : in  integer;
            hh_shift        : in  integer;
            hl_shift        : in  integer;
            lh_out          : out std_logic_vector(9 downto 0);
            ll_out          : out std_logic_vector(9 downto 0);
            hh_out          : out std_logic_vector(9 downto 0);
            hl_out          : out std_logic_vector(9 downto 0);
            lh_valid        : out std_logic;
            ll_valid        : out std_logic;
            hh_valid        : out std_logic;
            hl_valid        : out std_logic
        );
    end component;

    type test_row is array (0 to 7) of integer;
    type test_vector is array (0 to 7) of test_row;
    type expected_row is array (0 to 3) of integer;
    type expected_vector is array (0 to 3) of expected_row;

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

    constant lh_exp : expected_vector := (
        (0,0,0,0),
        (0,0,0,0),
        (-18,-18,0,0),
        (-18,-18,0,0)
    );
    constant ll_exp : expected_vector := (
        (32,32,20,40),
        (32,32,20,40),
        (32,32,32,32),
        (32,32,32,32)
    );
    constant hh_exp : expected_vector := (
        (0,0,0,0),
        (0,0,0,0),
        (0,0,-18,-18),
        (0,0,-18,-18)
    );
    constant hl_exp : expected_vector := (
        (0,0,-5,-5),
        (0,0,-5,-5),
        (0,0,0,0),
        (0,0,0,0)
    );

begin
    uut: haar_2d_encoder
    generic map (
        MAX_WIDTH       => MAX_WIDTH, 
        MAX_HEIGHT      => MAX_HEIGHT
    )
    port map (
        clk             => clk, 
        row_width       => row_width, 
        column_height   => column_height,
        pixel_in        => pixel_in,
        lh_shift        => lh_shift,
        ll_shift        => ll_shift,
        hh_shift        => hh_shift,
        hl_shift        => hl_shift,
        lh_out          => lh_out, 
        ll_out          => ll_out, 
        hh_out          => hh_out, 
        hl_out          => hl_out,
        lh_valid        => lh_valid, 
        ll_valid        => ll_valid, 
        hh_valid        => hh_valid, 
        hl_valid        => hl_valid
    );

    clk         <= not clk after 10 ns;
    lh_shift    <= 3;
    ll_shift    <= 2;
    hh_shift    <= 4;
    hl_shift    <= 3; 
    
stream_pixels: process
begin
    for i in 0 to column_height - 1 loop
        for j in 0 to row_width - 1 loop
            pixel_in <= std_logic_vector(to_unsigned(src(i)(j), 8));
            wait until rising_edge(clk);
            wait until falling_edge(clk);
        end loop; 
    end loop;
    wait;
end process;

check_ll_lh: process
    variable row_index, column_index : integer := 0;
begin
    loop
        wait until rising_edge(clk);
        wait until falling_edge(clk);
        if ll_valid = '1' then
            assert to_integer(signed(lh_out)) = lh_exp(row_index)(column_index)
            report "LH(" & integer'image(row_index) & ")(" & integer'image(column_index) & ") failed: LH = " & integer'image(to_integer(signed(lh_out))) & ", expected " & integer'image(lh_exp(row_index)(column_index))
            severity error;
            assert to_integer(signed(ll_out)) = ll_exp(row_index)(column_index)
            report "LL(" & integer'image(row_index) & ")(" & integer'image(column_index) & ") failed: LL = " & integer'image(to_integer(signed(ll_out))) & ", expected " & integer'image(ll_exp(row_index)(column_index))
            severity error;

            if row_index = column_height/2 - 1 then
                row_index := 0;
                column_index := column_index + 1;
            else
                row_index := row_index + 1;
            end if;
            if column_index = row_width/2 then
                column_index := 0;
                wait;
            end if;
        end if;
    end loop;
end process;

check_hl_hh: process
    variable row_index, column_index : integer := 0;
begin
    loop
        wait until rising_edge(clk);
        wait until falling_edge(clk);
        if hl_valid = '1' then
            assert to_integer(signed(hh_out)) = hh_exp(row_index)(column_index)
            report "HH(" & integer'image(row_index) & ")(" & integer'image(column_index) & ") failed: HH = " & integer'image(to_integer(signed(hh_out))) & ", expected " & integer'image(hh_exp(row_index)(column_index))
            severity error;
            assert to_integer(signed(hl_out)) = hl_exp(row_index)(column_index)
            report "HL(" & integer'image(row_index) & ")(" & integer'image(column_index) & ") failed: HL = " & integer'image(to_integer(signed(hl_out))) & ", expected " & integer'image(hl_exp(row_index)(column_index))
            severity error;

            if row_index = column_height/2 - 1 then
                row_index       := 0;
                column_index    := column_index + 1;
            else
                row_index := row_index + 1;
            end if;
            if column_index = row_width/2 then
                column_index := 0;
                wait;
            end if;
        end if;
    end loop;
end process;

end behave;