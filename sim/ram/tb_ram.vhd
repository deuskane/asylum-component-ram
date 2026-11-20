-------------------------------------------------------------------------------
-- Title      : tb_ram
-- Project    : ram
-------------------------------------------------------------------------------
-- File       : tb_ram.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Self-checking UVVM testbench of ram_1r1w, ram_2r1w, ram_1rw
--              and sbi_ram (SBI VIP).
--              TESTS_LIST : scenarios run in sequence, separated by ','
--                           (tb_ram_tests_pkg), each one after a reset
--                           pulse ; "" : build and elaboration only
--              WIDTH, DEPTH, SYNC_READ : generics of the RAMs (sbi_ram :
--                           DEPTH and SYNC_READ, word of WIDTH bits)
--              ram_1r1w, ram_2r1w and ram_1rw receive the same accesses
--              and share one reference model (tb_ram_bfm_pkg) ; a monitor
--              measures the wait states of each sbi_ram access and checks
--              that ready is never set without cs.
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-10-05  1.0      mrosiere Created (replaces tb_ram_1r1w)
-- 2026-11-20  2.0      mrosiere TESTS_LIST, one package per scenario
--                               (tb_ram_<name>_pkg), helpers and model in
--                               tb_ram_bfm_pkg, reset pulse before each
--                               scenario, sbi_ram with a NAME
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library bitvis_vip_sbi;
use     bitvis_vip_sbi.sbi_bfm_pkg.all;

library asylum;
use     asylum.sbi_pkg.all;
use     asylum.string_pkg.all;
use     asylum.ram_pkg.all;

library work;
use     work.tb_ram_bfm_pkg.all;
use     work.tb_ram_tests_pkg.all;

entity tb_ram is
  generic (
    TESTS_LIST       : string  := ""      -- Scenarios, e.g. "write_read,random"
   ;WIDTH            : natural := 8       -- Word width
   ;DEPTH            : natural := 16      -- Number of words, power of 2, >= 16
   ;SYNC_READ        : boolean := false   -- Registered read
  );
end entity tb_ram;

architecture sim of tb_ram is

  constant C_SCOPE         : string  := "TB_RAM";
  constant C_AW            : natural := asylum.math_pkg.log2(DEPTH);
  constant C_SBI_AW        : natural := C_AW + 2;  -- 2 extra bits to check the address aliasing of sbi_ram

  signal   clk             : std_logic := '0';
  signal   clk_ena         : boolean   := true;
  signal   arst_b          : std_logic := '0';

  -- ram_1r1w, ram_2r1w, ram_1rw
  signal   req             : t_ram_req(raddr0  (C_AW -1 downto 0)
                                      ,raddr1  (C_AW -1 downto 0)
                                      ,waddr   (C_AW -1 downto 0)
                                      ,wdata   (WIDTH-1 downto 0)
                                      ,addr    (C_AW -1 downto 0));
  signal   rsp             : t_ram_rsp(rdata   (WIDTH-1 downto 0)
                                      ,rdata0  (WIDTH-1 downto 0)
                                      ,rdata1  (WIDTH-1 downto 0)
                                      ,rw_rdata(WIDTH-1 downto 0));

  -- sbi_ram
  signal   sbi_ini         : sbi_ini_t(addr (C_SBI_AW-1 downto 0),
                                       wdata(WIDTH   -1 downto 0));
  signal   sbi_tgt         : sbi_tgt_t(rdata(WIDTH   -1 downto 0));
  signal   sbi_tgt_name    : sbi_tgt_t(rdata(WIDTH   -1 downto 0));
  signal   sbi_if          : t_sbi_if (addr (C_SBI_AW-1 downto 0),
                                       wdata(WIDTH   -1 downto 0),
                                       rdata(WIDTH   -1 downto 0));
  signal   sbi_wait        : natural := 0; -- Wait states of the last SBI access

