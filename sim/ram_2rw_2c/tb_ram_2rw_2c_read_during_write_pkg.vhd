-------------------------------------------------------------------------------
-- Title      : tb_ram_2rw_2c_read_during_write_pkg
-- Project    : ram
-------------------------------------------------------------------------------
-- File       : tb_ram_2rw_2c_read_during_write_pkg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Scenario read_during_write : one port reads the same address on
--              every cycle of its clock while the other port writes every
--              other address on its own clock : the read data stays the old
--              word ; then the new words are read back. Port 1 reads while
--              port 0 writes, then the reverse
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

package tb_ram_2rw_2c_read_during_write_pkg is

  procedure run
    (signal   clk0     : in    std_logic
    ;signal   req0     : out   t_port_req
    ;signal   rdata0   : in    std_logic_vector
    ;signal   clk1     : in    std_logic
    ;signal   req1     : out   t_port_req
    ;signal   rdata1   : in    std_logic_vector
    );

end package tb_ram_2rw_2c_read_during_write_pkg;

package body tb_ram_2rw_2c_read_during_write_pkg is

  -- Reader port r reads address a_r on every cycle while writer port w
  -- writes every other address with pattern(seed_w), then r checks them
  procedure read_while_write
    (constant a_r      : in    natural
    ;constant seed_r   : in    natural    -- Pattern of the word at a_r
    ;constant seed_w   : in    natural    -- Pattern of the words written by w
    ;constant msg      : in    string
    ;signal   clk_r    : in    std_logic
    ;signal   req_r    : out   t_port_req
    ;signal   rdata_r  : in    std_logic_vector
    ;signal   clk_w    : in    std_logic
    ;signal   req_w    : out   t_port_req
    ) is
    constant DEPTH : natural := 2**req_r.addr'length;
    constant WIDTH : natural := rdata_r'length;
    variable v_a   : natural := 0;       -- Next address written by w
    variable v_rd  : boolean := false;   -- A read of r is pending
  begin
    while v_a < DEPTH or v_rd
    loop
      wait until falling_edge(clk_r) or falling_edge(clk_w);
      if falling_edge(clk_r)
      then
        if v_rd
        then
          check_value(rdata_r, pattern(a_r, seed_r, WIDTH), error, msg & " : read @" & to_string(a_r) & " while the other port writes", C_TB_SCOPE);
        end if;
        v_rd := v_a < DEPTH;
        port_drive('1', to_sl(v_rd), '0', a_r, (WIDTH-1 downto 0 => '0'), req_r);
      end if;
      if falling_edge(clk_w)
      then
        if v_a = a_r
        then
          v_a := v_a + 1;
        end if;
        if v_a < DEPTH
        then
          port_drive('1', '1', '1', v_a, pattern(v_a, seed_w, WIDTH), req_w);
          v_a := v_a + 1;
        else
          port_idle(req_w);
        end if;
      end if;
    end loop;
    wait until falling_edge(clk_w);
    port_idle(req_w);

    -- New words, and the word read during the writes unchanged
    for a in 0 to DEPTH-1
    loop
      if a = a_r
      then
        port_read(a, pattern(a, seed_r, WIDTH), msg & " : word read during the writes", clk_r, req_r, rdata_r);
      else
        port_read(a, pattern(a, seed_w, WIDTH), msg & " : word written during the reads", clk_r, req_r, rdata_r);
      end if;
    end loop;
  end procedure;

  procedure run
    (signal   clk0     : in    std_logic
    ;signal   req0     : out   t_port_req
    ;signal   rdata0   : in    std_logic_vector
    ;signal   clk1     : in    std_logic
    ;signal   req1     : out   t_port_req
    ;signal   rdata1   : in    std_logic_vector
    ) is
    constant DEPTH : natural := 2**req0.addr'length;
  begin
    port_fill(6, clk1, req1);
    read_while_write(0      , 6, 7, "Port 1 reads, port 0 writes", clk1, req1, rdata1, clk0, req0);
    read_while_write(DEPTH-1, 7, 2, "Port 0 reads, port 1 writes", clk0, req0, rdata0, clk1, req1);
  end procedure;

end package body tb_ram_2rw_2c_read_during_write_pkg;
