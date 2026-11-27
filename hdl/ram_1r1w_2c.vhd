-------------------------------------------------------------------------------
-- Title      : ram_1r1w_2c
-- Project    : Asylum
-------------------------------------------------------------------------------
-- File       : ram_1r1w_2c.vhd
-- Author     : mrosiere
-- Company    :
-- Created    : 2026-11-27
-- Last update: 2026-11-27
-- Platform   :
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Description: Simple dual-port RAM with two clocks : one write port on
--              clk0_i, one registered read port on clk1_i (unrelated clocks
--              allowed), the template of a simple dual-port block RAM that
--              the tools infer (one process per clock, the array written by
--              one process only).
--              * write : on the rising edge of clk0_i when cke0_i = 1 and
--                we0_i = 1, wdata0_i is written at waddr0_i
--              * read  : on the rising edge of clk1_i when cke1_i = 1 and
--                re1_i = 1, the word at raddr1_i is loaded into rdata1_o (one
--                cycle of latency), rdata1_o held otherwise
--              Read of the address written at the same time (collision) :
--              the old word in simulation ; on a block RAM or a LUTRAM the
--              read data are undefined (and may be metastable : the write
--              -> read register path crosses the clock domains), the word
--              written is kept. A user that reads such a word discards it.
--              DEPTH is a power of 2.
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

library asylum;
use     asylum.math_pkg.all;

entity ram_1r1w_2c is
  generic (
    WIDTH        : natural := 32                                   -- Word width
   ;DEPTH        : natural := 32                                   -- Number of words (power of 2)
  );
  port (
    -- Write port
    clk0_i       : in  std_logic
   ;cke0_i       : in  std_logic
   ;we0_i        : in  std_logic
   ;waddr0_i     : in  std_logic_vector(log2(DEPTH) -1 downto 0)
   ;wdata0_i     : in  std_logic_vector(WIDTH       -1 downto 0)
    -- Read port
   ;clk1_i       : in  std_logic
   ;cke1_i       : in  std_logic
   ;re1_i        : in  std_logic
   ;raddr1_i     : in  std_logic_vector(log2(DEPTH) -1 downto 0)
   ;rdata1_o     : out std_logic_vector(WIDTH       -1 downto 0)
  );
end entity ram_1r1w_2c;

architecture rtl of ram_1r1w_2c is

  type ram_t is array (DEPTH-1 downto 0) of std_logic_vector(WIDTH-1 downto 0);

  signal   ram_r       : ram_t;
  signal   rdata1_r    : std_logic_vector(WIDTH-1 downto 0);

begin  -- architecture rtl

  -----------------------------------------------------------------------------
  -- Write port (clk0_i)
  -----------------------------------------------------------------------------
  process (clk0_i)
  begin
    if rising_edge(clk0_i)
    then
      if cke0_i = '1' and we0_i = '1'
      then
        ram_r(to_integer(unsigned(waddr0_i))) <= wdata0_i;
      end if;
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- Read port (clk1_i), registered
  -----------------------------------------------------------------------------
  process (clk1_i)
  begin
    if rising_edge(clk1_i)
    then
      if cke1_i = '1' and re1_i = '1'
      then
        rdata1_r <= ram_r(to_integer(unsigned(raddr1_i)));
      end if;
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- Outputs
  -----------------------------------------------------------------------------
  rdata1_o <= rdata1_r;

-- synthesis translate_off
  -- The address width is log2(DEPTH) (floor): with a DEPTH that is not a power
  -- of 2, the words 2**log2(DEPTH) to DEPTH-1 can not be addressed
  assert 2**log2(DEPTH) = DEPTH
    report "ram_1r1w_2c : DEPTH (" & integer'image(DEPTH) & ") is not a power of 2, only " & integer'image(2**log2(DEPTH)) & " words are addressable"
    severity error;
-- synthesis translate_on

end architecture rtl;
