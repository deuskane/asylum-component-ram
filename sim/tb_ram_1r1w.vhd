-------------------------------------------------------------------------------
-- Title      : tb_ram_1r1w
-- Project    : ram_1r1w
-------------------------------------------------------------------------------
-- File       : tb_ram_1r1w.vhd
-- Author     : mrosiere
-- Company    : 
-- Created    : 2016-11-11
-- Last update: 2021-08-29
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2016 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2016-11-11  1.0      mrosiere	Created
-------------------------------------------------------------------------------

library std;
use std.textio.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--use ieee.numeric_bit.all;
--use ieee.std_logic_arith.all;

library work;
use work.math_pkg.all;
use work.ram_1r1w_pkg.all;

entity tb_ram_1r1w is

end tb_ram_1r1w;

architecture tb of tb_ram_1r1w is

  -- =====[ Constants ]===========================
  constant WIDTH : natural := 8;
  constant DEPTH : natural := 8;

  -- =====[ Signals ]=============================
  signal clk_i        : std_logic := '0';
  signal cke_i        : std_logic;
--signal arstn_i      : std_logic;
  signal re_i         : std_logic;
  signal raddr_i      : std_logic_vector(log2(DEPTH) -1 downto 0);
  signal rdata_o      : std_logic_vector(WIDTH       -1 downto 0);
  signal we_i         : std_logic;
  signal waddr_i      : std_logic_vector(log2(DEPTH) -1 downto 0);
  signal wdata_i      : std_logic_vector(WIDTH       -1 downto 0);

  -------------------------------------------------------
  -- run
  -------------------------------------------------------
  procedure xrun
    (constant n     : in positive;           -- nb cycle
     signal   clk_i : in std_logic
     ) is
    
  begin
    for i in 0 to n-1
    loop
      wait until rising_edge(clk_i);        
    end loop;  -- i
  end xrun;

  procedure run
    (constant n     : in positive           -- nb cycle
     ) is
    
  begin
    xrun(n,clk_i);
  end run;

  -----------------------------------------------------
  -- Test signals
  -----------------------------------------------------
  signal test_done : std_logic := '0';
  signal test_ok   : std_logic := '0';
  
begin

  ------------------------------------------------
  -- Instance of DUT
  ------------------------------------------------
  
  dut : ram_1r1w
    generic map
    (WIDTH => WIDTH
    ,DEPTH => DEPTH
     )
    port map
    (clk_i   => clk_i  
    ,cke_i   => cke_i  
--  ,rstn_i  => rstn_i 
    ,re_i    => re_i   
    ,raddr_i => raddr_i
    ,rdata_o => rdata_o
    ,we_i    => we_i   
    ,waddr_i => waddr_i
    ,wdata_i => wdata_i
     );

  ------------------------------------------------
  -- Clock process
  ------------------------------------------------
  clk_i <= not test_done and not clk_i after 5 ns;

  ------------------------------------------------
  -- Test process
  ------------------------------------------------
  -- purpose: Testbench process
  -- type   : combinational
  -- inputs : 
  -- outputs: All dut design with clk_i
  tb_gen: process is
  begin  -- process tb_gen
    report "[TESTBENCH] Test Begin";

    run(1);

    -- Reset
    report "[TESTBENCH] Reset";
--  rstn_i <= '0';
    we_i   <= '0';
    re_i   <= '0';
    run(1);
--  rstn_i <= '1';
    run(1);

    cke_i  <= '1';
    
    report "[TESTBENCH] Write Only Sequence";
    we_i   <= '1';
    for x in 0 to DEPTH-1
    loop
      waddr_i <= std_logic_vector(to_unsigned(x,waddr_i'length));
      wdata_i <= std_logic_vector(to_unsigned(x,wdata_i'length));

      run(1);
    end loop;  -- x
    we_i   <= '0';
    
    report "[TESTBENCH] Read Only Sequence";
    re_i   <= '1';
    for x in 0 to DEPTH-1
    loop
      raddr_i <= std_logic_vector(to_unsigned(x,raddr_i'length));

      run(1);

      assert rdata_o = std_logic_vector(to_unsigned(x,rdata_o'length)) report "Unexpected value" severity failure;
    end loop;  -- x
    re_i   <= '0';
    
    report "[TESTBENCH] Write/Read Sequence";
    we_i   <= '1';
    for x in 0 to 2*DEPTH-1
    loop
      waddr_i <= std_logic_vector(to_unsigned(x,waddr_i'length));
      wdata_i <= not std_logic_vector(to_unsigned(x,wdata_i'length));
      if x>0 then
        re_i   <= '1';
        raddr_i <= std_logic_vector(to_unsigned(x-1,raddr_i'length));
      end if;

      run(1);

      if x>0 then
      assert rdata_o = not std_logic_vector(to_unsigned(x-1,rdata_o'length)) report "Unexpected value" severity failure;
      end if;
    end loop;  -- x
    we_i   <= '0';
    re_i   <= '0';
    
    report "[TESTBENCH] Test End";

    test_ok   <= '1';

    run(1);
    test_done <= '1';
    run(1);
  end process tb_gen;

  gen_test_done: process (test_done) is
  begin  -- process gen_test_done
    if test_done'event and test_done = '1' then  -- rising clock edge
      if test_ok = '1' then
        report "[TESTBENCH] Test OK";
      else
        report "[TESTBENCH] Test KO" severity failure;
      end if;
      
    end if;
  end process gen_test_done;

  
end tb;
