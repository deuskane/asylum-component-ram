-------------------------------------------------------------------------------
-- Title      : ram_wrapper
-- Project    : Asylum
-------------------------------------------------------------------------------
-- File       : ram_wrapper.vhd
-- Author     : Mathieu Rosiere
-------------------------------------------------------------------------------
-- Description:
-- Wrapper (lint_ghdl, lint_ghdl_synth_*) : one instance of each
-- RAM of the core (ram_1r1w, ram_2r1w, ram_1rw, sbi_ram) with flat and
-- constrained ports (sbi_ram has unconstrained SBI ports and cannot be a
-- synthesis top). WIDTH applies to ram_1r1w / ram_2r1w / ram_1rw (sbi_ram
-- word = SBI_DATA_WIDTH), DEPTH and SYNC_READ to the 4 RAMs.
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-10-20  1.0      mrosiere Created
-- 2026-10-24  1.1      mrosiere Was ram_synth_top, library asylum
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
library asylum;
use     asylum.math_pkg.all;
use     asylum.sbi_pkg.all;

entity ram_wrapper is
  generic (
    WIDTH         : natural := 32;
    DEPTH         : natural := 32;  -- <= 2**SBI_ADDR_WIDTH (sbi_ram)
    SYNC_READ     : boolean := false
  );
  port (
    clk_i         : in  std_logic;
    arst_b_i      : in  std_logic;
    cke_i         : in  std_logic;

    -- ram_1r1w
    r1w_re_i      : in  std_logic;
    r1w_raddr_i   : in  std_logic_vector(log2(DEPTH)-1 downto 0);
    r1w_rdata_o   : out std_logic_vector(WIDTH-1 downto 0);
    r1w_we_i      : in  std_logic;
    r1w_waddr_i   : in  std_logic_vector(log2(DEPTH)-1 downto 0);
    r1w_wdata_i   : in  std_logic_vector(WIDTH-1 downto 0);

    -- ram_2r1w
    r2w_re0_i     : in  std_logic;
    r2w_raddr0_i  : in  std_logic_vector(log2(DEPTH)-1 downto 0);
    r2w_rdata0_o  : out std_logic_vector(WIDTH-1 downto 0);
    r2w_re1_i     : in  std_logic;
    r2w_raddr1_i  : in  std_logic_vector(log2(DEPTH)-1 downto 0);
    r2w_rdata1_o  : out std_logic_vector(WIDTH-1 downto 0);
    r2w_we_i      : in  std_logic;
    r2w_waddr_i   : in  std_logic_vector(log2(DEPTH)-1 downto 0);
    r2w_wdata_i   : in  std_logic_vector(WIDTH-1 downto 0);

    -- ram_1rw
    rw_cs_i       : in  std_logic;
    rw_we_i       : in  std_logic;
    rw_addr_i     : in  std_logic_vector(log2(DEPTH)-1 downto 0);
    rw_wdata_i    : in  std_logic_vector(WIDTH-1 downto 0);
    rw_rdata_o    : out std_logic_vector(WIDTH-1 downto 0);

    -- sbi_ram (SBI)
    sbi_cs_i      : in  std_logic;
    sbi_re_i      : in  std_logic;
    sbi_we_i      : in  std_logic;
    sbi_addr_i    : in  std_logic_vector(SBI_ADDR_WIDTH-1 downto 0);
    sbi_wdata_i   : in  std_logic_vector(SBI_DATA_WIDTH-1 downto 0);
    sbi_ready_o   : out std_logic;
    sbi_rdata_o   : out std_logic_vector(SBI_DATA_WIDTH-1 downto 0)
  );
end entity ram_wrapper;

architecture rtl of ram_wrapper is

  signal sbi_ini       : sbi_ini_t(addr (SBI_ADDR_WIDTH-1 downto 0),
                                   wdata(SBI_DATA_WIDTH-1 downto 0));
  signal sbi_tgt       : sbi_tgt_t(rdata(SBI_DATA_WIDTH-1 downto 0));

begin

  ins_ram_1r1w : entity asylum.ram_1r1w
    generic map (
      WIDTH     => WIDTH,
      DEPTH     => DEPTH,
      SYNC_READ => SYNC_READ
    )
    port map (
      clk_i     => clk_i,
      cke_i     => cke_i,
      re_i      => r1w_re_i,
      raddr_i   => r1w_raddr_i,
      rdata_o   => r1w_rdata_o,
      we_i      => r1w_we_i,
      waddr_i   => r1w_waddr_i,
      wdata_i   => r1w_wdata_i
    );

  ins_ram_2r1w : entity asylum.ram_2r1w
    generic map (
      WIDTH     => WIDTH,
      DEPTH     => DEPTH,
      SYNC_READ => SYNC_READ
    )
    port map (
      clk_i     => clk_i,
      cke_i     => cke_i,
      re0_i     => r2w_re0_i,
      raddr0_i  => r2w_raddr0_i,
      rdata0_o  => r2w_rdata0_o,
      re1_i     => r2w_re1_i,
      raddr1_i  => r2w_raddr1_i,
      rdata1_o  => r2w_rdata1_o,
      we_i      => r2w_we_i,
      waddr_i   => r2w_waddr_i,
      wdata_i   => r2w_wdata_i
    );

  ins_ram_1rw : entity asylum.ram_1rw
    generic map (
      WIDTH     => WIDTH,
      DEPTH     => DEPTH,
      SYNC_READ => SYNC_READ
    )
    port map (
      clk_i     => clk_i,
      cke_i     => cke_i,
      cs_i      => rw_cs_i,
      we_i      => rw_we_i,
      addr_i    => rw_addr_i,
      wdata_i   => rw_wdata_i,
      rdata_o   => rw_rdata_o
    );

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
