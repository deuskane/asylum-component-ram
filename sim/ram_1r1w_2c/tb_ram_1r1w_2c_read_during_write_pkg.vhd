-------------------------------------------------------------------------------
-- Title      : tb_ram_1r1w_2c_read_during_write_pkg
-- Project    : ram
-------------------------------------------------------------------------------
-- File       : tb_ram_1r1w_2c_read_during_write_pkg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Scenario read_during_write : the read port reads the same
--              address on every cycle of clk1 while the write port writes
--              every other address on clk0 : the read data stay the old word ;
--              then the new words are read back
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

package tb_ram_1r1w_2c_read_during_write_pkg is

  -- Port 0 : write port (clk0), port 1 : read port (clk1)
  procedure run
    (signal   clk0     : in    std_logic
    ;signal   req0     : out   t_port_req
    ;signal   clk1     : in    std_logic
    ;signal   req1     : out   t_port_req
    ;signal   rdata1   : in    std_logic_vector
    );

end package tb_ram_1r1w_2c_read_during_write_pkg;

package body tb_ram_1r1w_2c_read_during_write_pkg is

  procedure run
    (signal   clk0     : in    std_logic
    ;signal   req0     : out   t_port_req
    ;signal   clk1     : in    std_logic
    ;signal   req1     : out   t_port_req
    ;signal   rdata1   : in    std_logic_vector
    ) is
    constant DEPTH : natural := 2**req0.addr'length;
    constant WIDTH : natural := rdata1'length;
    constant A_R   : natural := DEPTH-1;     -- Address read during the writes
    variable v_a   : natural := 0;
    variable v_rd  : boolean := false;
  begin
    port_fill(6, clk0, req0);
    while v_a < DEPTH or v_rd
    loop
      wait until falling_edge(clk1) or falling_edge(clk0);
      if falling_edge(clk1)
      then
        if v_rd
        then
          check_value(rdata1, pattern(A_R, 6, WIDTH), error, "Read @" & to_string(A_R) & " while the write port writes", C_TB_SCOPE);
        end if;
        v_rd := v_a < DEPTH;
        port_drive('1', to_sl(v_rd), '0', A_R, (WIDTH-1 downto 0 => '0'), req1);
      end if;
      if falling_edge(clk0)
      then
        if v_a = A_R
        then
          v_a := v_a + 1;
        end if;
        if v_a < DEPTH
        then
          port_drive('1', '1', '1', v_a, pattern(v_a, 7, WIDTH), req0);
          v_a := v_a + 1;
        else
          port_idle(req0);
        end if;
      end if;
    end loop;
    wait until falling_edge(clk0);
    port_idle(req0);

    for a in 0 to DEPTH-1
    loop
      if a = A_R
      then
        port_read(a, pattern(a, 6, WIDTH), "Word read during the writes" , clk1, req1, rdata1);
      else
        port_read(a, pattern(a, 7, WIDTH), "Word written during the reads", clk1, req1, rdata1);
      end if;
    end loop;
  end procedure;

end package body tb_ram_1r1w_2c_read_during_write_pkg;
