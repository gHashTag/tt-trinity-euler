`default_nettype none
// trinity_instr_rom.v — 32-deep x 16-bit Wishbone-programmable instruction ROM
// Apache-2.0
//
// 16-bit instruction format:
//   [15:13] opcode  (3 bits)  — 8 ternary opcodes
//   [12:8]  dst_reg (5 bits)
//   [7:3]   src_reg (5 bits)
//   [2:0]   imm3    (3 bits)  — immediate or branch offset
//
// Wishbone-lite write port:
//   wb_cyc & wb_stb & wb_we & !wb_ack  => latch wb_dat_w into mem[wb_adr[4:0]]
//
// Pre-loaded with a canonical boot program (32 NOPs by default, overridden by
// the wb write port before sequencer enable).
//
// PhD anchor: phi^2 + phi^-2 = 3 — Glava 18 (Ternary ISA)
// DOI: 10.5281/zenodo.19227877

module trinity_instr_rom (
    input  wire        clk,
    input  wire        rst_n,

    // Read port (from micro-sequencer)
    input  wire [4:0]  pc,
    output wire [15:0] instr,

    // Wishbone-lite write port (program-ROM at runtime)
    input  wire        wb_cyc,
    input  wire        wb_stb,
    input  wire        wb_we,
    input  wire [4:0]  wb_adr,
    input  wire [15:0] wb_dat_w,
    output reg         wb_ack
);

    // 32 x 16-bit registers — synthesises to ~512 flops (~512 cells)
    // Each reg on its own line (R-SI-1 / Verilog-2005 style)
    reg [15:0] mem_00;
    reg [15:0] mem_01;
    reg [15:0] mem_02;
    reg [15:0] mem_03;
    reg [15:0] mem_04;
    reg [15:0] mem_05;
    reg [15:0] mem_06;
    reg [15:0] mem_07;
    reg [15:0] mem_08;
    reg [15:0] mem_09;
    reg [15:0] mem_10;
    reg [15:0] mem_11;
    reg [15:0] mem_12;
    reg [15:0] mem_13;
    reg [15:0] mem_14;
    reg [15:0] mem_15;
    reg [15:0] mem_16;
    reg [15:0] mem_17;
    reg [15:0] mem_18;
    reg [15:0] mem_19;
    reg [15:0] mem_20;
    reg [15:0] mem_21;
    reg [15:0] mem_22;
    reg [15:0] mem_23;
    reg [15:0] mem_24;
    reg [15:0] mem_25;
    reg [15:0] mem_26;
    reg [15:0] mem_27;
    reg [15:0] mem_28;
    reg [15:0] mem_29;
    reg [15:0] mem_30;
    reg [15:0] mem_31;

    // Opcode constants (for default boot program readability)
    // 3'b000 = NOP, 3'b111 = HALT
    // Default: NOP at [0..30], HALT at [31]
    localparam [15:0] INSTR_NOP  = 16'h0000; // opcode=000 dst=0 src=0 imm=0
    localparam [15:0] INSTR_HALT = 16'hE000; // opcode=111 (HALT)

    // Wishbone write sequencer
    wire wb_wr_pulse = wb_cyc & wb_stb & wb_we & ~wb_ack;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wb_ack  <= 1'b0;
            // Boot program: NOPs then HALT
            mem_00 <= INSTR_NOP;
            mem_01 <= INSTR_NOP;
            mem_02 <= INSTR_NOP;
            mem_03 <= INSTR_NOP;
            mem_04 <= INSTR_NOP;
            mem_05 <= INSTR_NOP;
            mem_06 <= INSTR_NOP;
            mem_07 <= INSTR_NOP;
            mem_08 <= INSTR_NOP;
            mem_09 <= INSTR_NOP;
            mem_10 <= INSTR_NOP;
            mem_11 <= INSTR_NOP;
            mem_12 <= INSTR_NOP;
            mem_13 <= INSTR_NOP;
            mem_14 <= INSTR_NOP;
            mem_15 <= INSTR_NOP;
            mem_16 <= INSTR_NOP;
            mem_17 <= INSTR_NOP;
            mem_18 <= INSTR_NOP;
            mem_19 <= INSTR_NOP;
            mem_20 <= INSTR_NOP;
            mem_21 <= INSTR_NOP;
            mem_22 <= INSTR_NOP;
            mem_23 <= INSTR_NOP;
            mem_24 <= INSTR_NOP;
            mem_25 <= INSTR_NOP;
            mem_26 <= INSTR_NOP;
            mem_27 <= INSTR_NOP;
            mem_28 <= INSTR_NOP;
            mem_29 <= INSTR_NOP;
            mem_30 <= INSTR_NOP;
            mem_31 <= INSTR_HALT; // default boot: halt at PC=31
        end else begin
            wb_ack <= wb_wr_pulse;
            if (wb_wr_pulse) begin
                // Wishbone write: decode address, update selected cell
                case (wb_adr)
                    5'd0:  mem_00 <= wb_dat_w;
                    5'd1:  mem_01 <= wb_dat_w;
                    5'd2:  mem_02 <= wb_dat_w;
                    5'd3:  mem_03 <= wb_dat_w;
                    5'd4:  mem_04 <= wb_dat_w;
                    5'd5:  mem_05 <= wb_dat_w;
                    5'd6:  mem_06 <= wb_dat_w;
                    5'd7:  mem_07 <= wb_dat_w;
                    5'd8:  mem_08 <= wb_dat_w;
                    5'd9:  mem_09 <= wb_dat_w;
                    5'd10: mem_10 <= wb_dat_w;
                    5'd11: mem_11 <= wb_dat_w;
                    5'd12: mem_12 <= wb_dat_w;
                    5'd13: mem_13 <= wb_dat_w;
                    5'd14: mem_14 <= wb_dat_w;
                    5'd15: mem_15 <= wb_dat_w;
                    5'd16: mem_16 <= wb_dat_w;
                    5'd17: mem_17 <= wb_dat_w;
                    5'd18: mem_18 <= wb_dat_w;
                    5'd19: mem_19 <= wb_dat_w;
                    5'd20: mem_20 <= wb_dat_w;
                    5'd21: mem_21 <= wb_dat_w;
                    5'd22: mem_22 <= wb_dat_w;
                    5'd23: mem_23 <= wb_dat_w;
                    5'd24: mem_24 <= wb_dat_w;
                    5'd25: mem_25 <= wb_dat_w;
                    5'd26: mem_26 <= wb_dat_w;
                    5'd27: mem_27 <= wb_dat_w;
                    5'd28: mem_28 <= wb_dat_w;
                    5'd29: mem_29 <= wb_dat_w;
                    5'd30: mem_30 <= wb_dat_w;
                    5'd31: mem_31 <= wb_dat_w;
                    default: ; // no write
                endcase
            end
        end
    end

    // Combinational read port — select the correct mem cell based on PC
    reg [15:0] instr_mux;
    always @(*) begin
        case (pc)
            5'd0:  instr_mux = mem_00;
            5'd1:  instr_mux = mem_01;
            5'd2:  instr_mux = mem_02;
            5'd3:  instr_mux = mem_03;
            5'd4:  instr_mux = mem_04;
            5'd5:  instr_mux = mem_05;
            5'd6:  instr_mux = mem_06;
            5'd7:  instr_mux = mem_07;
            5'd8:  instr_mux = mem_08;
            5'd9:  instr_mux = mem_09;
            5'd10: instr_mux = mem_10;
            5'd11: instr_mux = mem_11;
            5'd12: instr_mux = mem_12;
            5'd13: instr_mux = mem_13;
            5'd14: instr_mux = mem_14;
            5'd15: instr_mux = mem_15;
            5'd16: instr_mux = mem_16;
            5'd17: instr_mux = mem_17;
            5'd18: instr_mux = mem_18;
            5'd19: instr_mux = mem_19;
            5'd20: instr_mux = mem_20;
            5'd21: instr_mux = mem_21;
            5'd22: instr_mux = mem_22;
            5'd23: instr_mux = mem_23;
            5'd24: instr_mux = mem_24;
            5'd25: instr_mux = mem_25;
            5'd26: instr_mux = mem_26;
            5'd27: instr_mux = mem_27;
            5'd28: instr_mux = mem_28;
            5'd29: instr_mux = mem_29;
            5'd30: instr_mux = mem_30;
            5'd31: instr_mux = mem_31;
            default: instr_mux = INSTR_NOP;
        endcase
    end

    assign instr = instr_mux;

endmodule
