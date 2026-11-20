-------------------------------------------------------------------------------
-- Title      : tb_ram_sbi_name_pkg
-- Project    : ram
-------------------------------------------------------------------------------
-- File       : tb_ram_sbi_name_pkg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Scenario sbi_name of tb_ram, from reset :
--              Name of sbi_ram in sbi_tgt_o.info : "RAM<DEPTH>B"
--              with NAME = "", NAME otherwise
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-20  1.0      mrosiere Created (Test 9 of tb_ram 1.0)
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library asylum;
use     asylum.sbi_pkg.all;

library work;
use     work.tb_ram_bfm_pkg.all;

package tb_ram_sbi_name_pkg is

  -- Name of sbi_ram in sbi_tgt_o.info : "RAM<DEPTH>B"
  -- with NAME = "", NAME otherwise
  procedure run
    (constant depth    : in    natural
    ;signal   name0    : in    string   -- info.name of sbi_ram, NAME = ""
    ;signal   name1    : in    string   -- info.name of sbi_ram, NAME = "RAM0"
    );

end package tb_ram_sbi_name_pkg;

package body tb_ram_sbi_name_pkg is

  procedure run
    (constant depth    : in    natural
    ;signal   name0    : in    string   -- info.name of sbi_ram, NAME = ""
    ;signal   name1    : in    string   -- info.name of sbi_ram, NAME = "RAM0"
    ) is
  begin
    check_value(name0, to_sbi_name("RAM" & integer'image(depth) & "B"), error, "info.name, NAME = """"" , C_TB_SCOPE);
    check_value(name1, to_sbi_name("RAM0")                          , error, "info.name, NAME = ""RAM0""", C_TB_SCOPE);
  end procedure;

end package body tb_ram_sbi_name_pkg;
