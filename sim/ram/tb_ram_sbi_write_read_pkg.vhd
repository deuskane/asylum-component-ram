-------------------------------------------------------------------------------
-- Title      : tb_ram_sbi_write_read_pkg
-- Project    : ram
-------------------------------------------------------------------------------
-- File       : tb_ram_sbi_write_read_pkg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Scenario sbi_write_read of tb_ram, from reset :
--              sbi_ram : write then read of every word, then
--              back-to-back write and read of each word ; wait states of each
--              access (0, or 1 with SYNC_READ)
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-20  1.0      mrosiere Created (Test 7 of tb_ram 1.0)
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library bitvis_vip_sbi;
use     bitvis_vip_sbi.sbi_bfm_pkg.all;

library work;
use     work.tb_ram_bfm_pkg.all;

package tb_ram_sbi_write_read_pkg is

  -- sbi_ram : write then read of every word, then
  -- back-to-back write and read of each word ; wait states of each
  -- access (0, or 1 with SYNC_READ)
  procedure run
    (constant depth    : in    natural
    ;constant sync_read: in    boolean
    ;signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ;signal   sbi_wait : in    natural
    );

end package tb_ram_sbi_write_read_pkg;

package body tb_ram_sbi_write_read_pkg is

  procedure run
    (constant depth    : in    natural
    ;constant sync_read: in    boolean
    ;signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ;signal   sbi_wait : in    natural
    ) is
    constant WIDTH : natural := sbi_if.wdata'length;
  begin
    for a in 0 to depth-1
    loop
      wr (a, pattern(a, 4, WIDTH), "Write", clk, sbi_if);
      chk_wait(sbi_wait, sync_read, "Write");
    end loop;
    for a in 0 to depth-1
    loop
      chk(a, pattern(a, 4, WIDTH), "Read", clk, sbi_if);
      chk_wait(sbi_wait, sync_read, "Read");
    end loop;
    for a in depth-1 downto 0
    loop
      wr (a, pattern(a, 5, WIDTH), "Write", clk, sbi_if);
      chk(a, pattern(a, 5, WIDTH), "Read after write", clk, sbi_if);
      chk_wait(sbi_wait, sync_read, "Read after write");
    end loop;
  end procedure;

end package body tb_ram_sbi_write_read_pkg;
