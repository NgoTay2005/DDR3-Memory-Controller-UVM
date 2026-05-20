package my_uvm_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    import dram_config_pkg::*;

    
    `include "sequence_item.sv"
    typedef uvm_sequencer #(dram_transaction) dram_sequencer;
    `include "sequence.svh"      
    `include "driver.svh"    
    `include "monitor.svh"
    `include "scoreboard.svh"
    `include "env.svh"    
    `include "test.svh"   
endpackage