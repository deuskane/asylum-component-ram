-------------------------------------------------------------------------------
-- Title      : tb_ram_random_pkg
-- Project    : ram
-------------------------------------------------------------------------------
-- File       : tb_ram_random_pkg.vhd
-- Author     : mrosiere
-------------------------------------------------------------------------------
-- Description: Scenario random of tb_ram, from reset :
--              1000 random cycles : reads (60 %), writes (50 %),
--              cke_i = 1 (90 %), random addresses and data
-------------------------------------------------------------------------------
-- Copyright (c) 2026
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author   Description
-- 2026-11-20  1.0      mrosiere Created (Test 6 of tb_ram 1.0)
-------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library work;
use     work.tb_ram_bfm_pkg.all;

package tb_ram_random_pkg is

  -- 1000 random cycles : reads (60 %), writes (50 %),
  -- cke_i = 1 (90 %), random addresses and data
  procedure run
    (signal   clk      : in    std_logic
    ;signal   req      : out   t_ram_req
    ;signal   rsp      : in    t_ram_rsp
    ;variable model    : inout t_model
    );

end package tb_ram_random_pkg;

package body tb_ram_random_pkg is

  procedure run
    (signal   clk      : in    std_logic
    ;signal   req      : out   t_ram_req
    ;signal   rsp      : in    t_ram_rsp
    ;variable model    : inout t_model
    ) is
    constant DEPTH : natural := model.mem'length;
    constant WIDTH : natural := rsp.rdata'length;
    variable v_data : std_logic_vector(WIDTH-1 downto 0);
  begin
    -- Same sequence whatever the position of the scenario in TESTS_LIST
    shared_seed1 := C_RAND_INIT_SEED_1;
    shared_seed2 := C_RAND_INIT_SEED_2;
    ram_fill(0, clk, req, rsp, model);
    for i in 1 to 1000
    loop
      v_data := random(WIDTH);
      ram_cycle(random(1, 100) <= 60, random(0, DEPTH-1),
                random(1, 100) <= 60, random(0, DEPTH-1),
                random(1, 100) <= 50, random(0, DEPTH-1), v_data,
                "Cycle " & to_string(i), clk, req, rsp, model,
                cke => random(1, 100) <= 90);
    end loop;
    ram_idle("Random", clk, req, rsp, model);
  end procedure;

end package body tb_ram_random_pkg;
