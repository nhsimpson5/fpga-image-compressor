library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;  

entity haar_2d_encoder is
generic (
    MAX_WIDTH : integer := 8;
    MAX_HEIGHT : integer := 8
);
port (
    clk             : in  std_logic;
    row_width       : in  integer range 0 to MAX_WIDTH;
    column_height   : in  integer range 0 to MAX_HEIGHT;
    pixel_in        : in  std_logic_vector(7 downto 0);
    lh_shift        : in  integer := 0; 
    ll_shift        : in  integer := 0;
    hh_shift        : in  integer := 0;
    hl_shift        : in  integer := 0;
    lh_out          : out std_logic_vector(9 downto 0);
    ll_out          : out std_logic_vector(9 downto 0);
    hh_out          : out std_logic_vector(9 downto 0);
    hl_out          : out std_logic_vector(9 downto 0);
    lh_valid        : out std_logic;
    ll_valid        : out std_logic;
    hh_valid        : out std_logic;
    hl_valid        : out std_logic
);

end entity haar_2d_encoder;

architecture rtl of haar_2d_encoder is

    type state_type is (ROW_PASS, COLUMN_PASS);
    type coefficient_row is array (0 to MAX_WIDTH - 1) of std_logic_vector(8 downto 0);
    type coefficient_array is array (0 to MAX_HEIGHT - 1) of coefficient_row;

    signal state                : state_type := ROW_PASS;
    signal coefficients         : coefficient_array;

    signal enable_row           : std_logic := '0';
    signal d_out                : std_logic_vector(8 downto 0);
    signal s_out                : std_logic_vector(7 downto 0);
    signal out_valid            : std_logic := '0';
    
    signal enable_column        : std_logic := '0';
    signal coeff_in             : std_logic_vector(8 downto 0);
    signal d_out_wide           : std_logic_vector(9 downto 0);
    signal s_out_wide           : std_logic_vector(8 downto 0);
    signal out_valid_wide       : std_logic := '0';

    signal row_index            : integer range 0 to MAX_HEIGHT     := 0;
    signal column_index         : integer range 0 to MAX_WIDTH      := 0;
    signal column_index_shadow  : integer range 0 to MAX_WIDTH      := 0;
    signal pair_index           : integer range 0 to MAX_WIDTH/2    := 0;
    signal last_pair            : std_logic := '0';

    signal s_out_wide_ext       : std_logic_vector(9 downto 0);
    signal shift_a              : integer := 0;
    signal shift_b              : integer := 0;
    signal value_a              : std_logic_vector(9 downto 0);
    signal value_b              : std_logic_vector(9 downto 0);

    component haar_row_transform is
        generic (
            MAX_WIDTH  : integer := 8 -- pixels per row
        );
        port(
            clk       : in  std_logic;
            enable    : in  std_logic;
            row_width : in  integer range 0 to MAX_WIDTH;
            pixel_in  : in  std_logic_vector(7 downto 0);
            d_out     : out std_logic_vector(8 downto 0); --signed, extra bit
            s_out     : out std_logic_vector(7 downto 0);
            out_valid : out std_logic
        );
    end component haar_row_transform;

    component haar_column_transform is 
        generic (
            MAX_HEIGHT  : integer := 8 --coefficients per column
        );
        port(
            clk           : in  std_logic;
            enable        : in  std_logic;
            column_height : in  integer range 0 to MAX_HEIGHT;
            coeff_in      : in  std_logic_vector(8 downto 0);
            d_out         : out std_logic_vector(9 downto 0); 
            s_out         : out std_logic_vector(8 downto 0);
            out_valid     : out std_logic
        );
    end component haar_column_transform;

    component haar_quantizer is 
        port(
            value_in    : in std_logic_vector(9 downto 0);
            shift       : in integer := 0;
            value_out   : out std_logic_vector(9 downto 0)
        );
    end component haar_quantizer;
    
begin

    bf_row: haar_row_transform
    generic map(
        MAX_WIDTH   => MAX_WIDTH
    )
    port map(
        clk         => clk,
        enable      => enable_row,
        row_width   => row_width,
        pixel_in    => pixel_in,
        d_out       => d_out,
        s_out       => s_out,
        out_valid   => out_valid
    ); 
    
    bf_column: haar_column_transform
    generic map(
        MAX_HEIGHT      => MAX_HEIGHT
    )
    port map(
        clk             => clk,
        enable          => enable_column,
        column_height   => column_height,
        coeff_in        => coeff_in,
        d_out           => d_out_wide,
        s_out           => s_out_wide,
        out_valid       => out_valid_wide
    );
    
    bf_quantizer_a: haar_quantizer
    port map(
        value_in    => d_out_wide,
        shift       => shift_a,
        value_out   => value_a
    );

    bf_quantizer_b: haar_quantizer
    port map(
        value_in    => s_out_wide_ext,
        shift       => shift_b,
        value_out   => value_b
    );

    enable_row          <= '1' when state = ROW_PASS    else '0';
    enable_column       <= '1' when state = COLUMN_PASS else '0';
    coeff_in            <= coefficients(row_index)(column_index);
    s_out_wide_ext      <= std_logic_vector(resize(signed(s_out_wide), 10));
    shift_a <= lh_shift when column_index_shadow < row_width/2 else hh_shift;
    shift_b <= ll_shift when column_index_shadow < row_width/2 else hl_shift;
     

process(clk) 
begin

    if rising_edge(clk) then
        column_index_shadow <= column_index;
        if row_index = column_height - 1 and column_index = row_width -1 then 
            last_pair <= '1';
        end if;
        if last_pair = '1' then
            last_pair <= '0';
            row_index <= 0;
            state <= ROW_PASS;
        end if;

        case state is
            when ROW_PASS =>
                if out_valid ='1' then
                    coefficients(row_index)(row_width/2 + pair_index)   <= d_out;
                    coefficients(row_index)(pair_index)                 <= std_logic_vector(resize(unsigned(s_out), 9));
                    if pair_index = (row_width-1)/2 then
                        row_index       <= row_index + 1;
                        pair_index      <= 0;
                        if row_index = column_height - 1 then 
                        row_index       <= 0;
                        state           <= COLUMN_PASS;
                        end if;
                    else
                        pair_index <= pair_index + 1;
                    end if;
                end if;
                
            when COLUMN_PASS =>
                if out_valid_wide ='1' then
                    if column_index_shadow < row_width/2 then
                            lh_out      <= value_a;
                            lh_valid    <= '1';
                            ll_out      <= value_b;
                            ll_valid    <= '1';
                        else
                            hh_out      <= value_a;
                            hh_valid    <= '1';
                            hl_out      <= value_b;
                            hl_valid    <= '1';
                        end if;
                else
                    lh_valid <= '0'; 
                    ll_valid <= '0';
                    hh_valid <= '0';
                    hl_valid <= '0';
                end if;
                if last_pair ='0' then
                    row_index <= row_index + 1;
                    if row_index = column_height - 1 then
                        row_index       <= 0;
                        column_index    <= column_index + 1;
                        if column_index = row_width - 1 then
                            column_index    <= 0;            
                        end if;
                    end if;
                end if;
        end case;
    end if;

end process;
end rtl;