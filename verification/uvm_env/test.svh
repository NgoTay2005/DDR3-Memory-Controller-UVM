
// File: test.svh

class base_test extends uvm_test;
    // Đăng ký lớp vào Factory của UVM
    `uvm_component_utils(base_test)

    
    dram_env env;

    
    function new(string name = "base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // Khởi tạo Environment
        env = dram_env::type_id::create("env", this);
    endfunction

    
    virtual task run_phase(uvm_phase phase);
        
        trace_sequence seq; 
        
        
        seq = trace_sequence::type_id::create("seq");

        
        phase.raise_objection(this);
        
        `uvm_info("TEST_TOP", "--- Kích hoạt kịch bản: DOC FILE TRACE ---", UVM_LOW)

        
        seq.start(env.sqr); 

        
        #1000;

        `uvm_info("TEST_TOP", "--- Hoàn tất kịch bản. Đang đóng mô phỏng... ---", UVM_LOW)

        
        phase.drop_objection(this); 
    endtask

endclass