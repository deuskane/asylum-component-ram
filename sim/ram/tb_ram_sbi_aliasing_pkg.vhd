-------------------------------------------------------------------------------
-- Title      : tb_ram_sbi_aliasing_pkg
-- Project    : ram
-------------------------------------------------------------------------------
-- File       : tb_ram_sbi_aliasing_pkg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Scenario sbi_aliasing of tb_ram, from reset :
--              sbi_ram decodes log2(DEPTH) address bits : the word
--              written at DEPTH+3 is read at 3, DEPTH+3, 2*DEPTH+3 and 3*DEPTH+3
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-20  1.0      mrosiere Created (Test 8 of tb_ram 1.0)
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

package tb_ram_sbi_aliasing_pkg is

  -- sbi_ram decodes log2(DEPTH) address bits : the word
  -- written at DEPTH+3 is read at 3, DEPTH+3, 2*DEPTH+3 and 3*DEPTH+3
  procedure run
    (constant depth    : in    natural
    ;constant sync_read: in    boolean
    ;signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ;signal   sbi_wait : in    natural
    );

end package tb_ram_sbi_aliasing_pkg;

package body tb_ram_sbi_aliasing_pkg is

  procedure run
    (constant depth    : in    natural
    ;constant sync_read: in    boolean
    ;signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ;signal   sbi_wait : in    natural
    ) is
    constant WIDTH : natural := sbi_if.wdata'length;
  begin
    wr(depth + 3, pattern(3, 6, WIDTH), "Write above DEPTH", clk, sbi_if);
    chk_wait(sbi_wait, sync_read, "Write above DEPTH");
    for k in 0 to 3
    loop
      chk(k*depth + 3, pattern(3, 6, WIDTH), "Alias " & to_string(k), clk, sbi_if);
      chk_wait(sbi_wait, sync_read, "Alias " & to_string(k));
    end loop;
  end procedure;

end package body tb_ram_sbi_aliasing_pkg;
