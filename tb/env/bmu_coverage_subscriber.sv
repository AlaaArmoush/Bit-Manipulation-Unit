class bmu_coverage_subscriber extends uvm_subscriber #(bmu_sequence_item);

  `uvm_component_utils(bmu_coverage_subscriber)

  protected bmu_sequence_item sampled_transaction;
  protected int unsigned      sample_count;

  protected function automatic logic [31:0] count_trailing_zeros(logic [31:0] operand);
    for (int unsigned bit_index = 0; bit_index < 32; bit_index++) begin
      if (operand[bit_index] === 1'b1) begin
        return bit_index;
      end
    end

    return 32;
  endfunction : count_trailing_zeros

  protected function automatic logic [31:0] population_count(logic [31:0] operand);
    logic [31:0] count;

    count = '0;

    for (int unsigned bit_index = 0; bit_index < 32; bit_index++) begin
      if (operand[bit_index] === 1'b1) begin
        count++;
      end
    end

    return count;
  endfunction : population_count

  // Helper functions for sampling coverage only when transactions are valid.
  protected function bit is_legal_csr_write_sample();
    rtl_pkg::rtl_alu_pkt_t legal_ap;

    if (sampled_transaction == null) begin
      return 1'b0;
    end

    legal_ap           = '0;
    legal_ap.csr_write = 1'b1;
    legal_ap.csr_imm   = sampled_transaction.ap.csr_imm;

    return (
        (sampled_transaction.rst_l        === 1'b1) &&
        (sampled_transaction.valid_in     === 1'b1) &&
        (sampled_transaction.csr_ren_in   === 1'b0) &&
        (sampled_transaction.ap.csr_write === 1'b1) &&
        ((sampled_transaction.ap.csr_imm  === 1'b0) ||
         (sampled_transaction.ap.csr_imm  === 1'b1)) &&
        (sampled_transaction.ap           === legal_ap)
    );
  endfunction : is_legal_csr_write_sample

  protected function bit is_legal_or_orn_sample();
    rtl_pkg::rtl_alu_pkt_t legal_ap;

    if (sampled_transaction == null) begin
      return 1'b0;
    end

    legal_ap     = '0;
    legal_ap.lor = 1'b1;
    legal_ap.zbb = sampled_transaction.ap.zbb;

    return (
        (sampled_transaction.rst_l      === 1'b1) &&
        (sampled_transaction.valid_in   === 1'b1) &&
        (sampled_transaction.csr_ren_in === 1'b0) &&
        (sampled_transaction.ap.lor     === 1'b1) &&
        ((sampled_transaction.ap.zbb    === 1'b0) ||
         (sampled_transaction.ap.zbb    === 1'b1)) &&
        (sampled_transaction.ap         === legal_ap)
    );
  endfunction : is_legal_or_orn_sample

  protected function bit is_legal_xor_xnor_sample();
    rtl_pkg::rtl_alu_pkt_t legal_ap;

    if (sampled_transaction == null) begin
      return 1'b0;
    end

    legal_ap      = '0;
    legal_ap.lxor = 1'b1;
    legal_ap.zbb  = sampled_transaction.ap.zbb;

    return (
        (sampled_transaction.rst_l      === 1'b1) &&
        (sampled_transaction.valid_in   === 1'b1) &&
        (sampled_transaction.csr_ren_in === 1'b0) &&
        (sampled_transaction.ap.lxor    === 1'b1) &&
        ((sampled_transaction.ap.zbb    === 1'b0) ||
         (sampled_transaction.ap.zbb    === 1'b1)) &&
        (sampled_transaction.ap         === legal_ap)
    );
  endfunction : is_legal_xor_xnor_sample

  protected function bit is_legal_srl_sample();
    rtl_pkg::rtl_alu_pkt_t legal_ap;

    if (sampled_transaction == null) begin
      return 1'b0;
    end

    legal_ap     = '0;
    legal_ap.srl = 1'b1;

    return (
        (sampled_transaction.rst_l      === 1'b1) &&
        (sampled_transaction.valid_in   === 1'b1) &&
        (sampled_transaction.csr_ren_in === 1'b0) &&
        (sampled_transaction.ap         === legal_ap)
    );
  endfunction : is_legal_srl_sample

  protected function bit is_legal_sra_sample();
    rtl_pkg::rtl_alu_pkt_t legal_ap;

    if (sampled_transaction == null) begin
      return 1'b0;
    end

    legal_ap     = '0;
    legal_ap.sra = 1'b1;

    return (
        (sampled_transaction.rst_l      === 1'b1) &&
        (sampled_transaction.valid_in   === 1'b1) &&
        (sampled_transaction.csr_ren_in === 1'b0) &&
        (sampled_transaction.ap         === legal_ap)
    );
  endfunction : is_legal_sra_sample

  protected function bit is_legal_ror_sample();
    rtl_pkg::rtl_alu_pkt_t legal_ap;

    if (sampled_transaction == null) begin
      return 1'b0;
    end

    legal_ap     = '0;
    legal_ap.ror = 1'b1;

    return (
        (sampled_transaction.rst_l      === 1'b1) &&
        (sampled_transaction.valid_in   === 1'b1) &&
        (sampled_transaction.csr_ren_in === 1'b0) &&
        (sampled_transaction.ap         === legal_ap)
    );
  endfunction : is_legal_ror_sample

  protected function bit is_legal_binv_sample();
    rtl_pkg::rtl_alu_pkt_t legal_ap;

    if (sampled_transaction == null) begin
      return 1'b0;
    end

    legal_ap      = '0;
    legal_ap.binv = 1'b1;

    return (
        (sampled_transaction.rst_l      === 1'b1) &&
        (sampled_transaction.valid_in   === 1'b1) &&
        (sampled_transaction.csr_ren_in === 1'b0) &&
        (sampled_transaction.ap         === legal_ap)
    );
  endfunction : is_legal_binv_sample

  protected function bit is_legal_sh2add_sample();
    rtl_pkg::rtl_alu_pkt_t legal_ap;

    if (sampled_transaction == null) begin
      return 1'b0;
    end

    legal_ap        = '0;
    legal_ap.sh2add = 1'b1;
    legal_ap.zba    = 1'b1;

    return (
        (sampled_transaction.rst_l      === 1'b1) &&
        (sampled_transaction.valid_in   === 1'b1) &&
        (sampled_transaction.csr_ren_in === 1'b0) &&
        (sampled_transaction.ap         === legal_ap)
    );
  endfunction : is_legal_sh2add_sample

  protected function bit is_legal_sub_sample();
    rtl_pkg::rtl_alu_pkt_t legal_ap;

    if (sampled_transaction == null) begin
      return 1'b0;
    end

    legal_ap     = '0;
    legal_ap.sub = 1'b1;

    return (
        (sampled_transaction.rst_l      === 1'b1) &&
        (sampled_transaction.valid_in   === 1'b1) &&
        (sampled_transaction.csr_ren_in === 1'b0) &&
        (sampled_transaction.ap         === legal_ap)
    );
  endfunction : is_legal_sub_sample

  protected function bit is_legal_slt_sample();
    rtl_pkg::rtl_alu_pkt_t legal_ap;

    if (sampled_transaction == null) begin
      return 1'b0;
    end

    legal_ap        = '0;
    legal_ap.slt    = 1'b1;
    legal_ap.sub    = 1'b1;
    legal_ap.unsign = sampled_transaction.ap.unsign;

    return (
        (sampled_transaction.rst_l      === 1'b1) &&
        (sampled_transaction.valid_in   === 1'b1) &&
        (sampled_transaction.csr_ren_in === 1'b0) &&
        ((sampled_transaction.ap.unsign === 1'b0) ||
         (sampled_transaction.ap.unsign === 1'b1)) &&
        (sampled_transaction.ap         === legal_ap)
    );
  endfunction : is_legal_slt_sample

  protected function bit is_legal_ctz_sample();
    rtl_pkg::rtl_alu_pkt_t legal_ap;

    if (sampled_transaction == null) begin
      return 1'b0;
    end

    legal_ap     = '0;
    legal_ap.ctz = 1'b1;

    return (
        (sampled_transaction.rst_l      === 1'b1) &&
        (sampled_transaction.valid_in   === 1'b1) &&
        (sampled_transaction.csr_ren_in === 1'b0) &&
        (sampled_transaction.ap         === legal_ap)
    );
  endfunction : is_legal_ctz_sample

  protected function bit is_legal_cpop_sample();
    rtl_pkg::rtl_alu_pkt_t legal_ap;

    if (sampled_transaction == null) begin
      return 1'b0;
    end

    legal_ap      = '0;
    legal_ap.cpop = 1'b1;

    return (
        (sampled_transaction.rst_l      === 1'b1) &&
        (sampled_transaction.valid_in   === 1'b1) &&
        (sampled_transaction.csr_ren_in === 1'b0) &&
        (sampled_transaction.ap         === legal_ap)
    );
  endfunction : is_legal_cpop_sample

  protected function bit is_legal_sext_b_sample();
    rtl_pkg::rtl_alu_pkt_t legal_ap;

    if (sampled_transaction == null) begin
      return 1'b0;
    end

    legal_ap         = '0;
    legal_ap.siext_b = 1'b1;

    return (
        (sampled_transaction.rst_l        === 1'b1) &&
        (sampled_transaction.valid_in     === 1'b1) &&
        (sampled_transaction.csr_ren_in   === 1'b0) &&
        (sampled_transaction.ap           === legal_ap)
    );
  endfunction : is_legal_sext_b_sample

  protected function bit is_legal_max_sample();
    rtl_pkg::rtl_alu_pkt_t legal_ap;

    if (sampled_transaction == null) begin
      return 1'b0;
    end

    legal_ap     = '0;
    legal_ap.max = 1'b1;
    legal_ap.sub = 1'b1;

    return (
        (sampled_transaction.rst_l      === 1'b1) &&
        (sampled_transaction.valid_in   === 1'b1) &&
        (sampled_transaction.csr_ren_in === 1'b0) &&
        (sampled_transaction.ap         === legal_ap)
    );
  endfunction : is_legal_max_sample

  protected function bit is_legal_pack_sample();
    rtl_pkg::rtl_alu_pkt_t legal_ap;

    if (sampled_transaction == null) begin
      return 1'b0;
    end

    legal_ap      = '0;
    legal_ap.pack = 1'b1;

    return (
        (sampled_transaction.rst_l      === 1'b1) &&
        (sampled_transaction.valid_in   === 1'b1) &&
        (sampled_transaction.csr_ren_in === 1'b0) &&
        (sampled_transaction.ap         === legal_ap)
    );
  endfunction : is_legal_pack_sample

  protected function bit is_grev_mode_sample();
    rtl_pkg::rtl_alu_pkt_t legal_ap;

    if (sampled_transaction == null) begin
      return 1'b0;
    end

    legal_ap      = '0;
    legal_ap.grev = 1'b1;

    return (
        (sampled_transaction.rst_l      === 1'b1) &&
        (sampled_transaction.valid_in   === 1'b1) &&
        (sampled_transaction.csr_ren_in === 1'b0) &&
        (sampled_transaction.ap         === legal_ap)
    );
  endfunction : is_grev_mode_sample

  protected function bit is_valid_hold_sample();
    if (sampled_transaction == null) begin
      return 1'b0;
    end

    return (
        (sampled_transaction.rst_l    === 1'b1) &&
        (sampled_transaction.valid_in === 1'b0) &&
        ((sampled_transaction.a_in === 32'h1357_9BDF) ||
         (sampled_transaction.a_in === 32'hAAAA_5555) ||
         (sampled_transaction.a_in === 32'hCAFE_BABE) ||
         (sampled_transaction.a_in === 32'hFFFF_0000))
    );
  endfunction : is_valid_hold_sample

  // COVERGROUPS
  covergroup sanity_flow_cg;
    //track each individual instance instead of global pooling
    option.per_instance = 1;

    accept_cp: coverpoint sampled_transaction.valid_in iff (sampled_transaction.rst_l === 1'b1) {
      bins accepted = {1'b1};
    }
  endgroup : sanity_flow_cg

  covergroup csr_read_cg;
    option.per_instance = 1;

    csr_data_class_cp: coverpoint sampled_transaction.csr_rddata_in
        iff ((sampled_transaction.rst_l       === 1'b1) &&
             (sampled_transaction.valid_in   === 1'b1) &&
             (sampled_transaction.csr_ren_in === 1'b1) &&
             (sampled_transaction.ap         === '0)) {
      bins all_zero = {32'h0000_0000};
      bins all_one = {32'hFFFF_FFFF};
      bins random_non_boundary = {[32'h0000_0001 : 32'hFFFF_FFFE]};
    }

    csr_read_legality_cp: coverpoint
        (sampled_transaction.ap === '0)
        iff ((sampled_transaction.rst_l       === 1'b1) &&
             (sampled_transaction.valid_in   === 1'b1) &&
             (sampled_transaction.csr_ren_in === 1'b1)) {
      bins legal = {1'b1}; bins invalid = {1'b0};
    }
  endgroup

  covergroup csr_write_cg;
    option.per_instance = 1;

    csr_write_mode_cp: coverpoint sampled_transaction.ap.csr_imm iff (is_legal_csr_write_sample()) {
      bins register_source = {1'b0}; bins immediate_source = {1'b1};
    }

    csr_write_selected_data_cp: coverpoint
        ((sampled_transaction.ap.csr_imm === 1'b1)
             ? sampled_transaction.b_in
             : sampled_transaction.a_in)
        iff (is_legal_csr_write_sample()) {
      bins all_zero = {32'h0000_0000};
      bins all_one = {32'hFFFF_FFFF};
      bins random_non_boundary = {[32'h0000_0001 : 32'hFFFF_FFFE]};
    }

    csr_write_mode_source_cross: cross csr_write_mode_cp, csr_write_selected_data_cp;

    csr_write_invalid_control_cp:
        coverpoint sampled_transaction.csr_ren_in
        iff ((sampled_transaction.rst_l        === 1'b1) &&
             (sampled_transaction.valid_in     === 1'b1) &&
             (sampled_transaction.ap.csr_write === 1'b1)) {
      bins csr_read_conflict = {1'b1}; ignore_bins no_csr_read_conflict = {1'b0};
    }
  endgroup : csr_write_cg

  covergroup or_orn_cg;
    option.per_instance = 1;

    or_orn_mode_cp: coverpoint sampled_transaction.ap.zbb iff (is_legal_or_orn_sample()) {
      bins or_mode = {1'b0}; bins orn_mode = {1'b1};
    }

    or_orn_operand_pattern_cp: coverpoint {
      sampled_transaction.a_in, sampled_transaction.b_in
    } iff (is_legal_or_orn_sample()) {
      bins all_zero = {64'h0000_0000_0000_0000};

      bins all_one = {64'hFFFF_FFFF_FFFF_FFFF};

      bins alternating = {64'hAAAA_AAAA_5555_5555, 64'h5555_5555_AAAA_AAAA};

      bins random_non_directed = default;
    }

    or_orn_mode_pattern_cross: cross or_orn_mode_cp, or_orn_operand_pattern_cp;

    or_orn_invalid_control_cp: coverpoint {
      sampled_transaction.csr_ren_in, sampled_transaction.ap.lxor
    } iff ((sampled_transaction.rst_l === 1'b1) && (sampled_transaction.valid_in === 1'b1) &&
           (sampled_transaction.ap.lor === 1'b1)) {
      bins unrelated_operation_conflict = {2'b01};
      bins csr_read_conflict = {2'b10};

      ignore_bins legal_or_orn = {2'b00};
      ignore_bins combined_conflicts = {2'b11};
    }
  endgroup : or_orn_cg

  covergroup xor_xnor_cg;
    option.per_instance = 1;

    xor_xnor_mode_cp: coverpoint sampled_transaction.ap.zbb iff (is_legal_xor_xnor_sample()) {
      bins xor_mode = {1'b0}; bins xnor_mode = {1'b1};
    }

    xor_xnor_operand_class_cp: coverpoint (
        ({sampled_transaction.a_in, sampled_transaction.b_in} ===
         64'h0000_0000_0000_0000) ? 3'd0 :
        ({sampled_transaction.a_in, sampled_transaction.b_in} ===
         64'hFFFF_FFFF_FFFF_FFFF) ? 3'd1 :
        (sampled_transaction.a_in === sampled_transaction.b_in) ? 3'd2 :
        (sampled_transaction.a_in === ~sampled_transaction.b_in) ? 3'd3 :
                                                                    3'd4
    ) iff (is_legal_xor_xnor_sample()) {
      bins all_zero = {3'd0};
      bins all_one = {3'd1};
      bins equal_non_boundary = {3'd2};
      bins complementary = {3'd3};
      bins random_other = {3'd4};
    }

    xor_xnor_mode_operand_cross: cross xor_xnor_mode_cp, xor_xnor_operand_class_cp;

    xor_xnor_invalid_control_cp:
        coverpoint (!is_legal_xor_xnor_sample())
        iff ((sampled_transaction.rst_l    === 1'b1) &&
             (sampled_transaction.valid_in === 1'b1) &&
             (sampled_transaction.ap.lxor  === 1'b1)) {
      bins invalid = {1'b1}; ignore_bins legal = {1'b0};
    }
  endgroup : xor_xnor_cg

  covergroup srl_cg;
    option.per_instance = 1;

    srl_shift_amount_cp: coverpoint sampled_transaction.b_in[4:0] iff (is_legal_srl_sample()) {
      bins zero = {5'd0}; bins interior = {[5'd1 : 5'd30]}; bins maximum = {5'd31};
    }

    srl_operand_msb_cp: coverpoint sampled_transaction.a_in[31] iff (is_legal_srl_sample()) {
      bins msb_clear = {1'b0}; bins msb_set = {1'b1};
    }

    srl_shift_operand_cross: cross srl_shift_amount_cp, srl_operand_msb_cp;
  endgroup : srl_cg

  covergroup sra_cg;
    option.per_instance = 1;

    sra_shift_amount_cp: coverpoint sampled_transaction.b_in[4:0] iff (is_legal_sra_sample()) {
      bins zero = {5'd0}; bins interior = {[5'd1 : 5'd30]}; bins maximum = {5'd31};
    }

    sra_operand_sign_cp: coverpoint sampled_transaction.a_in[31] iff (is_legal_sra_sample()) {
      bins positive = {1'b0}; bins negative = {1'b1};
    }

    sra_shift_sign_cross: cross sra_shift_amount_cp, sra_operand_sign_cp;
  endgroup : sra_cg

  covergroup ror_cg;
    option.per_instance = 1;

    ror_rotate_amount_cp: coverpoint sampled_transaction.b_in[4:0] iff (is_legal_ror_sample()) {
      bins zero = {5'd0}; bins interior = {[5'd1 : 5'd30]}; bins maximum = {5'd31};
    }

    ror_operand_pattern_cp: coverpoint sampled_transaction.a_in[0] iff (is_legal_ror_sample()) {
      bins lsb_clear = {1'b0}; bins lsb_set = {1'b1};
    }

    ror_amount_pattern_cross: cross ror_rotate_amount_cp, ror_operand_pattern_cp;
  endgroup : ror_cg

  covergroup binv_cg;
    option.per_instance = 1;

    binv_index_class_cp: coverpoint sampled_transaction.b_in[4:0] iff (is_legal_binv_sample()) {
      bins zero = {5'd0}; bins interior = {[5'd1 : 5'd30]}; bins maximum = {5'd31};
    }

    binv_selected_bit_cp:
        coverpoint sampled_transaction.a_in[
            sampled_transaction.b_in[4:0]
        ] iff (is_legal_binv_sample()) {
      bins selected_bit_clear = {1'b0}; bins selected_bit_set = {1'b1};
    }

    binv_index_selected_bit_cross: cross binv_index_class_cp, binv_selected_bit_cp;
  endgroup : binv_cg

  covergroup sh2add_cg;
    option.per_instance = 1;

    sh2add_a_data_class_cp: coverpoint $unsigned(
        sampled_transaction.a_in
    ) iff (is_legal_sh2add_sample()) {
      bins zero = {32'h0000_0000};
      bins all_one = {32'hFFFF_FFFF};
      bins non_boundary = {[32'h0000_0001 : 32'hFFFF_FFFE]};
    }

    sh2add_b_data_class_cp:
        coverpoint (
            (sampled_transaction.b_in === 32'h0000_0000) ? 3'd0 :
            (sampled_transaction.b_in === 32'hFFFF_FFFF) ? 3'd1 :
            (sampled_transaction.b_in[4:0] === 5'd0)     ? 3'd2 :
            (sampled_transaction.b_in[4:0] === 5'd31)    ? 3'd3 :
                                                               3'd4
        ) iff (is_legal_sh2add_sample()) {
      bins zero = {3'd0};
      bins all_one = {3'd1};
      bins low_five_zero = {3'd2};
      bins low_five_maximum = {3'd3};
      bins other = {3'd4};
    }

    sh2add_control_class_cp:
        coverpoint (
            (sampled_transaction.ap.zba !== 1'b1) ? 2'd1 :
            is_legal_sh2add_sample()               ? 2'd0 :
                                                     2'd2
        ) iff ((sampled_transaction.rst_l      === 1'b1) &&
               (sampled_transaction.valid_in   === 1'b1) &&
               (sampled_transaction.ap.sh2add  === 1'b1)) {
      bins legal_zba = {2'd0}; bins missing_zba = {2'd1}; bins conflicting_control = {2'd2};
    }
  endgroup : sh2add_cg

  covergroup sub_cg;
    option.per_instance = 1;

    sub_operand_relationship_cp: coverpoint (($unsigned(
        sampled_transaction.a_in
    ) > $unsigned(
        sampled_transaction.b_in
    )) ? 2'd2 : ($unsigned(
        sampled_transaction.a_in
    ) === $unsigned(
        sampled_transaction.b_in
    )) ? 2'd1 : 2'd0) iff (is_legal_sub_sample()) {
      bins a_less_than_b = {2'd0}; bins a_equal_to_b = {2'd1}; bins a_greater_than_b = {2'd2};
    }

    sub_boundary_class_cp: coverpoint ((($unsigned(
        sampled_transaction.a_in
    ) === 32'h0000_0000) && ($unsigned(
        sampled_transaction.b_in
    ) === 32'h0000_0000)) ? 3'd0 : (($unsigned(
        sampled_transaction.a_in
    ) === 32'hFFFF_FFFF) && ($unsigned(
        sampled_transaction.b_in
    ) === 32'hFFFF_FFFF)) ? 3'd1 : (((($unsigned(
        sampled_transaction.a_in
    ) === 32'h0000_0000) && ($unsigned(
        sampled_transaction.b_in
    ) === 32'hFFFF_FFFF))) || (($unsigned(
        sampled_transaction.a_in
    ) === 32'hFFFF_FFFF) && ($unsigned(
        sampled_transaction.b_in
    ) === 32'h0000_0000))) ? 3'd2 : 3'd3) iff (is_legal_sub_sample()) {
      bins both_zero = {3'd0};
      bins both_all_one = {3'd1};
      bins zero_and_all_one = {3'd2};
      bins non_boundary_pair = {3'd3};
    }

    sub_control_class_cp:
        coverpoint (
            (sampled_transaction.ap.zba === 1'b1) ? 3'd1 :
            (sampled_transaction.csr_ren_in === 1'b1) ? 3'd2 :
            is_legal_sub_sample() ? 3'd0 :
                                    3'd3
        ) iff ((sampled_transaction.rst_l    === 1'b1) &&
               (sampled_transaction.valid_in === 1'b1) &&
               (sampled_transaction.ap.sub   === 1'b1) &&
               (sampled_transaction.ap.slt   === 1'b0) &&
               (sampled_transaction.ap.max   === 1'b0)) {
      bins legal = {3'd0};
      bins prohibited_zba = {3'd1};
      bins csr_read_conflict = {3'd2};
      bins in_scope_control_conflict = {3'd3};
    }
  endgroup : sub_cg

  covergroup slt_cg;
    option.per_instance = 1;

    slt_mode_cp: coverpoint sampled_transaction.ap.unsign iff (is_legal_slt_sample()) {
      bins signed_mode = {1'b0}; bins unsigned_mode = {1'b1};
    }

    slt_operand_sign_pair_cp: coverpoint {
      sampled_transaction.a_in[31], sampled_transaction.b_in[31]
    } iff (is_legal_slt_sample()) {
      bins both_nonnegative = {2'b00};
      bins a_nonnegative_b_negative = {2'b01};
      bins a_negative_b_nonnegative = {2'b10};
      bins both_negative = {2'b11};
    }

    slt_relationship_cp: coverpoint ((sampled_transaction.ap.unsign === 1'b1) ? (($unsigned(
        sampled_transaction.a_in
    ) < $unsigned(
        sampled_transaction.b_in
    )) ? 2'd0 : (($unsigned(
        sampled_transaction.a_in
    ) === $unsigned(
        sampled_transaction.b_in
    )) ? 2'd1 : 2'd2)) : (($signed(
        sampled_transaction.a_in
    ) < $signed(
        sampled_transaction.b_in
    )) ? 2'd0 : (($signed(
        sampled_transaction.a_in
    ) === $signed(
        sampled_transaction.b_in
    )) ? 2'd1 : 2'd2))) iff (is_legal_slt_sample()) {
      bins a_less_than_b = {2'd0}; bins a_equal_to_b = {2'd1}; bins a_greater_than_b = {2'd2};
    }

    slt_mode_sign_relationship_cross:
        cross slt_mode_cp,
              slt_operand_sign_pair_cp,
              slt_relationship_cp {
      ignore_bins signed_a_nonnegative_b_negative_impossible =
          binsof(slt_mode_cp.signed_mode) &&
          binsof(slt_operand_sign_pair_cp.a_nonnegative_b_negative) &&
          (binsof(slt_relationship_cp.a_less_than_b) ||
           binsof(slt_relationship_cp.a_equal_to_b));

      ignore_bins signed_a_negative_b_nonnegative_impossible =
          binsof(slt_mode_cp.signed_mode) &&
          binsof(slt_operand_sign_pair_cp.a_negative_b_nonnegative) &&
          (binsof(slt_relationship_cp.a_equal_to_b) ||
           binsof(slt_relationship_cp.a_greater_than_b));

      ignore_bins unsigned_a_nonnegative_b_negative_impossible =
          binsof(slt_mode_cp.unsigned_mode) &&
          binsof(slt_operand_sign_pair_cp.a_nonnegative_b_negative) &&
          (binsof(slt_relationship_cp.a_equal_to_b) ||
           binsof(slt_relationship_cp.a_greater_than_b));

      ignore_bins unsigned_a_negative_b_nonnegative_impossible =
          binsof(slt_mode_cp.unsigned_mode) &&
          binsof(slt_operand_sign_pair_cp.a_negative_b_nonnegative) &&
          (binsof(slt_relationship_cp.a_less_than_b) ||
           binsof(slt_relationship_cp.a_equal_to_b));
    }

    slt_control_class_cp:
        coverpoint (
          (sampled_transaction.csr_ren_in === 1'b1)
              ? 2'd1
              : (is_legal_slt_sample() ? 2'd0 : 2'd2)
        ) iff ((sampled_transaction.rst_l    === 1'b1) &&
               (sampled_transaction.valid_in === 1'b1) &&
               (sampled_transaction.ap.slt   === 1'b1)) {
      bins legal = {2'd0}; bins csr_read_conflict = {2'd1}; bins in_scope_control_conflict = {2'd2};
    }
  endgroup : slt_cg

  covergroup ctz_cg;
    option.per_instance = 1;

    ctz_count_cp: coverpoint count_trailing_zeros(
        sampled_transaction.a_in
    ) iff (is_legal_ctz_sample()) {
      bins zero = {32'd0};
      bins one = {32'd1};
      bins interior = {[32'd2 : 32'd30]};
      bins thirty_one = {32'd31};
      bins thirty_two = {32'd32};
    }

    ctz_invalid_control_cp:
        coverpoint (
            (sampled_transaction.csr_ren_in === 1'b1)
                ? 2'd1
                : (is_legal_ctz_sample() ? 2'd0 : 2'd2)
        ) iff ((sampled_transaction.rst_l    === 1'b1) &&
               (sampled_transaction.valid_in === 1'b1) &&
               (sampled_transaction.ap.ctz   === 1'b1)) {
      bins csr_read_conflict = {2'd1};
      bins in_scope_control_conflict = {2'd2};
      ignore_bins legal = {2'd0};
    }
  endgroup : ctz_cg

  covergroup cpop_cg;
    option.per_instance = 1;

    cpop_count_cp: coverpoint population_count(
        sampled_transaction.a_in
    ) iff (is_legal_cpop_sample()) {
      bins zero = {32'd0};
      bins one = {32'd1};
      bins sixteen = {32'd16};
      bins interior = {[32'd2 : 32'd15], [32'd17 : 32'd31]};
      bins thirty_two = {32'd32};
    }

    cpop_position_class_cp: coverpoint (
        (sampled_transaction.a_in === 32'h0000_0000) ? 2'd0 :
        (sampled_transaction.a_in[31:16] === 16'h0000) ? 2'd1 :
        (sampled_transaction.a_in[15:0]  === 16'h0000) ? 2'd2 :
                                                         2'd3
    ) iff (is_legal_cpop_sample()) {
      ignore_bins no_set_bits = {2'd0};
      bins lower_half_only = {2'd1};
      bins upper_half_only = {2'd2};
      bins both_halves = {2'd3};
    }
  endgroup : cpop_cg

  covergroup sext_b_cg;
    option.per_instance = 1;

    sext_b_low_byte_sign_cp: coverpoint sampled_transaction.a_in[7] iff (is_legal_sext_b_sample()) {
      bins sign_clear = {1'b0}; bins sign_set = {1'b1};
    }

    sext_b_low_byte_data_class_cp:
        coverpoint (
            ((sampled_transaction.a_in[7:0] === 8'h7F) ||
             (sampled_transaction.a_in[7:0] === 8'h80))
        )
        iff (is_legal_sext_b_sample()) {
      bins random_interior = {1'b0}; bins sign_boundary = {1'b1};
    }

    sext_b_sign_data_class_cross: cross sext_b_low_byte_sign_cp, sext_b_low_byte_data_class_cp;

    sext_b_upper_a_invariance_cp:
        coverpoint (
            (sampled_transaction.a_in[31:8] === 24'h000000) ? 2'd0 :
            (sampled_transaction.a_in[31:8] === 24'hFFFFFF) ? 2'd1 :
                                                              2'd2
        )
        iff (is_legal_sext_b_sample() &&
             (sampled_transaction.a_in[7:0] === 8'hA5)) {
      bins upper_zero = {2'd0}; bins upper_one = {2'd1}; ignore_bins other_upper_value = {2'd2};
    }

    sext_b_invalid_control_cp:
        coverpoint (
            (sampled_transaction.csr_ren_in === 1'b1)
                ? 2'd1
                : (is_legal_sext_b_sample() ? 2'd0 : 2'd2)
        )
        iff ((sampled_transaction.rst_l       === 1'b1) &&
             (sampled_transaction.valid_in    === 1'b1) &&
             (sampled_transaction.ap.siext_b  === 1'b1)) {
      bins csr_read_conflict = {2'd1};
      bins in_scope_control_conflict = {2'd2};
      ignore_bins legal = {2'd0};
    }
  endgroup : sext_b_cg

  covergroup max_cg;
    option.per_instance = 1;

    max_signed_relationship_cp: coverpoint (($signed(
        sampled_transaction.a_in
    ) < $signed(
        sampled_transaction.b_in
    )) ? 2'd0 : ($signed(
        sampled_transaction.a_in
    ) === $signed(
        sampled_transaction.b_in
    )) ? 2'd1 : 2'd2) iff (is_legal_max_sample()) {
      bins a_less_than_b = {2'd0}; bins a_equal_to_b = {2'd1}; bins a_greater_than_b = {2'd2};
    }

    max_operand_sign_pair_cp: coverpoint {
      sampled_transaction.a_in[31], sampled_transaction.b_in[31]
    } iff (is_legal_max_sample()) {
      bins both_nonnegative = {2'b00};
      bins a_nonnegative_b_negative = {2'b01};
      bins a_negative_b_nonnegative = {2'b10};
      bins both_negative = {2'b11};
    }

    max_boundary_class_cp:
        coverpoint (
            ((sampled_transaction.a_in === 32'h8000_0000) &&
             (sampled_transaction.b_in === 32'h7FFF_FFFF)) ? 2'd1 :
            ((sampled_transaction.a_in === 32'h7FFF_FFFF) &&
             (sampled_transaction.b_in === 32'h8000_0000)) ? 2'd2 :
                                                             2'd0
        )
        iff (is_legal_max_sample()) {
      bins non_boundary = {2'd0}; bins signed_min_to_max = {2'd1}; bins signed_max_to_min = {2'd2};
    }

    max_relationship_sign_cross: cross max_signed_relationship_cp, max_operand_sign_pair_cp{
      ignore_bins nonnegative_negative_less_or_equal_impossible =
          binsof(max_operand_sign_pair_cp.a_nonnegative_b_negative) &&
          (binsof(max_signed_relationship_cp.a_less_than_b) ||
           binsof(max_signed_relationship_cp.a_equal_to_b));

      ignore_bins negative_nonnegative_equal_or_greater_impossible =
          binsof(max_operand_sign_pair_cp.a_negative_b_nonnegative) &&
          (binsof(max_signed_relationship_cp.a_equal_to_b) ||
           binsof(max_signed_relationship_cp.a_greater_than_b));
    }

    max_relationship_boundary_cross: cross max_signed_relationship_cp, max_boundary_class_cp{
      ignore_bins signed_min_to_max_equal_or_greater_impossible =
          binsof(max_boundary_class_cp.signed_min_to_max) &&
          (binsof(max_signed_relationship_cp.a_equal_to_b) ||
           binsof(max_signed_relationship_cp.a_greater_than_b));

      ignore_bins signed_max_to_min_less_or_equal_impossible =
          binsof(max_boundary_class_cp.signed_max_to_min) &&
          (binsof(max_signed_relationship_cp.a_less_than_b) ||
           binsof(max_signed_relationship_cp.a_equal_to_b));
    }

    max_invalid_control_cp:
        coverpoint (
            (sampled_transaction.csr_ren_in === 1'b1)
                ? 2'd1
                : (is_legal_max_sample() ? 2'd0 : 2'd2)
        )
        iff ((sampled_transaction.rst_l    === 1'b1) &&
             (sampled_transaction.valid_in === 1'b1) &&
             (sampled_transaction.ap.max   === 1'b1)) {
      bins csr_read_conflict = {2'd1};
      bins in_scope_control_conflict = {2'd2};

      ignore_bins legal = {2'd0};
    }
  endgroup : max_cg

  covergroup pack_cg;
    option.per_instance = 1;

    pack_selected_half_pattern_cp:
        coverpoint (
            ((sampled_transaction.a_in[15:0] === 16'h0000) &&
             (sampled_transaction.b_in[15:0] === 16'h0000)) ? 2'd0 :
            ((sampled_transaction.a_in[15:0] === 16'hFFFF) &&
             (sampled_transaction.b_in[15:0] === 16'hFFFF)) ? 2'd1 :
            (sampled_transaction.a_in[15:0] !==
             sampled_transaction.b_in[15:0])                ? 2'd2 :
                                                               2'd3
        )
        iff (is_legal_pack_sample()) {
      bins both_selected_halves_zero = {2'd0};
      bins both_selected_halves_one = {2'd1};
      bins different_selected_halves = {2'd2};

      ignore_bins equal_non_boundary_halves = {2'd3};
    }

    pack_a_upper_invariance_cp:
        coverpoint sampled_transaction.a_in[31:16]
        iff (is_legal_pack_sample() &&
             (sampled_transaction.a_in[15:0] === 16'hA55A) &&
             (sampled_transaction.b_in       === 32'h1357_2468)) {
      bins upper_zero = {16'h0000};
      bins upper_one = {16'hFFFF};

      ignore_bins other_upper_value = {[16'h0001 : 16'hFFFE]};
    }

    pack_b_upper_invariance_cp:
        coverpoint sampled_transaction.b_in[31:16]
        iff (is_legal_pack_sample() &&
             (sampled_transaction.a_in       === 32'h89AB_1357) &&
             (sampled_transaction.b_in[15:0] === 16'h5AA5)) {
      bins upper_zero = {16'h0000};
      bins upper_one = {16'hFFFF};

      ignore_bins other_upper_value = {[16'h0001 : 16'hFFFE]};
    }

    pack_invalid_control_cp:
        coverpoint (
            (sampled_transaction.csr_ren_in === 1'b1)
                ? 2'd1
                : (is_legal_pack_sample() ? 2'd0 : 2'd2)
        )
        iff ((sampled_transaction.rst_l    === 1'b1) &&
             (sampled_transaction.valid_in === 1'b1) &&
             (sampled_transaction.ap.pack  === 1'b1)) {
      bins csr_read_conflict = {2'd1};
      bins in_scope_control_conflict = {2'd2};

      ignore_bins legal = {2'd0};
    }
  endgroup : pack_cg

  covergroup grev_cg;
    option.per_instance = 1;

    grev_mode_cp: coverpoint (sampled_transaction.b_in[4:0] === 5'd24) iff (is_grev_mode_sample()) {
      bins mode_24 = {1'b1}; bins invalid_mode = {1'b0};
    }

    grev_byte_pattern_cp:
        coverpoint (
            (sampled_transaction.a_in === 32'h1234_5678) ? 2'd0 :
            (sampled_transaction.a_in === 32'h55AA_55AA) ? 2'd1 :
                                                               2'd2
        )
        iff (is_grev_mode_sample()) {
      bins distinct_bytes = {2'd0}; bins alternating_bytes = {2'd1}; bins random_other = {2'd2};
    }

    grev_mode_pattern_cross: cross grev_mode_cp, grev_byte_pattern_cp;

    grev_invalid_control_cp:
        coverpoint (
            (sampled_transaction.csr_ren_in === 1'b1)
                ? 2'd1
                : (is_grev_mode_sample() ? 2'd0 : 2'd2)
        )
        iff ((sampled_transaction.rst_l    === 1'b1) &&
             (sampled_transaction.valid_in === 1'b1) &&
             (sampled_transaction.ap.grev  === 1'b1)) {
      bins csr_read_conflict = {2'd1};
      bins in_scope_control_conflict = {2'd2};

      ignore_bins no_control_conflict = {2'd0};
    }
  endgroup : grev_cg

  covergroup valid_hold_cg;
    option.per_instance = 1;

    idle_operand_cp: coverpoint sampled_transaction.a_in iff (is_valid_hold_sample()) {
      bins cleared_controls = {32'h1357_9BDF};
      bins legal_or = {32'hAAAA_5555};
      bins operation_conflict = {32'hCAFE_BABE};
      bins csr_conflict = {32'hFFFF_0000};
    }

    idle_control_cp: coverpoint (
        ((sampled_transaction.ap === '0) &&
         (sampled_transaction.csr_ren_in === 1'b0)) ? 3'd0 :
        ((sampled_transaction.ap.lor === 1'b1) &&
         (sampled_transaction.ap.lxor === 1'b0) &&
         (sampled_transaction.csr_ren_in === 1'b0)) ? 3'd1 :
        ((sampled_transaction.ap.lor === 1'b1) &&
         (sampled_transaction.ap.lxor === 1'b1) &&
         (sampled_transaction.csr_ren_in === 1'b0)) ? 3'd2 :
        ((sampled_transaction.ap.lor === 1'b1) &&
         (sampled_transaction.csr_ren_in === 1'b1)) ? 3'd3 :
                                                       3'd4
    ) iff (is_valid_hold_sample()) {
      bins cleared_controls = {3'd0};
      bins legal_or = {3'd1};
      bins operation_conflict = {3'd2};
      bins csr_conflict = {3'd3};
      ignore_bins other = {3'd4};
    }

    idle_result_hold_cp:
        coverpoint (sampled_transaction.result_ff === 32'hA5C3_5A3C)
        iff (is_valid_hold_sample()) {
      bins held = {1'b1}; ignore_bins changed = {1'b0};
    }

    idle_error_cp: coverpoint sampled_transaction.error iff (is_valid_hold_sample()) {
      bins clear = {1'b0}; bins asserted = {1'b1};
    }

    idle_control_error_cross: cross idle_control_cp, idle_error_cp{
      ignore_bins cleared_controls_with_error =
          binsof(idle_control_cp.cleared_controls) &&
          binsof(idle_error_cp.asserted);

      ignore_bins legal_or_with_error =
          binsof(idle_control_cp.legal_or) &&
          binsof(idle_error_cp.asserted);

      ignore_bins operation_conflict_without_error =
          binsof(idle_control_cp.operation_conflict) &&
          binsof(idle_error_cp.clear);

      ignore_bins csr_conflict_without_error =
          binsof(idle_control_cp.csr_conflict) &&
          binsof(idle_error_cp.clear);
    }
  endgroup : valid_hold_cg

  function new(string name = "bmu_coverage_subscriber", uvm_component parent = null);
    super.new(name, parent);

    sampled_transaction = null;
    sample_count        = 0;
    sanity_flow_cg      = new();
    csr_read_cg         = new();
    csr_write_cg        = new();
    or_orn_cg           = new();
    xor_xnor_cg         = new();
    srl_cg              = new();
    sra_cg              = new();
    ror_cg              = new();
    binv_cg             = new();
    sh2add_cg           = new();
    sub_cg              = new();
    slt_cg              = new();
    ctz_cg              = new();
    cpop_cg             = new();
    sext_b_cg           = new();
    max_cg              = new();
    pack_cg             = new();
    grev_cg             = new();
    valid_hold_cg       = new();
  endfunction : new

  virtual function void write(bmu_sequence_item t);
    if (t == null) begin
      `uvm_fatal("NULL_COVERAGE_TRANSACTION", "The coverage subscriber received a null transaction")
      return;
    end

    sampled_transaction = bmu_sequence_item::type_id::create("coverage_snapshot");

    if (sampled_transaction == null) begin
      `uvm_fatal("NO_COVERAGE_SNAPSHOT", "Failed to create a stable coverage snapshot")
      return;
    end

    sampled_transaction.copy(t);
    sample_observation();
  endfunction : write

  protected virtual function void sample_observation();
    sample_count++;
    sanity_flow_cg.sample();
    csr_read_cg.sample();
    csr_write_cg.sample();
    or_orn_cg.sample();
    xor_xnor_cg.sample();
    srl_cg.sample();
    sra_cg.sample();
    ror_cg.sample();
    binv_cg.sample();
    sh2add_cg.sample();
    sub_cg.sample();
    slt_cg.sample();
    ctz_cg.sample();
    cpop_cg.sample();
    sext_b_cg.sample();
    max_cg.sample();
    pack_cg.sample();
    grev_cg.sample();
    valid_hold_cg.sample();

    `uvm_info(
        "COVERAGE_SAMPLE", $sformatf(
        "Received stable observation %0d: %s", sample_count, sampled_transaction.convert2string()),
        UVM_HIGH)
  endfunction : sample_observation

  virtual function void check_phase(uvm_phase phase);
    super.check_phase(phase);

    if (sanity_flow_cg.get_inst_coverage() < 100.0) begin
      `uvm_error("SANITY_COVERAGE_MISS",
                 "No accepted post-reset request reached the coverage subscriber")
    end
  endfunction : check_phase

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);

    `uvm_info("COVERAGE_SUMMARY", $sformatf(
              {
                "observations=%0d sanity_accept_coverage=%0.2f%% ",
                "csr_read_coverage=%0.2f%% csr_write_coverage=%0.2f%% ",
                "or_orn_coverage=%0.2f%% xor_xnor_coverage=%0.2f%% ",
                "srl_coverage=%0.2f%% sra_coverage=%0.2f%% ",
                "ror_coverage=%0.2f%% binv_coverage=%0.2f%% ",
                "sh2add_coverage=%0.2f%% sub_coverage=%0.2f%%",
                "slt_coverage=%0.2f%% ctz_coverage=%0.2f%%",
                " cpop_coverage=%0.2f%% sext_b_coverage=%0.2f%% ",
                "max_coverage=%0.2f%% pack_coverage=%0.2f%% ",
                "grev_coverage=%0.2f%% valid_hold_coverage=%0.2f%%"
              },
              sample_count,
              sanity_flow_cg.get_inst_coverage(),
              csr_read_cg.get_inst_coverage(),
              csr_write_cg.get_inst_coverage(),
              or_orn_cg.get_inst_coverage(),
              xor_xnor_cg.get_inst_coverage(),
              srl_cg.get_inst_coverage(),
              sra_cg.get_inst_coverage(),
              ror_cg.get_inst_coverage(),
              binv_cg.get_inst_coverage(),
              sh2add_cg.get_inst_coverage(),
              sub_cg.get_inst_coverage(),
              slt_cg.get_inst_coverage(),
              ctz_cg.get_inst_coverage(),
              cpop_cg.get_inst_coverage(),
              sext_b_cg.get_inst_coverage(),
              max_cg.get_inst_coverage(),
              pack_cg.get_inst_coverage(),
              grev_cg.get_inst_coverage(),
              valid_hold_cg.get_inst_coverage()
              ), UVM_NONE)
  endfunction : report_phase

endclass
