-------------------------------------------------------------------------------
-- Title      : tb_ram_tests_pkg
-- Project    : ram
-------------------------------------------------------------------------------
-- File       : tb_ram_tests_pkg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Scenarios of tb_ram : names (valid items of TESTS_LIST) and
--              dispatch (run_test) to the package of each scenario
--              (tb_ram_<name>_pkg)
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-20  1.0      mrosiere Created
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library bitvis_vip_sbi;
use     bitvis_vip_sbi.sbi_bfm_pkg.all;

library asylum;
use     asylum.string_pkg.all;

library work;
use     work.tb_ram_bfm_pkg.all;

package tb_ram_tests_pkg is

  -- Names of the scenarios (valid items of TESTS_LIST)
  constant C_TESTS : string := "write_read,read_during_write,clock_enable,read_enable,write_enable,random,sbi_write_read,sbi_aliasing,sbi_name";

  -- Run the scenario name
  procedure run_test
    (constant name      : in    string
    ;constant depth     : in    natural   -- DEPTH
    ;constant sync_read : in    boolean   -- SYNC_READ
    ;signal   clk       : in    std_logic
      -- ram_1r1w, ram_2r1w, ram_1rw
    ;signal   req       : out   t_ram_req
    ;signal   rsp       : in    t_ram_rsp
    ;variable model     : inout t_model
      -- sbi_ram
    ;signal   sbi_if    : inout t_sbi_if
    ;signal   sbi_wait  : in    natural   -- Wait states of the last access
    ;signal   name0     : in    string    -- info.name, NAME = ""
    ;signal   name1     : in    string    -- info.name, NAME = "RAM0"
    );

end package tb_ram_tests_pkg;

package body tb_ram_tests_pkg is

  procedure run_test
    (constant name      : in    string
    ;constant depth     : in    natural
    ;constant sync_read : in    boolean
    ;signal   clk       : in    std_logic
    ;signal   req       : out   t_ram_req
    ;signal   rsp       : in    t_ram_rsp
    ;variable model     : inout t_model
    ;signal   sbi_if    : inout t_sbi_if
    ;signal   sbi_wait  : in    natural
    ;signal   name0     : in    string
    ;signal   name1     : in    string
    ) is
  begin
    if    string_eq(name, "write_read")
    then
      work.tb_ram_write_read_pkg.run(clk, req, rsp, model);
    elsif string_eq(name, "read_during_write")
    then
      work.tb_ram_read_during_write_pkg.run(clk, req, rsp, model);
    elsif string_eq(name, "clock_enable")
    then
      work.tb_ram_clock_enable_pkg.run(clk, req, rsp, model);
    elsif string_eq(name, "read_enable")
    then
      work.tb_ram_read_enable_pkg.run(clk, req, rsp, model);
    elsif string_eq(name, "write_enable")
    then
      work.tb_ram_write_enable_pkg.run(clk, req, rsp, model);
    elsif string_eq(name, "random")
    then
      work.tb_ram_random_pkg.run(clk, req, rsp, model);
    elsif string_eq(name, "sbi_write_read")
    then
      work.tb_ram_sbi_write_read_pkg.run(depth, sync_read, clk, sbi_if, sbi_wait);
    elsif string_eq(name, "sbi_aliasing")
    then
      work.tb_ram_sbi_aliasing_pkg.run(depth, sync_read, clk, sbi_if, sbi_wait);
    elsif string_eq(name, "sbi_name")
    then
      work.tb_ram_sbi_name_pkg.run(depth, name0, name1);
    else
      alert(TB_ERROR, "Unknown test " & name, C_TB_SCOPE);
    end if;
  end procedure;

end package body tb_ram_tests_pkg;
