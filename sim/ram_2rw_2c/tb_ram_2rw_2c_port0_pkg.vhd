-------------------------------------------------------------------------------
-- Title      : tb_ram_2rw_2c_port0_pkg
-- Project    : ram
-------------------------------------------------------------------------------
-- File       : tb_ram_2rw_2c_port0_pkg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Scenario port0 : port 0 alone (port 1 idle), every address
--              written then read back on clk0
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-26  1.0      mrosiere Created
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library work;
use     work.tb_ram_2rw_2c_bfm_pkg.all;

package tb_ram_2rw_2c_port0_pkg is

  procedure run
    (signal   clk0     : in    std_logic
    ;signal   req0     : out   t_port_req
    ;signal   rdata0   : in    std_logic_vector
    ;signal   clk1     : in    std_logic
    ;signal   req1     : out   t_port_req
    ;signal   rdata1   : in    std_logic_vector
    );

end package tb_ram_2rw_2c_port0_pkg;

package body tb_ram_2rw_2c_port0_pkg is

  procedure run
    (signal   clk0     : in    std_logic
    ;signal   req0     : out   t_port_req
    ;signal   rdata0   : in    std_logic_vector
    ;signal   clk1     : in    std_logic
    ;signal   req1     : out   t_port_req
    ;signal   rdata1   : in    std_logic_vector
    ) is
  begin
    port_fill     (0,                clk0, req0);
    port_check_all(0, "Port 0 alone", clk0, req0, rdata0);
  end procedure;

end package body tb_ram_2rw_2c_port0_pkg;
