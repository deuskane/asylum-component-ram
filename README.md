<!--
  README MODEL (common to every Asylum IP, keep the same headings)
  ----------------------------------------------------------------
  Regenerate from the sources, never from the previous README text alone:
    hdl/*.vhd (entities, generics, ports), hdl/csr/*.hjson (register map),
    <IP>.core (VLNV, targets, depends), mk/targets.txt, sim/, syn/, esw/.
  Sections, in this order:
    badges / title + one-line pitch / Overview / Features / Block Diagram /
    Getting Started / Hardware Interfaces / Configuration / Resources /
    Theory of Operation / Registers / Programmer's Guide /
    Design Verification / Dependencies and Related IPs / License
  Rules:
    - English, short and factual: every statement backed by the sources.
    - No VLNV line: the version badge shows it.
    - Badges: first line version, license; second line CI, lint, sim, syn.
    - Block diagram and FSM: pages Overview and FSM of doc/<NAME>.drawio, exported to
      doc/<NAME>-Overview.png and doc/<NAME>-FSM.png (make -C doc).
    - Timing diagrams: WaveDrom source doc/<NAME>-<what>.json, rendered
      doc/<NAME>-<what>.svg (make -C doc), shown as images.
    - No CPU named (OpenBlaze, PicoBlaze, RISC-V) outside the CPU and SoC IPs.
    - Registers: link to the generated hdl/csr/<X>_csr.md, never copy the tables.
    - Tables: Configuration = Name|Type|Default|Description,
      Hardware Interfaces = Name|Direction|Type|Description, grouped by interface.
    - A section with nothing to say is one line ("This IP has no
      software-visible registers."), never removed.
-->
[![Version](https://img.shields.io/github/v/tag/deuskane/asylum-component-ram?filter=asylum-component-ram-*&label=version&color=blue)](https://github.com/deuskane/asylum-component-ram/tags)
[![License](https://img.shields.io/github/license/deuskane/asylum-component-ram)](LICENSE)

[![CI](https://github.com/deuskane/asylum-component-ram/actions/workflows/ci.yml/badge.svg)](https://github.com/deuskane/asylum-component-ram/actions/workflows/ci.yml)
[![lint](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fdeuskane%2Fasylum-component-ram%2Fbadges%2Flint.json)](https://github.com/deuskane/asylum-component-ram/actions/workflows/ci.yml)
[![sim](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fdeuskane%2Fasylum-component-ram%2Fbadges%2Fsim.json)](https://github.com/deuskane/asylum-component-ram/actions/workflows/ci.yml)
[![syn](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fdeuskane%2Fasylum-component-ram%2Fbadges%2Fsyn.json)](https://github.com/deuskane/asylum-component-ram/actions/workflows/ci.yml)

# RAM

**Small, readable inferred RAMs in VHDL: one read and one write port, two read ports, single port, asynchronous or registered read, and a memory on the SBI bus.**

Part of the [Asylum project](https://github.com/deuskane/asylum-project), a collection of small IP cores, written to be read and learned from.

## Table of Contents

1. [Overview](#overview)
2. [Features](#features)
3. [Block Diagram](#block-diagram)
4. [Getting Started](#getting-started)
5. [Hardware Interfaces](#hardware-interfaces)
6. [Configuration](#configuration)
7. [Resources](#resources)
8. [Theory of Operation](#theory-of-operation)
9. [Registers](#registers)
10. [Programmer's Guide](#programmers-guide)
11. [Design Verification](#design-verification)
12. [Dependencies and Related IPs](#dependencies-and-related-ips)
13. [License](#license)

## Overview

This IP gathers the RAMs of Asylum. They are plain VHDL arrays, written so that a synthesis tool infers a memory (distributed RAM or block RAM on an FPGA, flip-flops in an ASIC flow without SRAM macro):

- **`ram_1r1w`**: one read port and one write port (a FIFO storage);
- **`ram_2r1w`**: two read ports and one write port (a register file);
- **`ram_1rw`**: a single port, one address for the read and the write;
- **`sbi_ram`**: `ram_1rw` as a target of the SBI bus (the simple bus of Asylum), a data memory for a CPU.

The three RAMs share the same generics (`WIDTH`, `DEPTH`, `SYNC_READ`) and a clock enable.

## Features

- Word width `WIDTH` and number of words `DEPTH` (power of 2), address of `log2(DEPTH)` bits
- `SYNC_READ = false`: combinational read; `SYNC_READ = true`: registered read, enabled by the read enable of the port
- Registered read during a write of the same address: the old word (read-first)
- Synchronous write on the rising edge of `clk_i`, clock enable `cke_i` on every port
- No reset of the memory: block RAM and distributed RAM friendly
- `sbi_ram`: data width of the SBI bus, zero wait state (`SYNC_READ = false`) or one wait state (`SYNC_READ = true`), its name in `sbi_tgt_o.info` (`NAME`, or `RAM<DEPTH>B`)
- Simulation check that `DEPTH` is a power of 2

## Block Diagram

![Block diagram of sbi_ram, ram_1r1w, ram_2r1w and ram_1rw](doc/ram-Overview.png)

## Getting Started

The cores of the Asylum IPs are published in the FuseSoC library [asylum-cores](https://github.com/deuskane/asylum-cores) (with the UVVM core used by the testbench):

```bash
pip install fusesoc
fusesoc library add https://github.com/deuskane/asylum-cores
fusesoc run --target sim_16x8b_sync_read_read_during_write asylum:component:ram  # needs GHDL
```

To use the IP in your design, add `asylum:component:ram` to the `depend` list of your core and instantiate a RAM (library `asylum`, components in `asylum.ram_pkg`):

```vhdl
library asylum;
use     asylum.sbi_pkg.all;
use     asylum.ram_pkg.all;

  -- Data memory of 128 bytes on the SBI bus
  ins_sbi_ram : sbi_ram
    generic map
    ( NAME      => "RAM0"
     ,DEPTH     => 128
     ,SYNC_READ => true
    )
    port map
    ( clk_i     => clk
     ,arst_b_i  => arst_b
     ,sbi_ini_i => sbi_ini           -- 8-bit data, at least 7 address bits
     ,sbi_tgt_o => sbi_tgt
    );

  -- Register file: 16 words of 8 bits, two combinational reads
  ins_regfile : ram_2r1w
    generic map
    ( WIDTH     => 8
     ,DEPTH     => 16
     ,SYNC_READ => false
    )
    port map
    ( clk_i     => clk
     ,cke_i     => '1'
     ,re0_i     => '1'
     ,raddr0_i  => rs1
     ,rdata0_o  => rs1_data
     ,re1_i     => '1'
     ,raddr1_i  => rs2
     ,rdata1_o  => rs2_data
     ,we_i      => rd_we
     ,waddr_i   => rd
     ,wdata_i   => rd_data
    );
```

[PicoSoC](https://github.com/deuskane/asylum-soc-picosoc) is a complete example: its data memories are `sbi_ram` instances.

## Hardware Interfaces

Top-level entity: **`sbi_ram`** ([hdl/sbi_ram.vhd](hdl/sbi_ram.vhd)). The RAMs without bus are below.

### Clock and Reset

| Name | Direction | Type | Description |
|------|-----------|------|-------------|
| `clk_i` | in | std_logic | System clock, the only clock of the IP |
| `arst_b_i` | in | std_logic | Asynchronous reset, active low: only `ready_r` (`SYNC_READ = true`), the memory has no reset |

### Bus (SBI)

| Name | Direction | Type | Description |
|------|-----------|------|-------------|
| `sbi_ini_i` | in | sbi_ini_t | Request from the initiator: `cs`, `we`, `addr` (the `log2(DEPTH)` low bits are used), `wdata`; `re` is not used |
| `sbi_tgt_o` | out | sbi_tgt_t | Response to the initiator: `ready`, `rdata`, `info` |

The word width of `sbi_ram` is the width of the `wdata` field of the SBI signals it is connected to (`SBI_DATA_WIDTH = 8` in `asylum.sbi_pkg`).

### RAMs without bus

[hdl/ram_1r1w.vhd](hdl/ram_1r1w.vhd), [hdl/ram_2r1w.vhd](hdl/ram_2r1w.vhd), [hdl/ram_1rw.vhd](hdl/ram_1rw.vhd). Every RAM has `clk_i` and `cke_i` (clock enable of the write and of the registered read); the addresses are `std_logic_vector(log2(DEPTH)-1 downto 0)`, the data `std_logic_vector(WIDTH-1 downto 0)`.

| Name | Direction | RAM | Description |
|------|-----------|-----|-------------|
| `re_i`, `raddr_i`, `rdata_o` | in, in, out | `ram_1r1w` | Read port: read enable (`SYNC_READ = true` only), address, data |
| `re0_i`, `raddr0_i`, `rdata0_o` | in, in, out | `ram_2r1w` | Read port 0 |
| `re1_i`, `raddr1_i`, `rdata1_o` | in, in, out | `ram_2r1w` | Read port 1 |
| `we_i`, `waddr_i`, `wdata_i` | in | `ram_1r1w`, `ram_2r1w` | Write port: write enable, address, data |
| `cs_i`, `we_i` | in | `ram_1rw` | Chip select, write enable: write when `cs_i = we_i = 1`, registered read when `cs_i = 1` and `we_i = 0` |
| `addr_i`, `wdata_i`, `rdata_o` | in, in, out | `ram_1rw` | Address of the read and of the write, write data, read data |

## Configuration

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `WIDTH` | natural | `32` | `ram_1r1w`, `ram_2r1w`, `ram_1rw`: word width in bits |
| `DEPTH` | natural | `32` (`sbi_ram`: `256`) | Number of words, a power of 2 (simulation assertion of severity `error` otherwise) |
| `SYNC_READ` | boolean | `false` | `false`: combinational read; `true`: registered read (`sbi_ram`: one wait state) |
| `NAME` | string | `""` | `sbi_ram` only: name in `sbi_tgt_o.info`; `""` gives `RAM<DEPTH>B` (e.g. `RAM256B`) |

The address has `log2(DEPTH)` bits (rounded down): with a `DEPTH` that is not a power of 2, the words `2**log2(DEPTH)` to `DEPTH-1` cannot be addressed (`sbi_ram` instantiates `2**log2(DEPTH)` words).

## Resources

Figures of the `syn_*` targets (`make nonreg_syn`, see [Targets](#targets)): each RAM synthesized alone with the generics of the configuration, `ram_1r1w`, `ram_2r1w` and `ram_1rw` as toplevel, `sbi_ram` in [syn/sbi_ram_wrapper.vhd](syn/sbi_ram_wrapper.vhd) (flat SBI ports, 8-bit words), by Yosys and its GHDL plugin; the reports are in the build directory of each target.

| Configuration | LUT¹ | LUTRAM¹ | FF¹ | CARRY4¹ | MUXF7/F8¹ | BRAM¹ | DSP¹ | Area² (µm²) | kGE³ |
|---|---|---|---|---|---|---|---|---|---|
| `syn_ram_1r1w_16x8b_read_async` | 1 | 8 | 0 | 0 | 0 | 0 | 0 | 5047.34 | 1.345 |
| `syn_ram_1r1w_16x8b_read_sync` | 2 | 8 | 8 | 0 | 0 | 0 | 0 | 5303.84 | 1.413 |
| `syn_ram_1r1w_32x32b_read_async` | 1 | 24 | 0 | 0 | 0 | 0 | 0 | 39848.22 | 10.616 |
| `syn_ram_1r1w_32x32b_read_sync` | 2 | 24 | 32 | 0 | 0 | 0 | 0 | 40963.04 | 10.913 |
| `syn_ram_1r1w_256x8b_read_sync` | 13 | 48 | 8 | 0 | 0 | 0 | 0 | 81109.04 | 21.608 |
| `syn_ram_2r1w_16x8b_read_async` | 1 | 16 | 0 | 0 | 0 | 0 | 0 | 5948.20 | 1.585 |
| `syn_ram_2r1w_16x8b_read_sync` | 3 | 16 | 16 | 0 | 0 | 0 | 0 | 6461.20 | 1.721 |
| `syn_ram_2r1w_32x32b_read_async` | 1 | 48 | 0 | 0 | 0 | 0 | 0 | 47415.48 | 12.632 |
| `syn_ram_2r1w_32x32b_read_sync` | 3 | 48 | 64 | 0 | 0 | 0 | 0 | 49657.63 | 13.229 |
| `syn_ram_2r1w_256x8b_read_sync` | 22 | 96 | 16 | 0 | 0 | 0 | 0 | 96665.21 | 25.753 |
| `syn_ram_1rw_16x8b_read_async` | 1 | 4 | 0 | 0 | 0 | 0 | 0 | 5016.06 | 1.336 |
| `syn_ram_1rw_16x8b_read_sync` | 2 | 4 | 8 | 0 | 0 | 0 | 0 | 5266.30 | 1.403 |
| `syn_ram_1rw_32x32b_read_async` | 1 | 16 | 0 | 0 | 0 | 0 | 0 | 39265.16 | 10.461 |
| `syn_ram_1rw_32x32b_read_sync` | 2 | 16 | 32 | 0 | 0 | 0 | 0 | 40238.59 | 10.720 |
| `syn_ram_1rw_256x8b_read_sync` | 2 | 32 | 8 | 0 | 0 | 0 | 0 | 79441.19 | 21.164 |
| `syn_sbi_ram_16x8b_read_async` | 1 | 4 | 0 | 0 | 0 | 0 | 0 | 5001.05 | 1.332 |
| `syn_sbi_ram_16x8b_read_sync` | 4 | 4 | 9 | 0 | 0 | 0 | 0 | 5297.58 | 1.411 |
| `syn_sbi_ram_32x8b_read_async` | 1 | 4 | 0 | 0 | 0 | 0 | 0 | 10013.35 | 2.668 |
| `syn_sbi_ram_32x8b_read_sync` | 4 | 4 | 9 | 0 | 0 | 0 | 0 | 10298.63 | 2.744 |
| `syn_sbi_ram_256x8b_read_sync` | 4 | 32 | 9 | 0 | 0 | 0 | 0 | 79422.42 | 21.159 |

¹ Xilinx Artix-7 (LUT6), Yosys 0.33 `synth_xilinx -flatten -noiopad -noclkbuf`, before place and route: every cell of the netlist is counted, Vivado may differ. **Where the memory goes**: in every configuration Yosys puts the memory in distributed RAM (LUTRAM column, 4 LUTs per `RAM32M`, `RAM64M` or `RAM256X1S` cell), none in a block RAM, even 256x8 with a registered read. The registered read data are flip-flops (`WIDTH` per read port: 8, 16, 32 or 64), plus `ready_r` in `sbi_ram` (its `INV` on the reset pin counts as a `LUT1`). `ram_2r1w` uses twice the LUTRAM of `ram_1r1w`: one copy of the memory per read port. Another tool may choose a block RAM for the registered read: check its read-during-write mode (see [Read during write](#read-during-write)).

² SkyWater sky130 `sky130_fd_sc_hd`, typical corner (tt, 25 °C, 1.80 V), Yosys 0.33 `synth` + `dfflibmap` + `abc -liberty`: standard-cell area only, no timing constraint, no buffering, clock tree or placement. **Where the memory goes**: there is no SRAM macro, the memory becomes flip-flops, `DEPTH x WIDTH` of them (128 for 16x8, 256 for 32x8, 1024 for 32x32, 2048 for 256x8), plus the registered read data and the read multiplexers: the area grows with the number of bits, not with the number of ports.

³ Area in thousands of NAND2 gate equivalents (`sky130_fd_sc_hd__nand2_1` = 3.7536 µm²).

## Theory of Operation

### Hierarchy

| File | Unit | Role |
|------|------|------|
| [hdl/ram_1r1w.vhd](hdl/ram_1r1w.vhd) | `ram_1r1w` | One read port, one write port |
| [hdl/ram_2r1w.vhd](hdl/ram_2r1w.vhd) | `ram_2r1w` | Two read ports, one write port |
| [hdl/ram_1rw.vhd](hdl/ram_1rw.vhd) | `ram_1rw` | Single port |
| [hdl/sbi_ram.vhd](hdl/sbi_ram.vhd) | `sbi_ram` | `ram_1rw` on the SBI bus, ready logic, target name |
| [hdl/ram_pkg.vhd](hdl/ram_pkg.vhd) | `ram_pkg` | Components |

### Write and read

![Read during write and registered read](doc/ram-read.svg)

- The memory `ram_r` is an array of `DEPTH` words without reset. A word is written on the rising edge of `clk_i` when `cke_i = 1` and the write is enabled (`we_i`, or `cs_i and we_i` for `ram_1rw`).
- `SYNC_READ = false`: `rdata` is `ram_r(raddr)`, combinational: it follows the address, and a word written on an edge is visible right after it. The read enables are not used.
- `SYNC_READ = true`: `rdata_r` loads `ram_r(raddr)` on the rising edge when `cke_i = 1` and the read enable of the port is 1 (`ram_1rw`: `cs_i = 1` and `we_i = 0`); it keeps its value otherwise, also during a write of `ram_1rw`.
- `ram_2r1w` reads two addresses in the same cycle, each port with its own read enable and read register.

### Read during write

- With `SYNC_READ = true`, a read and a write of the same address on the same enabled edge return the **old** word (read-first): the registered read samples the memory before the write. It is the behaviour of the RTL, checked by the scenario `read_during_write` of the testbench.
- On an FPGA, the contract holds only if the inferred memory keeps it: many dual-port block RAMs are write-first or undefined on a collision. Check the mode chosen by the tool for each RAM that can read and write the same address in the same cycle.
- A design that must not depend on it never reads and writes the same address in the same cycle, or adds its own bypass (`fifo_sync` of [asylum-component-fifo](https://github.com/deuskane/asylum-component-fifo) registers the written word for this case).

### `sbi_ram`

- `sbi_ini_i.cs`, `we`, `addr(log2(DEPTH)-1 downto 0)` and `wdata` drive `ram_1rw` (`cke_i = 1`), its read data is `sbi_tgt_o.rdata`.
- Only the `log2(DEPTH)` low address bits are decoded: the RAM is repeated above (the interconnect decodes the base address).
- `SYNC_READ = false`: `ready = cs`, every access takes one cycle.
- `SYNC_READ = true`: `ready_r <= cs and not ready_r`: `ready` rises one cycle after `cs` (the read data are registered) and falls the next cycle, every access takes two cycles. A write held two cycles writes the same word twice.
- `sbi_tgt_o.info.name` is `NAME`, or `RAM<DEPTH>B` when `NAME = ""`.

## Registers

This IP has no software-visible registers: every SBI address of `sbi_ram` below `2**log2(DEPTH)` is a word of the memory.

## Programmer's Guide

`sbi_ram` has no registers: software reads and writes its words as plain memory (one byte per address with the 8-bit SBI bus); the memory is not initialized, write a word before reading it.

## Design Verification

### Testbench

| File | DUT | Description |
|------|-----|-------------|
| [sim/ram/tb_ram.vhd](sim/ram/tb_ram.vhd) | `ram_1r1w`, `ram_2r1w`, `ram_1rw`, `sbi_ram` | Self-checking UVVM testbench, generics `TESTS_LIST` (scenarios, see below), `WIDTH`, `DEPTH` (power of 2, >= 16), `SYNC_READ`. The three RAMs without bus receive the same accesses (`ram_1rw`: `cs = we or re0`, address = write address during a write, else read address 0) and share one reference model: every cycle the inputs are driven on the falling edge of the clock and the read data of every port are checked a quarter period later, against the content (combinational read) or the word registered by the last enabled read. `sbi_ram` is driven by the SBI BFM (`bitvis_vip_sbi`); a monitor measures the wait states of every access and raises an error if `ready` is set without `cs`. A second `sbi_ram` with `NAME = "RAM0"` is only used for its name |

Scenarios in `tb_ram_<name>_pkg`, cycle, model and SBI helpers in [tb_ram_bfm_pkg](sim/ram/tb_ram_bfm_pkg.vhd), names and dispatch in [tb_ram_tests_pkg](sim/ram/tb_ram_tests_pkg.vhd).

### Scenarios (`TESTS_LIST`)

The scenarios are chosen at run time with the generic `TESTS_LIST`: names separated by `,` without space (`write_read,random,write_read`), a name may be repeated. The sequencer first checks every name (an unknown name is a `TB_ERROR` before any scenario runs), then for each scenario drives a reset pulse with the RAM inputs and the bus inactive, empties the reference model, logs `TEST <i>/<N> : <name>` and runs it. The memories are not reset: each scenario writes the words it reads (the model checks a word only once written by the scenario). The empty list (default) only compiles and elaborates the testbench. The list is parsed and its names checked with `list_length` / `list_item` / `list_contains` of `asylum.string_pkg` (`asylum:utils:pkg` >= 1.10.0).

Checks counted as the `=> OK` lines of the log, reference configuration (16 words of 8 bits, `SYNC_READ = true`):

| Name | Checks | Description |
|------|--------|-------------|
| `write_read` | 68 | Write of every word, then read of every word (`ram_2r1w` port 1 in reverse order); the idle cycles hold the registered read data |
| `read_during_write` | 127 | Read and write of the same address on the same edge: the registered read returns the old word, the next read the new word |
| `clock_enable` | 20 | `cke_i = 0` blocks the writes and the registered reads of every port |
| `read_enable` | 16 | A read enable at 0 holds the registered read data while the address changes; a write of `ram_1rw` does not update its registered read data |
| `write_enable` | 124 | A write not selected (`we_i = 0` on `ram_1r1w` / `ram_2r1w`, `cs_i = 0` with `we_i = 1` on `ram_1rw`) does not change the word |
| `random` | 3999 | 1000 random cycles: reads (60 %), writes (50 %), `cke_i = 1` (90 %), random addresses and data, fixed seeds |
| `sbi_write_read` | 80 | `sbi_ram`: write then read of every word, then back-to-back write and read of each word; wait states of every access (0, or 1 with `SYNC_READ`) |
| `sbi_aliasing` | 9 | `sbi_ram`: the word written at `DEPTH+3` is read at 3, `DEPTH+3`, `2*DEPTH+3` and `3*DEPTH+3`; wait states |
| `sbi_name` | 2 | `sbi_tgt_o.info.name`: `RAM<DEPTH>B` with `NAME = ""`, `NAME` otherwise |

With `SYNC_READ = false` the read data are checked on every cycle (no registered data to wait for): more checks, e.g. 4769 in `sim_16x8b_async_read`.

### Targets

| Target | Toplevel | Description |
|--------|----------|-------------|
| `default` | `ram_1r1w` | HDL fileset (not a simulation) |
| `sim_16x8b_sync_read` | `tb_ram` | Reference configuration (`WIDTH = 8`, `DEPTH = 16`, `SYNC_READ = true`): build and elaboration only (`TESTS_LIST` empty), base of the scenario targets and of the list runs |
| `sim_16x8b_sync_read_<name>` | `tb_ram` | One target per scenario: `sim_16x8b_sync_read_write_read`, `_read_during_write`, `_clock_enable`, `_read_enable`, `_write_enable`, `_random`, `_sbi_write_read`, `_sbi_aliasing`, `_sbi_name` (4445 checks in all) |
| `sim_16x8b_async_read` | `tb_ram` | `WIDTH = 8`, `DEPTH = 16`, `SYNC_READ = false`, every scenario (4769 checks) |
| `sim_64x32b_sync_read` | `tb_ram` | `WIDTH = 32`, `DEPTH = 64`, `SYNC_READ = true`, every scenario (5645 checks) |
| `sim_64x32b_async_read` | `tb_ram` | `WIDTH = 32`, `DEPTH = 64`, `SYNC_READ = false`, every scenario (6833 checks) |
| `lint_ghdl` | `asylum.sbi_ram_wrapper` | GHDL `-Wall` analysis of every RAM and of [syn/sbi_ram_wrapper.vhd](syn/sbi_ram_wrapper.vhd) (`sbi_ram` with flat SBI ports), elaboration of `sbi_ram_wrapper` |
| `lint_ghdl_synth_<ram>_<config>` | the RAM, or `sbi_ram_wrapper` | `ghdl --synth` check (no latch, synthesizable) of `ram_1r1w`, `ram_2r1w`, `ram_1rw`: `32x32b_read_async`, `32x32b_read_sync`, `16x8b_read_async`, `16x8b_read_sync`, `256x8b_read_sync`; of `sbi_ram`: `32x8b_read_async`, `32x8b_read_sync`, `16x8b_read_async`, `16x8b_read_sync`, `256x8b_read_sync` |
| `syn_<ram>_<config>` | the RAM, or `sbi_ram_wrapper` | Synthesis with Yosys, Artix-7 and sky130 (see [Resources](#resources)), same configurations as `lint_ghdl_synth_*` |

The reference configuration has a build-only base target and one target per scenario: one CI job per scenario, a failure is isolated. Every other configuration has one target that runs the whole list: the `TEST <i>/<N>` header names a failing scenario. FuseSoC replaces the `parameters` list of an inherited target, so each target repeats the generics of its configuration.

Every `sim_*`, `lint_*` and `syn_*` target is a job of the [GitHub CI](https://github.com/deuskane/asylum-component-ram/actions/workflows/ci.yml), run in the [asylum-env](https://github.com/deuskane/asylum-ci) image (GHDL, FuseSoC, UVVM, Yosys). The `sim`, `lint` and `syn` badges count the passed and failed targets of the last run on `main`.

### How to Run

From a clone of [asylum-project](https://github.com/deuskane/asylum-project) (GHDL and FuseSoC installed, or in the asylum-env image):

```bash
make help                                    # variables, rules and targets
make sim_16x8b_sync_read_read_during_write   # one scenario, log in log/
make sim_64x32b_async_read                   # every scenario of a configuration
make nonreg_sim                              # every sim_* target
make nonreg_lint                             # every lint_* target
make nonreg_syn                              # every syn_* target (Yosys, figures of Resources)
make TARGETS_FILTER=sbi_ram nonreg_syn
```

To run a list of scenarios, build the testbench once, then run the list without recompiling, either with FuseSoC (same `--build-root` and `--no-export` as the Makefile, so that the build of the target is reused; any generic of the target can be overridden after the VLNV):

```bash
make sim_16x8b_sync_read                     # build and elaboration (TESTS_LIST empty)
fusesoc --cores-root . run --build-root build --no-export --run --target sim_16x8b_sync_read asylum:component:ram:1.2.3 --TESTS_LIST=random,write_read
```

or in the build directory of the target. `EXTRA_OPTIONS` replaces every generic set by the target: repeat the generics of the configuration, else their default values apply:

```bash
cd build/asylum_component_ram_1.2.3/sim_16x8b_sync_read-ghdl
make run EXTRA_OPTIONS="-gTESTS_LIST=random,write_read -gWIDTH=8 -gDEPTH=16 -gSYNC_READ=true"
```

To add a scenario: a `tb_ram_<name>_pkg` package with a `run` procedure in the `files_sim` fileset, its name in `C_TESTS` and its case in `run_test` of [tb_ram_tests_pkg](sim/ram/tb_ram_tests_pkg.vhd), a `sim_16x8b_sync_read_<name>` target and the name in the `TESTS_LIST` of the other configurations in [ram.core](ram.core), then `make mk/targets.txt` and `make ci_generate`.

Outside the CI, GHDL writes a waveform `dut.fst`.

## Dependencies and Related IPs

| Core | Repository | Purpose |
|------|------------|---------|
| `asylum:utils:pkg` | [asylum-utils-pkg](https://github.com/deuskane/asylum-utils-pkg) | `math_pkg` (`log2`), `sbi_pkg` (SBI records, `to_sbi_name`); the testbench needs >= 1.10.0 (`string_pkg` lists of `TESTS_LIST`) |
| `asylum:utils:ghdl_synth` | [asylum-utils-generators](https://github.com/deuskane/asylum-utils-generators) | `ghdl --synth` check of the `lint_ghdl_synth_*` targets |
| `asylum:utils:yosys_synth` | [asylum-utils-generators](https://github.com/deuskane/asylum-utils-generators) | Yosys synthesis of the `syn_*` targets (Artix-7 and sky130) |
| `bitvis:verification:uvvm` | [UVVM](https://github.com/UVVM/UVVM) | Verification library and SBI BFM |

The synthesis checks use the dependency-free cores `ghdl_synth` and `yosys_synth`, not `asylum:utils:generators`: the generators depend on the FIFO, which depends on this IP.

Used by [asylum-component-fifo](https://github.com/deuskane/asylum-component-fifo) and [asylum-component-stack](https://github.com/deuskane/asylum-component-stack) (`ram_1r1w`), and [asylum-soc-picosoc](https://github.com/deuskane/asylum-soc-picosoc) (`sbi_ram`); the register banks generated by regtool use it through the FIFO. All the IPs: [asylum-project](https://github.com/deuskane/asylum-project).

## License

Apache License 2.0, see [LICENSE](LICENSE).
