-------------------------------------------------------------------------------
-- Title      : tb_ram_2rw_2c_bfm_pkg
-- Project    : ram
-------------------------------------------------------------------------------
-- File       : tb_ram_2rw_2c_bfm_pkg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Helpers of the tb_ram_2rw_2c scenarios : inputs of one port
--              (t_port_req), drive of an access, check of the read data,
--              accesses of one port on its own clock (port_write,
--              port_read, port_fill, port_check_all)
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

package tb_ram_2rw_2c_bfm_pkg is

  constant C_TB_SCOPE   : string := "TB_RAM_2RW_2C";

  -- Inputs of one port of ram_2rw_2c
  type t_port_req is record
    cke      : std_logic;
    cs       : std_logic;
    we       : std_logic;
    addr     : std_logic_vector;
    wdata    : std_logic_vector;
  end record t_port_req;

  -- Directed data pattern of a word : the bytes differ from one address
  -- and from one seed to the other (inverted for odd seeds)
  function pattern
    (constant a        : in    natural
    ;constant seed     : in    natural
    ;constant width    : in    natural
    ) return std_logic_vector;

  -- '1' for true
  function to_sl
    (constant b        : in    boolean
    ) return std_logic;

  -- Port idle : cke = 1, no access
  procedure port_idle
    (signal   req      : out   t_port_req
    );

  -- Drive one access without waiting (the edge of the port clock performs
  -- it)
  procedure port_drive
    (constant cke      : in    std_logic
    ;constant cs       : in    std_logic
    ;constant we       : in    std_logic
    ;constant addr     : in    natural
    ;constant wdata    : in    std_logic_vector
    ;signal   req      : out   t_port_req
    );

  -- One access on the falling edge of clk, performed by the next rising
  -- edge, then idle from the next falling edge, where rdata is returned
  procedure port_cycle
    (constant cke      : in    std_logic
    ;constant cs       : in    std_logic
    ;constant we       : in    std_logic
    ;constant addr     : in    natural
    ;constant wdata    : in    std_logic_vector
    ;signal   clk      : in    std_logic
    ;signal   req      : out   t_port_req
    );

  -- Write of one word
  procedure port_write
    (constant addr     : in    natural
    ;constant data     : in    std_logic_vector
    ;signal   clk      : in    std_logic
    ;signal   req      : out   t_port_req
    );

  -- Read of one word, check of rdata
  procedure port_read
    (constant addr     : in    natural
    ;constant data_exp : in    std_logic_vector
    ;constant msg      : in    string
    ;signal   clk      : in    std_logic
    ;signal   req      : out   t_port_req
    ;signal   rdata    : in    std_logic_vector
    );

  -- Every address written with pattern(a, seed)
  procedure port_fill
    (constant seed     : in    natural
    ;signal   clk      : in    std_logic
    ;signal   req      : out   t_port_req
    );

  -- Every address read and checked against pattern(a, seed)
  procedure port_check_all
    (constant seed     : in    natural
    ;constant msg      : in    string
    ;signal   clk      : in    std_logic
    ;signal   req      : out   t_port_req
    ;signal   rdata    : in    std_logic_vector
    );

end package tb_ram_2rw_2c_bfm_pkg;

package body tb_ram_2rw_2c_bfm_pkg is

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
    variable b : unsigned(8-1 downto 0);
  begin
    -- Byte k of the word : (a*37 + seed*101 + 5 + k*29) mod 256
    for i in 0 to width-1
    loop
      b    := to_unsigned((a*37 + seed*101 + 5 + (i/8)*29) mod 2**8, 8);
      v(i) := b(i mod 8);
    end loop;
    if seed mod 2 = 1
    then
      v := not v;
    end if;
    return v;
  end function;

  procedure port_idle
    (signal   req      : out   t_port_req
    ) is
  begin
    req.cke   <= '1';
    req.cs    <= '0';
    req.we    <= '0';
    req.addr  <= (req.addr'range  => '0');
    req.wdata <= (req.wdata'range => '0');
  end procedure;

  procedure port_drive
    (constant cke      : in    std_logic
    ;constant cs       : in    std_logic
    ;constant we       : in    std_logic
    ;constant addr     : in    natural
    ;constant wdata    : in    std_logic_vector
    ;signal   req      : out   t_port_req
    ) is
  begin
    req.cke   <= cke;
    req.cs    <= cs;
    req.we    <= we;
    req.addr  <= std_logic_vector(to_unsigned(addr, req.addr'length));
    req.wdata <= wdata;
  end procedure;

  procedure port_cycle
    (constant cke      : in    std_logic
    ;constant cs       : in    std_logic
    ;constant we       : in    std_logic
    ;constant addr     : in    natural
    ;constant wdata    : in    std_logic_vector
    ;signal   clk      : in    std_logic
    ;signal   req      : out   t_port_req
    ) is
  begin
    wait until falling_edge(clk);
    port_drive(cke, cs, we, addr, wdata, req);
    wait until falling_edge(clk);
    port_idle(req);
  end procedure;

  procedure port_write
    (constant addr     : in    natural
    ;constant data     : in    std_logic_vector
    ;signal   clk      : in    std_logic
    ;signal   req      : out   t_port_req
    ) is
  begin
    port_cycle('1', '1', '1', addr, data, clk, req);
  end procedure;

  procedure port_read
    (constant addr     : in    natural
    ;constant data_exp : in    std_logic_vector
    ;constant msg      : in    string
    ;signal   clk      : in    std_logic
    ;signal   req      : out   t_port_req
    ;signal   rdata    : in    std_logic_vector
    ) is
  begin
    port_cycle('1', '1', '0', addr, (data_exp'range => '0'), clk, req);
    check_value(rdata, data_exp, error, msg & " @" & to_string(addr), C_TB_SCOPE);
  end procedure;

  procedure port_fill
    (constant seed     : in    natural
    ;signal   clk      : in    std_logic
    ;signal   req      : out   t_port_req
    ) is
  begin
    for a in 0 to 2**req.addr'length-1
    loop
      port_write(a, pattern(a, seed, req.wdata'length), clk, req);
    end loop;
  end procedure;

  procedure port_check_all
    (constant seed     : in    natural
    ;constant msg      : in    string
    ;signal   clk      : in    std_logic
    ;signal   req      : out   t_port_req
    ;signal   rdata    : in    std_logic_vector
    ) is
  begin
    for a in 0 to 2**req.addr'length-1
    loop
      port_read(a, pattern(a, seed, rdata'length), msg, clk, req, rdata);
    end loop;
  end procedure;

end package body tb_ram_2rw_2c_bfm_pkg;
