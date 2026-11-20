-------------------------------------------------------------------------------
-- Title      : tb_ram_bfm_pkg
-- Project    : ram
-------------------------------------------------------------------------------
-- File       : tb_ram_bfm_pkg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Helpers of the tb_ram scenarios.
--              ram_1r1w, ram_2r1w and ram_1rw receive the same accesses
--              (record t_ram_req) and share one reference model (t_model) :
--              ram_cycle drives one access on the falling edge of the
--              clock, checks the read data of every port a quarter period
--              later, then updates the model with the rising edge.
--              sbi_ram : SBI accesses (SBI VIP) and checks.
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-20  1.0      mrosiere Created (cycle and model of tb_ram 1.0)
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library bitvis_vip_sbi;
use     bitvis_vip_sbi.sbi_bfm_pkg.all;

package tb_ram_bfm_pkg is

  constant C_TB_SCOPE   : string := "TB_RAM_BFM";
  constant C_CLK_PERIOD : time   := 10 ns;

  -- SBI BFM : sbi_ram answers with 0 or 1 wait state
  constant C_SBI_CFG    : t_sbi_bfm_config := (
    max_wait_cycles            => 10,
    max_wait_cycles_severity   => failure,
    use_fixed_wait_cycles_read => false,
    fixed_wait_cycles_read     => 0,
    clock_period               => C_CLK_PERIOD,
    clock_period_margin        => 0 ns,
    clock_margin_severity      => TB_ERROR,
    setup_time                 => -1 ns,
    hold_time                  => -1 ns,
    bfm_sync                   => SYNC_ON_CLOCK_ONLY,
    match_strictness           => MATCH_EXACT,
    id_for_bfm                 => ID_BFM,
    id_for_bfm_wait            => ID_BFM_WAIT,
    id_for_bfm_poll            => ID_BFM_POLL,
    use_ready_signal           => true
  );

  -- Inputs of ram_1r1w, ram_2r1w and ram_1rw (one access per clock cycle)
  type t_ram_req is record
    cke      : std_logic;          -- cke_i of the three RAMs
    re0      : std_logic;          -- ram_1r1w re_i, ram_2r1w re0_i
    raddr0   : std_logic_vector;   -- ram_1r1w raddr_i, ram_2r1w raddr0_i
    re1      : std_logic;          -- ram_2r1w re1_i
    raddr1   : std_logic_vector;   -- ram_2r1w raddr1_i
    we       : std_logic;          -- ram_1r1w, ram_2r1w we_i
    waddr    : std_logic_vector;   -- ram_1r1w, ram_2r1w waddr_i
    wdata    : std_logic_vector;   -- wdata_i of the three RAMs
    cs       : std_logic;          -- ram_1rw cs_i
    rw_we    : std_logic;          -- ram_1rw we_i
    addr     : std_logic_vector;   -- ram_1rw addr_i
  end record t_ram_req;

  -- Read data of ram_1r1w, ram_2r1w and ram_1rw
  type t_ram_rsp is record
    rdata    : std_logic_vector;   -- ram_1r1w rdata_o
    rdata0   : std_logic_vector;   -- ram_2r1w rdata0_o
    rdata1   : std_logic_vector;   -- ram_2r1w rdata1_o
    rw_rdata : std_logic_vector;   -- ram_1rw rdata_o
  end record t_ram_rsp;

  type t_words is array (natural range <>) of std_logic_vector;

  -- Reference model, common to ram_1r1w, ram_2r1w and ram_1rw. Reset before
  -- each scenario : a word or a registered read data is checked only once
  -- written by the scenario (the RAMs are not reset)
  type t_model is record
    sync_read    : boolean;          -- SYNC_READ of the RAMs
    mem          : t_words;          -- Content
    valid        : boolean_vector;   -- Word written since the model reset
    exp0         : std_logic_vector; -- Registered read data : ram_1r1w, ram_2r1w port 0
    exp0_valid   : boolean;
    exp1         : std_logic_vector; -- Registered read data : ram_2r1w port 1
    exp1_valid   : boolean;
    exp_rw       : std_logic_vector; -- Registered read data : ram_1rw
    exp_rw_valid : boolean;
  end record t_model;

  -- Directed data pattern of a word (inverted for odd seeds to toggle all
  -- the bits)
  function pattern
    (constant a        : in    natural
    ;constant seed     : in    natural
    ;constant width    : in    natural
    ) return std_logic_vector;

  -- Empty model (nothing written, no registered read data)
  procedure model_reset
    (variable model    : inout t_model
    ;constant sync_read: in    boolean
    );

  -- Inputs of the three RAMs idle (no access, cke_i = 1)
  procedure ram_req_idle
    (signal   req      : out   t_ram_req
    );

  -- One clock cycle on ram_1r1w, ram_2r1w and ram_1rw
  -- * ram_1r1w : (re0, raddr0) and the write port
  -- * ram_2r1w : (re0, raddr0), (re1, raddr1) and the write port
  -- * ram_1rw  : cs = we or re0, addr = waddr when we else raddr0
  -- cke = false : cke_i = 0 ; sel = false : the write is not selected
  -- (we_i = 0 on ram_1r1w and ram_2r1w, cs_i = 0 on ram_1rw)
  procedure ram_cycle
    (constant re0      : in    boolean
    ;constant raddr0   : in    natural
    ;constant re1      : in    boolean
    ;constant raddr1   : in    natural
    ;constant we       : in    boolean
    ;constant waddr    : in    natural
    ;constant wdata    : in    std_logic_vector
    ;constant msg      : in    string
    ;signal   clk      : in    std_logic
    ;signal   req      : out   t_ram_req
    ;signal   rsp      : in    t_ram_rsp
    ;variable model    : inout t_model
    ;constant cke      : in    boolean := true
    ;constant sel      : in    boolean := true
    );

  -- Write of one word (no read)
  procedure ram_write
    (constant a        : in    natural
    ;constant data     : in    std_logic_vector
    ;constant msg      : in    string
    ;signal   clk      : in    std_logic
    ;signal   req      : out   t_ram_req
    ;signal   rsp      : in    t_ram_rsp
    ;variable model    : inout t_model
    );

  -- Read of a0 (ram_1r1w, ram_2r1w port 0, ram_1rw) and a1 (ram_2r1w port 1)
  procedure ram_read
    (constant a0       : in    natural
    ;constant a1       : in    natural
    ;constant msg      : in    string
    ;signal   clk      : in    std_logic
    ;signal   req      : out   t_ram_req
    ;signal   rsp      : in    t_ram_rsp
    ;variable model    : inout t_model
    );

  -- Cycle without access (the registered read data are held)
  procedure ram_idle
    (constant msg      : in    string
    ;signal   clk      : in    std_logic
    ;signal   req      : out   t_ram_req
    ;signal   rsp      : in    t_ram_rsp
    ;variable model    : inout t_model
    );

  -- Write of every word, pattern(a, seed), then one idle cycle
  procedure ram_fill
    (constant seed     : in    natural
    ;signal   clk      : in    std_logic
    ;signal   req      : out   t_ram_req
    ;signal   rsp      : in    t_ram_rsp
    ;variable model    : inout t_model
    );

  -- sbi_ram : SBI write
  procedure wr
    (constant addr     : in    natural
    ;constant data     : in    std_logic_vector
    ;constant msg      : in    string
    ;signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    );

  -- sbi_ram : SBI read and check
  procedure chk
    (constant addr     : in    natural
    ;constant data     : in    std_logic_vector
    ;constant msg      : in    string
    ;signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    );

  -- sbi_ram : wait states of the last access (0, or 1 with SYNC_READ)
  procedure chk_wait
    (signal   sbi_wait : in    natural
    ;constant sync_read: in    boolean
    ;constant msg      : in    string
    );

  -- Reset pulse, released on a falling edge
  procedure do_reset
    (signal   clk      : in    std_logic
    ;signal   arst_b   : out   std_logic
    );

