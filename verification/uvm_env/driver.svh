// File: driver.svh


class dram_driver extends uvm_driver #(dram_transaction);
    `uvm_component_utils(dram_driver)

   
    virtual dram_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    
    virtual task run_phase(uvm_phase phase);
        vif.valid_i <= 0;
        vif.addr_i  <= 0;
        
        forever begin
            seq_item_port.get_next_item(req); // Lay goi tin tu Sequencer
            drive_item(req);                 // Thuc thi lai tin hieu
            seq_item_port.item_done();        
        end
    endtask

    task drive_item(dram_transaction tr);
        @(posedge vif.clk);
        vif.valid_i <= 1;
        vif.addr_i  <= tr.addr;
        vif.type_i  <= tr.is_write;
      
        do begin
            @(posedge vif.clk);
        end while (!vif.ready_o);
        
        vif.valid_i <= 0;
    endtask
endclass