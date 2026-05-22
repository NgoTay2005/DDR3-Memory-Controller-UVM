# 🚀 High-Performance Synthesizable DDR3 Memory Controller with FR-FCFS Scheduler & UVM Verification Environment

![SystemVerilog](https://img.shields.io/badge/Language-SystemVerilog-blue.svg)
![Methodology](https://img.shields.io/badge/Methodology-UVM_1.2-green.svg)
![Tools](https://img.shields.io/badge/Tools-ModelSim%20%7C%20Quartus%20II-orange.svg)
![Standard](https://img.shields.io/badge/Standard-JEDEC_JESD79--3F-red.svg)

A complete, industrial-grade **DDR3 Memory Controller** designed from the ground up in **SystemVerilog (RTL)** and verified using a robust **Universal Verification Methodology (UVM 1.2)** environment. The controller features an optimized **FR-FCFS (First-Ready First-Come-First-Served)** scheduling algorithm, **Address Hashing (MAP_XOR)** to minimize bank conflicts, and an automated hardware-level **Auto-Refresh Engine**.

---

## 📋 Table of Contents
1. [Introduction & Motivation](#-1-introduction--motivation)
2. [Core Architecture & Features](#-2-core-architecture--features)
3. [Detailed Hardware Architecture (RTL)](#-3-detailed-hardware-architecture-rtl)
4. [JEDEC Timing Parameters Configuration](#-4-jedec-timing-parameters-configuration)
5. [UVM Verification Environment](#-5-uvm-verification-environment)
6. [Repository Directory Structure](#-6-repository-directory-structure)
7. [Simulation Guide (ModelSim / QuestaSim)](#-7-simulation-guide-modelsim--questasim)
8. [Hardware Synthesis & Resource Utilization](#-8-hardware-synthesis--resource-utilization)
9. [Author & Academic Metadata](#-9-author--academic-metadata)

---

## 🧠 1. Introduction & Motivation

Modern computing systems face a critical bottleneck known as the **"Memory Wall"**. While CPU performance has historically scaled rapidly according to Moore's Law, discrete DRAM performance has improved at a significantly slower rate. This creates an exponential speed gap between processing cores and volatile memory arrays.

This project implements a dedicated intermediate **DDR3 Memory Controller** to bridge this gap. The primary challenges addressed include:
* **Latency Hiding:** Transforming high-latency raw DRAM operations into seamless, pipelined data bursts.
* **Timing Enforcement:** Converting abstract CPU read/write transactions into strictly ordered physical command sequences satisfying nanosecond-level JEDEC parameters (tRCD, tRP, tRAS, etc.).
* **Bandwidth Optimization:** Intelligently reordering memory requests to keep data buses continuously utilized.
<img width="413" height="205" alt="image" src="https://github.com/user-attachments/assets/d782f727-863c-4f1a-9b4b-710a8f8d47bb" />

---

## ⚡ 2. Core Architecture & Features

* **Multi-Bank Concurrency:** Direct support for 8 independent logical banks, facilitating **Bank Interleaving** to completely hide row precharge and activation latencies.
* **1T1C Storage Cell Compatibility:** Handles the physical destructive-read nature of DRAM arrays, ensuring automated row restoration via sense amplifiers.
* **Non-Blocking Request Handling:** Completely avoids traditional Head-of-Line (HOL) blocking by utilizing an un-ordered Random-Access request buffer.
* **Dynamic Refreshes:** Integrated autonomous Refresh Controller tracking tREFI and executing tRFC cycles to prevent charge leakages across memory columns.

---

## 🏗️ 3. Detailed Hardware Architecture (RTL)
<img width="661" height="405" alt="image" src="https://github.com/user-attachments/assets/b77d29b5-7389-4222-965a-b20c5e2f2682" />

The structural hierarchy of `memory_controller.sv` is partitioned into distinct modular entities to ensure precise separation of concerns and synthesis efficiency:

### A. Address Mapper (`address_mapper.sv`)
Decodes the inbound 32-bit CPU address into standardized DRAM structural components: **Row (14 bits)**, **Bank (3 bits)**, and **Column (10 bits)**. 
* **The Bank-Conflict Bottleneck:** Sequential stride lookups often flood the same bank, forcing repetitive closing and opening of rows.
* **MAP_XOR Hashing Solution:** Implements an XOR hashing function between the initial Bank bits `[12:10]` and upper Row segments `[20:18]`. This mathematical distribution shuffles sequential addresses uniformly across all 8 banks, dramatically maximizing bank interleaving efficiency.
<img width="666" height="332" alt="image" src="https://github.com/user-attachments/assets/668e6b0b-fbda-4af0-8fd9-ec47f4e22500" />

### B. Request Queue (`request_queue.sv`)
Acts as the intelligent waiting room for memory operations. Rather than acting as a standard rigid FIFO, it behaves as a **Random-Access Register Buffer** managing up to 8 concurrent requests simultaneously.
* Monitors queue occupancy and drives the `ready_o` flow-control handshake back to the CPU interface.
* If the buffer is completely saturated, it drops `ready_o` to low, executing a deterministic **Backpressure** mechanism to prevent overflow.
<img width="679" height="411" alt="image" src="https://github.com/user-attachments/assets/abf39d99-ef65-4300-9715-5d9ed4ee2a8a" />

### C. FR-FCFS Scheduler (`scheduler.sv`)
The scheduling engine evaluates the pending requests inside the Request Queue in parallel every clock cycle using a two-tier priority arbiter:
1. **Tier 1 - Row-Hit Priority (First-Ready):** Prioritizes requests whose target Row matches the row currently latched into that specific Bank's sense amplifier. This avoids costly closing (`PRECHARGE`) and reopening (`ACTIVATE`) phases, preserving peak data bus throughput.
2. **Tier 2 - Age Priority (First-Come-First-Served):** If no Row-Hits are available, the arbiter switches to selecting the oldest pending operation in the buffer. This ensures strict fairness and completely mitigates starvation bugs.
<img width="716" height="411" alt="image" src="https://github.com/user-attachments/assets/7f6c0ed4-9194-40e4-9f08-7ef7a4699a9c" />

### D. Bank FSM Array (`bank_fsm.sv`)
Instantiates 8 separate, isolated Finite State Machines running concurrently to track and safeguard individual memory banks. Each FSM governs the legal transitions across four foundational states:
* `IDLE`: Bank is closed. Senses are precharged. Ready for an `ACTIVATE` command (`01`).
* `ACTIVATING`: Row is being opened. Internal hardware timer counts down the tRCD delay.
* `ACTIVE`: Row is fully latched. Safe to execute multiple `READ` or `WRITE` bursts (`11`).
* `PRECHARGING`: Row is closing down. Internal timer enforces tRP duration before releasing the bank back to `IDLE`.
<img width="743" height="429" alt="image" src="https://github.com/user-attachments/assets/8a29b15d-0cdf-426e-b19d-73ab785d31d7" />

### E. Output Mux & Auto-Refresh Engine
Embedded directly at the top-level entity, a high-priority 3-step state machine monitors the periodic refresh requirements (`ST_NORMAL` -> `ST_PRE_ALL` -> `ST_REF`).
* When the refresh timer hits the JEDEC tREFI window, the controller drops all ongoing operations, forces a `PRECHARGE ALL` (`10`) to safely wrap up current bank activities, and asserts an active `AUTO REFRESH` command window.
* It locks out the scheduler and asserts blank `NOP` cycles (`00`) for the full duration of tRFC (107 cycles) to allow safe chip-wide charge restoration.

---

## 📊 4. JEDEC Timing Parameters Configuration

The parameters are encapsulated cleanly inside the global configuration package `dram_config_pkg.sv`. These integers dictate the exact number of clock cycles required to satisfy physical DRAM delays at a target operational frequency:

| Parameter Name | Value (Cycles) | Technical Description & Physical Significance |
| :--- | :---: | :--- |
| `NUM_BANKS` | **8** | Number of independent internal memory banks. |
| `MAX_QUEUE_SIZE`| **8** | Total available tracking slots inside the Request Queue buffer. |
| `T_RCD` | **9** | **RAS-to-CAS Delay:** Minimum cycles from Row Activation (`ACT`) to Column Read/Write command. |
| `T_RP` | **9** | **Row Precharge Time:** Minimum cycles required to deactivate an open row and restore bitlines. |
| `T_CL` | **9** | **CAS Latency:** Delay between a `READ` command emission and the first valid data bit on the bus. |
| `T_RAS` | **24** | **Row Active Time:** Minimum duration a row must remain fully open before a `PRECHARGE` can close it. |
| `T_RC` | **33** | **Row Cycle Time:** Total cycle length for an autonomous loop (tRC = tRAS + tRP). |
| `T_BURST` | **4** | **Burst Length Duration:** Clock cycles consumed to transmit an 8-bit deep data packet on a dual-edge bus (8/2 = 4). |
| `T_CWD` | **7** | **Column Write Delay:** Delay between a `WRITE` command and valid input data placement. |
| `T_CCD` | **4** | **CAS-to-CAS Delay:** Minimum spacing required between consecutive Read/Write access commands. |
| `T_WR` | **10** | **Write Recovery Time:** Interval between the final data write burst and the subsequent safe `PRECHARGE`. |
| `T_RFC` | **107** | **Refresh Cycle Time:** The mandatory downtime required for an autonomous `AUTO REFRESH` command. |
| `T_REFI` | **5200** | **Refresh Interval:** The maximum allowable cycle space between consecutive refresh bursts. |

---

## 🔬 5. UVM Verification Environment

The design is rigorously verified using a premier, transaction-level object-oriented testbench structured on the standard **Universal Verification Methodology (UVM 1.2)** class hierarchy.
<img width="768" height="382" alt="image" src="https://github.com/user-attachments/assets/699409ec-6424-40dd-b7ac-8e02b33f7fa6" />
### 🔷 Testbench Data Flow Model
The verification platform isolates verification intentions into structured, self-contained transaction components:

* **Transaction Definition (`sequence_item.sv`):** Abstracts raw pin level transitions into an object-oriented class called `dram_transaction`. Variables intended for stimulus generation are appended with the `rand` modifier (`rand logic [31:0] addr; rand logic is_write;`).
  <img width="724" height="373" alt="image" src="https://github.com/user-attachments/assets/437f9ff8-6b3a-4776-b5b9-c58a7cc12d36" />

* **Directed Trace Sequence (`sequence.svh`):** Employs directed verification methodologies by loading complex CPU access traces from an external text spreadsheet file (`trace.txt`).
* **DRAM Driver (`driver.svh`):** Represents the primary active abstraction bridge. It blocks execution until a new item arrives, parses its logical fields, and drives the pin-level signals on the `Virtual Interface (vif)` synchronously on the rising edge of the system clock. It actively checks for hardware-level backpressure stalls.
  <img width="738" height="389" alt="image" src="https://github.com/user-attachments/assets/6743d5d3-1297-4ff2-b957-bf301a0ce205" />
* **Monitor & Scoreboard Architecture:** The `uvm_monitor` passively samples the active pins on the virtual interface, transforms them back into localized transactions, and broadcasts them out of an analysis port. The `uvm_scoreboard` captures these actual outputs, processes the identical stimulus inputs across a rigorous mathematical **Reference Predictor Model** representing an ideal DRAM model, and utilizes an exact tracking `Comparator` block to guarantee transaction equivalency, automatically logging a clear `PASS/FAIL` transaction report.
<img width="761" height="405" alt="image" src="https://github.com/user-attachments/assets/1dcc75fa-9e3d-4340-98bf-d891e516edad" />
<img width="753" height="415" alt="image" src="https://github.com/user-attachments/assets/b7c652c1-2b59-49cb-a435-b1c5c1e6de9c" />

---


## 📂 6. Repository Directory Structure

The workspace follows strict industry conventions for clean separation of synthesizable RTL design cores, verification infrastructures, and simulation data pools:

```text
DDR3_Controller_Project/
├── rtl/                         # Synthesizable Hardware RTL Design Code
│   ├── common/                  
│   │   └── dram_config_pkg.sv   # System configuration & JEDEC timing parameters
│   ├── address_mapper.sv        # Address decoder with MAP_XOR hashing logic
│   ├── bank_fsm.sv              # Concurrent finite state machine array for 8 banks
│   ├── request_queue.sv         # Random-access request tracking buffer
│   ├── scheduler.sv             # FR-FCFS scheduling priority arbiter
│   └── memory_controller.sv     # Top-Level structural hardware module wrapper
├── verification/                # Testbench Infrastructure & Verification Environment
│   ├── uvm_env/                 
│   │   ├── my_uvm_pkg.sv        # Main package container for verification classes
│   │   ├── sequence_item.sv     # Abracted transaction data definition
│   │   ├── driver.svh           # TLM transaction-to-pin signal driver
│   │   ├── monitor.svh          # Passive pin-level transaction monitor
│   │   └── scoreboard.svh       # Automated reference checking & prediction engine
│   └── simple_tb/               
│       └── tb_top.sv            # Top-level verification testbench wrapping DUT and VIF
├── sim/                         # Automated Tool Configuration Scripts
│   ├── wave.do                  # Saved ModelSim waveform signal configurations
│   └── run_sim.tcl              # Automated tool script for end-to-end compilation & simulation
├── data/                        # Stimulus Data Pools and Logging Output
│   ├── trace.txt                # Directed CPU input scenario trace file
│   └── final_trace.log          # Automated logging printout from UVM scoreboard check
└── docs/                        # Architectural Diagrams & Technical Reports
    └── block_diagram.pdf        # Structural system mapping and hierarchy charts



