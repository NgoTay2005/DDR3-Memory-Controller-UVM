class dram_env extends uvm_env;
    `uvm_component_utils(dram_env)

    dram_driver     drv;
    dram_monitor    mon;
    dram_scoreboard scb;
    dram_sequencer  sqr; 

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        drv = dram_driver::type_id::create("drv", this);
        mon = dram_monitor::type_id::create("mon", this);
        scb = dram_scoreboard::type_id::create("scb", this);
        sqr = dram_sequencer::type_id::create("sqr", this); 
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        mon.item_collected_port.connect(scb.item_export);
        
        
        drv.seq_item_port.connect(sqr.seq_item_export);
    endfunction
endclass