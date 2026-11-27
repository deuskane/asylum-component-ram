-------------------------------------------------------------------------------
-- Title      : ram_2rw_2c
-- Project    : Asylum
-------------------------------------------------------------------------------
-- File       : ram_2rw_2c.vhd
-- Author     : mrosiere
-- Company    :
-- Created    : 2026-11-26
-- Last update: 2026-11-26
-- Platform   :
-- Standard   : VHDL'08
-------------------------------------------------------------------------------
-- Description: True dual-port RAM : two read / write ports, each with its
--              own clock (port 0 : clk0_i, port 1 : clk1_i, unrelated
--              clocks allowed), inferable as a true dual-port block RAM.
--              Each port, on the rising edge of its clock when cke = 1 and
--              cs = 1 : we = 1 writes wdata at addr (rdata unchanged),
--              we = 0 reads addr into rdata (one cycle of latency).
--              Same address on both ports at the same time :
--              * write on both : port 1 wins in simulation (last
--                assignment of the process) ; undefined on a block RAM
--              * read on one, write on the other : the read returns the
--                old word in simulation ; on a block RAM the read data are
--                undefined (and may be metastable : the write -> read
--                register path crosses the clock domains), the word written
--                is kept only if the write port does not read (no change
--                mode, as here)
--              The user avoids these collisions, or discards the read data.
--              A single writer with a reader on another clock is
--              ram_1r1w_2c (simpler, the template every tool infers).
--              DEPTH is a power of 2.
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-26  1.0      mrosiere Created
-- 2026-11-27  1.1      mrosiere Collisions : comment
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library asylum;
use     asylum.math_pkg.all;

entity ram_2rw_2c is
  generic (
    WIDTH        : natural := 32                                   -- Word width
   ;DEPTH        : natural := 32                                   -- Number of words (power of 2)
  );
  port (
    -- Port 0
    clk0_i       : in  std_logic
   ;cke0_i       : in  std_logic
   ;cs0_i        : in  std_logic
   ;we0_i        : in  std_logic
   ;addr0_i      : in  std_logic_vector(log2(DEPTH) -1 downto 0)
   ;wdata0_i     : in  std_logic_vector(WIDTH       -1 downto 0)
   ;rdata0_o     : out std_logic_vector(WIDTH       -1 downto 0)
    -- Port 1
   ;clk1_i       : in  std_logic
   ;cke1_i       : in  std_logic
   ;cs1_i        : in  std_logic
   ;we1_i        : in  std_logic
   ;addr1_i      : in  std_logic_vector(log2(DEPTH) -1 downto 0)
   ;wdata1_i     : in  std_logic_vector(WIDTH       -1 downto 0)
   ;rdata1_o     : out std_logic_vector(WIDTH       -1 downto 0)
  );
end entity ram_2rw_2c;

architecture rtl of ram_2rw_2c is

  type ram_t is array (DEPTH-1 downto 0) of std_logic_vector(WIDTH-1 downto 0);

  signal   ram_r       : ram_t;
  signal   rdata0_r    : std_logic_vector(WIDTH-1 downto 0);
  signal   rdata1_r    : std_logic_vector(WIDTH-1 downto 0);

  signal   addr0       : integer range 0 to DEPTH-1;
  signal   addr1       : integer range 0 to DEPTH-1;

begin  -- architecture rtl

  addr0 <= to_integer(unsigned(addr0_i));
  addr1 <= to_integer(unsigned(addr1_i));

  -----------------------------------------------------------------------------
  -- Both ports in one process : ram_r has one driver (a signal written by two
  -- processes would be resolved to 'X'). Read when not writing ("no change"
  -- of the block RAMs)
  -----------------------------------------------------------------------------
  process (clk0_i, clk1_i)
  begin
    if rising_edge(clk0_i)
    then
      if cke0_i = '1' and cs0_i = '1'
      then
        if we0_i = '1'
        then
          ram_r(addr0) <= wdata0_i;
        else
          rdata0_r     <= ram_r(addr0);
        end if;
      end if;
    end if;

    if rising_edge(clk1_i)
    then
      if cke1_i = '1' and cs1_i = '1'
      then
        if we1_i = '1'
        then
          ram_r(addr1) <= wdata1_i;
        else
          rdata1_r     <= ram_r(addr1);
        end if;
      end if;
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- Outputs
  -----------------------------------------------------------------------------
  rdata0_o <= rdata0_r;
  rdata1_o <= rdata1_r;

-- synthesis translate_off
  -- The address width is log2(DEPTH) (floor): with a DEPTH that is not a power
  -- of 2, the words 2**log2(DEPTH) to DEPTH-1 can not be addressed
  assert 2**log2(DEPTH) = DEPTH
    report "ram_2rw_2c : DEPTH (" & integer'image(DEPTH) & ") is not a power of 2, only " & integer'image(2**log2(DEPTH)) & " words are addressable"
    severity error;
-- synthesis translate_on

end architecture rtl;
