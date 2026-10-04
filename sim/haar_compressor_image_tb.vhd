library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity haar_compressor_image_tb is
end haar_compressor_image_tb;

architecture behave of haar_compressor_image_tb is
    constant MAX_WIDTH  : integer   := 16;  
    constant MAX_HEIGHT : integer   := 16;
    constant COUNT_BITS : integer   := 5;
    constant DATA_WIDTH : integer   := 10;
    constant IMAGE_NAME : string    := "gradient_8x8";

    signal clk                                      : std_logic := '0';
    signal row_width                                : integer range 0 to MAX_WIDTH  := MAX_WIDTH;
    signal column_height                            : integer range 0 to MAX_HEIGHT := MAX_HEIGHT;
    signal colour_depth                             : integer := 0;
    signal pixel_in                                 : std_logic_vector(7 downto 0);
    signal lh_shift, ll_shift, hh_shift, hl_shift   : integer := 0;

    signal lh_value_out, ll_value_out, hh_value_out, hl_value_out : std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal lh_count_out, ll_count_out, hh_count_out, hl_count_out : std_logic_vector(COUNT_BITS - 1 downto 0);
    signal lh_out_valid, ll_out_valid, hh_out_valid, hl_out_valid : std_logic;

    signal lh_subband_status, ll_subband_status, hh_subband_status, hl_subband_status : std_logic := '0';


