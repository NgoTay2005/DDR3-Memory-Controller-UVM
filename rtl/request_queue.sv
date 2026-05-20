// File: request_queue.sv
// Luu tru cac yeu cau tu CPU truoc khi lap lich

import dram_config_pkg::*;

module request_queue (
    input  logic        clk,
    input  logic        rst_n,
    
    // Giao tiep voi CPU (Input)
    input  logic        push_i,
    input  logic [31:0] addr_i,
    input  logic        type_i,      // 0: READ, 1: WRITE
    
    // Giao tiep voi Scheduler (Output)
    input  logic [$clog2(MAX_QUEUE_SIZE)-1:0] pop_idx_i,
    input  logic        pop_vld_i,
    
    output logic        ready_o,     // Bao cho CPU biet hang doi chua day
    output logic [MAX_QUEUE_SIZE-1:0] vld_bits_o,
    output logic [31:0] addr_q_o [MAX_QUEUE_SIZE],
    output logic        type_q_o [MAX_QUEUE_SIZE]
);

    logic [MAX_QUEUE_SIZE-1:0] vld_reg;
    logic [31:0] addr_reg [MAX_QUEUE_SIZE];
    logic        type_reg [MAX_QUEUE_SIZE];

    // Tim vi tri trong dau tien de day lenh moi vao
    logic [$clog2(MAX_QUEUE_SIZE)-1:0] free_slot;
    logic found_free;

    always_comb begin
        found_free = 0;
        free_slot = 0;
        for (int i = 0; i < MAX_QUEUE_SIZE; i++) begin
            if (!vld_reg[i] && !found_free) begin
                free_slot = i;
                found_free = 1;
            end
        end
    end

    assign ready_o = found_free;
    assign vld_bits_o = vld_reg;
    assign addr_q_o = addr_reg;
    assign type_q_o = type_reg;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            vld_reg <= '0;
        end else begin
            // Them lenh moi vao hang doi (Backpressure logic)
            if (push_i && ready_o) begin
                vld_reg[free_slot] <= 1'b1;
                addr_reg[free_slot] <= addr_i;
                type_reg[free_slot] <= type_i;
            end
            
            // Xoa lenh da duoc thuc thi (Dung pop_idx tu Scheduler)
            if (pop_vld_i) begin
                vld_reg[pop_idx_i] <= 1'b0;
            end
        end
    end

endmodule