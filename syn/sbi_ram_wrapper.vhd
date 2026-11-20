-------------------------------------------------------------------------------
-- Title      : sbi_ram_wrapper
-- Project    : Asylum
-------------------------------------------------------------------------------
-- File       : sbi_ram_wrapper.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description:
-- Wrapper (lint_ghdl, lint_ghdl_synth_sbi_ram_*, syn_sbi_ram_*) : sbi_ram
-- with flat and constrained ports (sbi_ram has unconstrained SBI ports and
-- cannot be a synthesis top). Word = SBI_DATA_WIDTH bits.
-- ram_1r1w, ram_2r1w and ram_1rw have flat ports : they are the toplevel of
-- their own lint_ghdl_synth_* / syn_* targets.
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-10-20  1.0      mrosiere Created
-- 2026-10-24  1.1      mrosiere Was ram_synth_top, library asylum
-- 2026-11-20  2.0      mrosiere Was ram_wrapper : sbi_ram only (one
--                               synthesis toplevel per RAM)
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
library asylum;
use     asylum.sbi_pkg.all;

entity sbi_ram_wrapper is
  generic (
    DEPTH         : natural := 256;  -- <= 2**SBI_ADDR_WIDTH
    SYNC_READ     : boolean := false
  );
  port (
    clk_i         : in  std_logic;
    arst_b_i      : in  std_logic;

    -- sbi_ram (SBI)
    sbi_cs_i      : in  std_logic;
    sbi_re_i      : in  std_logic;
    sbi_we_i      : in  std_logic;
    sbi_addr_i    : in  std_logic_vector(SBI_ADDR_WIDTH-1 downto 0);
    sbi_wdata_i   : in  std_logic_vector(SBI_DATA_WIDTH-1 downto 0);
    sbi_ready_o   : out std_logic;
    sbi_rdata_o   : out std_logic_vector(SBI_DATA_WIDTH-1 downto 0)
  );
end entity sbi_ram_wrapper;

architecture rtl of sbi_ram_wrapper is

  signal sbi_ini       : sbi_ini_t(addr (SBI_ADDR_WIDTH-1 downto 0),
                                   wdata(SBI_DATA_WIDTH-1 downto 0));
  signal sbi_tgt       : sbi_tgt_t(rdata(SBI_DATA_WIDTH-1 downto 0));

begin

  sbi_ini.cs        <= sbi_cs_i;
  sbi_ini.re        <= sbi_re_i;
  sbi_ini.we        <= sbi_we_i;
  sbi_ini.addr      <= sbi_addr_i;
  sbi_ini.wdata     <= sbi_wdata_i;
  sbi_ready_o       <= sbi_tgt.ready;
  sbi_rdata_o       <= sbi_tgt.rdata;

  ins_sbi_ram : entity asylum.sbi_ram
    generic map (
      DEPTH     => DEPTH,
      SYNC_READ => SYNC_READ
    )
    port map (
      clk_i     => clk_i,
      arst_b_i  => arst_b_i,
      sbi_ini_i => sbi_ini,
      sbi_tgt_o => sbi_tgt
    );

end architecture rtl;
