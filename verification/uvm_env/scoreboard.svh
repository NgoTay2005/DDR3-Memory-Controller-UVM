// File: scoreboard.svh


class dram_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(dram_scoreboard)
    uvm_analysis_imp #(dram_transaction, dram_scoreboard) item_export;

    int total_req = 0;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
        item_export = new("item_export", this);
    endfunction

    
    virtual function void write(dram_transaction tr);
        total_req++;
        `uvm_info("SCB", $sformatf("Nhan duoc lenh %s tai dia chi %h", 
                  (tr.is_write ? "WRITE" : "READ"), tr.addr), UVM_LOW)
       
    endfunction

    virtual function void report_phase(uvm_phase phase);
        `uvm_info("SCB", $sformatf("Tong ket mo phong: %d requests da xu ly", total_req), UVM_LOW)
    endfunction
endclass