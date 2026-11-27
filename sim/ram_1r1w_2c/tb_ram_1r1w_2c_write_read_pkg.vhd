-------------------------------------------------------------------------------
-- Title      : tb_ram_1r1w_2c_write_read_pkg
-- Project    : ram
-------------------------------------------------------------------------------
-- File       : tb_ram_1r1w_2c_write_read_pkg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Scenario write_read : every address written on clk0, then read
--              back on clk1, twice with two patterns
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-27  1.0      mrosiere Created
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library work;
use     work.tb_ram_2rw_2c_bfm_pkg.all;

package tb_ram_1r1w_2c_write_read_pkg is

  -- Port 0 : write port (clk0), port 1 : read port (clk1)
  procedure run
    (signal   clk0     : in    std_logic
    ;signal   req0     : out   t_port_req
    ;signal   clk1     : in    std_logic
    ;signal   req1     : out   t_port_req
    ;signal   rdata1   : in    std_logic_vector
    );

end package tb_ram_1r1w_2c_write_read_pkg;

package body tb_ram_1r1w_2c_write_read_pkg is

  procedure run
    (signal   clk0     : in    std_logic
    ;signal   req0     : out   t_port_req
    ;signal   clk1     : in    std_logic
    ;signal   req1     : out   t_port_req
    ;signal   rdata1   : in    std_logic_vector
    ) is
  begin
    port_fill     (0,                                  clk0, req0);
    port_check_all(0, "Written on clk0, read on clk1", clk1, req1, rdata1);
    port_fill     (1,                                  clk0, req0);
    port_check_all(1, "Written again, read on clk1"  , clk1, req1, rdata1);
  end procedure;

end package body tb_ram_1r1w_2c_write_read_pkg;