end package tb_ram_bfm_pkg;

package body tb_ram_bfm_pkg is

  function to_sl
    (constant b        : in    boolean
    ) return std_logic is
  begin
    if b
    then
      return '1';
    else
      return '0';
    end if;
  end function;

  function pattern
    (constant a        : in    natural
    ;constant seed     : in    natural
    ;constant width    : in    natural
    ) return std_logic_vector is
    variable v : std_logic_vector(width-1 downto 0);
  begin
    v := std_logic_vector(resize(to_unsigned((a*37 + seed*101 + 5) mod 2**8, 8), width));
    if seed mod 2 = 1
    then
      v := not v;
    end if;
    return v;
  end function;

  procedure model_reset
    (variable model    : inout t_model
    ;constant sync_read: in    boolean
    ) is
  begin
    model.sync_read    := sync_read;
    model.valid        := (model.valid'range => false);
    model.exp0_valid   := false;
    model.exp1_valid   := false;
    model.exp_rw_valid := false;
  end procedure;

  procedure ram_req_idle
    (signal   req      : out   t_ram_req
    ) is
  begin
    req.cke    <= '1';
    req.re0    <= '0';
    req.raddr0 <= (req.raddr0'range => '0');
    req.re1    <= '0';
    req.raddr1 <= (req.raddr1'range => '0');
    req.we     <= '0';
    req.waddr  <= (req.waddr'range  => '0');
    req.wdata  <= (req.wdata'range  => '0');
    req.cs     <= '0';
    req.rw_we  <= '0';
    req.addr   <= (req.addr'range   => '0');
  end procedure;

  procedure ram_cycle
    (constant re0      : in    boolean
    ;constant raddr0   : in    natural
    ;constant re1      : in    boolean
    ;constant raddr1   : in    natural
    ;constant we       : in    boolean
    ;constant waddr    : in    natural
    ;constant wdata    : in    std_logic_vector
    ;constant msg      : in    string
    ;signal   clk      : in    std_logic
    ;signal   req      : out   t_ram_req
    ;signal   rsp      : in    t_ram_rsp
    ;variable model    : inout t_model
    ;constant cke      : in    boolean := true
    ;constant sel      : in    boolean := true
    ) is
    constant AW        : natural := req.raddr0'length;
    variable v_rw_addr : natural;   -- ram_1rw address
  begin
    if we
    then
      v_rw_addr := waddr;
    else
      v_rw_addr := raddr0;
    end if;

    wait until falling_edge(clk);
    req.cke    <= to_sl(cke);
    req.re0    <= to_sl(re0);
    req.raddr0 <= std_logic_vector(to_unsigned(raddr0   , AW));
    req.re1    <= to_sl(re1);
    req.raddr1 <= std_logic_vector(to_unsigned(raddr1   , AW));
    req.we     <= to_sl(we and sel);
    req.waddr  <= std_logic_vector(to_unsigned(waddr    , AW));
    req.wdata  <= wdata;
    req.cs     <= to_sl((we or re0) and sel);
    req.rw_we  <= to_sl(we);
    req.addr   <= std_logic_vector(to_unsigned(v_rw_addr, AW));
    wait for C_CLK_PERIOD/4;

    if not model.sync_read
    then
      -- Asynchronous read : content before the write of the next edge
      if model.valid(raddr0)
      then
        check_value(rsp.rdata   , model.mem(raddr0)   , error, msg & ": ram_1r1w rdata @"  & to_string(raddr0)   , C_TB_SCOPE);
        check_value(rsp.rdata0  , model.mem(raddr0)   , error, msg & ": ram_2r1w rdata0 @" & to_string(raddr0)   , C_TB_SCOPE);
      end if;
      if model.valid(raddr1)
      then
        check_value(rsp.rdata1  , model.mem(raddr1)   , error, msg & ": ram_2r1w rdata1 @" & to_string(raddr1)   , C_TB_SCOPE);
      end if;
      if model.valid(v_rw_addr)
      then
        check_value(rsp.rw_rdata, model.mem(v_rw_addr), error, msg & ": ram_1rw rdata @"   & to_string(v_rw_addr), C_TB_SCOPE);
      end if;
    else
      -- Synchronous read : data registered by the last enabled read
      if model.exp0_valid
      then
        check_value(rsp.rdata   , model.exp0  , error, msg & ": ram_1r1w registered rdata" , C_TB_SCOPE);
        check_value(rsp.rdata0  , model.exp0  , error, msg & ": ram_2r1w registered rdata0", C_TB_SCOPE);
      end if;
      if model.exp1_valid
      then
        check_value(rsp.rdata1  , model.exp1  , error, msg & ": ram_2r1w registered rdata1", C_TB_SCOPE);
      end if;
      if model.exp_rw_valid
      then
        check_value(rsp.rw_rdata, model.exp_rw, error, msg & ": ram_1rw registered rdata"  , C_TB_SCOPE);
      end if;
    end if;

    -- Model update (read before write on the same edge)
    if cke
    then
      if re0
      then
        model.exp0         := model.mem  (raddr0);
        model.exp0_valid   := model.valid(raddr0);
      end if;
      if re1
      then
        model.exp1         := model.mem  (raddr1);
        model.exp1_valid   := model.valid(raddr1);
      end if;
      if re0 and not we and sel
      then
        model.exp_rw       := model.mem  (raddr0);
        model.exp_rw_valid := model.valid(raddr0);
      end if;
      if we and sel
      then
        model.mem  (waddr) := wdata;
        model.valid(waddr) := true;
      end if;
    end if;

    wait until rising_edge(clk);
  end procedure;

  procedure ram_write
    (constant a        : in    natural
    ;constant data     : in    std_logic_vector
    ;constant msg      : in    string
    ;signal   clk      : in    std_logic
    ;signal   req      : out   t_ram_req
    ;signal   rsp      : in    t_ram_rsp
    ;variable model    : inout t_model
    ) is
  begin
    ram_cycle(false, 0, false, 0, true, a, data, msg, clk, req, rsp, model);
  end procedure;

  procedure ram_read
    (constant a0       : in    natural
    ;constant a1       : in    natural
    ;constant msg      : in    string
    ;signal   clk      : in    std_logic
    ;signal   req      : out   t_ram_req
    ;signal   rsp      : in    t_ram_rsp
    ;variable model    : inout t_model
    ) is
  begin
    ram_cycle(true, a0, true, a1, false, 0, (rsp.rdata'range => '0'), msg, clk, req, rsp, model);
  end procedure;

  procedure ram_idle
    (constant msg      : in    string
    ;signal   clk      : in    std_logic
    ;signal   req      : out   t_ram_req
    ;signal   rsp      : in    t_ram_rsp
    ;variable model    : inout t_model
    ) is
  begin
    ram_cycle(false, 0, false, 0, false, 0, (rsp.rdata'range => '0'), msg & " idle", clk, req, rsp, model);
  end procedure;

  procedure ram_fill
    (constant seed     : in    natural
    ;signal   clk      : in    std_logic
    ;signal   req      : out   t_ram_req
    ;signal   rsp      : in    t_ram_rsp
    ;variable model    : inout t_model
    ) is
  begin
    for a in model.mem'range
    loop
      ram_write(a, pattern(a, seed, rsp.rdata'length), "Fill", clk, req, rsp, model);
    end loop;
    ram_idle("Fill", clk, req, rsp, model);
  end procedure;

  procedure wr
    (constant addr     : in    natural
    ;constant data     : in    std_logic_vector
    ;constant msg      : in    string
    ;signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ) is
  begin
    sbi_write(addr_value => to_unsigned(addr, sbi_if.addr'length)
             ,data_value => data
             ,msg        => msg
             ,clk        => clk
             ,sbi_if     => sbi_if
             ,scope      => C_TB_SCOPE
             ,config     => C_SBI_CFG
             );
  end procedure;

  procedure chk
    (constant addr     : in    natural
    ;constant data     : in    std_logic_vector
    ;constant msg      : in    string
    ;signal   clk      : in    std_logic
    ;signal   sbi_if   : inout t_sbi_if
    ) is
  begin
    sbi_check(addr_value  => to_unsigned(addr, sbi_if.addr'length)
             ,data_exp    => data
             ,msg         => msg
             ,clk         => clk
             ,sbi_if      => sbi_if
             ,alert_level => error
             ,scope       => C_TB_SCOPE
             ,config      => C_SBI_CFG
             );
  end procedure;

  procedure chk_wait
    (signal   sbi_wait : in    natural
    ;constant sync_read: in    boolean
    ;constant msg      : in    string
    ) is
  begin
    check_value(sbi_wait, boolean'pos(sync_read), error, msg & ": sbi_ram wait states", C_TB_SCOPE);
  end procedure;

  procedure do_reset
    (signal   clk      : in    std_logic
    ;signal   arst_b   : out   std_logic
    ) is
  begin
    arst_b <= '0';
    wait for 5*C_CLK_PERIOD;
    wait until falling_edge(clk);
    arst_b <= '1';
    wait until rising_edge(clk);
  end procedure;

end package body tb_ram_bfm_pkg;
