library IEEE;
use     IEEE.STD_LOGIC_1164.ALL;
use     IEEE.NUMERIC_STD.ALL;
library asylum;
use     asylum.math_pkg.all;

package ram_pkg is
-- [COMPONENT_INSERT][BEGIN]
component ram_1r1w is
  -- =====[ Interfaces ]==========================
  generic (
    WIDTH     : natural := 32;
    DEPTH     : natural := 32;
    SYNC_READ : boolean := false
    );
  port (
    clk_i        : in  std_logic;
    cke_i        : in  std_logic;
--  arstn_i      : in  std_logic;
    -- MEM_READ
    re_i         : in  std_logic;
    raddr_i      : in  std_logic_vector(log2(DEPTH) -1 downto 0);
    rdata_o      : out std_logic_vector(WIDTH       -1 downto 0);
    -- MEM_WRITE
    we_i         : in  std_logic;
    waddr_i      : in  std_logic_vector(log2(DEPTH) -1 downto 0);
    wdata_i      : in  std_logic_vector(WIDTH       -1 downto 0)    
    );
end component ram_1r1w;

-- [COMPONENT_INSERT][END]

end ram_pkg;
