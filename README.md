# Asylum RAM Component

## Table of Contents

1. [Introduction](#introduction)
2. [Modules](#modules)
   - [ram_1r1w](#ram_1r1w)
3. [Verification](#verification)

---

## Introduction

The Asylum RAM Component is a parameterizable Single-Port RAM (1 Read, 1 Write) module designed for hardware integration within the Asylum project. This component provides flexible memory architecture with support for both synchronous and asynchronous read operations.

### Key Features

- **Parameterizable**: Configurable word width (`WIDTH`) and memory depth (`DEPTH`)
- **Single Read Port**: Independent read address and control signals
- **Single Write Port**: Independent write address and control signals
- **Clock Enable**: Built-in clock enable (`cke_i`) for power management
- **Flexible Read Mode**: Selectable synchronous or asynchronous read operation via `SYNC_READ` generic
- **VHDL Implementation**: Synthesizable VHDL RTL code suitable for FPGA/ASIC deployment

### Project Structure

```
asylum-component-ram/
├── hdl/                 # Hardware description files
│   ├── ram_pkg.vhd      # Component package definition
│   └── ram_1r1w.vhd     # RAM core implementation
├── sim/                 # Simulation and testbench
│   └── tb_ram_1r1w.vhd  # Testbench for ram_1r1w
├── mk/                  # Build configuration
│   ├── defs.mk          # Build definitions
│   └── targets.txt      # Build targets
├── Makefile             # Build automation
├── ram.core             # FuseSoC core file
└── README.md            # This file
```

---

## Modules

### ram_1r1w

The `ram_1r1w` module implements a single-port dual-access RAM with one independent read port and one independent write port. Both ports are controlled through a common clock signal.

#### Generics

| Generic    | Type    | Default | Description                                        |
|-----------|---------|---------|--------------------------------------------------|
| `WIDTH`   | natural | 32      | Word width in bits (data bus width)            |
| `DEPTH`   | natural | 32      | Memory depth (number of addressable words)     |
| `SYNC_READ` | boolean | false   | Read mode: `true` for synchronous, `false` for asynchronous |

#### Ports

| Port      | Direction | Type                              | Description                                    |
|-----------|-----------|-----------------------------------|----------------------------------------------|
| `clk_i`   | in        | `std_logic`                       | System clock (rising edge triggered)        |
| `cke_i`   | in        | `std_logic`                       | Clock enable (active high)                   |
| `re_i`    | in        | `std_logic`                       | Read enable (active high)                    |
| `raddr_i` | in        | `std_logic_vector(log2(DEPTH)-1..0)` | Read address bus                        |
| `rdata_o` | out       | `std_logic_vector(WIDTH-1..0)`    | Read data output                             |
| `we_i`    | in        | `std_logic`                       | Write enable (active high)                   |
| `waddr_i` | in        | `std_logic_vector(log2(DEPTH)-1..0)` | Write address bus                       |
| `wdata_i` | in        | `std_logic_vector(WIDTH-1..0)`    | Write data input                             |

#### Functionality

**Write Operation:**
- Write occurs on the rising edge of `clk_i` when both `cke_i` and `we_i` are high
- Data present on `wdata_i` is written to the memory location specified by `waddr_i`
- Write operations are synchronous to the clock

**Read Operation (Asynchronous Mode: `SYNC_READ = false`):**
- Data at the memory location specified by `raddr_i` is immediately available on `rdata_o`
- The `re_i` signal is not used in this mode (read always enabled)
- Combinatorial path from address to data output

**Read Operation (Synchronous Mode: `SYNC_READ = true`):**
- Read address is latched on the rising edge of `clk_i` when both `cke_i` and `re_i` are high
- Data output (`rdata_o`) appears one clock cycle after the read address is latched
- Synchronous operation provides registered outputs

**Clock Enable:**
- When `cke_i` is low, all write operations are disabled
- In synchronous read mode, when `cke_i` is low, read latches are not updated
- In asynchronous read mode, `cke_i` does not affect read data

#### Example Instantiation

```vhdl
ram_inst : ram_1r1w
  generic map (
    WIDTH     => 8,      -- 8-bit words
    DEPTH     => 256,    -- 256 locations
    SYNC_READ => false   -- Asynchronous read
  )
  port map (
    clk_i    => clk,
    cke_i    => '1',
    re_i     => read_enable,
    raddr_i  => read_addr,
    rdata_o  => read_data,
    we_i     => write_enable,
    waddr_i  => write_addr,
    wdata_i  => write_data
  );
```

---

## Verification

### Simulation Framework

The project uses **GHDL** (VHDL simulator) for design verification, configured through **FuseSoC** (FPGA package manager).

#### Testbench: tb_ram_1r1w

The testbench (`sim/tb_ram_1r1w.vhd`) performs comprehensive functional verification of the RAM module with the following test sequences:

**Test Configuration:**
- Word width: 8 bits
- Memory depth: 8 locations
- Clock period: 10 ns

**Test Sequences:**

1. **Write Only Test**
   - Writes sequential values (0-7) to memory addresses (0-7)
   - Verifies write path functionality

2. **Read Only Test**
   - Reads from addresses (0-7) and verifies data matches previously written values
   - Validates read path and data retention

3. **Write/Read Sequence Test**
   - Performs simultaneous write and read operations
   - Writes complemented values while reading previous data
   - Verifies port independence and simultaneous operation correctness
