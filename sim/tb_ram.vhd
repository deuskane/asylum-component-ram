-------------------------------------------------------------------------------
-- Title      : tb_ram
-- Project    : ram
-------------------------------------------------------------------------------
-- File       : tb_ram.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Self-checking UVVM testbench of ram_1r1w, ram_1rw, ram_2r1w
--              and sbi_ram (SBI VIP).
--              ram_1r1w, ram_2r1w and ram_1rw receive the same write stream,
--              so they share one reference model; the read data are checked
--              every cycle (asynchronous or registered read, from SYNC_READ).
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-10-05  1.0      mrosiere Created (replaces tb_ram_1r1w)
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
use     asylum.ram_pkg.all;

entity tb_ram is
  generic (
    WIDTH     : natural := 8;
    DEPTH     : natural := 16;   -- Power of 2, >= 16
    SYNC_READ : boolean := false
    );
end tb_ram;

architecture tb of tb_ram is

  constant C_SCOPE      : string  := "TB_RAM";
  constant C_CLK_PERIOD : time    := 10 ns;
  constant C_AW         : natural := asylum.math_pkg.log2(DEPTH);
  constant C_SBI_AW     : natural := C_AW + 2;     -- 2 extra bits to check the address aliasing of sbi_ram
  constant C_SBI_WAIT   : natural := boolean'pos(SYNC_READ); -- Expected wait states of sbi_ram

  signal clk            : std_logic := '0';
  signal clk_ena        : boolean   := true;
  signal arst_b         : std_logic := '0';
  signal cke            : std_logic := '1';

  -- ram_1r1w
  signal r1w1_re        : std_logic := '0';
  signal r1w1_raddr     : std_logic_vector(C_AW -1 downto 0) := (others => '0');
  signal r1w1_rdata     : std_logic_vector(WIDTH-1 downto 0);
  signal r1w1_we        : std_logic := '0';
  signal r1w1_waddr     : std_logic_vector(C_AW -1 downto 0) := (others => '0');
  signal r1w1_wdata     : std_logic_vector(WIDTH-1 downto 0) := (others => '0');

  -- ram_2r1w
  signal r2w1_re0       : std_logic := '0';
  signal r2w1_raddr0    : std_logic_vector(C_AW -1 downto 0) := (others => '0');
  signal r2w1_rdata0    : std_logic_vector(WIDTH-1 downto 0);
  signal r2w1_re1       : std_logic := '0';
  signal r2w1_raddr1    : std_logic_vector(C_AW -1 downto 0) := (others => '0');
  signal r2w1_rdata1    : std_logic_vector(WIDTH-1 downto 0);
  signal r2w1_we        : std_logic := '0';
  signal r2w1_waddr     : std_logic_vector(C_AW -1 downto 0) := (others => '0');
  signal r2w1_wdata     : std_logic_vector(WIDTH-1 downto 0) := (others => '0');

  -- ram_1rw
  signal rw1_cs         : std_logic := '0';
  signal rw1_we         : std_logic := '0';
  signal rw1_addr       : std_logic_vector(C_AW -1 downto 0) := (others => '0');
  signal rw1_wdata      : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
  signal rw1_rdata      : std_logic_vector(WIDTH-1 downto 0);

  -- sbi_ram
  signal sbi_ini        : sbi_ini_t(addr (C_SBI_AW-1 downto 0),
                                    wdata(WIDTH   -1 downto 0));
  signal sbi_tgt        : sbi_tgt_t(rdata(WIDTH   -1 downto 0));
  signal sbi_if         : t_sbi_if (addr (C_SBI_AW-1 downto 0),
                                    wdata(WIDTH   -1 downto 0),
                                    rdata(WIDTH   -1 downto 0));
  signal sbi_wait       : natural := 0; -- Wait states of the last SBI access

