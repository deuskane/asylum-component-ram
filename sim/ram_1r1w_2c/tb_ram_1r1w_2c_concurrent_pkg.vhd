-------------------------------------------------------------------------------
-- Title      : tb_ram_1r1w_2c_concurrent_pkg
-- Project    : ram
-------------------------------------------------------------------------------
-- File       : tb_ram_1r1w_2c_concurrent_pkg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Scenario concurrent : both ports busy at the same time, each on
--              its own clock : the write port writes every address once, one
--              word per cycle of clk0, while the read port reads, one word
--              per cycle of clk1, every word written at least one cycle of
--              clk0 before (no collision)
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

package tb_ram_1r1w_2c_concurrent_pkg is

  -- Port 0 : write port (clk0), port 1 : read port (clk1)
  procedure run
    (signal   clk0     : in    std_logic
    ;signal   req0     : out   t_port_req
    ;signal   clk1     : in    std_logic
    ;signal   req1     : out   t_port_req
    ;signal   rdata1   : in    std_logic_vector
    );

end package tb_ram_1r1w_2c_concurrent_pkg;

package body tb_ram_1r1w_2c_concurrent_pkg is

  procedure run
    (signal   clk0     : in    std_logic
    ;signal   req0     : out   t_port_req
    ;signal   clk1     : in    std_logic
    ;signal   req1     : out   t_port_req
    ;signal   rdata1   : in    std_logic_vector
    ) is
    constant DEPTH : natural := 2**req0.addr'length;
    constant WIDTH : natural := rdata1'length;
    variable v_w   : natural := 0;      -- Next address driven on the write port
    variable v_r   : natural := 0;      -- Next address read
    variable v_p   : integer := -1;     -- Address of the pending read (-1 : none)
    variable v_end : boolean := false;  -- Last word written
  begin
    while v_r < DEPTH or v_p >= 0
    loop
      wait until falling_edge(clk0) or falling_edge(clk1);
      if falling_edge(clk0)
      then
        if v_w < DEPTH
        then
          port_drive('1', '1', '1', v_w, pattern(v_w, 5, WIDTH), req0);
          v_w := v_w + 1;
        else
          -- The last word was written on the rising edge before
          v_end := true;
          port_idle(req0);
        end if;
      end if;
      if falling_edge(clk1)
      then
        if v_p >= 0
        then
          check_value(rdata1, pattern(v_p, 5, WIDTH), error, "Read while the write port writes @" & to_string(v_p), C_TB_SCOPE);
          v_p := -1;
        end if;
        -- Word v_r written on an edge of clk0 already past : v_w - 2 at least
        if v_r < DEPTH and (v_r + 2 <= v_w or v_end)
        then
          port_drive('1', '1', '0', v_r, (WIDTH-1 downto 0 => '0'), req1);
          v_p := v_r;
          v_r := v_r + 1;
        else
          port_idle(req1);
        end if;
      end if;
    end loop;
  end procedure;

end package body tb_ram_1r1w_2c_concurrent_pkg;
