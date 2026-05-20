// File: address_mapper.sv
// Giai ma dia chi CPU sang Row, Bank, Col dung MAP_XOR

import dram_config_pkg::*;

module address_mapper (
    input  logic [31:0] addr_i,
    output logic [13:0] row_o,
    output logic [2:0]  bank_o,
    output logic [9:0]  col_o
);

    logic [2:0] row_xor_part;

    // Tach bit theo cau truc: [Row: 26-13] [Bank: 12-10] [Column: 9-0]
    assign col_o = addr_i[9:0];
    assign row_o = addr_i[26:13];

    // Logic MAP_XOR: XOR 3-bit Bank voi 3-bit Row (bit 18-20) de phan tan du lieu
    assign row_xor_part = addr_i[20:18];
    assign bank_o       = addr_i[12:10] ^ row_xor_part;

endmodule