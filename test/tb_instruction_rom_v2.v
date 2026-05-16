`default_nettype none
`timescale 1ns/1ps
// tb_instruction_rom_v2.v — readout testbench for all 64 opcodes
// EULER ISA v2 — TRI-27 + CLARA extension
// Apache-2.0
//
// Tests:
//   1. Reset — verify addr 0x00..0x1E = NOP (0x0000), addr 0x1F = HALT (0xE000)
//   2. K3 zone — verify addr 0x20..0x2F hold expected K3 instruction words
//   3. ASP zone — verify addr 0x30..0x3F hold expected ASP instruction words
//   4. Wishbone write — write a word to addr 5, read it back
//   5. Compat check — re-verify addr 0x00..0x1F unchanged after Wishbone write
//
// PhD anchor: phi^2 + phi^-2 = 3
// DOI: 10.5281/zenodo.19227877

module tb_instruction_rom_v2;

    // Clock and reset
    reg clk;
    reg rst_n;

    // DUT ports
    reg  [5:0]  pc;
    wire [15:0] instr;

    reg         wb_cyc;
    reg         wb_stb;
    reg         wb_we;
    reg  [5:0]  wb_adr;
    reg  [15:0] wb_dat_w;
    wire        wb_ack;

    // Pass/fail counters
    integer pass_count;
    integer fail_count;

    // Instantiate DUT
    instruction_rom_v2 dut (
        .clk      (clk),
        .rst_n    (rst_n),
        .pc       (pc),
        .instr    (instr),
        .wb_cyc   (wb_cyc),
        .wb_stb   (wb_stb),
        .wb_we    (wb_we),
        .wb_adr   (wb_adr),
        .wb_dat_w (wb_dat_w),
        .wb_ack   (wb_ack)
    );

    // Clock: 10 ns period
    initial clk = 0;
    always #5 clk = ~clk;

    // Helper task: read one address and check expected value
    task check_rom;
        input [5:0]  addr;
        input [15:0] expected;
        input [63:0] label; // 8-char ASCII tag packed into 64 bits (not printed, used for debug)
        begin
            pc = addr;
            #1; // combinational settle
            if (instr === expected) begin
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL addr=%0d (0x%02h): got 0x%04h, expected 0x%04h",
                          addr, addr, instr, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // Helper task: wishbone single write
    task wb_write;
        input [5:0]  addr;
        input [15:0] data;
        begin
            @(posedge clk);
            wb_cyc   <= 1'b1;
            wb_stb   <= 1'b1;
            wb_we    <= 1'b1;
            wb_adr   <= addr;
            wb_dat_w <= data;
            @(posedge clk);
            // wait for ack
            while (!wb_ack) @(posedge clk);
            wb_cyc   <= 1'b0;
            wb_stb   <= 1'b0;
            wb_we    <= 1'b0;
            @(posedge clk);
        end
    endtask

    // Expected values — must match localparam definitions in RTL
    localparam [15:0] E_NOP          = 16'h0000;
    localparam [15:0] E_HALT         = 16'hE000;

    localparam [15:0] E_K3_AND       = 16'b001_00001_00001_000;
    localparam [15:0] E_K3_OR        = 16'b001_00001_00001_001;
    localparam [15:0] E_K3_NOT       = 16'b001_00001_00001_010;
    localparam [15:0] E_K3_MIN       = 16'b001_00001_00001_011;
    localparam [15:0] E_K3_MAX       = 16'b001_00010_00001_000;
    localparam [15:0] E_K3_XOR       = 16'b001_00010_00001_001;
    localparam [15:0] E_K3_IMP       = 16'b001_00010_00001_010;
    localparam [15:0] E_K3_EQUIV     = 16'b001_00010_00001_011;
    localparam [15:0] E_K3_NAND      = 16'b010_00001_00001_000;
    localparam [15:0] E_K3_NOR       = 16'b010_00001_00001_001;
    localparam [15:0] E_K3_XNOR      = 16'b010_00001_00001_010;
    localparam [15:0] E_K3_LUK       = 16'b010_00001_00001_011;
    localparam [15:0] E_K3_CONS      = 16'b010_00010_00001_000;
    localparam [15:0] E_K3_THRESH    = 16'b010_00010_00001_001;
    localparam [15:0] E_K3_SEL       = 16'b010_00010_00001_010;
    localparam [15:0] E_K3_RED       = 16'b010_00010_00001_011;

    localparam [15:0] E_ASP_FACT     = 16'b011_00001_00001_000;
    localparam [15:0] E_ASP_RULE     = 16'b011_00001_00001_001;
    localparam [15:0] E_ASP_NEG      = 16'b011_00001_00001_010;
    localparam [15:0] E_ASP_STABLE   = 16'b011_00001_00001_011;
    localparam [15:0] E_ASP_CHOICE   = 16'b011_00010_00001_000;
    localparam [15:0] E_ASP_CONSTR   = 16'b011_00010_00001_001;
    localparam [15:0] E_ASP_AGGR     = 16'b011_00010_00001_010;
    localparam [15:0] E_ASP_PROP     = 16'b011_00010_00001_011;
    localparam [15:0] E_ASP_BT       = 16'b100_00001_00001_000;
    localparam [15:0] E_ASP_UNIFY    = 16'b100_00001_00001_001;
    localparam [15:0] E_ASP_RESOLVE  = 16'b100_00001_00001_010;
    localparam [15:0] E_ASP_GROUND   = 16'b100_00001_00001_011;
    localparam [15:0] E_ASP_JUST     = 16'b100_00010_00001_000;
    localparam [15:0] E_ASP_EXPL     = 16'b100_00010_00001_001;
    localparam [15:0] E_ASP_COMMIT   = 16'b100_00010_00001_010;
    localparam [15:0] E_ASP_HALT     = 16'b111_11111_11111_111;

    integer i;

    initial begin
        // Initialise
        pass_count = 0;
        fail_count = 0;
        pc       = 6'd0;
        wb_cyc   = 1'b0;
        wb_stb   = 1'b0;
        wb_we    = 1'b0;
        wb_adr   = 6'd0;
        wb_dat_w = 16'h0000;

        // Apply reset
        rst_n = 1'b0;
        repeat(4) @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk);

        $display("=== TEST 1: TRI-27 zone (addr 0x00..0x1F) ===");
        // Addr 0x00..0x1E should all be NOP
        for (i = 0; i < 31; i = i + 1) begin
            check_rom(i[5:0], E_NOP, 64'h4e4f505f5f5f5f5f); // "NOP_____"
        end
        // Addr 0x1F should be HALT
        check_rom(6'h1F, E_HALT, 64'h48414c545f5f5f5f); // "HALT____"

        $display("=== TEST 2: K3 zone (addr 0x20..0x2F) ===");
        check_rom(6'h20, E_K3_AND,    64'h6b335f616e645f5f);
        check_rom(6'h21, E_K3_OR,     64'h6b335f6f725f5f5f);
        check_rom(6'h22, E_K3_NOT,    64'h6b335f6e6f745f5f);
        check_rom(6'h23, E_K3_MIN,    64'h6b335f6d696e5f5f);
        check_rom(6'h24, E_K3_MAX,    64'h6b335f6d61785f5f);
        check_rom(6'h25, E_K3_XOR,    64'h6b335f786f725f5f);
        check_rom(6'h26, E_K3_IMP,    64'h6b335f696d705f5f);
        check_rom(6'h27, E_K3_EQUIV,  64'h6b335f657175765f);
        check_rom(6'h28, E_K3_NAND,   64'h6b335f6e616e645f);
        check_rom(6'h29, E_K3_NOR,    64'h6b335f6e6f725f5f);
        check_rom(6'h2A, E_K3_XNOR,   64'h6b335f786e6f725f);
        check_rom(6'h2B, E_K3_LUK,    64'h6b335f6c756b5f5f);
        check_rom(6'h2C, E_K3_CONS,   64'h6b335f636f6e735f);
        check_rom(6'h2D, E_K3_THRESH, 64'h6b335f74687265xx);
        check_rom(6'h2E, E_K3_SEL,    64'h6b335f73656c5f5f);
        check_rom(6'h2F, E_K3_RED,    64'h6b335f7265645f5f);

        $display("=== TEST 3: ASP zone (addr 0x30..0x3F) ===");
        check_rom(6'h30, E_ASP_FACT,    64'h6173705f66616374);
        check_rom(6'h31, E_ASP_RULE,    64'h6173705f72756c65);
        check_rom(6'h32, E_ASP_NEG,     64'h6173705f6e656700);
        check_rom(6'h33, E_ASP_STABLE,  64'h6173705f73746100);
        check_rom(6'h34, E_ASP_CHOICE,  64'h6173705f63686f69);
        check_rom(6'h35, E_ASP_CONSTR,  64'h6173705f636f6e73);
        check_rom(6'h36, E_ASP_AGGR,    64'h6173705f61676772);
        check_rom(6'h37, E_ASP_PROP,    64'h6173705f70726f70);
        check_rom(6'h38, E_ASP_BT,      64'h6173705f62745f5f);
        check_rom(6'h39, E_ASP_UNIFY,   64'h6173705f756e6966);
        check_rom(6'h3A, E_ASP_RESOLVE, 64'h6173705f7265736f);
        check_rom(6'h3B, E_ASP_GROUND,  64'h6173705f67726f75);
        check_rom(6'h3C, E_ASP_JUST,    64'h6173705f6a757374);
        check_rom(6'h3D, E_ASP_EXPL,    64'h6173705f6578706c);
        check_rom(6'h3E, E_ASP_COMMIT,  64'h6173705f636f6d6d);
        check_rom(6'h3F, E_ASP_HALT,    64'h6173705f68616c74);

        $display("=== TEST 4: Wishbone write + readback (addr 5) ===");
        wb_write(6'd5, 16'hBEEF);
        check_rom(6'd5, 16'hBEEF, 64'h77625f7772697465);

        $display("=== TEST 5: Backward-compat — addr 0x00..0x1F unchanged after WB write ===");
        // Addresses 0..4 and 6..30 should still be NOP; addr 31 = HALT; addr 5 = 0xBEEF
        for (i = 0; i < 5; i = i + 1) begin
            check_rom(i[5:0], E_NOP, 64'h4e4f505f5f5f5f5f);
        end
        // addr 5 now holds 0xBEEF (written in test 4)
        check_rom(6'd5, 16'hBEEF, 64'h77625f7665726966);
        for (i = 6; i < 31; i = i + 1) begin
            check_rom(i[5:0], E_NOP, 64'h4e4f505f5f5f5f5f);
        end
        check_rom(6'h1F, E_HALT, 64'h48414c545f5f5f5f);

        $display("=== TEST 6: K3 zone still intact after Wishbone write ===");
        check_rom(6'h20, E_K3_AND,  64'h6b335f616e645f5f);
        check_rom(6'h3F, E_ASP_HALT, 64'h6173705f68616c74);

        $display("==============================================");
        $display("EULER ISA v2 ROM readout: PASS=%0d  FAIL=%0d",
                  pass_count, fail_count);
        $display("==============================================");

        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("*** %0d TEST(S) FAILED ***", fail_count);

        $finish;
    end

    // Timeout guard
    initial begin
        #50000;
        $display("TIMEOUT — simulation exceeded 50us");
        $finish;
    end

endmodule
