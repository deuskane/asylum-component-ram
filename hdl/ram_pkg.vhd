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

component ram_1r1w_2c is
  generic (
    WIDTH        : natural := 32                                   -- Word width
   ;DEPTH        : natural := 32                                   -- Number of words (power of 2)
  );
  port (
    -- Write port
    clk0_i       : in  std_logic
   ;cke0_i       : in  std_logic
   ;we0_i        : in  std_logic
   ;waddr0_i     : in  std_logic_vector(log2(DEPTH) -1 downto 0)
   ;wdata0_i     : in  std_logic_vector(WIDTH       -1 downto 0)
    -- Read port
   ;clk1_i       : in  std_logic
   ;cke1_i       : in  std_logic
   ;re1_i        : in  std_logic
   ;raddr1_i     : in  std_logic_vector(log2(DEPTH) -1 downto 0)
   ;rdata1_o     : out std_logic_vector(WIDTH       -1 downto 0)
  );
end component ram_1r1w_2c;

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

component ram_2r1w is
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
    re0_i        : in  std_logic;
    raddr0_i     : in  std_logic_vector(log2(DEPTH) -1 downto 0);
    rdata0_o     : out std_logic_vector(WIDTH       -1 downto 0);

    re1_i        : in  std_logic;
    raddr1_i     : in  std_logic_vector(log2(DEPTH) -1 downto 0);
    rdata1_o     : out std_logic_vector(WIDTH       -1 downto 0);
    -- MEM_WRITE
    we_i         : in  std_logic;
    waddr_i      : in  std_logic_vector(log2(DEPTH) -1 downto 0);
    wdata_i      : in  std_logic_vector(WIDTH       -1 downto 0)    
    );
end component ram_2r1w;

component ram_2rw_2c is
  generic (
    WIDTH        : natural := 32                                   -- Word width
   ;DEPTH        : natural := 32                                   -- Number of words (power of 2)
  );
  port (
    -- Port 0
    clk0_i       : in  std_logic
   ;cke0_i       : in  std_logic
   ;cs0_i        : in  std_logic
   ;we0_i        : in  std_logic
   ;addr0_i      : in  std_logic_vector(log2(DEPTH) -1 downto 0)
   ;wdata0_i     : in  std_logic_vector(WIDTH       -1 downto 0)
   ;rdata0_o     : out std_logic_vector(WIDTH       -1 downto 0)
    -- Port 1
   ;clk1_i       : in  std_logic
   ;cke1_i       : in  std_logic
   ;cs1_i        : in  std_logic
   ;we1_i        : in  std_logic
   ;addr1_i      : in  std_logic_vector(log2(DEPTH) -1 downto 0)
   ;wdata1_i     : in  std_logic_vector(WIDTH       -1 downto 0)
   ;rdata1_o     : out std_logic_vector(WIDTH       -1 downto 0)
  );
end component ram_2rw_2c;

component sbi_ram is
    generic (
        NAME       : string  := "";
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
