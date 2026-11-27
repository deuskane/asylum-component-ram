-------------------------------------------------------------------------------
-- Title      : tb_ram_1r1w_2c_enables_pkg
-- Project    : ram
-------------------------------------------------------------------------------
-- File       : tb_ram_1r1w_2c_enables_pkg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Scenario enables : cke0 = 0 or we0 = 0 blocks the write, cke1 = 0
--              or re1 = 0 blocks the read (rdata held)
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

package tb_ram_1r1w_2c_enables_pkg is

  -- Port 0 : write port (clk0), port 1 : read port (clk1)
  procedure run
    (signal   clk0     : in    std_logic
    ;signal   req0     : out   t_port_req
    ;signal   clk1     : in    std_logic
    ;signal   req1     : out   t_port_req
    ;signal   rdata1   : in    std_logic_vector
    );

end package tb_ram_1r1w_2c_enables_pkg;

package body tb_ram_1r1w_2c_enables_pkg is

  procedure run
    (signal   clk0     : in    std_logic
    ;signal   req0     : out   t_port_req
    ;signal   clk1     : in    std_logic
    ;signal   req1     : out   t_port_req
    ;signal   rdata1   : in    std_logic_vector
    ) is
    constant WIDTH : natural := rdata1'length;
    constant X     : std_logic_vector(WIDTH-1 downto 0) := pattern(2, 0, WIDTH);
    constant Y     : std_logic_vector(WIDTH-1 downto 0) := pattern(2, 1, WIDTH);
    constant Z     : std_logic_vector(WIDTH-1 downto 0) := pattern(3, 2, WIDTH);
  begin
    port_write(2, X, clk0, req0);
    port_write(3, Z, clk0, req0);
    port_read (2, X, "Write", clk1, req1, rdata1);

    port_cycle('0', '1', '1', 2, Y, clk0, req0);
    port_cycle('1', '1', '0', 2, Y, clk0, req0);
    port_read (2, X, "No write with cke0 = 0 or we0 = 0", clk1, req1, rdata1);

    port_cycle('0', '1', '0', 3, Y, clk1, req1);
    check_value(rdata1, X, error, "rdata held, read with cke1 = 0", C_TB_SCOPE);
    port_cycle('1', '0', '0', 3, Y, clk1, req1);
    check_value(rdata1, X, error, "rdata held, read with re1 = 0" , C_TB_SCOPE);
    port_read (3, Z, "Read after the blocked ones", clk1, req1, rdata1);
  end procedure;

end package body tb_ram_1r1w_2c_enables_pkg;
