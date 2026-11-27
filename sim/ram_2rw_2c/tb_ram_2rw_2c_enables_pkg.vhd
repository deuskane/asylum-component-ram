-------------------------------------------------------------------------------
-- Title      : tb_ram_2rw_2c_enables_pkg
-- Project    : ram
-------------------------------------------------------------------------------
-- File       : tb_ram_2rw_2c_enables_pkg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Scenario enables : on each port, cke = 0 blocks the write and
--              the read, cs = 0 blocks the write and the read, a write keeps
--              rdata (no change), rdata is held between two reads
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

package tb_ram_2rw_2c_enables_pkg is

  procedure run
    (signal   clk0     : in    std_logic
    ;signal   req0     : out   t_port_req
    ;signal   rdata0   : in    std_logic_vector
    ;signal   clk1     : in    std_logic
    ;signal   req1     : out   t_port_req
    ;signal   rdata1   : in    std_logic_vector
    );

end package tb_ram_2rw_2c_enables_pkg;

package body tb_ram_2rw_2c_enables_pkg is

  procedure enables
    (constant msg      : in    string
    ;signal   clk      : in    std_logic
    ;signal   req      : out   t_port_req
    ;signal   rdata    : in    std_logic_vector
    ) is
    constant WIDTH : natural := rdata'length;
    constant X     : std_logic_vector(WIDTH-1 downto 0) := pattern(2, 0, WIDTH);
    constant Y     : std_logic_vector(WIDTH-1 downto 0) := pattern(2, 1, WIDTH);
    constant Z     : std_logic_vector(WIDTH-1 downto 0) := pattern(3, 2, WIDTH);
  begin
    port_write(2, X, clk, req);
    port_write(3, Z, clk, req);
    port_read (2, X, msg & " : write", clk, req, rdata);

    port_cycle('0', '1', '1', 2, Y, clk, req);
    check_value(rdata, X, error, msg & " : rdata held, write with cke = 0", C_TB_SCOPE);
    port_cycle('0', '1', '0', 3, Y, clk, req);
    check_value(rdata, X, error, msg & " : rdata held, read with cke = 0" , C_TB_SCOPE);
    port_cycle('1', '0', '0', 3, Y, clk, req);
    check_value(rdata, X, error, msg & " : rdata held, read with cs = 0"  , C_TB_SCOPE);
    port_cycle('1', '0', '1', 2, Y, clk, req);
    check_value(rdata, X, error, msg & " : rdata held, write with cs = 0" , C_TB_SCOPE);
    port_read (2, X, msg & " : no write with cke = 0 or cs = 0", clk, req, rdata);

    port_read (3, Z, msg & " : read", clk, req, rdata);
    port_write(2, Y, clk, req);
    check_value(rdata, Z, error, msg & " : rdata held by a write (no change)", C_TB_SCOPE);
    port_read (2, Y, msg & " : write after the blocked ones", clk, req, rdata);
  end procedure;

  procedure run
    (signal   clk0     : in    std_logic
    ;signal   req0     : out   t_port_req
    ;signal   rdata0   : in    std_logic_vector
    ;signal   clk1     : in    std_logic
    ;signal   req1     : out   t_port_req
    ;signal   rdata1   : in    std_logic_vector
    ) is
  begin
    enables("Port 0", clk0, req0, rdata0);
    enables("Port 1", clk1, req1, rdata1);
  end procedure;

end package body tb_ram_2rw_2c_enables_pkg;
