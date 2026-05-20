`timescale 1ns/1ps
import dram_config_pkg::*;

module tb_top;
    logic clk, rst_n;
    logic valid_i, type_i, ready_o;
    logic [31:0] addr_i;

    // Kết nối Controller
    memory_controller dut (
        .clk(clk), .rst_n(rst_n),
        .valid_i(valid_i), .addr_i(addr_i), .type_i(type_i),
        .ready_o(ready_o), .dram_cmd_o(), .dram_row_o(), .dram_bank_o()
    );

    // Tạo Clock 667MHz
    initial begin clk = 0; forever #0.75 clk = ~clk; end

    // Logic đọc file trace.txt
    initial begin
        int file_h, status;
        logic [31:0] addr_v;
        string cmd_s;
        longint time_v;

        {valid_i, rst_n} = 2'b00; #10 rst_n = 1;
        file_h = $fopen("trace.txt", "r");
        
        if (!file_h) begin $display("Loi: Khong tim thay trace.txt"); $finish; end

        while (!$feof(file_h)) begin
            status = $fscanf(file_h, "%h %s %d\n", addr_v, cmd_s, time_v);
            if (status > 0) begin
                wait (time_v <= $time);
                @(posedge clk);
                valid_i = 1; addr_i = addr_v; type_i = (cmd_s == "WRITE");
                $display("[%0t] CPU gui lenh: %s dia chi %h", $time, cmd_s, addr_v);
                @(posedge clk);
                while (!ready_o) @(posedge clk);
                valid_i = 0;
            end
        end
        #1000; $display("Mo phong hoan tat!"); $finish;
    end
endmodule
