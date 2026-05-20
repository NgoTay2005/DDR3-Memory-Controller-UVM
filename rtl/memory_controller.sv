// File: memory_controller.sv
// Module Top-level ket noi Queue, Scheduler va 8 Banks

import dram_config_pkg::*;

module memory_controller (
    input  logic        clk,
    input  logic        rst_n,
    
    // Giao tiep CPU
    input  logic        valid_i,
    input  logic [31:0] addr_i,
    input  logic        type_i,
    output logic        ready_o,
    
    // Giao tiep DRAM (Signals vat ly)
    output logic [1:0]  dram_cmd_o,   // 1: ACT, 2: PRE, 3: RD/WR, 0: NOP/REF
    output logic [13:0] dram_row_o,
    output logic [2:0]  dram_bank_o
);

    // 1. Khai bao tin hieu ket noi noi bo
    logic [MAX_QUEUE_SIZE-1:0] vld_bits;
    logic [31:0] addr_q [MAX_QUEUE_SIZE];
    logic        type_q [MAX_QUEUE_SIZE];
    logic [$clog2(MAX_QUEUE_SIZE)-1:0] pop_idx;
    logic        pop_vld;

    logic [NUM_BANKS-1:0] b_active, b_ready_act, b_ready_rdwr, b_ready_pre;
    logic [13:0] b_row [NUM_BANKS];
    logic [1:0]  b_cmd_bus [NUM_BANKS];

    logic [2:0]  sch_bank;
    logic [1:0]  sch_cmd;
    logic [13:0] sch_row;

    // 2. Logic Refresh (May trang thai 3 buoc)
    typedef enum logic [1:0] {ST_NORMAL, ST_PRE_ALL, ST_REF} refresh_state_e;
    refresh_state_e ref_state;
    logic [12:0] ref_cnt;
    logic [7:0]  rfc_timer;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ref_state <= ST_NORMAL;
            ref_cnt   <= T_REFI;
            rfc_timer <= 0;
        end else begin
            if (ref_cnt > 0) ref_cnt <= ref_cnt - 1;
            if (rfc_timer > 0) rfc_timer <= rfc_timer - 1;

            case (ref_state)
                ST_NORMAL:  if (ref_cnt == 0) ref_state <= ST_PRE_ALL;
                ST_PRE_ALL: if (&b_ready_act) ref_state <= ST_REF; // Cho tat ca bank idle
                ST_REF: begin
                    if (rfc_timer == 0 && ref_state == ST_REF) begin
                        ref_state <= ST_NORMAL;
                        ref_cnt   <= T_REFI;
                    end
                end
            endcase
            if (ref_state == ST_PRE_ALL && &b_ready_act) rfc_timer <= T_RFC;
        end
    end

    // 3. Khoi tao cac module con
    request_queue queue_inst (
        .clk(clk), .rst_n(rst_n),
        .push_i(valid_i), .addr_i(addr_i), .type_i(type_i),
        .pop_idx_i(pop_idx), .pop_vld_i(pop_vld),
        .ready_o(ready_o), .vld_bits_o(vld_bits), .addr_q_o(addr_q), .type_q_o(type_q)
    );

    scheduler sch_inst (
        .vld_bits_i(vld_bits), .addr_q_i(addr_q), .type_q_i(type_q),
        .bank_active_i(b_active), .bank_row_i(b_row),
        .ready_act_i(b_ready_act), .ready_rdwr_i(b_ready_rdwr), .ready_pre_i(b_ready_pre),
        .sel_bank_o(sch_bank), .cmd_o(sch_cmd), .row_o(sch_row),
        .pop_idx_o(pop_idx), .pop_vld_o(pop_vld)
    );

    generate
        for (genvar i = 0; i < NUM_BANKS; i++) begin : bank_gen
            bank_fsm bank_inst (
                .clk(clk), .rst_n(rst_n),
                .cmd_i(b_cmd_bus[i]), .row_i(sch_row),
                .is_active_o(b_active[i]), .is_idle_o(b_ready_act[i]),
                .curr_row_o(b_row[i]), .ready_act_o(), 
                .ready_rdwr_o(b_ready_rdwr[i]), .ready_pre_o(b_ready_pre[i])
            );
            // Phan phoi lenh tu Scheduler den dung Bank duoc chon
            assign b_cmd_bus[i] = (ref_state != ST_NORMAL) ? 2'b00 : // Khoa bank khi refresh
                                  (sch_bank == i) ? sch_cmd : 2'b00;
        end
    endgenerate

    // 4. Output Mux: Uu tien lenh tu Refresh FSM
    assign dram_cmd_o  = (ref_state == ST_PRE_ALL) ? 2'b10 : // PRE ALL
                         (ref_state == ST_REF)     ? 2'b00 : // REFRESH (NOP)
                         sch_cmd;
    assign dram_bank_o = (ref_state != ST_NORMAL) ? 3'b000 : sch_bank;
    assign dram_row_o  = sch_row;

endmodule