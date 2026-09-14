library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity haar_column_transform is
  generic (
    MAX_HEIGHT  : integer := 8 --coefficients per column
  );
  port(
    clk           : in  std_logic;
    column_height : in  integer range 0 to MAX_HEIGHT;
    coeff_in      : in  std_logic_vector(8 downto 0);
    d_out         : out std_logic_vector(9 downto 0); 
    s_out         : out std_logic_vector(8 downto 0);
    out_valid     : out std_logic
  );
end haar_column_transform;

architecture rtl of haar_column_transform is 

  signal column_index  : integer range 0 to MAX_HEIGHT - 1 := 0;
  
  component haar_butterfly_wide is
    port(
      a_in    : in std_logic_vector(8 downto 0);
      b_in    : in std_Logic_vector(8 downto 0);
      d_out   : out std_logic_vector(9 downto 0); 
      s_out   : out std_logic_vector(8 downto 0)
    );
    end component haar_butterfly_wide;

  --bf internal signals
  signal prev_coeff       : std_logic_vector(8 downto 0);
  signal bf_d             : std_logic_vector(9 downto 0);
  signal bf_s             : std_logic_vector(8 downto 0);

begin

  bf: haar_butterfly_wide
  port map(
    a_in  => prev_coeff,
    b_in  => coeff_in,
    d_out => bf_d,
    s_out => bf_s
  );

  process(clk)  
  begin
    if rising_edge(clk) then  
      if column_index mod 2 = 0 then
        out_valid <= '0';
      else
        d_out <= bf_d;
        s_out <= bf_s;
        out_valid <= '1';
      end if;
      prev_coeff <= coeff_in;
      if column_index = column_height - 1 then
        column_index <= 0;
      else
        column_index <= column_index + 1;
      end if;
    end if;
  end process;
end rtl;