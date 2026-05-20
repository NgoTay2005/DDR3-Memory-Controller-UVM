// File: dram_config_pkg.sv
// Thong so JEDEC DDR3-1333

package dram_config_pkg;

    // Kieu du lieu cho Mapping va Policy
    typedef enum logic [1:0] {
        MAP_ROW_BANK_COL = 2'b00,
        MAP_ROW_COL_BANK = 2'b01,
        MAP_XOR          = 2'b10
    } mapping_scheme_e;

    typedef enum logic {
        OPEN_PAGE  = 1'b0,
        CLOSE_PAGE = 1'b1
    } page_policy_e;

    // Cau hinh he thong
    parameter int NUM_BANKS      = 8;
    parameter int ROW_SIZE       = 1024; 
    parameter int MAX_QUEUE_SIZE = 8;    // Toi uu cho tong hop mach (Synthesis)

    // Timing JEDEC (Don vi: Clock cycles)
    parameter int T_CL    = 9;
    parameter int T_RCD   = 9;
    parameter int T_RP    = 9;
    parameter int T_RAS   = 24;
    parameter int T_RC    = 33;
    parameter int T_BURST = 4;
    parameter int T_CWD   = 7;
    parameter int T_CCD   = 4;
    parameter int T_WTR   = 5;
    parameter int T_WR    = 10;
    parameter int T_RTP   = 5;
    parameter int T_RRD   = 4;
    parameter int T_FAW   = 20;
    parameter int T_RFC   = 107;
    parameter int T_REFI  = 5200;

    // Thiet lap mac dinh
    parameter mapping_scheme_e DEFAULT_MAP    = MAP_XOR;
    parameter page_policy_e    DEFAULT_POLICY = OPEN_PAGE;

endpackage