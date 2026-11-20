-------------------------------------------------------------------------------
-- Title      : tb_ram_read_enable_pkg
-- Project    : ram
-------------------------------------------------------------------------------
-- File       : tb_ram_read_enable_pkg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Scenario read_enable of tb_ram, from reset :
--              A read enable at 0 holds the registered read data
--              while the read address changes ; a write of ram_1rw (another
--              address) does not update its registered read data
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-20  1.0      mrosiere Created (Test 5 of tb_ram 1.0)
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library work;
use     work.tb_ram_bfm_pkg.all;

package tb_ram_read_enable_pkg is

  -- A read enable at 0 holds the registered read data
  -- while the read address changes ; a write of ram_1rw (another
  -- address) does not update its registered read data
  procedure run
    (signal   clk      : in    std_logic
    ;signal   req      : out   t_ram_req
    ;signal   rsp      : in    t_ram_rsp
    ;variable model    : inout t_model
    );

end package tb_ram_read_enable_pkg;

package body tb_ram_read_enable_pkg is

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
    ram_read(5, 6, "Read", clk, req, rsp, model);
    ram_cycle(false, 7, false, 8 mod DEPTH, false, 0, ZERO, "Address change with re = 0", clk, req, rsp, model);
    ram_cycle(false, 9 mod DEPTH, false, 10 mod DEPTH, false, 0, ZERO, "Address change with re = 0", clk, req, rsp, model);
    ram_write(7, pattern(7, 3, WIDTH), "Write", clk, req, rsp, model);
    ram_idle("Write", clk, req, rsp, model);
  end procedure;

end package body tb_ram_read_enable_pkg;
