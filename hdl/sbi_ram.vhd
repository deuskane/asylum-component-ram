-------------------------------------------------------------------------------
-- Title      : sbi_ram
-- Project    : PicoSOC
-------------------------------------------------------------------------------
-- File       : sbi_ram.vhd
-- Author     : Mathieu Rosiere
-- Company    : 
-- Created    : 2026-05-16
-- Last update: 2026-05-16
-- Platform   : 
-- Standard   : VHDL'87
-------------------------------------------------------------------------------
-- Description:
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2026-05-16  1.0      mrosiere Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library asylum;
use asylum.sbi_pkg.all;
use asylum.ram_pkg.all;
use asylum.math_pkg.all;
use asylum.sbi_pkg.all;

-- RAM wrapper entity with SBI interface
entity sbi_ram is
    generic (
        NAME       : string  := "";
        DEPTH      : natural := 256;
        SYNC_READ  : boolean := false
    );
    port (
    clk_i            : in    std_logic;
    arst_b_i         : in    std_logic; -- asynchronous reset

    -- Bus
    sbi_ini_i        : in    sbi_ini_t;
    sbi_tgt_o        : out   sbi_tgt_t
    );
end entity sbi_ram;

architecture rtl of sbi_ram is

    constant ADDR_WIDTH : natural := log2(DEPTH);

    signal ready_r : std_logic;
    signal ready   : std_logic;

begin

    -- -------------------------------------------------------------------------
    -- Single Port RAM Instance: Maps SBI bus signals to the generic RAM core
    -- -------------------------------------------------------------------------
    u_ram_1rw : ram_1rw
        generic map (
            DEPTH     => 2**ADDR_WIDTH,
            WIDTH     => sbi_ini_i.wdata'length,
            SYNC_READ => SYNC_READ
        )
        port map (
            clk_i   => clk_i,
            cke_i   => '1', -- always enabled
            cs_i    => sbi_ini_i.cs,
            we_i    => sbi_ini_i.we,
            addr_i  => sbi_ini_i.addr(ADDR_WIDTH-1 downto 0),
            wdata_i => sbi_ini_i.wdata,

            -- Read data output
            rdata_o => sbi_tgt_o.rdata
        );

    -- -------------------------------------------------------------------------        
    -- Ready signal generation
    -- -------------------------------------------------------------------------

    --  for synchronous read mode
    gen_sync_ready: if SYNC_READ = true
    generate
        process (clk_i, arst_b_i)
        begin
            if arst_b_i = '0' then
                ready_r <= '0';
            elsif rising_edge(clk_i) then
                ready_r <= sbi_ini_i.cs and not ready_r; -- ready goes high one cycle after cs is asserted
            end if;
        end process;

        ready <= ready_r;
    end generate gen_sync_ready;

    -- for asynchronous read mode
    gen_async_ready: if SYNC_READ = false
    generate
        ready <= sbi_ini_i.cs;
    end generate gen_async_ready; 

    sbi_tgt_o.ready <= ready; 

    -- -------------------------------------------------------------------------
    -- Target information
    -- -------------------------------------------------------------------------
    gen_info: if NAME /= "" 
    generate
        sbi_tgt_o.info.name <= to_sbi_name(NAME);
    end generate gen_info;

    gen_info_default: if NAME = "" 
    generate
        sbi_tgt_o.info.name <= to_sbi_name("RAM"&to_string(DEPTH)&"B");
    end generate gen_info_default;

end architecture rtl;