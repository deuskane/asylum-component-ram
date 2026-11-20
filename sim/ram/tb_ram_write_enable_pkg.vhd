-------------------------------------------------------------------------------
-- Title      : tb_ram_write_enable_pkg
-- Project    : ram
-------------------------------------------------------------------------------
-- File       : tb_ram_write_enable_pkg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Scenario write_enable of tb_ram, from reset :
--              A write without select (we_i = 0 on ram_1r1w and
--              ram_2r1w, cs_i = 0 with we_i = 1 on ram_1rw) does not change the
--              word : the next read returns the old word
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-20  1.0      mrosiere Created
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library work;
use     work.tb_ram_bfm_pkg.all;

package tb_ram_write_enable_pkg is

  -- A write without select (we_i = 0 on ram_1r1w and
  -- ram_2r1w, cs_i = 0 with we_i = 1 on ram_1rw) does not change the
  -- word : the next read returns the old word
  procedure run
    (signal   clk      : in    std_logic
    ;signal   req      : out   t_ram_req
    ;signal   rsp      : in    t_ram_rsp
    ;variable model    : inout t_model
    );

end package tb_ram_write_enable_pkg;

package body tb_ram_write_enable_pkg is

  procedure run
    (signal   clk      : in    std_logic
    ;signal   req      : out   t_ram_req
    ;signal   rsp      : in    t_ram_rsp
    ;variable model    : inout t_model
    ) is
    constant DEPTH : natural := model.mem'length;
    constant WIDTH : natural := rsp.rdata'length;
  begin
    ram_fill(0, clk, req, rsp, model);
    for a in 0 to DEPTH-1
    loop
      ram_cycle(false, 0, false, 0, true, a, pattern(a, 7, WIDTH), "Write not selected", clk, req, rsp, model, sel => false);
      ram_read(a, DEPTH-1-a, "Read after a write not selected", clk, req, rsp, model);
    end loop;
    ram_idle("Read after a write not selected", clk, req, rsp, model);
  end procedure;

end package body tb_ram_write_enable_pkg;
