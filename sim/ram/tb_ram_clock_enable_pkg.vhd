-------------------------------------------------------------------------------
-- Title      : tb_ram_clock_enable_pkg
-- Project    : ram
-------------------------------------------------------------------------------
-- File       : tb_ram_clock_enable_pkg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Scenario clock_enable of tb_ram, from reset :
--              cke_i = 0 blocks the write and the registered read of
--              every port (ram_1rw : read cycle and write cycle)
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-20  1.0      mrosiere Created (Test 4 of tb_ram 1.0)
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library work;
use     work.tb_ram_bfm_pkg.all;

package tb_ram_clock_enable_pkg is

  -- cke_i = 0 blocks the write and the registered read of
  -- every port (ram_1rw : read cycle and write cycle)
  procedure run
    (signal   clk      : in    std_logic
    ;signal   req      : out   t_ram_req
    ;signal   rsp      : in    t_ram_rsp
    ;variable model    : inout t_model
    );

end package tb_ram_clock_enable_pkg;

package body tb_ram_clock_enable_pkg is

  procedure run
    (signal   clk      : in    std_logic
    ;signal   req      : out   t_ram_req
    ;signal   rsp      : in    t_ram_rsp
    ;variable model    : inout t_model
    ) is
    constant DEPTH : natural := model.mem'length;
    constant WIDTH : natural := rsp.rdata'length;
    constant ZERO  : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
  begin
    ram_fill(0, clk, req, rsp, model);
    ram_read(2, 3, "Read", clk, req, rsp, model);
    ram_cycle(true, 0, true, 1, true , 0, pattern(0, 2, WIDTH), "Read and write with cke_i = 0", clk, req, rsp, model, cke => false);
    ram_cycle(true, 4, true, 5, true , 1, pattern(1, 2, WIDTH), "Read and write with cke_i = 0", clk, req, rsp, model, cke => false);
    ram_cycle(true, 6, true, 7, false, 0, ZERO                , "Read with cke_i = 0"          , clk, req, rsp, model, cke => false);
    ram_read(0, 1, "Read after cke_i = 0", clk, req, rsp, model);
    ram_idle("Read after cke_i = 0", clk, req, rsp, model);
  end procedure;

end package body tb_ram_clock_enable_pkg;