begin

  arst_b <= '0', '1' after 5*C_CLK_PERIOD;

  clock_generator(clk, clk_ena, C_CLK_PERIOD, "TB Clock");

  ------------------------------------------------
  -- DUTs
  ------------------------------------------------
  ins_ram_1r1w : ram_1r1w
    generic map
    (WIDTH     => WIDTH
    ,DEPTH     => DEPTH
    ,SYNC_READ => SYNC_READ
    )
    port map
    (clk_i     => clk
    ,cke_i     => cke
    ,re_i      => r1w1_re
    ,raddr_i   => r1w1_raddr
    ,rdata_o   => r1w1_rdata
    ,we_i      => r1w1_we
    ,waddr_i   => r1w1_waddr
    ,wdata_i   => r1w1_wdata
    );

  ins_ram_2r1w : ram_2r1w
    generic map
    (WIDTH     => WIDTH
    ,DEPTH     => DEPTH
    ,SYNC_READ => SYNC_READ
    )
    port map
    (clk_i     => clk
    ,cke_i     => cke
    ,re0_i     => r2w1_re0
    ,raddr0_i  => r2w1_raddr0
    ,rdata0_o  => r2w1_rdata0
    ,re1_i     => r2w1_re1
    ,raddr1_i  => r2w1_raddr1
    ,rdata1_o  => r2w1_rdata1
    ,we_i      => r2w1_we
    ,waddr_i   => r2w1_waddr
    ,wdata_i   => r2w1_wdata
    );

  ins_ram_1rw : ram_1rw
    generic map
    (WIDTH     => WIDTH
    ,DEPTH     => DEPTH
    ,SYNC_READ => SYNC_READ
    )
    port map
    (clk_i     => clk
    ,cke_i     => cke
    ,cs_i      => rw1_cs
    ,we_i      => rw1_we
    ,addr_i    => rw1_addr
    ,wdata_i   => rw1_wdata
    ,rdata_o   => rw1_rdata
    );

  ins_sbi_ram : sbi_ram
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

  sbi_ini.cs     <= sbi_if.cs;
  sbi_ini.addr   <= std_logic_vector(sbi_if.addr);
  sbi_ini.re     <= sbi_if.rena;
  sbi_ini.we     <= sbi_if.wena;
  sbi_ini.wdata  <= sbi_if.wdata;
  sbi_if.ready   <= sbi_tgt.ready;
  sbi_if.rdata   <= sbi_tgt.rdata;

  ------------------------------------------------
  -- SBI monitor: wait states of each access and
  -- ready only during an access
  ------------------------------------------------
  p_sbi_monitor : process (clk) is
    variable v_cnt : natural := 0;
  begin
    if rising_edge(clk) then
      if arst_b = '1' then
        if sbi_ini.cs = '1' then
          if sbi_tgt.ready = '1' then
            sbi_wait <= v_cnt;
            v_cnt    := 0;
          else
            v_cnt    := v_cnt + 1;
          end if;
        else
          v_cnt := 0;
          if sbi_tgt.ready = '1' then
            alert(ERROR, "sbi_ram: ready = 1 without cs", C_SCOPE);
          end if;
        end if;
      end if;
    end if;
  end process p_sbi_monitor;

  ------------------------------------------------
  -- Sequencer
  ------------------------------------------------
  p_main : process

    subtype  t_word  is std_logic_vector(WIDTH-1 downto 0);
    type     t_mem   is array (0 to DEPTH-1) of t_word;
    type     t_valid is array (0 to DEPTH-1) of boolean;

    -- Reference model of the content (common to ram_1r1w, ram_2r1w and ram_1rw)
    variable v_mem        : t_mem;
    variable v_valid      : t_valid := (others => false);

    -- Expected registered read data (SYNC_READ)
    variable v_exp0       : t_word;          -- ram_1r1w and ram_2r1w port 0
    variable v_exp0_valid : boolean := false;
    variable v_exp1       : t_word;          -- ram_2r1w port 1
    variable v_exp1_valid : boolean := false;
    variable v_exp_rw     : t_word;          -- ram_1rw
    variable v_exp_rw_valid : boolean := false;

    variable v_nb_checks  : natural := 0;
    variable v_data       : t_word;

    function to_sl(b : boolean) return std_logic is
    begin
      if b then return '1'; else return '0'; end if;
    end function;

    function to_addr(a : natural) return std_logic_vector is
    begin
      return std_logic_vector(to_unsigned(a, C_AW));
    end function;

    -- Directed data pattern (inverted for odd seeds to toggle all the bits)
    function pattern(a : natural; seed : natural) return t_word is
      variable v : t_word;
    begin
      v := std_logic_vector(resize(to_unsigned((a*37 + seed*101 + 5) mod 2**8, 8), WIDTH));
      if seed mod 2 = 1 then
        v := not v;
      end if;
      return v;
    end function;

    procedure check_word(constant value : in t_word;
                         constant exp   : in t_word;
                         constant msg   : in string) is
    begin
      check_value(value, exp, ERROR, msg, C_SCOPE);
      v_nb_checks := v_nb_checks + 1;
    end procedure;

    ----------------------------------------------
    -- One clock cycle on ram_1r1w, ram_2r1w and ram_1rw
    -- * ram_1r1w : (re0, raddr0) and the write port
    -- * ram_2r1w : (re0, raddr0), (re1, raddr1) and the write port
    -- * ram_1rw  : cs = we or re0, addr = waddr when we else raddr0
    -- Inputs are driven on the falling edge, the read data are checked a
    -- quarter period later, the model is updated with the rising edge.
    ----------------------------------------------
    procedure cycle(constant re0    : in boolean;
                    constant raddr0 : in natural;
                    constant re1    : in boolean;
                    constant raddr1 : in natural;
                    constant we     : in boolean;
                    constant waddr  : in natural;
                    constant wdata  : in t_word;
                    constant msg    : in string;
                    constant ce     : in boolean := true) is
      variable v_rw_addr : natural;
    begin
      if we then v_rw_addr := waddr; else v_rw_addr := raddr0; end if;

      wait until falling_edge(clk);
      cke          <= to_sl(ce);
      -- ram_1r1w
      r1w1_re      <= to_sl(re0);
      r1w1_raddr   <= to_addr(raddr0);
      r1w1_we      <= to_sl(we);
      r1w1_waddr   <= to_addr(waddr);
      r1w1_wdata   <= wdata;
      -- ram_2r1w
      r2w1_re0     <= to_sl(re0);
      r2w1_raddr0  <= to_addr(raddr0);
      r2w1_re1     <= to_sl(re1);
      r2w1_raddr1  <= to_addr(raddr1);
      r2w1_we      <= to_sl(we);
      r2w1_waddr   <= to_addr(waddr);
      r2w1_wdata   <= wdata;
      -- ram_1rw
      rw1_cs       <= to_sl(we or re0);
      rw1_we       <= to_sl(we);
      rw1_addr     <= to_addr(v_rw_addr);
      rw1_wdata    <= wdata;
      wait for C_CLK_PERIOD/4;

      if not SYNC_READ then
        -- Asynchronous read: content before the write of the next edge
        if v_valid(raddr0) then
          check_word(r1w1_rdata , v_mem(raddr0), msg & ": ram_1r1w rdata @" & to_string(raddr0));
          check_word(r2w1_rdata0, v_mem(raddr0), msg & ": ram_2r1w rdata0 @" & to_string(raddr0));
        end if;
        if v_valid(raddr1) then
          check_word(r2w1_rdata1, v_mem(raddr1), msg & ": ram_2r1w rdata1 @" & to_string(raddr1));
        end if;
        if v_valid(v_rw_addr) then
          check_word(rw1_rdata  , v_mem(v_rw_addr), msg & ": ram_1rw rdata @" & to_string(v_rw_addr));
        end if;
      else
        -- Synchronous read: data registered by the last enabled read
        if v_exp0_valid then
          check_word(r1w1_rdata , v_exp0, msg & ": ram_1r1w registered rdata");
          check_word(r2w1_rdata0, v_exp0, msg & ": ram_2r1w registered rdata0");
        end if;
        if v_exp1_valid then
          check_word(r2w1_rdata1, v_exp1, msg & ": ram_2r1w registered rdata1");
        end if;
        if v_exp_rw_valid then
          check_word(rw1_rdata  , v_exp_rw, msg & ": ram_1rw registered rdata");
        end if;
      end if;

      -- Model update (read before write on the same edge)
      if ce then
        if re0 then
          v_exp0 := v_mem(raddr0); v_exp0_valid := v_valid(raddr0);
        end if;
        if re1 then
          v_exp1 := v_mem(raddr1); v_exp1_valid := v_valid(raddr1);
        end if;
        if re0 and not we then
          v_exp_rw := v_mem(raddr0); v_exp_rw_valid := v_valid(raddr0);
        end if;
        if we then
          v_mem  (waddr) := wdata;
          v_valid(waddr) := true;
        end if;
      end if;

      wait until rising_edge(clk);
    end procedure;

    -- Cycle without access (checks the registered read data are held)
    procedure idle(constant msg : in string) is
    begin
      cycle(false, 0, false, 0, false, 0, (WIDTH-1 downto 0 => '0'), msg & " idle");
    end procedure;

    procedure check_sbi_wait(constant msg : in string) is
    begin
      check_value(sbi_wait, C_SBI_WAIT, ERROR, msg & ": sbi_ram wait states", C_SCOPE);
      v_nb_checks := v_nb_checks + 1;
    end procedure;

  begin
    log(ID_LOG_HDR, "Start of simulation: WIDTH = " & to_string(WIDTH) & ", DEPTH = " & to_string(DEPTH) & ", SYNC_READ = " & to_string(SYNC_READ), C_SCOPE);
    sbi_if <= init_sbi_if_signals(C_SBI_AW, WIDTH);

    wait until arst_b = '1';
    wait until rising_edge(clk);

    -- Positive acknowledges are not logged (several checks per cycle)
    disable_log_msg(ID_POS_ACK);

    ----------------------------------------------
    log(ID_LOG_HDR, "Test 1: ram_1r1w / ram_2r1w / ram_1rw: write all the words", C_SCOPE);
    ----------------------------------------------
    for a in 0 to DEPTH-1 loop
      cycle(false, 0, false, 0, true, a, pattern(a, 0), "T1 write");
    end loop;
    idle("T1");

    ----------------------------------------------
    log(ID_LOG_HDR, "Test 2: read all the words (port 1 in reverse order)", C_SCOPE);
    ----------------------------------------------
    for a in 0 to DEPTH-1 loop
      cycle(true, a, true, DEPTH-1-a, false, 0, (WIDTH-1 downto 0 => '0'), "T2 read");
    end loop;
    idle("T2");
    idle("T2");

    ----------------------------------------------
    log(ID_LOG_HDR, "Test 3: read and write of the same address in the same cycle", C_SCOPE);
    ----------------------------------------------
    -- Read data = old content (registered read: read before write), then new content
    for a in 0 to DEPTH-1 loop
      cycle(true, a, true, a, true , a, pattern(a, 1), "T3 read during write");
      cycle(true, a, true, a, false, 0, (WIDTH-1 downto 0 => '0'), "T3 read after write");
    end loop;
    idle("T3");

    ----------------------------------------------
    log(ID_LOG_HDR, "Test 4: cke_i = 0 blocks the write and the registered read", C_SCOPE);
    ----------------------------------------------
    cycle(true, 2, true, 3, false, 0, (WIDTH-1 downto 0 => '0'), "T4 read");
    cycle(true, 0, true, 1, true , 0, pattern(0, 2), "T4 read and write with cke_i = 0", ce => false);
    cycle(true, 4, true, 5, true , 1, pattern(1, 2), "T4 read and write with cke_i = 0", ce => false);
    cycle(true, 0, true, 1, false, 0, (WIDTH-1 downto 0 => '0'), "T4 read after cke_i = 0");
    idle("T4");

    ----------------------------------------------
    log(ID_LOG_HDR, "Test 5: re = 0 holds the registered read data", C_SCOPE);
    ----------------------------------------------
    cycle(true , 5, true , 6, false, 0, (WIDTH-1 downto 0 => '0'), "T5 read");
    cycle(false, 7, false, 8 mod DEPTH, false, 0, (WIDTH-1 downto 0 => '0'), "T5 address change with re = 0");
    cycle(false, 9 mod DEPTH, false, 10 mod DEPTH, false, 0, (WIDTH-1 downto 0 => '0'), "T5 address change with re = 0");
    -- ram_1rw: a write does not update the registered read data
    cycle(false, 0, false, 0, true, 5, pattern(5, 3), "T5 write");
    idle("T5");

    ----------------------------------------------
    log(ID_LOG_HDR, "Test 6: random accesses", C_SCOPE);
    ----------------------------------------------
    for i in 1 to 1000 loop
      v_data := random(WIDTH);
      cycle(random(1, 100) <= 60, random(0, DEPTH-1),
            random(1, 100) <= 60, random(0, DEPTH-1),
            random(1, 100) <= 50, random(0, DEPTH-1), v_data,
            "T6 cycle " & to_string(i),
            ce => random(1, 100) <= 90);
    end loop;
    idle("T6");

    ----------------------------------------------
    log(ID_LOG_HDR, "Test 7: sbi_ram write / read of all the words", C_SCOPE);
    ----------------------------------------------
    for a in 0 to DEPTH-1 loop
      sbi_write(to_unsigned(a, C_SBI_AW), pattern(a, 4), "T7 write", clk, sbi_if, C_SCOPE);
      check_sbi_wait("T7 write");
    end loop;
    for a in 0 to DEPTH-1 loop
      sbi_check(to_unsigned(a, C_SBI_AW), pattern(a, 4), "T7 check", clk, sbi_if, ERROR, C_SCOPE);
      check_sbi_wait("T7 check");
      v_nb_checks := v_nb_checks + 1;
    end loop;
    -- Back-to-back write and read of the same address
    for a in DEPTH-1 downto 0 loop
      sbi_write(to_unsigned(a, C_SBI_AW), pattern(a, 5), "T7 write", clk, sbi_if, C_SCOPE);
      sbi_check(to_unsigned(a, C_SBI_AW), pattern(a, 5), "T7 check", clk, sbi_if, ERROR, C_SCOPE);
      check_sbi_wait("T7 check");
      v_nb_checks := v_nb_checks + 1;
    end loop;

    ----------------------------------------------
    log(ID_LOG_HDR, "Test 8: sbi_ram address aliasing (only log2(DEPTH) address bits are decoded)", C_SCOPE);
    ----------------------------------------------
    sbi_write(to_unsigned(DEPTH + 3, C_SBI_AW), pattern(3, 6), "T8 write above DEPTH", clk, sbi_if, C_SCOPE);
    for k in 0 to 3 loop
      sbi_check(to_unsigned(k*DEPTH + 3, C_SBI_AW), pattern(3, 6), "T8 check alias " & to_string(k), clk, sbi_if, ERROR, C_SCOPE);
      v_nb_checks := v_nb_checks + 1;
    end loop;

    ----------------------------------------------
    log(ID_LOG_HDR, "Test 9: sbi_ram target name", C_SCOPE);
    ----------------------------------------------
    check_value(sbi_tgt.info.name, to_sbi_name("RAM" & integer'image(DEPTH) & "B"), ERROR, "T9 default info.name", C_SCOPE);
    v_nb_checks := v_nb_checks + 1;

    enable_log_msg(ID_POS_ACK);
    log(ID_SEQUENCER, to_string(v_nb_checks) & " checks done", C_SCOPE);

    ----------------------------------------------
    -- End of simulation
    ----------------------------------------------
    wait for 10*C_CLK_PERIOD;
    report_alert_counters(FINAL);
    log(ID_LOG_HDR, "SIMULATION COMPLETED", C_SCOPE);
    clk_ena <= false;
    std.env.stop;
    wait;
  end process p_main;

end tb;
