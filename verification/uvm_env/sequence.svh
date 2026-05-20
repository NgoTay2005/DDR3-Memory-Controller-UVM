// File: sequence.svh


class trace_sequence extends uvm_sequence #(dram_transaction);
    `uvm_object_utils(trace_sequence)

    function new(string name = "trace_sequence");
        super.new(name);
    endfunction

    virtual task body();
        int file_h;
        int status;
        string cmd_s;
        logic [31:0] addr_v;
        longint time_v;

        file_h = $fopen("trace.txt", "r");
        if (!file_h) begin
            `uvm_error("SEQ", "Khong tim thay file trace.txt!")
            return;
        end

        while (!$feof(file_h)) begin
            status = $fscanf(file_h, "%h %s %d\n", addr_v, cmd_s, time_v);
            if (status > 0) begin
                
                req = dram_transaction::type_id::create("req");
                
                start_item(req);
                req.addr = addr_v;
                req.is_write = (cmd_s == "WRITE");
                finish_item(req);
                
                `uvm_info("SEQ", $sformatf("Da nap lenh tu trace: %s", cmd_s), UVM_HIGH)
            end
        end
        $fclose(file_h);
    endtask
endclass