library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rle_encoder is
  generic (
    MAX_WIDTH  : integer := 8;   
    COUNT_BITS : integer := 5;
    DATA_WIDTH : integer := 10
  );
  port(
    clk       : in  std_logic;
    row_width : in  integer range 0 to MAX_WIDTH;
    value_in  : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    valid_in  : in  std_logic := '0';
    value_out : out std_logic_vector(DATA_WIDTH-1 downto 0);
    count_out : out std_logic_vector(COUNT_BITS - 1 downto 0);
    out_valid : out std_logic
  );
end rle_encoder;

architecture rtl of rle_encoder is

  type state_type is (ACCUMULATE, ROW_END);
  signal state       : state_type := ACCUMULATE;

  signal run_value   : std_logic_vector(DATA_WIDTH-1 downto 0);
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
          if valid_in = '1' then
            if pos_counter = 0 then
                run_value <= value_in;
                run_count <= to_unsigned(1, run_count'length);
            else 
                if value_in = run_value and run_count < MAX_COUNT then 
                    run_count <= run_count + 1;
                else
                    --flush values
                    value_out <= run_value;
                    count_out <= std_logic_vector(run_count);
                    out_valid <= '1';
                    --restart 
                    run_value <= value_in;
                    run_count <= to_unsigned(1, run_count'length);
                end if;
            end if;
            if pos_counter = row_width - 1 then 
                state <= ROW_END;
            else 
                pos_counter <= pos_counter + 1;
            end if;
          end if;
        when ROW_END =>
            --flush values
            value_out <= run_value;
            count_out <= std_logic_vector(run_count);
            out_valid <= '1';
            --restart 
            if valid_in = '1' then 
              run_value   <= value_in;
              run_count   <= to_unsigned(1, COUNT_BITS);
              pos_counter <= 1;
            else
              pos_counter <= 0;
            end if;
            state <= ACCUMULATE;
      end case;
    end if;
  end process;

end rtl;