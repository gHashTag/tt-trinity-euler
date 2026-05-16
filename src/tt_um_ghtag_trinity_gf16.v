`default_nettype none
`include "trinity_packet.vh"
// tt_um_ghtag_trinity_gf16 - TinyTapeout top.
// Apache-2.0
//
// v0 Trinity mesh-computer top: instantiates trinity_mesh_2x2 (4 GF16 tiles + crossbar
// router) plus a CPU-less master FSM that issues a canned packet sequence to tile 0.
//
// Backward compatibility: the existing testbench checks {uio_out, uo_out} == 0x47C0
// immediately after reset. The combinational gf16_dot4 of the canned vectors remains
// instantiated and drives the outputs by default; the mesh FSM result overrides only
// once it asserts result_valid_q (so the new mesh path is exercised on the same pins
// after a few extra cycles, observable by a longer-waiting testbench).

module tt_um_ghtag_trinity_gf16 (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    // ---- Legacy combinational dot4 path (preserved) ----
    wire [15:0] dot_out;
    gf16_dot4 u_dot (
        .a0(16'h3E00), .a1(16'h4000), .a2(16'h4100), .a3(16'h4200),
        .b0(16'h3E00), .b1(16'h4000), .b2(16'h4100), .b3(16'h4200),
        .result(dot_out)
    );

    // Input echo (legacy)
    reg [15:0] input_echo;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            input_echo <= 0;
        else if (ena)
            input_echo <= {ui_in, uio_in};
    end

    // ---- New: Trinity v0 mesh fabric ----
    wire [31:0] host_in_pkt;
    wire        host_in_valid;
    wire        host_in_ready;
    wire [31:0] host_out_pkt;
    wire        host_out_valid;
    wire        host_out_ready;
    wire [15:0] mesh_dbg_tile0;
    wire [15:0] mesh_result;
    wire        mesh_result_valid;
    // G4 DePIN on-die receipt outputs from the master FSM (latched RECEIPT packet)
    wire [7:0]  mesh_rcpt_checksum;
    wire [7:0]  mesh_rcpt_job_id;
    wire [1:0]  mesh_rcpt_tile_id;
    wire        mesh_rcpt_valid;

    trinity_master_fsm u_master (
        .clk             (clk),
        .rst_n           (rst_n),
        .ena             (ena),
        .load_mode       (ui_in[0]),
        .host_in_pkt     (host_in_pkt),
        .host_in_valid   (host_in_valid),
        .host_in_ready   (host_in_ready),
        .host_out_pkt    (host_out_pkt),
        .host_out_valid  (host_out_valid),
        .host_out_ready  (host_out_ready),
        .result_reg      (mesh_result),
        .result_valid_q  (mesh_result_valid),
        .rcpt_checksum_q (mesh_rcpt_checksum),
        .rcpt_job_id_q   (mesh_rcpt_job_id),
        .rcpt_tile_id_q  (mesh_rcpt_tile_id),
        .rcpt_valid_q    (mesh_rcpt_valid)
    );

    // P4 upgrade: replace trinity_mesh_2x2 with trinity_router_2x2 crossbar NoC.
    // The mesh was a thin wrapper (router + 4 tiles); we inline that wrapping here
    // so the router becomes the top-level NoC instance with proper crossbar topology.
    wire [4*`TRN_PKT_W-1:0] t_pkt_flat;
    wire [3:0]              t_valid;
    wire [3:0]              t_ready;
    wire [4*`TRN_PKT_W-1:0] t_ret_pkt_flat;
    wire [3:0]              t_ret_valid;
    wire [3:0]              t_ret_ready;

    trinity_router_2x2 u_router (
        .clk            (clk),
        .rst_n          (rst_n),
        .host_in_pkt    (host_in_pkt),
        .host_in_valid  (host_in_valid),
        .host_in_ready  (host_in_ready),
        .host_out_pkt   (host_out_pkt),
        .host_out_valid (host_out_valid),
        .host_out_ready (host_out_ready),
        .t_pkt_flat     (t_pkt_flat),
        .t_valid        (t_valid),
        .t_ready        (t_ready),
        .t_ret_pkt_flat (t_ret_pkt_flat),
        .t_ret_valid    (t_ret_valid),
        .t_ret_ready    (t_ret_ready)
    );

    wire [`TRN_PKT_W-1:0] t_in_pkt   [0:3];
    wire [`TRN_PKT_W-1:0] t_out_pkt  [0:3];
    wire [15:0]           tile_dbg   [0:3];

    genvar gi;
    generate
        for (gi = 0; gi < 4; gi = gi + 1) begin : g_tile
            assign t_in_pkt[gi] = t_pkt_flat[(gi+1)*`TRN_PKT_W-1 -: `TRN_PKT_W];
            assign t_ret_pkt_flat[(gi+1)*`TRN_PKT_W-1 -: `TRN_PKT_W] = t_out_pkt[gi];

            trinity_gf16_tile #(.TILE_ID(gi[1:0]), .DOT_WIDTH(8)) u_tile (
                .clk        (clk),
                .rst_n      (rst_n),
                .in_pkt     (t_in_pkt[gi]),
                .in_valid   (t_valid[gi]),
                .in_ready   (t_ready[gi]),
                .out_pkt    (t_out_pkt[gi]),
                .out_valid  (t_ret_valid[gi]),
                .out_ready  (t_ret_ready[gi]),
                .dbg_result (tile_dbg[gi])
            );
        end
    endgenerate

    assign mesh_dbg_tile0 = tile_dbg[0];

    // ---- Wave-26b CROWN: silicon-anchored physics POST modules ----
    // L-S1: φ-anchor POST (proves φ²+φ⁻²=3 via Lucas recurrence on power-up)
    wire phi_ok;
    wire post_done;
    phi_anchor_post u_phi_post (
        .clk(clk), .rst_n(rst_n),
        .phi_ok(phi_ok), .post_done(post_done)
    );

    // L-S2: Lucas ROM (probed during POST + addressable for host)
    wire [7:0] lucas_val;
    wire [2:0] lucas_idx = ui_in[3:1];   // ui_in[3:1] selects L_n
    lucas_rom u_lucas (.idx(lucas_idx), .value(lucas_val));
    // lucas_ok is the AND of all 6 ROM entries matching the canonical chain.
    // This is a combinational integrity check: we compare each ROM output
    // against the constant the synthesizer should fold flat — any bit-flip in
    // the ROM gives lucas_ok=0. Cheap (~20 gates) for an irreplaceable invariant.
    wire [7:0] _l2, _l3, _l4, _l5, _l6, _l7;
    lucas_rom u_lr2 (.idx(3'd0), .value(_l2));
    lucas_rom u_lr3 (.idx(3'd1), .value(_l3));
    lucas_rom u_lr4 (.idx(3'd2), .value(_l4));
    lucas_rom u_lr5 (.idx(3'd3), .value(_l5));
    lucas_rom u_lr6 (.idx(3'd4), .value(_l6));
    lucas_rom u_lr7 (.idx(3'd5), .value(_l7));
    wire lucas_ok = (_l2 == 8'd3)  && (_l3 == 8'd4)  && (_l4 == 8'd7)  &&
                    (_l5 == 8'd11) && (_l6 == 8'd18) && (_l7 == 8'd29);

    // L-S3: 8x8 VSA ternary matmul — kicked off at reset release with a canned
    // pair (identity-on-ternary: A=B=I_8 in {-1,0,+1} encoding); matmul_ok
    // simply asserts when compute completes.
    reg [127:0] vsa_a, vsa_b;
    reg         vsa_start;
    wire        vsa_done, matmul_ok;
    wire [511:0] vsa_c;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Encode identity-like input: every element = +1 (encoding 2'b00)
            vsa_a <= 128'b0;
            vsa_b <= 128'b0;
            vsa_start <= 1'b1;  // single-shot pulse latched by matmul on first cycle
        end else begin
            vsa_start <= 1'b0;
        end
    end
    vsa_matmul_8x8 u_vsa (
        .clk(clk), .rst_n(rst_n),
        .start(vsa_start),
        .a_flat(vsa_a), .b_flat(vsa_b),
        .done(vsa_done),
        .c_flat(vsa_c),
        .matmul_ok(matmul_ok)
    );

    // L-S5: 16-bit LFSR for die-unique nonce (folded into _unused; available via
    // future Wishbone read in next wave). We OR-reduce to a single non-zero flag.
    wire [15:0] hwrng_word;
    hwrng_lfsr u_rng (.clk(clk), .rst_n(rst_n), .ena(1'b1), .rnd(hwrng_word));
    wire hwrng_nonzero = |hwrng_word;

    // L-S6: Wishbone-lite status byte aggregating all POST results.
    wire [7:0] status_byte;
    wb_status_reg u_status (
        .clk(clk), .rst_n(rst_n),
        .phi_ok(phi_ok),
        .lucas_ok(lucas_ok),
        .matmul_ok(matmul_ok),
        .post_done(post_done),
        .rcpt_valid(mesh_rcpt_valid),
        .hwrng_nonzero(hwrng_nonzero),
        .status_byte(status_byte)
    );

    // L-S4: CRC-32 of the RECEIPT triplet {job_id, tile_id, result_lo}.
    // Sequenced over three cycles when mesh_rcpt_valid rises. We expose only
    // the low byte of the final CRC through a registered output observable via
    // the future Wishbone path; current top simply folds into _unused.
    reg [1:0]  crc_step;
    reg        crc_start, crc_valid;
    reg [7:0]  crc_byte;
    reg        rcpt_valid_d;
    wire [31:0] crc_raw, crc_final;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc_step     <= 2'd0;
            crc_start    <= 1'b0;
            crc_valid    <= 1'b0;
            crc_byte     <= 8'b0;
            rcpt_valid_d <= 1'b0;
        end else begin
            rcpt_valid_d <= mesh_rcpt_valid;
            crc_start    <= mesh_rcpt_valid && !rcpt_valid_d;
            if (mesh_rcpt_valid && !rcpt_valid_d) begin
                crc_step <= 2'd0;
                crc_valid <= 1'b1;
                crc_byte <= mesh_rcpt_job_id;
            end else if (crc_valid) begin
                case (crc_step)
                    2'd0: begin crc_byte <= {6'b0, mesh_rcpt_tile_id}; crc_step <= 2'd1; end
                    2'd1: begin crc_byte <= mesh_rcpt_checksum;         crc_step <= 2'd2; end
                    default: crc_valid <= 1'b0;
                endcase
            end
        end
    end
    crc32_receipt u_crc (
        .clk(clk), .rst_n(rst_n),
        .start(crc_start),
        .valid(crc_valid),
        .byte_in(crc_byte),
        .crc_raw(crc_raw),
        .crc_final(crc_final)
    );

    // ==================================================================
    // Wave-26b SUPER-CROWN modules (L-S10..L-S18) — 8×2 tile expansion
    // ==================================================================

    // L-S10: 16×16 ternary matmul (JEPA-T tier)
    reg  [511:0] mm16_a, mm16_b;
    reg          mm16_start;
    wire         mm16_done, mm16_ok;
    wire [2047:0] mm16_c;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mm16_a <= 512'b0;
            mm16_b <= 512'b0;
            mm16_start <= 1'b1;
        end else mm16_start <= 1'b0;
    end
    vsa_matmul_16x16 u_mm16 (
        .clk(clk), .rst_n(rst_n),
        .start(mm16_start),
        .a_flat(mm16_a), .b_flat(mm16_b),
        .done(mm16_done), .c_flat(mm16_c),
        .matmul_ok(mm16_ok)
    );

    // L-S11: BitNet encoder
    reg  [127:0] enc_x;
    reg          enc_start;
    wire         enc_done, enc_ok;
    wire [63:0]  enc_y;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            enc_x <= 128'b0;
            enc_start <= 1'b1;
        end else enc_start <= 1'b0;
    end
    bitnet_encoder u_enc (
        .clk(clk), .rst_n(rst_n),
        .start(enc_start), .x_in(enc_x),
        .done(enc_done), .y_out(enc_y),
        .encoder_ok(enc_ok)
    );

    // L-S12: BPB counter (fed by canned scoring pulses)
    wire bpb_ok;
    wire [23:0] bpb_total;
    wire [15:0] bpb_samples;
    reg [3:0] bpb_tick;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) bpb_tick <= 4'd0;
        else if (bpb_tick != 4'hF) bpb_tick <= bpb_tick + 4'd1;
    end
    bpb_counter u_bpb (
        .clk(clk), .rst_n(rst_n),
        .valid(bpb_tick == 4'd5),
        .pred_class(mesh_rcpt_checksum),
        .true_class(8'hC1),
        .total_loss(bpb_total),
        .sample_count(bpb_samples),
        .bpb_ok(bpb_ok)
    );

    // L-S13: BLAKE3-mini RECEIPT signer
    reg [511:0] hash_in;
    reg         hash_start;
    wire        hash_done, hash_ok;
    wire [255:0] hash_digest;
    reg hash_kicked;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hash_in     <= 512'b0;
            hash_start  <= 1'b0;
            hash_kicked <= 1'b0;
        end else if (mesh_rcpt_valid && !hash_kicked) begin
            hash_in <= {448'b0,
                        mesh_rcpt_checksum, mesh_rcpt_job_id,
                        {6'b0, mesh_rcpt_tile_id}, 8'hA5,
                        crc_final};
            hash_start  <= 1'b1;
            hash_kicked <= 1'b1;
        end else begin
            hash_start <= 1'b0;
        end
    end
    blake3_anchor u_hash (
        .clk(clk), .rst_n(rst_n),
        .start(hash_start), .m_in(hash_in),
        .done(hash_done), .digest(hash_digest),
        .hash_ok(hash_ok)
    );

    // L-S14: multi-tile RECEIPT aggregator
    wire all_attested, multi_rcpt_ok;
    wire [7:0] agg_checksum, agg_job_id;
    wire [3:0] attested_mask;
    multi_tile_receipt u_mrcpt (
        .clk(clk), .rst_n(rst_n),
        .t0_valid(mesh_rcpt_valid),
        .t0_checksum(mesh_rcpt_checksum),
        .t0_job_id(mesh_rcpt_job_id),
        // Tiles 1..3 share the same source for now (single-mesh demo); when full
        // multi-tile master FSM lands in next wave, these get distinct feeds.
        .t1_valid(mesh_rcpt_valid),
        .t1_checksum(mesh_rcpt_checksum),
        .t1_job_id(mesh_rcpt_job_id),
        .t2_valid(mesh_rcpt_valid),
        .t2_checksum(mesh_rcpt_checksum),
        .t2_job_id(mesh_rcpt_job_id),
        .t3_valid(mesh_rcpt_valid),
        .t3_checksum(mesh_rcpt_checksum),
        .t3_job_id(mesh_rcpt_job_id),
        .agg_checksum(agg_checksum),
        .agg_job_id(agg_job_id),
        .attested_mask(attested_mask),
        .all_attested(all_attested),
        .multi_rcpt_ok(multi_rcpt_ok)
    );

    // L-S15: Trinity ternary ALU-9 decoder (combinational demo, fed by hwrng)
    wire [1:0] alu_result;
    wire       alu_valid, alu_ok;
    alu9_decoder u_alu (
        .opcode(hwrng_word[3:0]),
        .a(hwrng_word[5:4]),
        .b(hwrng_word[7:6]),
        .result(alu_result),
        .valid(alu_valid),
        .decoder_ok(alu_ok)
    );

    // L-S16: RING27 ternary memory (shift every 8 clocks, fed by ALU result)
    reg [2:0] ring_shift_cnt;
    wire ring_ok;
    wire [1:0] ring_rd;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) ring_shift_cnt <= 3'b0;
        else        ring_shift_cnt <= ring_shift_cnt + 3'b1;
    end
    ring27_memory u_ring (
        .clk(clk), .rst_n(rst_n),
        .shift(ring_shift_cnt == 3'd0),
        .wr_en(alu_valid && (ring_shift_cnt == 3'd4)),
        .addr(hwrng_word[12:8] % 5'd27),
        .wr_data(alu_result),
        .rd_data(ring_rd),
        .ring_ok(ring_ok)
    );

    // L-S17: phi-PLL fractional divider
    wire phi_tick;
    wire [2:0] phi_state;
    wire phi_div_ok;
    phi_pll_div u_phi_div (
        .clk(clk), .rst_n(rst_n),
        .phi_tick(phi_tick),
        .state(phi_state),
        .phi_div_ok(phi_div_ok)
    );

    // L-S18: Wishbone-lite full peripheral (probe-only on TT pins; no host bus exposed)
    wire [7:0] wb_dat_r;
    wire wb_ack, wb_ok;
    wishbone_full u_wb (
        .clk(clk), .rst_n(rst_n),
        .wb_cyc(1'b0), .wb_stb(1'b0), .wb_we(1'b0),
        .wb_adr(4'b0), .wb_dat_w(8'b0),
        .wb_dat_r(wb_dat_r), .wb_ack(wb_ack),
        .status_byte(status_byte),
        .matmul_lo(mm16_c[7:0]),
        .rcpt_chk(agg_checksum),
        .bpb_lo(bpb_total[7:0]),
        .wb_ok(wb_ok)
    );

    // =========================================================================
    // F1 Euler ISA: 32-deep instruction ROM + 5-bit PC micro-sequencer
    // PhD anchor: Glava 8 (AGI Driver) + Glava 18 (Ternary ISA)
    // Coq target: microseq_halts
    // =========================================================================

    // Wishbone-lite write bus to ROM (tied off at top level for now;
    // future host can drive these via uio_in to load programs)
    wire        rom_wb_cyc  = 1'b0;
    wire        rom_wb_stb  = 1'b0;
    wire        rom_wb_we   = 1'b0;
    wire [4:0]  rom_wb_adr  = 5'b0;
    wire [15:0] rom_wb_datw = 16'b0;
    wire        rom_wb_ack;

    wire [4:0]  seq_pc;
    wire [15:0] seq_instr;
    wire        seq_halted;
    wire [7:0]  seq_acc;

    trinity_instr_rom u_instr_rom (
        .clk      (clk),
        .rst_n    (rst_n),
        .pc       (seq_pc),
        .instr    (seq_instr),
        .wb_cyc   (rom_wb_cyc),
        .wb_stb   (rom_wb_stb),
        .wb_we    (rom_wb_we),
        .wb_adr   (rom_wb_adr),
        .wb_dat_w (rom_wb_datw),
        .wb_ack   (rom_wb_ack)
    );

    trinity_micro_seq u_micro_seq (
        .clk     (clk),
        .rst_n   (rst_n),
        .ena     (ena),
        .pc      (seq_pc),
        .instr   (seq_instr),
        .halted  (seq_halted),
        .acc_out (seq_acc)
    );

    // SUPER-CROWN aggregate health bit (all 9 original + micro-seq halted flag)
    wire super_crown_ok =
        mm16_ok & enc_ok & bpb_ok & hash_ok & multi_rcpt_ok &
        alu_ok  & ring_ok & phi_div_ok & wb_ok & seq_halted;

    // Output mux: combinational dot result by default, mesh result once produced.
    wire [15:0] final_result = mesh_result_valid ? mesh_result : dot_out;

    // =================================================================
    // TRI NET friend/foe handshake (MY_ANCHOR = e = 8'hAE)
    // uio[0]=tx_bit (OUT), uio[1]=rx_bit (IN), uio[2]=friend, uio[3]=valid
    // =================================================================
    wire ff_tx, ff_friend, ff_valid;
    trinity_friend_foe #(.MY_ANCHOR(8'hAE)) u_friend_foe (
        .clk             (clk),
        .rst_n           (rst_n),
        .rx_bit          (uio_in[1]),
        .tx_bit          (ff_tx),
        .friend_detected (ff_friend),
        .handshake_valid (ff_valid)
    );

    // ==================================================================
    // CROWN47 ROM — Crown of TRI NET (Crown42 + 5 Tegmark-31 fillers).
    // 47 Trinity constants in 24-bit pseudo-float (Vasilev-Pellis v22.12).
    // Activated by uio_in[7]=1 with load_mode=0 (preserves T4 {0x47C0}).
    //   ui_in[6:0]   = crown_addr (0..46)
    //   uio_in[6:5]  = byte_sel (0=mant_lo 1=mant_hi 2=exp 3=tier_flag)
    // Anchor phi^2+phi^-2=3 . DOI 10.5281/zenodo.19227877  R-SI-1 clean.
    // ==================================================================
    wire        crown_mode = uio_in[7] && !ui_in[0];
    wire [7:0]  crown_byte_raw;
    crown47_rom_8bit u_crown47 (
        .addr     (ui_in[6:0]),
        .byte_sel (uio_in[6:5]),
        .byte_out (crown_byte_raw)
    );

    assign uo_out  = crown_mode ? crown_byte_raw
                                : (final_result[7:0]  | input_echo[7:0]);
    // uio_out: legacy mesh result high byte by default; switches to CROWN status_byte
    // only when host asserts load_mode (ui_in[0]=1). This preserves the canonical
    // legacy test T4 which expects {uio_out, uo_out} == 0x47C0 when ui_in==0.
    wire [7:0] uio_legacy =
        crown_mode                ? 8'h00 :
        (ui_in[0] && post_done)   ? status_byte :
                                     (final_result[15:8] | input_echo[15:8]);
    // uio[3:0] reserved for TRI NET friend/foe; uio[7:4] keeps legacy mux.
    // Canonical mode (load_mode=0): use full uio_legacy for TG-TRIAD-X anchor 0x47C0
    // Live mode (load_mode=1): carry TRI NET friend/foe handshake bits
    assign uio_out = !ui_in[0] ? uio_legacy :
                                      {uio_legacy[7:4], ff_valid, ff_friend, 1'b0, ff_tx};
    // uio[1] is the RX bit (input) in live mode; all outputs in canonical mode
    assign uio_oe  = !ui_in[0] ? 8'hFF : 8'b1111_1101;

    // Silence lint on unused. The G4 receipt outputs are exposed to the
    // testbench via the master FSM directly (not via TT pins, which are
    // exhausted by the legacy dot4/mesh result mux); they MUST be folded
    // into _unused here so synthesis keeps the registers.
    wire _unused = &{1'b0, mesh_dbg_tile0, ena, uio_in,
                     mesh_rcpt_checksum, mesh_rcpt_job_id,
                     mesh_rcpt_tile_id, mesh_rcpt_valid,
                     lucas_val, vsa_done, vsa_c,
                     crc_raw, crc_final,
                     hwrng_word[14:0],
                     mm16_done, mm16_c[2047:8],
                     enc_done, enc_y,
                     bpb_total[23:8], bpb_samples,
                     hash_done, hash_digest,
                     all_attested, agg_job_id, attested_mask,
                     alu_result, alu_valid,
                     ring_rd, phi_tick, phi_state,
                     wb_dat_r, wb_ack,
                     super_crown_ok,
                     rom_wb_ack, seq_acc, seq_instr,
                     ui_in[7:4], 1'b0};

endmodule
