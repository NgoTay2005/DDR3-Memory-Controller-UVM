// File: interface.sv


interface dram_if(input logic clk, input logic rst_n);
    // Cac tin hieu giao tiep voi CPU
    logic        valid_i;
    logic [31:0] addr_i;
    logic        type_i;
    logic        ready_o;

    
    logic [1:0]  dram_cmd_o;
    logic [13:0] dram_row_o;
    logic [2:0]  dram_bank_o;
endinterface