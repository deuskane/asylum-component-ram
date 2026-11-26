-------------------------------------------------------------------------------
-- Title      : tb_ram_2rw_2c_concurrent_pkg
-- Project    : ram
-------------------------------------------------------------------------------
-- File       : tb_ram_2rw_2c_concurrent_pkg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Scenario concurrent : both ports busy at the same time, each on
--              its own clock : port 0 writes the even addresses while port 1
--              writes the odd ones, then port 0 reads the odd addresses while
--              port 1 reads the even ones (one access per cycle of each
--              clock)
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

package tb_ram_2rw_2c_concurrent_pkg is

  procedure run
    (signal   clk0     : in    std_logic
    ;signal   req0     : out   t_port_req
    ;signal   rdata0   : in    std_logic_vector
    ;signal   clk1     : in    std_logic
    ;signal   req1     : out   t_port_req
    ;signal   rdata1   : in    std_logic_vector
    );

end package tb_ram_2rw_2c_concurrent_pkg;

package body tb_ram_2rw_2c_concurrent_pkg is

  procedure run
    (signal   clk0     : in    std_logic
    ;signal   req0     : out   t_port_req
    ;signal   rdata0   : in    std_logic_vector
    ;signal   clk1     : in    std_logic
    ;signal   req1     : out   t_port_req
    ;signal   rdata1   : in    std_logic_vector
    ) is
    constant DEPTH : natural := 2**req0.addr'length;
    constant WIDTH : natural := rdata0'length;
    variable v_a0  : natural;    -- Next address of each port
    variable v_a1  : natural;
    variable v_p0  : integer;    -- Address of the pending read of each port (-1 : none)
    variable v_p1  : integer;
  begin
    -- Writes : port 0 even addresses (seed 4), port 1 odd addresses (seed 5)
    v_a0 := 0;
    v_a1 := 1;
    while v_a0 < DEPTH or v_a1 < DEPTH
    loop
      wait until falling_edge(clk0) or falling_edge(clk1);
      if falling_edge(clk0)
      then
        if v_a0 < DEPTH
        then
          port_drive('1', '1', '1', v_a0, pattern(v_a0, 4, WIDTH), req0);
          v_a0 := v_a0 + 2;
        else
          port_idle(req0);
        end if;
      end if;
      if falling_edge(clk1)
      then
        if v_a1 < DEPTH
        then
          port_drive('1', '1', '1', v_a1, pattern(v_a1, 5, WIDTH), req1);
          v_a1 := v_a1 + 2;
        else
          port_idle(req1);
        end if;
      end if;
    end loop;

    -- Reads : port 0 odd addresses, port 1 even addresses, the read data of
    -- a port checked on its next falling edge
    v_a0 := 1;
    v_a1 := 0;
    v_p0 := -1;
    v_p1 := -1;
    while v_a0 < DEPTH or v_a1 < DEPTH or v_p0 >= 0 or v_p1 >= 0
    loop
      wait until falling_edge(clk0) or falling_edge(clk1);
      if falling_edge(clk0)
      then
        if v_p0 >= 0
        then
          check_value(rdata0, pattern(v_p0, 5, WIDTH), error, "Port 0 reads a word of port 1 @" & to_string(v_p0), C_TB_SCOPE);
          v_p0 := -1;
        end if;
        if v_a0 < DEPTH
        then
          port_drive('1', '1', '0', v_a0, (WIDTH-1 downto 0 => '0'), req0);
          v_p0 := v_a0;
          v_a0 := v_a0 + 2;
        else
          port_idle(req0);
        end if;
      end if;
      if falling_edge(clk1)
      then
        if v_p1 >= 0
        then
          check_value(rdata1, pattern(v_p1, 4, WIDTH), error, "Port 1 reads a word of port 0 @" & to_string(v_p1), C_TB_SCOPE);
          v_p1 := -1;
        end if;
        if v_a1 < DEPTH
        then
          port_drive('1', '1', '0', v_a1, (WIDTH-1 downto 0 => '0'), req1);
          v_p1 := v_a1;
          v_a1 := v_a1 + 2;
        else
          port_idle(req1);
        end if;
      end if;
    end loop;
  end procedure;

end package body tb_ram_2rw_2c_concurrent_pkg;
