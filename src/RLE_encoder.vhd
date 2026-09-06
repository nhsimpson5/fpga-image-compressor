library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rle_encoder is
  generic (
    MAX_WIDTH  : integer := 8;   -- pixels per row
    COUNT_BITS : integer := 5    -- bits in the run-length field
  );
  port(
    clk       : in  std_logic;
    row_width : in  integer range 0 to MAX_WIDTH;
    pixel_in  : in  std_logic_vector(7 downto 0);
    value_out : out std_logic_vector(7 downto 0);
    count_out : out std_logic_vector(COUNT_BITS - 1 downto 0);
    out_valid : out std_logic
  );
end rle_encoder;

architecture rtl of rle_encoder is

  type state_type is (ACCUMULATE, ROW_END);
  signal state       : state_type := ACCUMULATE;

  signal run_value   : std_logic_vector(7 downto 0);
  signal run_count   : unsigned(COUNT_BITS - 1 downto 0);
  signal pos_counter : integer range 0 to MAX_WIDTH - 1 := 0;

  constant MAX_COUNT : unsigned(COUNT_BITS - 1 downto 0) := (others => '1');

begin

  process(clk)
  begin
    if rising_edge(clk) then
      out_valid <= '0';  -- default each cycle unless a flush overrides it below

      case state is
        when ACCUMULATE =>
            if pos_counter = 0 then
                run_value <= pixel_in;
                run_count <= to_unsigned(1, run_count'length);
            else 
                if pixel_in = run_value and run_count < MAX_COUNT then 
                    run_count <= run_count + 1;
                else
                    --flush values
                    value_out <= run_value;
                    count_out <= std_logic_vector(run_count);
                    out_valid <= '1';
                    --restart 
                    run_value <= pixel_in;
                    run_count <= to_unsigned(1, run_count'length);
                end if;
            end if;
            if pos_counter = row_width - 1 then 
                state <= ROW_END;
            else 
                pos_counter <= pos_counter + 1;
            end if;
        when ROW_END =>
            --flush values
            value_out <= run_value;
            count_out <= std_logic_vector(run_count);
            out_valid <= '1';
            --restart 
            pos_counter <= 0;
            state <= ACCUMULATE;
      end case;
    end if;
  end process;

end rtl;