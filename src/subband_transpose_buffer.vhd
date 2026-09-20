library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity subband_transpose_buffer is
    generic (
    MAX_WIDTH           : integer := 8;
    MAX_HEIGHT          : integer := 8
    );
    port(
        clk             : in  std_logic;
        row_width       : in  integer range 0 to MAX_WIDTH;
        column_height   : in  integer range 0 to MAX_HEIGHT;
        data_in         : in std_logic_vector(9 downto 0);
        valid_in        : in std_logic;
        data_out        : out std_logic_vector(9 downto 0);
        valid_out       : out std_logic
    );
end entity subband_transpose_buffer;

architecture rtl of subband_transpose_buffer is

    type state_type is (FILL, DRAIN);
    type buffer_row is array (0 to MAX_WIDTH - 1) of std_logic_vector(9 downto 0);
    type buffer_array is array (0 to MAX_HEIGHT - 1) of buffer_row;

    signal state            : state_type    := FILL;
    signal subband_buffer   : buffer_array;
    signal write_row        : integer       := 0;
    signal write_column     : integer       := 0;
    signal read_row         : integer       := 0;
    signal read_column      : integer       := 0;
    signal last_read        : std_logic     := '0';

begin
    data_out <= subband_buffer(read_row)(read_column);
    valid_out <= '1' when state = DRAIN else '0';
    last_read <= '1' when read_row = column_height - 1 and read_column = row_width - 1 else '0';
process(clk)
begin
    if rising_edge(clk) then
        if last_read = '1' then
            read_row    <= 0;
            read_column <= 0;
            state       <= FILL;
        else
            case state is 
                when FILL =>
                    if write_column = row_width then
                        write_row       <= 0;
                        write_column    <= 0; 
                        state           <= DRAIN;
                    else
                        if valid_in = '1' then
                            subband_buffer(write_row)(write_column) <= data_in;
                            if write_row = column_height - 1 then
                                write_row       <= 0;
                                write_column    <= write_column + 1;
                            else
                                write_row       <= write_row + 1;
                            end if;
                        end if;
                    end if;
                when DRAIN =>
                    if read_column = row_width - 1 then
                        read_column     <= 0;
                        read_row        <= read_row + 1;
                    else
                        read_column     <= read_column + 1;
                    end if;
            end case;
        end if;
    end if;
end process;
end rtl;
