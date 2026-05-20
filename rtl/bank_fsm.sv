// File: bank_fsm.sv
// Quan ly trang thai va bo dem thoi gian JEDEC cho tung Bank

import dram_config_pkg::*;

module bank_fsm (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [1:0]  cmd_i,       // 0: NOP, 1: ACT, 2: PRE, 3: RD/WR
    input  logic [13:0] row_i,
    output logic        is_idle_o,   // Bank dang dong hoan toan
    output logic        is_active_o, // Bank dang mo mot hang
    output logic [13:0] curr_row_o,
    output logic        ready_act_o, // San sang nhan lenh ACT
    output logic        ready_rdwr_o,// San sang nhan lenh READ/WRITE
    output logic        ready_pre_o  // San sang nhan lenh PRE
);

    typedef enum logic [1:0] {IDLE, ACTIVATING, ACTIVE, PRECHARGING} state_e;
    state_e state;

    // Cac bo dem lui de quan ly thoi gian thuc thi
    logic [7:0] timer; 
    logic [13:0] open_row;

    assign is_idle_o   = (state == IDLE);
    assign is_active_o = (state == ACTIVE);
    assign curr_row_o  = open_row;

    // Logic kiem tra dieu kien thoi gian (Core logic)
    assign ready_act_o  = (state == IDLE) && (timer == 0);
    assign ready_rdwr_o = (state == ACTIVE) && (timer == 0);
    assign ready_pre_o  = (state == ACTIVE) && (timer == 0);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            timer <= 0;
            open_row <= 0;
        end else begin
            // Bo dem lui o moi chu ky clock
            if (timer > 0) timer <= timer - 1;

            case (state)
                IDLE: begin
                    if (cmd_i == 2'b01) begin // Lenh ACT
                        state <= ACTIVATING;
                        timer <= T_RCD - 1; // Cho phep R/W sau tRCD
                        open_row <= row_i;
                    end
                end

                ACTIVATING: begin
                    if (timer == 0) state <= ACTIVE;
                end

                ACTIVE: begin
                    if (cmd_i == 2'b11) begin // Lenh READ/WRITE
                        timer <= T_BURST - 1; // Khoa bus trong thoi gian burst
                    end else if (cmd_i == 2'b10) begin // Lenh PRE
                        state <= PRECHARGING;
                        timer <= T_RP - 1; // Cho phep ACT sau tRP
                        open_row <= 0;
                    end
                end

                PRECHARGING: begin
                    if (timer == 0) state <= IDLE;
                end
            endcase
        end
    end

endmodule