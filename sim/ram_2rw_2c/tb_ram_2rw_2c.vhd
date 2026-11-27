-------------------------------------------------------------------------------
-- Title      : tb_ram_2rw_2c
-- Project    : ram
-------------------------------------------------------------------------------
-- File       : tb_ram_2rw_2c.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Self-checking UVVM testbench of ram_2rw_2c (true dual-port
--              RAM, one clock per port).
--              TESTS_LIST  : scenarios run in sequence, separated by ','
--                            (tb_ram_2rw_2c_tests_pkg) ; "" : build and
--                            elaboration only
--              WIDTH, DEPTH : generics of the RAM (DEPTH >= 2)
--              CLK0_PERIOD, CLK1_PERIOD : periods of the clocks of port 0
--                            and port 1, in ns (unrelated clocks : e.g. 10
--                            and 13)
--              Monitor : the read data of a port change on a rising edge of
--              its own clock only.
--              The RAM has no reset : each scenario writes the words it
--              reads, after both ports were idle for a few cycles.
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

library asylum;
use     asylum.ram_pkg.all;
use     asylum.string_pkg.all;

library work;
use     work.tb_ram_2rw_2c_bfm_pkg.all;
use     work.tb_ram_2rw_2c_tests_pkg.all;

entity tb_ram_2rw_2c is
  generic (
    TESTS_LIST       : string  := ""      -- Scenarios, e.g. "port0,cross"
   ;WIDTH            : natural := 8       -- Word width
   ;DEPTH            : natural := 16      -- Number of words, power of 2, >= 2
   ;CLK0_PERIOD      : natural := 10      -- Period of clk0, ns
   ;CLK1_PERIOD      : natural := 13      -- Period of clk1, ns
  );
end entity tb_ram_2rw_2c;

architecture sim of tb_ram_2rw_2c is

  constant C_SCOPE         : string  := "TB_RAM_2RW_2C";
  constant C_AW            : natural := asylum.math_pkg.log2(DEPTH);

  signal   clk0            : std_logic := '0';
  signal   clk1            : std_logic := '0';
  signal   clk_ena         : boolean   := true;

  signal   req0            : t_port_req(addr (C_AW -1 downto 0)
                                       ,wdata(WIDTH-1 downto 0));
  signal   req1            : t_port_req(addr (C_AW -1 downto 0)
                                       ,wdata(WIDTH-1 downto 0));
  signal   rdata0          : std_logic_vector(WIDTH-1 downto 0);
  signal   rdata1          : std_logic_vector(WIDTH-1 downto 0);

begin

  clock_generator(clk0, clk_ena, CLK0_PERIOD * 1 ns, "TB Clock 0");
  clock_generator(clk1, clk_ena, CLK1_PERIOD * 1 ns, "TB Clock 1");

  -----------------------------------------------------------------------------
  -- DUT
  -----------------------------------------------------------------------------
  dut : ram_2rw_2c
    generic map
    (WIDTH     => WIDTH
    ,DEPTH     => DEPTH
    )
    port map
    (clk0_i    => clk0
    ,cke0_i    => req0.cke
    ,cs0_i     => req0.cs
    ,we0_i     => req0.we
    ,addr0_i   => req0.addr
    ,wdata0_i  => req0.wdata
    ,rdata0_o  => rdata0
    ,clk1_i    => clk1
    ,cke1_i    => req1.cke
    ,cs1_i     => req1.cs
    ,we1_i     => req1.we
    ,addr1_i   => req1.addr
    ,wdata1_i  => req1.wdata
    ,rdata1_o  => rdata1
    );

  -----------------------------------------------------------------------------
  -- Monitor : the read data of a port change on a rising edge of its own
  -- clock only
  -----------------------------------------------------------------------------
  p_rdata0 : process
  begin
    wait on rdata0;
    if not (clk0 = '1' and clk0'last_event = 0 ns)
    then
      alert(ERROR, "rdata0_o changed out of a rising edge of clk0", C_SCOPE);
    end if;
  end process p_rdata0;

  p_rdata1 : process
  begin
    wait on rdata1;
    if not (clk1 = '1' and clk1'last_event = 0 ns)
    then
      alert(ERROR, "rdata1_o changed out of a rising edge of clk1", C_SCOPE);
    end if;
  end process p_rdata1;

  -----------------------------------------------------------------------------
  -- Sequencer
  -----------------------------------------------------------------------------
  p_main : process
  begin
    log(ID_LOG_HDR, "WIDTH = " & to_string(WIDTH) & ", DEPTH = " & to_string(DEPTH) &
        ", clk0 " & to_string(CLK0_PERIOD) & " ns, clk1 " & to_string(CLK1_PERIOD) & " ns, TESTS_LIST : " & TESTS_LIST, C_SCOPE);

    if DEPTH < 2
    then
      alert(TB_ERROR, "DEPTH >= 2 needed by the scenarios", C_SCOPE);
    end if;

    -- Every name is checked before the first scenario
    for i in 1 to list_length(TESTS_LIST)
    loop
      if not list_contains(C_TESTS, list_item(TESTS_LIST, i))
      then
        alert(TB_ERROR, "Unknown test """ & list_item(TESTS_LIST, i) & """ (tests : " & C_TESTS & ")", C_SCOPE);
      end if;
    end loop;

    for i in 1 to list_length(TESTS_LIST)
    loop
      -- Both ports idle for a few cycles (the RAM has no reset)
      port_idle(req0);
      port_idle(req1);
      wait for 4 * maximum(CLK0_PERIOD, CLK1_PERIOD) * 1 ns;

      log(ID_LOG_HDR, "TEST " & integer'image(i) & "/" & integer'image(list_length(TESTS_LIST)) & " : " & list_item(TESTS_LIST, i), C_SCOPE);
      run_test(list_item(TESTS_LIST, i), clk0, req0, rdata0, clk1, req1, rdata1);
    end loop;

    wait for 4 * maximum(CLK0_PERIOD, CLK1_PERIOD) * 1 ns;
    report_alert_counters(FINAL);
    std.env.stop;
    wait;
  end process p_main;

end architecture sim;
