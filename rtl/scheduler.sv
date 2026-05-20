// File: scheduler.sv
// Bo lap lich FR-FCFS: Uu tien Row Hit va chong Starvation

import dram_config_pkg::*;

module scheduler (
    // Tu Queue
    input  logic [MAX_QUEUE_SIZE-1:0] vld_bits_i,
    input  logic [31:0]               addr_q_i [MAX_QUEUE_SIZE],
    input  logic                      type_q_i [MAX_QUEUE_SIZE],
    
    // Tu Bank FSMs (Mang 8 Banks)
    input  logic [NUM_BANKS-1:0]      bank_active_i,
    input  logic [13:0]               bank_row_i [NUM_BANKS],
    input  logic [NUM_BANKS-1:0]      ready_act_i,
    input  logic [NUM_BANKS-1:0]      ready_rdwr_i,
    input  logic [NUM_BANKS-1:0]      ready_pre_i,
    
    // Dau ra dieu khien
    output logic [2:0]                sel_bank_o,
    output logic [1:0]                cmd_o,       // 1: ACT, 2: PRE, 3: RD/WR
    output logic [13:0]               row_o,
    output logic [$clog2(MAX_QUEUE_SIZE)-1:0] pop_idx_o,
    output logic                      pop_vld_o
);

    // Giai ma dia chi cho tung o trong Queue
    logic [13:0] q_row  [MAX_QUEUE_SIZE];
    logic [2:0]  q_bank [MAX_QUEUE_SIZE];

    generate
        for (genvar i = 0; i < MAX_QUEUE_SIZE; i++) begin : addr_dec
            address_mapper mapper_inst (
                .addr_i (addr_q_i[i]),
                .row_o  (q_row[i]),
                .bank_o (q_bank[i]),
                .col_o  ()
            );
        end
    endgenerate

    // Tinh toan trang thai tung Request
    logic [MAX_QUEUE_SIZE-1:0] is_row_hit;
    logic [MAX_QUEUE_SIZE-1:0] can_rdwr;
    logic [MAX_QUEUE_SIZE-1:0] can_act;
    logic [MAX_QUEUE_SIZE-1:0] can_pre;

    always_comb begin
        for (int i = 0; i < MAX_QUEUE_SIZE; i++) begin
            is_row_hit[i] = vld_bits_i[i] && bank_active_i[q_bank[i]] && (bank_row_i[q_bank[i]] == q_row[i]);
            can_rdwr[i]   = is_row_hit[i] && ready_rdwr_i[q_bank[i]];
            can_act[i]    = vld_bits_i[i] && !bank_active_i[q_bank[i]] && ready_act_i[q_bank[i]];
            can_pre[i]    = vld_bits_i[i] && bank_active_i[q_bank[i]] && (bank_row_i[q_bank[i]] != q_row[i]) && ready_pre_i[q_bank[i]];
        end
    end

    // Bo phan xu uu tien (Priority Arbiter)
    always_comb begin
        pop_vld_o  = 1'b0;
        pop_idx_o  = 0;
        sel_bank_o = 0;
        cmd_o      = 0;
        row_o      = 0;

        // Uu tien 1: Row Hit (San sang RD/WR ngay lap tuc)
        for (int i = 0; i < MAX_QUEUE_SIZE; i++) begin
            if (can_rdwr[i] && !pop_vld_o) begin
                pop_vld_o  = 1'b1;
                pop_idx_o  = i;
                cmd_o      = 2'b11; // RD/WR
                sel_bank_o = q_bank[i];
            end
        end

        // Uu tien 2: Oldest Ready (ACT hoac PRE cho yeu cau den som nhat)
        if (!pop_vld_o) begin
            for (int i = 0; i < MAX_QUEUE_SIZE; i++) begin
                if (!pop_vld_o) begin
                    if (can_act[i]) begin
                        pop_vld_o  = 1'b1;
                        pop_idx_o  = i;
                        cmd_o      = 2'b01; // ACT
                        sel_bank_o = q_bank[i];
                        row_o      = q_row[i];
                    end else if (can_pre[i]) begin
                        pop_vld_o  = 1'b1;
                        pop_idx_o  = i;
                        cmd_o      = 2'b10; // PRE
                        sel_bank_o = q_bank[i];
                    end
                end
            end
        end
    end

endmodule