begin

    uut: entity work.haar_compressor
    generic map (
        MAX_WIDTH       => MAX_WIDTH,
        MAX_HEIGHT      => MAX_HEIGHT,
        COUNT_BITS      => COUNT_BITS    
    )
    port map (
        clk             => clk,
        row_width       => row_width,
        column_height   => column_height,
        pixel_in        => pixel_in,
        lh_shift        => lh_shift,      ll_shift        => ll_shift,      hh_shift        => hh_shift,        hl_shift => hl_shift,
        lh_value_out    => lh_value_out,  lh_count_out    => lh_count_out,  lh_out_valid    => lh_out_valid,
        ll_value_out    => ll_value_out,  ll_count_out    => ll_count_out,  ll_out_valid    => ll_out_valid,
        hh_value_out    => hh_value_out,  hh_count_out    => hh_count_out,  hh_out_valid    => hh_out_valid,
        hl_value_out    => hl_value_out,  hl_count_out    => hl_count_out,  hl_out_valid    => hl_out_valid
    );

    clk <= not clk after 10 ns;
    
    --set subband shift values
    lh_shift <= 3;
    ll_shift <= 2;
    hl_shift <= 4;
    hh_shift <= 3;

    
    stimulus: process
        file input_file                             : text;
        variable in_status                          : file_open_status;
        variable l                                  : line;
        variable width, height, maxval, pixel_value : integer;
    begin
        file_open(in_status, input_file, "images/" & IMAGE_NAME & ".pgm", read_mode);
        assert in_status = open_ok report "Failed to open input file" severity failure;

        readline(input_file, l);           
        readline(input_file, l);
        read(l, width);
        row_width <= width;
        read(l, height);
        column_height <= height;
        readline(input_file, l);
        read(l, maxval);
        
        row_width       <= width;
        column_height   <= height;
        colour_depth    <= maxval;

        for row in 0 to height - 1 loop
            readline(input_file, l);
            for col in 0 to width - 1 loop
                read(l, pixel_value);
                pixel_in <= std_logic_vector(to_unsigned(pixel_value, 8));
                wait until rising_edge(clk);
                wait until falling_edge(clk);
            end loop;
        end loop;

        file_close(input_file);
        wait;
    end process;


    lh_collect : process
        file lh_tmp_file      : text open write_mode is "sim/output/lh_tmp.txt";
        variable l            : line;
        variable total_count  : integer := 0;
    begin
        wait until rising_edge(clk);
        wait until falling_edge(clk);
        if lh_out_valid = '1' and lh_subband_status = '0' then
            write(l, to_integer(unsigned(lh_count_out)));
            write(l, string'(" "));
            write(l, to_integer(signed(lh_value_out)));
            writeline(lh_tmp_file, l);
            total_count := total_count + to_integer(unsigned(lh_count_out));
            if total_count = (row_width/2) * (column_height/2) then
                lh_subband_status <= '1';
                file_close(lh_tmp_file);
            end if;
        end if;
    end process;


    ll_collect : process
        file ll_tmp_file      : text open write_mode is "sim/output/ll_tmp.txt";
        variable l            : line;
        variable total_count  : integer := 0;
    begin
        wait until rising_edge(clk);
        wait until falling_edge(clk);
        if ll_out_valid = '1' and ll_subband_status = '0' then
            write(l, to_integer(unsigned(ll_count_out)));
            write(l, string'(" "));
            write(l, to_integer(signed(ll_value_out)));
            writeline(ll_tmp_file, l);
            total_count := total_count + to_integer(unsigned(ll_count_out));
            if total_count = (row_width/2) * (column_height/2) then
                ll_subband_status <= '1';
                file_close(ll_tmp_file);
            end if;
        end if;
    end process;


    hl_collect : process
        file hl_tmp_file      : text open write_mode is "sim/output/hl_tmp.txt";
        variable l            : line;
        variable total_count  : integer := 0;
    begin
        wait until rising_edge(clk);
        wait until falling_edge(clk);
        if hl_out_valid = '1' and hl_subband_status = '0' then
            write(l, to_integer(unsigned(hl_count_out)));
            write(l, string'(" "));
            write(l, to_integer(signed(hl_value_out)));
            writeline(hl_tmp_file, l);
            total_count := total_count + to_integer(unsigned(hl_count_out));
            if total_count = (row_width/2) * (column_height/2) then
                hl_subband_status <= '1';
                file_close(hl_tmp_file);
            end if;
        end if;
    end process;


    hh_collect : process
        file hh_tmp_file      : text open write_mode is "sim/output/hh_tmp.txt";
        variable l            : line;
        variable total_count  : integer := 0;
    begin
        wait until rising_edge(clk);
        wait until falling_edge(clk);
        if hh_out_valid = '1' and hh_subband_status = '0' then
            write(l, to_integer(unsigned(hh_count_out)));
            write(l, string'(" "));
            write(l, to_integer(signed(hh_value_out)));
            writeline(hh_tmp_file, l);
            total_count := total_count + to_integer(unsigned(hh_count_out));
            if total_count = (row_width/2) * (column_height/2) then
                hh_subband_status <= '1';
                file_close(hh_tmp_file);
            end if;
        end if;
    end process;

    write_wvlt1: process
        file output_file            : text;
        file tmp_file               : text;
        variable status             : file_open_status;
        variable l                  : line;
        variable pair_total         : integer := 0;
        variable compression_ratio  : real;
    begin
        wait until lh_subband_status = '1' and ll_subband_status = '1'and hl_subband_status = '1' and hh_subband_status = '1';
        file_open(status, output_file, "sim/output/" & IMAGE_NAME & ".wvlt", write_mode);

        -- header section
        write(l, string'("WVLT1"));
        writeline(output_file, l);
        write(l, row_width);
        write(l, string'(" "));
        write(l, column_height);
        writeline(output_file, l);
        write(l, colour_depth);
        writeline(output_file, l);
        write(l, lh_shift);
        write(l, string'(" "));
        write(l, ll_shift);
        write(l, string'(" "));
        write(l, hl_shift);
        write(l, string'(" "));
        write(l, hh_shift);
        writeline(output_file, l);

        -- LH section
        write(l, string'("LH"));
        writeline(output_file, l);
        file_open(status, tmp_file, "sim/output/lh_tmp.txt", read_mode);
        while not endfile(tmp_file) loop
            readline(tmp_file, l);
            writeline(output_file, l);
            pair_total := pair_total + 1;
        end loop;
        file_close(tmp_file);

        -- LL section
        write(l, string'("LL"));
        writeline(output_file, l);
        file_open(status, tmp_file, "sim/output/ll_tmp.txt", read_mode);
        while not endfile(tmp_file) loop
            readline(tmp_file, l);
            writeline(output_file, l);
            pair_total := pair_total + 1;
        end loop;
        file_close(tmp_file);

        -- HL section
        write(l, string'("HL"));
        writeline(output_file, l);
        file_open(status, tmp_file, "sim/output/hl_tmp.txt", read_mode);
        while not endfile(tmp_file) loop
            readline(tmp_file, l);
            writeline(output_file, l);
            pair_total := pair_total + 1;
        end loop;
        file_close(tmp_file);

        -- HH section
        write(l, string'("HH"));
        writeline(output_file, l);
        file_open(status, tmp_file, "sim/output/hh_tmp.txt", read_mode);
        while not endfile(tmp_file) loop
            readline(tmp_file, l);
            writeline(output_file, l);
            pair_total := pair_total + 1;
        end loop;
        file_close(tmp_file);
        file_close(output_file);

        compression_ratio := real(row_width*column_height*8) / real(pair_total*(DATA_WIDTH + COUNT_BITS));
        report "compression ratio: " & real'image(compression_ratio);
        report "image dimensions processed";
        wait;
    end process;
end behave;