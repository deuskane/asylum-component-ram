-------------------------------------------------------------------------------
-- Title      : tb_ram_read_during_write_pkg
-- Project    : ram
-------------------------------------------------------------------------------
-- File       : tb_ram_read_during_write_pkg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Scenario read_during_write of tb_ram, from reset :
--              Read and write of the same address on the same edge :
--              the registered read data is the old word (read-first), the next
--              read returns the new word ; asynchronous read : the old word
--              before the edge
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-20  1.0      mrosiere Created (Test 3 of tb_ram 1.0)
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library work;
use     work.tb_ram_bfm_pkg.all;

package tb_ram_read_during_write_pkg is

  -- Read and write of the same address on the same edge :
  -- the registered read data is the old word (read-first), the next
  -- read returns the new word ; asynchronous read : the old word
  -- before the edge
  procedure run
    (signal   clk      : in    std_logic
    ;signal   req      : out   t_ram_req
    ;signal   rsp      : in    t_ram_rsp
    ;variable model    : inout t_model
    );

end package tb_ram_read_during_write_pkg;

package body tb_ram_read_during_write_pkg is

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
    for a in 0 to DEPTH-1
    loop
      ram_cycle(true, a, true, a, true , a, pattern(a, 1, WIDTH), "Read during write", clk, req, rsp, model);
      ram_cycle(true, a, true, a, false, 0, ZERO                , "Read after write" , clk, req, rsp, model);
    end loop;
    ram_idle("Read after write", clk, req, rsp, model);
  end procedure;

end package body tb_ram_read_during_write_pkg;
