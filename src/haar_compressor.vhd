library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity haar_compressor is
    generic (
        MAX_WIDTH  : integer := 8;
        MAX_HEIGHT : integer := 8;
        COUNT_BITS : integer := 5
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

        lh_value_out    : out std_logic_vector(9 downto 0);
        lh_count_out    : out std_logic_vector(COUNT_BITS - 1 downto 0);
        lh_out_valid    : out std_logic;

        ll_value_out    : out std_logic_vector(9 downto 0);
        ll_count_out    : out std_logic_vector(COUNT_BITS - 1 downto 0);
        ll_out_valid    : out std_logic;

        hh_value_out    : out std_logic_vector(9 downto 0);
        hh_count_out    : out std_logic_vector(COUNT_BITS - 1 downto 0);
        hh_out_valid    : out std_logic;

        hl_value_out    : out std_logic_vector(9 downto 0);
        hl_count_out    : out std_logic_vector(COUNT_BITS - 1 downto 0);
        hl_out_valid    : out std_logic

    );
end entity haar_compressor;

architecture rtl of haar_compressor is

    signal lh_coeff, ll_coeff, hh_coeff, hl_coeff                                       : std_logic_vector(9 downto 0);
    signal lh_coeff_valid, ll_coeff_valid, hh_coeff_valid, hl_coeff_valid               : std_logic;

    signal lh_buffered, ll_buffered, hh_buffered, hl_buffered                           : std_logic_vector(9 downto 0);
    signal lh_buffered_valid, ll_buffered_valid, hl_buffered_valid, hh_buffered_valid   : std_logic;

    signal half_row_width     : integer range 0 to MAX_WIDTH  := 0;
    signal half_column_height : integer range 0 to MAX_HEIGHT := 0;

    
begin
    half_row_width     <= row_width / 2;
    half_column_height <= column_height / 2;
    
    haar_2d_encoder_inst: entity work.haar_2d_encoder
     generic map(
        MAX_WIDTH       => MAX_WIDTH,
        MAX_HEIGHT      => MAX_HEIGHT
    )
     port map(
        clk             => clk,
        row_width       => row_width,
        column_height   => column_height,
        pixel_in        => pixel_in,
        lh_shift        => lh_shift,
        ll_shift        => ll_shift,
        hh_shift        => hh_shift,
        hl_shift        => hl_shift,
        lh_out          => lh_coeff,
        ll_out          => ll_coeff,
        hh_out          => hh_coeff,
        hl_out          => hl_coeff,
        lh_valid        => lh_coeff_valid,
        ll_valid        => ll_coeff_valid,
        hh_valid        => hh_coeff_valid,
        hl_valid        => hl_coeff_valid
    );

    lh_subband_transpose_buffer_inst: entity work.subband_transpose_buffer
    generic map(
        MAX_WIDTH       => MAX_WIDTH/2,
        MAX_HEIGHT      => MAX_HEIGHT/2
    )
    port map(
        clk             => clk,
        row_width       => half_row_width,
        column_height   => half_column_height,
        data_in         => lh_coeff,
        valid_in        => lh_coeff_valid,
        data_out        => lh_buffered,
        valid_out       => lh_buffered_valid
    );

    ll_subband_transpose_buffer_inst: entity work.subband_transpose_buffer
    generic map(
        MAX_WIDTH       => MAX_WIDTH/2,
        MAX_HEIGHT      => MAX_HEIGHT/2
    )
    port map(
        clk             => clk,
        row_width       => half_row_width,
        column_height   => half_column_height,
        data_in         => ll_coeff,
        valid_in        => ll_coeff_valid,
        data_out        => ll_buffered,
        valid_out       => ll_buffered_valid
    );

    hl_subband_transpose_buffer_inst: entity work.subband_transpose_buffer
    generic map(
        MAX_WIDTH       => MAX_WIDTH/2,
        MAX_HEIGHT      => MAX_HEIGHT/2
    )
    port map(
        clk             => clk,
        row_width       => half_row_width,
        column_height   => half_column_height,
        data_in         => hl_coeff,
        valid_in        => hl_coeff_valid,
        data_out        => hl_buffered,
        valid_out       => hl_buffered_valid
    );

    hh_subband_transpose_buffer_inst: entity work.subband_transpose_buffer
    generic map(
        MAX_WIDTH       => MAX_WIDTH/2,
        MAX_HEIGHT      => MAX_HEIGHT/2
    )
    port map(
        clk             => clk,
        row_width       => half_row_width,
        column_height   => half_column_height,
        data_in         => hh_coeff,
        valid_in        => hh_coeff_valid,
        data_out        => hh_buffered,
        valid_out       => hh_buffered_valid
    );
    
    lh_rle_encoder_inst: entity work.rle_encoder
    generic map(
        MAX_WIDTH       => MAX_WIDTH/2,
        COUNT_BITS      => COUNT_BITS,
        DATA_WIDTH      => lh_buffered'length
    )
    port map(
        clk             => clk,
        row_width       => half_row_width,
        value_in        => lh_buffered,
        valid_in        => lh_buffered_valid,
        value_out       => lh_value_out,
        count_out       => lh_count_out,
        out_valid       => lh_out_valid
    );

    ll_rle_encoder_inst: entity work.rle_encoder
    generic map(
        MAX_WIDTH       => MAX_WIDTH/2,
        COUNT_BITS      => COUNT_BITS,
        DATA_WIDTH      => ll_buffered'length
    )
    port map(
        clk             => clk,
        row_width       => half_row_width,
        value_in        => ll_buffered,
        valid_in        => ll_buffered_valid,
        value_out       => ll_value_out,
        count_out       => ll_count_out,
        out_valid       => ll_out_valid
    );

    hl_rle_encoder_inst: entity work.rle_encoder
    generic map(
        MAX_WIDTH       => MAX_WIDTH/2,
        COUNT_BITS      => COUNT_BITS,
        DATA_WIDTH      => hl_buffered'length
    )
    port map(
        clk             => clk,
        row_width       => half_row_width,
        value_in        => hl_buffered,
        valid_in        => hl_buffered_valid,
        value_out       => hl_value_out,
        count_out       => hl_count_out,
        out_valid       => hl_out_valid
    );

    hh_rle_encoder_inst: entity work.rle_encoder
    generic map(
        MAX_WIDTH       => MAX_WIDTH/2,
        COUNT_BITS      => COUNT_BITS,
        DATA_WIDTH      => hh_buffered'length
    )
    port map(
        clk             => clk,
        row_width       => half_row_width,
        value_in        => hh_buffered,
        valid_in        => hh_buffered_valid,
        value_out       => hh_value_out,
        count_out       => hh_count_out,
        out_valid       => hh_out_valid
    );

end rtl;