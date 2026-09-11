library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity haar_row_transformer is
  generic (
    MAX_WIDTH  : integer := 8 -- pixels per row
  );
  port(
    clk       : in  std_logic;
    row_width : in  integer range 0 to MAX_WIDTH;
    pixel_in  : in  std_logic_vector(7 downto 0);
    d_out     : out std_logic_vector(8 downto 0); --signed, extra bit
    s_out     : out std_logic_vector(7 downto 0);
    out_valid : out std_logic
  );
end haar_row_transformer;

architecture rtl of haar_row_transformer is 

  signal pos_counter  : integer range 0 to MAX_WIDTH - 1 := 0;

  component haar_butterfly is
    port(
      a_in    : in std_logic_vector(7 downto 0);
      b_in    : in std_Logic_vector(7 downto 0);
      d_out   : out std_logic_vector(8 downto 0); --signed, extra bit
      s_out   : out std_logic_vector(7 downto 0)
    );
    end component haar_butterfly;

  --bf internal signals
  signal prev_pixel     : std_logic_vector(7 downto 0);
  signal bf_d           : std_logic_vector(8 downto 0);
  signal bf_s           : std_logic_vector(7 downto 0);
  

begin

  bf: haar_butterfly
  port map(
    a_in => prev_pixel,
    b_in => pixel_in,
    d_out => bf_d,
    s_out => bf_s
  );

  process(clk)  
  begin
    if rising_edge(clk) then 
      if pos_counter mod 2 = 0 then
        out_valid <= '0';
      else
        d_out <= bf_d;
        s_out <= bf_s;
        out_valid <= '1';
      end if;
      prev_pixel <= pixel_in;
      if pos_counter = row_width - 1 then
        pos_counter <= 0;
      else
        pos_counter <= pos_counter + 1;
      end if;
    end if;
  end process;
end rtl;