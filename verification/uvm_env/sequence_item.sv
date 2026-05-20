// File: sequence_item.sv


import uvm_pkg::*;
`include "uvm_macros.svh"

class dram_transaction extends uvm_sequence_item;
    
    rand logic [31:0] addr;
    rand logic        is_write; // 0: READ, 1: WRITE
    logic [31:0]      data;     // Du lieu thuc te (neu co)

    
    `uvm_object_utils_begin(dram_transaction)
        `uvm_field_int(addr,     UVM_ALL_ON)
        `uvm_field_int(is_write, UVM_ALL_ON)
        `uvm_field_int(data,     UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "dram_transaction");
        super.new(name);
    endfunction

endclass