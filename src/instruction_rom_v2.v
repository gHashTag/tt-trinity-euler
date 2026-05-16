`default_nettype none
// instruction_rom_v2.v — 64-deep x 16-bit CLARA-extended instruction ROM
// EULER ISA v2 — TRI-27 + 32 CLARA opcodes
// Apache-2.0
//
// ============================================================================
// 16-bit instruction word format (unchanged from v1):
//   [15:13] func3   (3 bits)  — sub-function / condition
//   [12:8]  dst_reg (5 bits)
//   [7:3]   src_reg (5 bits)
//   [2:0]   imm3    (3 bits)  — immediate or branch offset
//
// 6-bit opcode address space:
//   addr[5] = 0  → TRI-27 original ops   (addresses 0x00..0x1F)
//   addr[5] = 1  → CLARA ops             (addresses 0x20..0x3F)
//     addr[5:4] = 10 → K3 logic ops      (addresses 0x20..0x2F, 16 ops)
//     addr[5:4] = 11 → ASP solver ops    (addresses 0x30..0x3F, 16 ops)
//
// Backward compatibility: addresses 0x00..0x1F are byte-identical to
// trinity_instr_rom.v defaults (NOPs + HALT at addr 31).
//
// ROM only — no execution unit (Phase 2 silicon).
// Wishbone-lite write port retained for runtime programmability.
//
// PhD anchor: phi^2 + phi^-2 = 3 — Glava 18 (Ternary ISA) + Glava 28 (CLARA)
// DOI: 10.5281/zenodo.19227877
// Watermark: 0x47C0
// ============================================================================

module instruction_rom_v2 (
    input  wire        clk,
    input  wire        rst_n,

    // Read port (6-bit PC for 64-entry ROM)
    input  wire [5:0]  pc,
    output wire [15:0] instr,

    // Wishbone-lite write port
    input  wire        wb_cyc,
    input  wire        wb_stb,
    input  wire        wb_we,
    input  wire [5:0]  wb_adr,
    input  wire [15:0] wb_dat_w,
    output reg         wb_ack
);

    // -------------------------------------------------------------------------
    // Default instruction templates
    // -------------------------------------------------------------------------
    // Original TRI-27 boot defaults (must be byte-identical to v1)
    localparam [15:0] INSTR_NOP  = 16'h0000; // opcode=000 dst=0 src=0 imm=0
    localparam [15:0] INSTR_HALT = 16'hE000; // opcode=111 (HALT) — addr 31

    // CLARA K3 logic op defaults (addr 0x20..0x2F)
    // Encoding: func3=000, dst_reg=K3_dst placeholder=5'b00001, src_reg=5'b00001, imm3=sub-op
    // Full K3 semantics decoded by k3_alu.v execution unit (Phase 2)
    // addr 0x20 — k3_and   : K3 Kleene AND          — func3=001, opcode-tag=6'h20
    localparam [15:0] INSTR_K3_AND    = 16'b001_00001_00001_000; // 0x2208
    // addr 0x21 — k3_or    : K3 Kleene OR           — func3=001
    localparam [15:0] INSTR_K3_OR     = 16'b001_00001_00001_001; // 0x2209
    // addr 0x22 — k3_not   : K3 Kleene NOT (unary)  — func3=001
    localparam [15:0] INSTR_K3_NOT    = 16'b001_00001_00001_010; // 0x220A
    // addr 0x23 — k3_min   : ternary minimum        — func3=001
    localparam [15:0] INSTR_K3_MIN    = 16'b001_00001_00001_011; // 0x220B
    // addr 0x24 — k3_max   : ternary maximum        — func3=001
    localparam [15:0] INSTR_K3_MAX    = 16'b001_00010_00001_000; // 0x2408
    // addr 0x25 — k3_xor   : ternary XOR (mod-3 add)— func3=001
    localparam [15:0] INSTR_K3_XOR    = 16'b001_00010_00001_001; // 0x2409
    // addr 0x26 — k3_imp   : K3 Kleene implication  — func3=001
    localparam [15:0] INSTR_K3_IMP    = 16'b001_00010_00001_010; // 0x240A
    // addr 0x27 — k3_equiv : K3 bi-implication      — func3=001
    localparam [15:0] INSTR_K3_EQUIV  = 16'b001_00010_00001_011; // 0x240B
    // addr 0x28 — k3_nand  : K3 NAND                — func3=010
    localparam [15:0] INSTR_K3_NAND   = 16'b010_00001_00001_000; // 0x4208
    // addr 0x29 — k3_nor   : K3 NOR                 — func3=010
    localparam [15:0] INSTR_K3_NOR    = 16'b010_00001_00001_001; // 0x4209
    // addr 0x2A — k3_xnor  : K3 XNOR                — func3=010
    localparam [15:0] INSTR_K3_XNOR   = 16'b010_00001_00001_010; // 0x420A
    // addr 0x2B — k3_luk   : Lukasiewicz implication — func3=010
    localparam [15:0] INSTR_K3_LUK    = 16'b010_00001_00001_011; // 0x420B
    // addr 0x2C — k3_consensus : ternary consensus   — func3=010
    localparam [15:0] INSTR_K3_CONS   = 16'b010_00010_00001_000; // 0x4408
    // addr 0x2D — k3_threshold : 3-val threshold     — func3=010
    localparam [15:0] INSTR_K3_THRESH = 16'b010_00010_00001_001; // 0x4409
    // addr 0x2E — k3_select    : ternary MUX         — func3=010
    localparam [15:0] INSTR_K3_SEL    = 16'b010_00010_00001_010; // 0x440A
    // addr 0x2F — k3_reduce    : ternary reduce/fold  — func3=010
    localparam [15:0] INSTR_K3_RED    = 16'b010_00010_00001_011; // 0x440B

    // CLARA ASP solver op defaults (addr 0x30..0x3F)
    // func3=011 marks ASP ops; imm3 encodes sub-type
    // addr 0x30 — asp_fact        : assert ground fact   — func3=011
    localparam [15:0] INSTR_ASP_FACT    = 16'b011_00001_00001_000; // 0x6208
    // addr 0x31 — asp_rule_apply  : apply Datalog rule   — func3=011
    localparam [15:0] INSTR_ASP_RULE    = 16'b011_00001_00001_001; // 0x6209
    // addr 0x32 — asp_negation    : NAF negation-as-failure — func3=011
    localparam [15:0] INSTR_ASP_NEG     = 16'b011_00001_00001_010; // 0x620A
    // addr 0x33 — asp_stable_check: stable-model membership — func3=011
    localparam [15:0] INSTR_ASP_STABLE  = 16'b011_00001_00001_011; // 0x620B
    // addr 0x34 — asp_choice      : choice rule head       — func3=011
    localparam [15:0] INSTR_ASP_CHOICE  = 16'b011_00010_00001_000; // 0x6408
    // addr 0x35 — asp_constraint  : integrity constraint   — func3=011
    localparam [15:0] INSTR_ASP_CONSTR  = 16'b011_00010_00001_001; // 0x6409
    // addr 0x36 — asp_aggregate   : aggregate (count/sum)  — func3=011
    localparam [15:0] INSTR_ASP_AGGR    = 16'b011_00010_00001_010; // 0x640A
    // addr 0x37 — asp_propagate   : BCP unit propagation   — func3=011
    localparam [15:0] INSTR_ASP_PROP    = 16'b011_00010_00001_011; // 0x640B
    // addr 0x38 — asp_backtrack   : backtrack / undo       — func3=100
    localparam [15:0] INSTR_ASP_BT      = 16'b100_00001_00001_000; // 0x8208
    // addr 0x39 — asp_unify       : unification step       — func3=100
    localparam [15:0] INSTR_ASP_UNIFY   = 16'b100_00001_00001_001; // 0x8209
    // addr 0x3A — asp_resolve     : resolution step        — func3=100
    localparam [15:0] INSTR_ASP_RESOLVE = 16'b100_00001_00001_010; // 0x820A
    // addr 0x3B — asp_ground      : grounding pass         — func3=100
    localparam [15:0] INSTR_ASP_GROUND  = 16'b100_00001_00001_011; // 0x820B
    // addr 0x3C — asp_justify     : produce justification  — func3=100
    localparam [15:0] INSTR_ASP_JUST    = 16'b100_00010_00001_000; // 0x8408
    // addr 0x3D — asp_explain     : push explanation token — func3=100
    localparam [15:0] INSTR_ASP_EXPL    = 16'b100_00010_00001_001; // 0x8409
    // addr 0x3E — asp_commit      : commit answer-set      — func3=100
    localparam [15:0] INSTR_ASP_COMMIT  = 16'b100_00010_00001_010; // 0x840A
    // addr 0x3F — asp_halt_solver : terminate ASP solver   — func3=111
    localparam [15:0] INSTR_ASP_HALT    = 16'b111_11111_11111_111; // 0xFFFF (all-ones sentinel)

    // -------------------------------------------------------------------------
    // Storage — 64 x 16-bit registers (Verilog-2005: one reg per line)
    // -------------------------------------------------------------------------
    // Addresses 0x00..0x1F — TRI-27 original (backward-compat)
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
    // Addresses 0x20..0x2F — K3 logic ops
    reg [15:0] mem_32;
    reg [15:0] mem_33;
    reg [15:0] mem_34;
    reg [15:0] mem_35;
    reg [15:0] mem_36;
    reg [15:0] mem_37;
    reg [15:0] mem_38;
    reg [15:0] mem_39;
    reg [15:0] mem_40;
    reg [15:0] mem_41;
    reg [15:0] mem_42;
    reg [15:0] mem_43;
    reg [15:0] mem_44;
    reg [15:0] mem_45;
    reg [15:0] mem_46;
    reg [15:0] mem_47;
    // Addresses 0x30..0x3F — ASP solver ops
    reg [15:0] mem_48;
    reg [15:0] mem_49;
    reg [15:0] mem_50;
    reg [15:0] mem_51;
    reg [15:0] mem_52;
    reg [15:0] mem_53;
    reg [15:0] mem_54;
    reg [15:0] mem_55;
    reg [15:0] mem_56;
    reg [15:0] mem_57;
    reg [15:0] mem_58;
    reg [15:0] mem_59;
    reg [15:0] mem_60;
    reg [15:0] mem_61;
    reg [15:0] mem_62;
    reg [15:0] mem_63;

    // -------------------------------------------------------------------------
    // Wishbone write sequencer
    // -------------------------------------------------------------------------
    wire wb_wr_pulse = wb_cyc & wb_stb & wb_we & ~wb_ack;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wb_ack <= 1'b0;

            // -------------------------------------------------------------------
            // Boot program — TRI-27 original (addr 0x00..0x1F, byte-identical to v1)
            // -------------------------------------------------------------------
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
            mem_31 <= INSTR_HALT;   // addr 31 = HALT (byte-identical to v1)

            // -------------------------------------------------------------------
            // CLARA K3 logic ops (addr 0x20..0x2F)
            // -------------------------------------------------------------------
            mem_32 <= INSTR_K3_AND;
            mem_33 <= INSTR_K3_OR;
            mem_34 <= INSTR_K3_NOT;
            mem_35 <= INSTR_K3_MIN;
            mem_36 <= INSTR_K3_MAX;
            mem_37 <= INSTR_K3_XOR;
            mem_38 <= INSTR_K3_IMP;
            mem_39 <= INSTR_K3_EQUIV;
            mem_40 <= INSTR_K3_NAND;
            mem_41 <= INSTR_K3_NOR;
            mem_42 <= INSTR_K3_XNOR;
            mem_43 <= INSTR_K3_LUK;
            mem_44 <= INSTR_K3_CONS;
            mem_45 <= INSTR_K3_THRESH;
            mem_46 <= INSTR_K3_SEL;
            mem_47 <= INSTR_K3_RED;

            // -------------------------------------------------------------------
            // CLARA ASP solver ops (addr 0x30..0x3F)
            // -------------------------------------------------------------------
            mem_48 <= INSTR_ASP_FACT;
            mem_49 <= INSTR_ASP_RULE;
            mem_50 <= INSTR_ASP_NEG;
            mem_51 <= INSTR_ASP_STABLE;
            mem_52 <= INSTR_ASP_CHOICE;
            mem_53 <= INSTR_ASP_CONSTR;
            mem_54 <= INSTR_ASP_AGGR;
            mem_55 <= INSTR_ASP_PROP;
            mem_56 <= INSTR_ASP_BT;
            mem_57 <= INSTR_ASP_UNIFY;
            mem_58 <= INSTR_ASP_RESOLVE;
            mem_59 <= INSTR_ASP_GROUND;
            mem_60 <= INSTR_ASP_JUST;
            mem_61 <= INSTR_ASP_EXPL;
            mem_62 <= INSTR_ASP_COMMIT;
            mem_63 <= INSTR_ASP_HALT;

        end else begin
            wb_ack <= wb_wr_pulse;
            if (wb_wr_pulse) begin
                case (wb_adr)
                    6'd0:  mem_00 <= wb_dat_w;
                    6'd1:  mem_01 <= wb_dat_w;
                    6'd2:  mem_02 <= wb_dat_w;
                    6'd3:  mem_03 <= wb_dat_w;
                    6'd4:  mem_04 <= wb_dat_w;
                    6'd5:  mem_05 <= wb_dat_w;
                    6'd6:  mem_06 <= wb_dat_w;
                    6'd7:  mem_07 <= wb_dat_w;
                    6'd8:  mem_08 <= wb_dat_w;
                    6'd9:  mem_09 <= wb_dat_w;
                    6'd10: mem_10 <= wb_dat_w;
                    6'd11: mem_11 <= wb_dat_w;
                    6'd12: mem_12 <= wb_dat_w;
                    6'd13: mem_13 <= wb_dat_w;
                    6'd14: mem_14 <= wb_dat_w;
                    6'd15: mem_15 <= wb_dat_w;
                    6'd16: mem_16 <= wb_dat_w;
                    6'd17: mem_17 <= wb_dat_w;
                    6'd18: mem_18 <= wb_dat_w;
                    6'd19: mem_19 <= wb_dat_w;
                    6'd20: mem_20 <= wb_dat_w;
                    6'd21: mem_21 <= wb_dat_w;
                    6'd22: mem_22 <= wb_dat_w;
                    6'd23: mem_23 <= wb_dat_w;
                    6'd24: mem_24 <= wb_dat_w;
                    6'd25: mem_25 <= wb_dat_w;
                    6'd26: mem_26 <= wb_dat_w;
                    6'd27: mem_27 <= wb_dat_w;
                    6'd28: mem_28 <= wb_dat_w;
                    6'd29: mem_29 <= wb_dat_w;
                    6'd30: mem_30 <= wb_dat_w;
                    6'd31: mem_31 <= wb_dat_w;
                    6'd32: mem_32 <= wb_dat_w;
                    6'd33: mem_33 <= wb_dat_w;
                    6'd34: mem_34 <= wb_dat_w;
                    6'd35: mem_35 <= wb_dat_w;
                    6'd36: mem_36 <= wb_dat_w;
                    6'd37: mem_37 <= wb_dat_w;
                    6'd38: mem_38 <= wb_dat_w;
                    6'd39: mem_39 <= wb_dat_w;
                    6'd40: mem_40 <= wb_dat_w;
                    6'd41: mem_41 <= wb_dat_w;
                    6'd42: mem_42 <= wb_dat_w;
                    6'd43: mem_43 <= wb_dat_w;
                    6'd44: mem_44 <= wb_dat_w;
                    6'd45: mem_45 <= wb_dat_w;
                    6'd46: mem_46 <= wb_dat_w;
                    6'd47: mem_47 <= wb_dat_w;
                    6'd48: mem_48 <= wb_dat_w;
                    6'd49: mem_49 <= wb_dat_w;
                    6'd50: mem_50 <= wb_dat_w;
                    6'd51: mem_51 <= wb_dat_w;
                    6'd52: mem_52 <= wb_dat_w;
                    6'd53: mem_53 <= wb_dat_w;
                    6'd54: mem_54 <= wb_dat_w;
                    6'd55: mem_55 <= wb_dat_w;
                    6'd56: mem_56 <= wb_dat_w;
                    6'd57: mem_57 <= wb_dat_w;
                    6'd58: mem_58 <= wb_dat_w;
                    6'd59: mem_59 <= wb_dat_w;
                    6'd60: mem_60 <= wb_dat_w;
                    6'd61: mem_61 <= wb_dat_w;
                    6'd62: mem_62 <= wb_dat_w;
                    6'd63: mem_63 <= wb_dat_w;
                    default: ; // no write
                endcase
            end
        end
    end

    // -------------------------------------------------------------------------
    // Combinational read port — 6-bit PC mux
    // -------------------------------------------------------------------------
    reg [15:0] instr_mux;
    always @(*) begin
        case (pc)
            6'd0:  instr_mux = mem_00;
            6'd1:  instr_mux = mem_01;
            6'd2:  instr_mux = mem_02;
            6'd3:  instr_mux = mem_03;
            6'd4:  instr_mux = mem_04;
            6'd5:  instr_mux = mem_05;
            6'd6:  instr_mux = mem_06;
            6'd7:  instr_mux = mem_07;
            6'd8:  instr_mux = mem_08;
            6'd9:  instr_mux = mem_09;
            6'd10: instr_mux = mem_10;
            6'd11: instr_mux = mem_11;
            6'd12: instr_mux = mem_12;
            6'd13: instr_mux = mem_13;
            6'd14: instr_mux = mem_14;
            6'd15: instr_mux = mem_15;
            6'd16: instr_mux = mem_16;
            6'd17: instr_mux = mem_17;
            6'd18: instr_mux = mem_18;
            6'd19: instr_mux = mem_19;
            6'd20: instr_mux = mem_20;
            6'd21: instr_mux = mem_21;
            6'd22: instr_mux = mem_22;
            6'd23: instr_mux = mem_23;
            6'd24: instr_mux = mem_24;
            6'd25: instr_mux = mem_25;
            6'd26: instr_mux = mem_26;
            6'd27: instr_mux = mem_27;
            6'd28: instr_mux = mem_28;
            6'd29: instr_mux = mem_29;
            6'd30: instr_mux = mem_30;
            6'd31: instr_mux = mem_31;
            6'd32: instr_mux = mem_32;
            6'd33: instr_mux = mem_33;
            6'd34: instr_mux = mem_34;
            6'd35: instr_mux = mem_35;
            6'd36: instr_mux = mem_36;
            6'd37: instr_mux = mem_37;
            6'd38: instr_mux = mem_38;
            6'd39: instr_mux = mem_39;
            6'd40: instr_mux = mem_40;
            6'd41: instr_mux = mem_41;
            6'd42: instr_mux = mem_42;
            6'd43: instr_mux = mem_43;
            6'd44: instr_mux = mem_44;
            6'd45: instr_mux = mem_45;
            6'd46: instr_mux = mem_46;
            6'd47: instr_mux = mem_47;
            6'd48: instr_mux = mem_48;
            6'd49: instr_mux = mem_49;
            6'd50: instr_mux = mem_50;
            6'd51: instr_mux = mem_51;
            6'd52: instr_mux = mem_52;
            6'd53: instr_mux = mem_53;
            6'd54: instr_mux = mem_54;
            6'd55: instr_mux = mem_55;
            6'd56: instr_mux = mem_56;
            6'd57: instr_mux = mem_57;
            6'd58: instr_mux = mem_58;
            6'd59: instr_mux = mem_59;
            6'd60: instr_mux = mem_60;
            6'd61: instr_mux = mem_61;
            6'd62: instr_mux = mem_62;
            6'd63: instr_mux = mem_63;
            default: instr_mux = INSTR_NOP;
        endcase
    end

    assign instr = instr_mux;

endmodule
