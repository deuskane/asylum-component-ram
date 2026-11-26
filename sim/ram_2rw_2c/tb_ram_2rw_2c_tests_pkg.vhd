-------------------------------------------------------------------------------
-- Title      : tb_ram_2rw_2c_tests_pkg
-- Project    : ram
-------------------------------------------------------------------------------
-- File       : tb_ram_2rw_2c_tests_pkg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Scenarios of tb_ram_2rw_2c : names (valid items of
--              TESTS_LIST) and dispatch (run_test) to the package of each
--              scenario (tb_ram_2rw_2c_<name>_pkg)
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-26  1.0      mrosiere Created
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library asylum;
use     asylum.string_pkg.all;

library work;
use     work.tb_ram_2rw_2c_bfm_pkg.all;

package tb_ram_2rw_2c_tests_pkg is

  -- Names of the scenarios (valid items of TESTS_LIST)
  constant C_TESTS : string := "port0,port1,cross,concurrent,read_during_write,enables";

  -- Run the scenario name
  procedure run_test
    (constant name     : in    string
    ;signal   clk0     : in    std_logic
    ;signal   req0     : out   t_port_req
    ;signal   rdata0   : in    std_logic_vector
    ;signal   clk1     : in    std_logic
    ;signal   req1     : out   t_port_req
    ;signal   rdata1   : in    std_logic_vector
    );

end package tb_ram_2rw_2c_tests_pkg;

package body tb_ram_2rw_2c_tests_pkg is

  procedure run_test
    (constant name     : in    string
    ;signal   clk0     : in    std_logic
    ;signal   req0     : out   t_port_req
    ;signal   rdata0   : in    std_logic_vector
    ;signal   clk1     : in    std_logic
    ;signal   req1     : out   t_port_req
    ;signal   rdata1   : in    std_logic_vector
    ) is
  begin
    if    string_eq(name, "port0")
    then
      work.tb_ram_2rw_2c_port0_pkg.run            (clk0, req0, rdata0, clk1, req1, rdata1);
    elsif string_eq(name, "port1")
    then
      work.tb_ram_2rw_2c_port1_pkg.run            (clk0, req0, rdata0, clk1, req1, rdata1);
    elsif string_eq(name, "cross")
    then
      work.tb_ram_2rw_2c_cross_pkg.run            (clk0, req0, rdata0, clk1, req1, rdata1);
    elsif string_eq(name, "concurrent")
    then
      work.tb_ram_2rw_2c_concurrent_pkg.run       (clk0, req0, rdata0, clk1, req1, rdata1);
    elsif string_eq(name, "read_during_write")
    then
      work.tb_ram_2rw_2c_read_during_write_pkg.run(clk0, req0, rdata0, clk1, req1, rdata1);
    elsif string_eq(name, "enables")
    then
      work.tb_ram_2rw_2c_enables_pkg.run          (clk0, req0, rdata0, clk1, req1, rdata1);
    else
      alert(TB_ERROR, "Unknown test " & name, C_TB_SCOPE);
    end if;
  end procedure;

end package body tb_ram_2rw_2c_tests_pkg;
