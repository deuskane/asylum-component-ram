-------------------------------------------------------------------------------
-- Title      : ram_2r1w
-- Project    : ram_2r1w
-------------------------------------------------------------------------------
-- File       : ram_2r1w.vhd
-- Author     : mrosiere
-- Company    : 
-- Created    : 2026-09-15
-- Last update: 2026-09-15
-- Platform   : 
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-09-15  1.0      mrosiere Created
-------------------------------------------------------------------------------

library std;
use     std.textio.all;

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library asylum;
use     asylum.math_pkg.all;

entity ram_2r1w is
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
end ram_2r1w;

architecture rtl of ram_2r1w is
  -- =====[ Types ]===============================
  type ram_t is array (DEPTH-1 downto 0) of std_logic_vector(WIDTH -1 downto 0);

  -- =====[ Registers ]===========================
  signal ram_r    : ram_t;
  signal rdata0_r : std_logic_vector(WIDTH-1 downto 0);
  signal rdata1_r : std_logic_vector(WIDTH-1 downto 0);
  
  -- =====[ Signals ]=============================
  signal raddr0   : integer range 0 to DEPTH-1;
  signal raddr1   : integer range 0 to DEPTH-1;
  signal waddr    : integer range 0 to DEPTH-1;

begin  -- rtl

  -- Convert address to integer
  raddr0 <= to_integer(unsigned(raddr0_i));
  raddr1 <= to_integer(unsigned(raddr1_i));
  waddr  <= to_integer(unsigned(waddr_i));

  process (clk_i)
  begin  -- process transition
    if (clk_i'event and clk_i = '1')
    then  -- rising clk_i edge
      if (cke_i = '1')
      then
        if (we_i = '1')
        then
          ram_r (waddr) <= wdata_i;
        end if;
      end if;
    end if;
  end process;

  gen_sync_read: if SYNC_READ = true
  generate
    
    process (clk_i)
    begin  -- process transition
      if (clk_i'event and clk_i = '1')
      then  -- rising clk_i edge
        if (cke_i = '1')
        then
          -- Synchronous Read
          if (re0_i = '1')
          then
            rdata0_r <= ram_r(raddr0);
          end if;
          if (re1_i = '1')
          then
            rdata1_r <= ram_r(raddr1);
          end if;
        end if;
      end if;
    end process;

    rdata0_o <= rdata0_r;
    rdata1_o <= rdata1_r;
    
  end generate gen_sync_read;

  gen_async_read: if SYNC_READ = false
  generate
    -- Asynchronous Read
    rdata0_o <= ram_r(raddr0);
    rdata1_o <= ram_r(raddr1);
  end generate gen_async_read;
  
end rtl;
