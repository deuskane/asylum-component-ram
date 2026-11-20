-------------------------------------------------------------------------------
-- Title      : tb_ram_write_read_pkg
-- Project    : ram
-------------------------------------------------------------------------------
-- File       : tb_ram_write_read_pkg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Scenario write_read of tb_ram, from reset :
--              Write of every word, then read of every word on every
--              port (ram_2r1w port 1 in reverse order), registered read data held
--              by the idle cycles
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-20  1.0      mrosiere Created (Test 1 and 2 of tb_ram 1.0)
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library work;
use     work.tb_ram_bfm_pkg.all;

package tb_ram_write_read_pkg is

  -- Write of every word, then read of every word on every
  -- port (ram_2r1w port 1 in reverse order), registered read data held
  -- by the idle cycles
  procedure run
    (signal   clk      : in    std_logic
    ;signal   req      : out   t_ram_req
    ;signal   rsp      : in    t_ram_rsp
    ;variable model    : inout t_model
    );

end package tb_ram_write_read_pkg;

package body tb_ram_write_read_pkg is

  procedure run
    (signal   clk      : in    std_logic
    ;signal   req      : out   t_ram_req
    ;signal   rsp      : in    t_ram_rsp
    ;variable model    : inout t_model
    ) is
    constant DEPTH : natural := model.mem'length;
    constant WIDTH : natural := rsp.rdata'length;
  begin
    for a in 0 to DEPTH-1
    loop
      ram_write(a, pattern(a, 0, WIDTH), "Write", clk, req, rsp, model);
    end loop;
    ram_idle("Write", clk, req, rsp, model);
    for a in 0 to DEPTH-1
    loop
      ram_read(a, DEPTH-1-a, "Read", clk, req, rsp, model);
    end loop;
    ram_idle("Read", clk, req, rsp, model);
    ram_idle("Read", clk, req, rsp, model);
  end procedure;

end package body tb_ram_write_read_pkg;
