// File: tb_top.sv
// Testbench mo phong: Da fix loi fscanf va vld_bits

`timescale 1ns/1ps
import dram_config_pkg::*;

module tb_top;

    logic clk;
    logic rst_n;
    logic valid_i;
    logic [31:0] addr_i;
    logic type_i;
    logic ready_o;

    logic [1:0]  dram_cmd;
    logic [13:0] dram_row;
    logic [2:0]  dram_bank;

    memory_controller dut (
        .clk(clk), .rst_n(rst_n),
        .valid_i(valid_i), .addr_i(addr_i), .type_i(type_i), .ready_o(ready_o),
        .dram_cmd_o(dram_cmd), .dram_row_o(dram_row), .dram_bank_o(dram_bank)
    );

    initial begin
        clk = 0;
        forever #0.75 clk = ~clk;
    end

    int file_h;
    int status; // Bien de nhan ket qua tra ve cua fscanf
    string cmd_s;
    logic [31:0] addr_v;
    longint time_v;

    initial begin
        rst_n = 0;
        valid_i = 0;
        #10 rst_n = 1;

        file_h = $fopen("trace.txt", "r");
        if (!file_h) begin
            $display("Loi: Khong tim thay file trace.txt!");
            $finish;
        end

        while (!$feof(file_h)) begin
            // Sua loi fscanf: Gan vao bien status
            status = $fscanf(file_h, "%h %s %d\n", addr_v, cmd_s, time_v);
            
            if (status > 0) begin
                valid_i = 1;
                addr_i  = addr_v;
                type_i  = (cmd_s == "READ") ? 0 : 1;

                @(posedge clk);
                while (!ready_o) @(posedge clk); 
                
                valid_i = 0;
                $display("[%0t] CPU gui lenh: %s dia chi %h", $time, cmd_s, addr_v);
            end
        end

        // Sua loi vld_bits: Them hau to _o cho dung ten port trong request_queue
        wait (dut.queue_inst.vld_bits_o == 0);
        #100;
        $display("Mo phong hoan tat!");
        $fclose(file_h);
        $finish;
    end

    always @(posedge clk) begin
        if (dram_cmd != 0) begin
            $display("[%0t] DRAM CMD: %b | Bank: %d | Row: %d", $time, dram_cmd, dram_bank, dram_row);
        end
    end

endmodule