begin

  clock_generator(clk, clk_ena, C_CLK_PERIOD, "TB Clock");

  -----------------------------------------------------------------------------
  -- DUTs
  -----------------------------------------------------------------------------
  dut_ram_1r1w : ram_1r1w
    generic map
    (WIDTH     => WIDTH
    ,DEPTH     => DEPTH
    ,SYNC_READ => SYNC_READ
    )
    port map
    (clk_i     => clk
    ,cke_i     => req.cke
    ,re_i      => req.re0
    ,raddr_i   => req.raddr0
    ,rdata_o   => rsp.rdata
    ,we_i      => req.we
    ,waddr_i   => req.waddr
    ,wdata_i   => req.wdata
    );

  dut_ram_2r1w : ram_2r1w
    generic map
    (WIDTH     => WIDTH
    ,DEPTH     => DEPTH
    ,SYNC_READ => SYNC_READ
    )
    port map
    (clk_i     => clk
    ,cke_i     => req.cke
    ,re0_i     => req.re0
    ,raddr0_i  => req.raddr0
    ,rdata0_o  => rsp.rdata0
    ,re1_i     => req.re1
    ,raddr1_i  => req.raddr1
    ,rdata1_o  => rsp.rdata1
    ,we_i      => req.we
    ,waddr_i   => req.waddr
    ,wdata_i   => req.wdata
    );

  dut_ram_1rw : ram_1rw
    generic map
    (WIDTH     => WIDTH
    ,DEPTH     => DEPTH
    ,SYNC_READ => SYNC_READ
    )
    port map
    (clk_i     => clk
    ,cke_i     => req.cke
    ,cs_i      => req.cs
    ,we_i      => req.rw_we
    ,addr_i    => req.addr
    ,wdata_i   => req.wdata
    ,rdata_o   => rsp.rw_rdata
    );

  dut_sbi_ram : sbi_ram
    generic map
    (NAME      => ""
    ,DEPTH     => DEPTH
    ,SYNC_READ => SYNC_READ
    )
    port map
    (clk_i     => clk
    ,arst_b_i  => arst_b
    ,sbi_ini_i => sbi_ini
    ,sbi_tgt_o => sbi_tgt
    );

  -- Same bus, only its info.name is checked
  dut_sbi_ram_name : sbi_ram
    generic map
    (NAME      => "RAM0"
    ,DEPTH     => DEPTH
    ,SYNC_READ => SYNC_READ
    )
    port map
    (clk_i     => clk
    ,arst_b_i  => arst_b
    ,sbi_ini_i => sbi_ini
    ,sbi_tgt_o => sbi_tgt_name
    );

  sbi_ini.cs    <= sbi_if.cs;
  sbi_ini.addr  <= std_logic_vector(sbi_if.addr);
  sbi_ini.re    <= sbi_if.rena;
  sbi_ini.we    <= sbi_if.wena;
  sbi_ini.wdata <= sbi_if.wdata;
  sbi_if.ready  <= sbi_tgt.ready;
  sbi_if.rdata  <= sbi_tgt.rdata;

  -----------------------------------------------------------------------------
  -- SBI monitor : wait states of each access, ready only during an access
  -----------------------------------------------------------------------------
  p_sbi_monitor : process (clk) is
    variable v_cnt : natural := 0;
  begin
    if rising_edge(clk)
    then
      if arst_b = '0'
      then
        -- No access yet : a wait state check fails
        sbi_wait <= natural'high;
        v_cnt    := 0;
      else
        if sbi_ini.cs = '1'
        then
          if sbi_tgt.ready = '1'
          then
            sbi_wait <= v_cnt;
            v_cnt    := 0;
          else
            v_cnt    := v_cnt + 1;
          end if;
        else
          v_cnt := 0;
          if sbi_tgt.ready = '1'
          then
            alert(ERROR, "sbi_ram: ready = 1 without cs", C_SCOPE);
          end if;
        end if;
      end if;
    end if;
  end process p_sbi_monitor;

  -----------------------------------------------------------------------------
  -- Sequencer
  -----------------------------------------------------------------------------
  p_sequencer : process
    -- Reference model of ram_1r1w, ram_2r1w and ram_1rw
    variable v_model : t_model(mem   (0 to DEPTH-1)(WIDTH-1 downto 0)
                              ,valid (0 to DEPTH-1)
                              ,exp0  (WIDTH-1 downto 0)
                              ,exp1  (WIDTH-1 downto 0)
                              ,exp_rw(WIDTH-1 downto 0));
  begin
    log(ID_LOG_HDR, "WIDTH = " & to_string(WIDTH) & ", DEPTH = " & to_string(DEPTH) & ", SYNC_READ = " & to_string(SYNC_READ) & ", TESTS_LIST : " & TESTS_LIST, C_SCOPE);

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
      -- Reset pulse, RAM inputs and bus inactive, empty model : each
      -- scenario starts from reset and writes the words it reads
      sbi_if <= init_sbi_if_signals(C_SBI_AW, WIDTH);
      ram_req_idle(req);
      model_reset(v_model, SYNC_READ);
      do_reset(clk, arst_b);

      log(ID_LOG_HDR, "TEST " & integer'image(i) & "/" & integer'image(list_length(TESTS_LIST)) & " : " & list_item(TESTS_LIST, i), C_SCOPE);
      run_test(list_item(TESTS_LIST, i), DEPTH, SYNC_READ, clk, req, rsp, v_model, sbi_if, sbi_wait, sbi_tgt.info.name, sbi_tgt_name.info.name);
    end loop;

    report_alert_counters(FINAL);
    std.env.stop;
    wait;
  end process p_sequencer;

end architecture sim;
