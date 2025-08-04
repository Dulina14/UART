# Matrix-Vector Multiplication (MVM) over UART – Verilog Implementation

This repository contains a Verilog-based implementation of a Matrix-Vector Multiplication (MVM) system integrated with UART interfaces for serial data transmission. The design supports efficient hardware acceleration of MVM operations with flexible parameterization.

## 📌 Features

- **UART Receiver and Transmitter Modules**  
  Communicates matrix and vector data to and from the system using serial communication (e.g., 9600 baud rate supported via `CLOCKS_PER_PULSE`).

- **Matrix-Vector Multiplication Core**  
  Implements a pipelined multiply-accumulate (MAC) datapath with an adder tree structure.

- **AXI-Stream-like Handshaking**  
  Utilizes `valid/ready` interface signals for safe data transfer between modules.

- **Skid Buffer**  
  Handles backpressure during dataflow to prevent data loss or stalls.

- **Test-Friendly and Parameterizable**  
  Modular and parameter-driven (`R`, `C`, `W_X`, `W_K`, etc.) to adapt to various input sizes and bit-widths.

## 🧠 System Overview

The system consists of:

1. **UART_RX**: Deserializes and assembles the incoming serial data into matrix and vector payloads.
2. **Matrix-Vector Multiplication Core**: Computes dot products of matrix rows and input vector.
3. **UART_TX**: Serializes the output results and transmits them back.
4. **Top-Level Module**: `mvm_uart_system` connects all components, suitable for FPGA prototyping.

## 🔧 Parameters

| Parameter           | Description                         |
|---------------------|-------------------------------------|
| `R`                 | Number of matrix rows               |
| `C`                 | Number of matrix columns            |
| `W_X`               | Bit-width of vector elements        |
| `W_K`               | Bit-width of matrix elements        |
| `W_Y_OUT`           | Output bit-width (usually padded)   |
| `BITS_PER_WORD`     | UART word length (typically 8)      |
| `CLOCKS_PER_PULSE`  | Baud rate timing configuration      |

## 📁 Files

- `uart_rx.v` / `uart_tx.v` – UART interface modules
- `matvec_mul.v` – Core MAC engine with pipelined adder tree
- `axis_matvec_mul.v` – Wrapper with AXI-like handshaking
- `skid_buffer.v` – Handles flow control buffering
- `mvm_uart_system.v` – Top-level integration
- `tt_um_uart_mvm_sys.v` – Example top module for integration (e.g., Tiny Tapeout or FPGA)

## 🚀 Getting Started

To simulate or synthesize:

1. Clone the repo
2. Use a Verilog simulator like **Icarus Verilog**, **ModelSim**, or a synthesis tool like **Vivado** or **Quartus**
3. Adjust parameters in the top module to fit your use case
4. Connect UART `rx` and `tx` pins to a USB-UART module for live communication

## 📬 Serial Protocol

- **Input Format**: Flattened matrix (row-major) followed by vector, transmitted byte-by-byte
- **Output Format**: Flattened result vector, one word per row
---
