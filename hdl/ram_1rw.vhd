-------------------------------------------------------------------------------
-- Title      : ram_1rw
-- Project    : ram_1rw
-------------------------------------------------------------------------------
-- File       : ram_1rw.vhd
-- Author     : mrosiere
-- Company    : 
-- Created    : 2026-05-16
-- Last update: 2026-05-16
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2016 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2026-05-16  1.0      mrosiere	Created
-- 2026-10-05  1.1      mrosiere Remove unused std.textio, assert DEPTH is a
--                               power of 2
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library asylum;
use asylum.math_pkg.all;

entity ram_1rw is
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
end ram_1rw;

architecture rtl of ram_1rw is
  -- =====[ Types ]===============================
  type ram_t is array (DEPTH-1 downto 0) of std_logic_vector(WIDTH -1 downto 0);

  -- =====[ Registers ]===========================
  signal ram_r  : ram_t;
  signal rdata_r: std_logic_vector(WIDTH-1 downto 0);
  
  -- =====[ Signals ]=============================
  signal addr   : integer range 0 to DEPTH-1;

begin  -- rtl

  -- Convert address to integer
  addr   <= to_integer(unsigned(addr_i));

  process (clk_i)
  begin  -- process transition
    if (clk_i'event and clk_i = '1')
    then  -- rising clk_i edge
      if (cke_i = '1')
      then
        if (cs_i = '1' and we_i = '1')
        then
          ram_r (addr) <= wdata_i;
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
          if (cs_i = '1' and we_i = '0')
          then
            rdata_r <= ram_r(addr);
          end if;
        end if;
      end if;
    end process;

    rdata_o <= rdata_r;
    
  end generate gen_sync_read;

  gen_async_read: if SYNC_READ = false
  generate
    -- Asynchronous Read
    rdata_o <= ram_r(addr);

  end generate gen_async_read;
  
  
-- pragma translate_off
  -- The address width is log2(DEPTH) (floor): with a DEPTH that is not a power
  -- of 2, the words 2**log2(DEPTH) to DEPTH-1 can not be addressed
  assert 2**log2(DEPTH) = DEPTH
    report "ram_1rw: DEPTH (" & integer'image(DEPTH) & ") is not a power of 2, only " & integer'image(2**log2(DEPTH)) & " words are addressable"
    severity error;
-- pragma translate_on

end rtl;
