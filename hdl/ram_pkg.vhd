library IEEE;
use     IEEE.STD_LOGIC_1164.ALL;
use     IEEE.NUMERIC_STD.ALL;
library asylum;
use     asylum.math_pkg.all;
use     asylum.sbi_pkg.all;

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

component ram_1rw is
  -- =====[ Interfaces ]==========================
  generic (
    WIDTH     : natural := 32;
    DEPTH     : natural := 32;
    SYNC_READ : boolean := false
    );
  port (
    clk_i        : in  std_logic;
    cke_i        : in  std_logic;
    -- MEM_ACCESS
    cs_i         : in  std_logic;
    we_i         : in  std_logic;
    addr_i       : in  std_logic_vector(log2(DEPTH) -1 downto 0);
    wdata_i      : in  std_logic_vector(WIDTH       -1 downto 0);
    rdata_o      : out std_logic_vector(WIDTH       -1 downto 0)
    );
end component ram_1rw;

component sbi_ram is
    generic (
        DEPTH      : natural := 256;
        SYNC_READ  : boolean := false
    );
    port (
    clk_i            : in    std_logic;
    arst_b_i         : in    std_logic; -- asynchronous reset

    -- Bus
    sbi_ini_i        : in    sbi_ini_t;
    sbi_tgt_o        : out   sbi_tgt_t
    );
end component sbi_ram;

-- [COMPONENT_INSERT][END]

end ram_pkg;
