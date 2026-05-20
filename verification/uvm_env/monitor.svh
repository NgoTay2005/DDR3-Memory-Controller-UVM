// File: monitor.svh


class dram_monitor extends uvm_monitor;
    `uvm_component_utils(dram_monitor)

    virtual dram_if vif;
    uvm_analysis_port #(dram_transaction) item_collected_port;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        item_collected_port = new("item_collected_port", this);
    endfunction

    virtual task run_phase(uvm_phase phase);
        forever begin
            dram_transaction tr;
            @(posedge vif.clk);
            if (vif.valid_i && vif.ready_o) begin
                tr = dram_transaction::type_id::create("tr");
                tr.addr     = vif.addr_i;
                tr.is_write = vif.type_i;
                item_collected_port.write(tr); 
            end
        end
    endtask
endclass