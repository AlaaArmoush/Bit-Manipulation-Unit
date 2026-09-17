class bmu_reference_model extends uvm_object;
  `uvm_object_utils(bmu_reference_model)

  function new(string name = "bmu_reference_model");
    super.new(name);
  endfunction : new

  protected function automatic logic [31:0] count_trailing_zeros(logic [31:0] operand);
    for (int unsigned bit_index = 0; bit_index < 32; bit_index++) begin
      if (operand[bit_index] === 1'b1) begin
        return bit_index;
      end
    end

    return 32;
  endfunction : count_trailing_zeros

  virtual function bit predict(const ref bmu_sequence_item request,
                               output bmu_sequence_item prediction,
                               output bmu_operation_e predicted_operation);
    rtl_pkg::rtl_alu_pkt_t legal_csr_write_ap;
    rtl_pkg::rtl_alu_pkt_t legal_or_orn_ap;
    rtl_pkg::rtl_alu_pkt_t legal_xor_xnor_ap;
    rtl_pkg::rtl_alu_pkt_t legal_srl_ap;
    rtl_pkg::rtl_alu_pkt_t legal_sra_ap;
    rtl_pkg::rtl_alu_pkt_t legal_ror_ap;
    rtl_pkg::rtl_alu_pkt_t legal_binv_ap;
    rtl_pkg::rtl_alu_pkt_t legal_sh2add_ap;
    rtl_pkg::rtl_alu_pkt_t legal_sub_ap;
    rtl_pkg::rtl_alu_pkt_t legal_slt_ap;
    rtl_pkg::rtl_alu_pkt_t legal_ctz_ap;

    prediction          = null;
    predicted_operation = BMU_OP_UNKNOWN;

    if (request == null) begin
      `uvm_fatal("NULL_REQUEST", "The reference model received a null request")
      return 1'b0;
    end

    // CSR read
    if (request.csr_ren_in === 1'b1) begin
      prediction = bmu_sequence_item::type_id::create("csr_read_prediction");

      if (prediction == null) begin
        `uvm_fatal("NO_PREDICTION", "Failed to create the CSR-read prediction")
        return 1'b0;
      end

      prediction.copy(request);

      if (request.ap === '0) begin
        // CSR-R-01 through CSR-R-04: legal CSR bypass.
        prediction.result_ff = request.csr_rddata_in;
        prediction.error     = 1'b0;
        predicted_operation  = BMU_OP_CSR_READ;
      end else begin
        // CSR-R-05: invalid CSR-read control combination.
        prediction.result_ff = 32'h0000_0000;
        prediction.error     = 1'b1;
        predicted_operation  = BMU_OP_INVALID_CONTROL;
      end

      return 1'b1;
    end

    // CSR write
    if (request.ap.csr_write === 1'b1) begin
      prediction = bmu_sequence_item::type_id::create("csr_write_prediction");

      if (prediction == null) begin
        `uvm_fatal("NO_PREDICTION", "Failed to create the CSR-write prediction")
        return 1'b0;
      end

      prediction.copy(request);

      legal_csr_write_ap           = '0;
      legal_csr_write_ap.csr_write = 1'b1;
      legal_csr_write_ap.csr_imm   = request.ap.csr_imm;

      if ((request.csr_ren_in === 1'b0) &&
          ((request.ap.csr_imm === 1'b0) ||
           (request.ap.csr_imm === 1'b1)) &&
          (request.ap === legal_csr_write_ap)) begin
        // CSR-W-01 through CSR-W-06:
        // immediate mode selects B; register mode selects A.
        if (request.ap.csr_imm === 1'b1) begin
          prediction.result_ff = request.b_in;
          predicted_operation  = BMU_OP_CSR_WRITE_IMMEDIATE;
        end else begin
          prediction.result_ff = request.a_in;
          predicted_operation  = BMU_OP_CSR_WRITE_REGISTER;
        end

        prediction.error = 1'b0;
      end else begin
        // CSR-W-07: accepted CSR-write control conflict.
        prediction.result_ff = 32'h0000_0000;
        prediction.error     = 1'b1;
        predicted_operation  = BMU_OP_INVALID_CONTROL;
      end

      return 1'b1;
    end

    // OR / ORN
    if (request.ap.lor === 1'b1) begin
      prediction = bmu_sequence_item::type_id::create("or_orn_prediction");

      if (prediction == null) begin
        `uvm_fatal("NO_PREDICTION", "Failed to create the OR/ORN prediction")
        return 1'b0;
      end

      prediction.copy(request);

      legal_or_orn_ap     = '0;
      legal_or_orn_ap.lor = 1'b1;
      legal_or_orn_ap.zbb = request.ap.zbb;

      if ((request.csr_ren_in === 1'b0) &&
          ((request.ap.zbb === 1'b0) ||
           (request.ap.zbb === 1'b1)) &&
          (request.ap === legal_or_orn_ap)) begin
        if (request.ap.zbb === 1'b1) begin
          // OR-01 through OR-04 in ORN mode.
          prediction.result_ff = request.a_in | ~request.b_in;
          predicted_operation  = BMU_OP_ORN;
        end else begin
          // OR-01 through OR-04 in OR mode.
          prediction.result_ff = request.a_in | request.b_in;
          predicted_operation  = BMU_OP_OR;
        end

        prediction.error = 1'b0;
      end else begin
        // OR-I-01: accepted OR/ORN request with conflicting controls.
        prediction.result_ff = 32'h0000_0000;
        prediction.error     = 1'b1;
        predicted_operation  = BMU_OP_INVALID_CONTROL;
      end

      return 1'b1;
    end

    // XOR / XNOR
    if (request.ap.lxor === 1'b1) begin
      prediction = bmu_sequence_item::type_id::create("xor_xnor_prediction");

      if (prediction == null) begin
        `uvm_fatal("NO_PREDICTION", "Failed to create the XOR/XNOR prediction")
        return 1'b0;
      end

      prediction.copy(request);

      legal_xor_xnor_ap      = '0;
      legal_xor_xnor_ap.lxor = 1'b1;
      legal_xor_xnor_ap.zbb  = request.ap.zbb;

      if ((request.csr_ren_in === 1'b0) &&
          ((request.ap.zbb === 1'b0) ||
           (request.ap.zbb === 1'b1)) &&
          (request.ap === legal_xor_xnor_ap)) begin
        if (request.ap.zbb === 1'b1) begin
          // XOR-01 through XOR-05 in XNOR mode.
          prediction.result_ff = request.a_in ^ ~request.b_in;
          predicted_operation  = BMU_OP_XNOR;
        end else begin
          // XOR-01 through XOR-05 in XOR mode.
          prediction.result_ff = request.a_in ^ request.b_in;
          predicted_operation  = BMU_OP_XOR;
        end

        prediction.error = 1'b0;
      end else begin
        // XOR-I-01: accepted XOR/XNOR request with conflicting controls.
        prediction.result_ff = 32'h0000_0000;
        prediction.error     = 1'b1;
        predicted_operation  = BMU_OP_INVALID_CONTROL;
      end

      return 1'b1;
    end

    // Shift Right Logical
    if (request.ap.srl === 1'b1) begin
      prediction = bmu_sequence_item::type_id::create("srl_prediction");

      if (prediction == null) begin
        `uvm_fatal("NO_PREDICTION", "Failed to create the SRL prediction")
        return 1'b0;
      end

      prediction.copy(request);

      legal_srl_ap     = '0;
      legal_srl_ap.srl = 1'b1;

      if ((request.csr_ren_in === 1'b0) && (request.ap === legal_srl_ap)) begin
        // SRL-01, SRL-02, SRL-04, SRL-05, and SRL-06:
        // only b_in[4:0] selects the logical shift amount.
        prediction.result_ff = $unsigned(request.a_in) >> request.b_in[4:0];
        prediction.error     = 1'b0;
        predicted_operation  = BMU_OP_SRL;
      end else begin
        // SRL-03: accepted SRL request with conflicting controls.
        prediction.result_ff = 32'h0000_0000;
        prediction.error     = 1'b1;
        predicted_operation  = BMU_OP_INVALID_CONTROL;
      end

      return 1'b1;
    end

    // Shift Right Arithmetic
    if (request.ap.sra === 1'b1) begin
      prediction = bmu_sequence_item::type_id::create("sra_prediction");

      if (prediction == null) begin
        `uvm_fatal("NO_PREDICTION", "Failed to create the SRA prediction")
        return 1'b0;
      end

      prediction.copy(request);

      legal_sra_ap     = '0;
      legal_sra_ap.sra = 1'b1;

      if ((request.csr_ren_in === 1'b0) && (request.ap === legal_sra_ap)) begin
        // SRA-01, SRA-02, SRA-04, SRA-05, and SRA-06:
        // interpret A as a signed 32-bit value and use only b_in[4:0].
        prediction.result_ff = $signed(request.a_in) >>> request.b_in[4:0];
        prediction.error     = 1'b0;
        predicted_operation  = BMU_OP_SRA;
      end else begin
        // SRA-03: accepted SRA request with conflicting controls.
        prediction.result_ff = 32'h0000_0000;
        prediction.error     = 1'b1;
        predicted_operation  = BMU_OP_INVALID_CONTROL;
      end

      return 1'b1;
    end

    // Rotate Right
    if (request.ap.ror === 1'b1) begin
      prediction = bmu_sequence_item::type_id::create("ror_prediction");

      if (prediction == null) begin
        `uvm_fatal("NO_PREDICTION", "Failed to create the ROR prediction")
        return 1'b0;
      end

      prediction.copy(request);

      legal_ror_ap     = '0;
      legal_ror_ap.ror = 1'b1;

      if ((request.csr_ren_in === 1'b0) && (request.ap === legal_ror_ap)) begin
        // ROR-01, ROR-02, ROR-04, ROR-05, and ROR-06:
        // duplicate the 32-bit operand, shift the 64-bit value right by
        // b_in[4:0], and retain the low 32 bits.
        prediction.result_ff = {$unsigned(request.a_in), $unsigned(request.a_in)} >>
            request.b_in[4:0];
        prediction.error = 1'b0;
        predicted_operation = BMU_OP_ROR;
      end else begin
        // ROR-03: accepted ROR request with conflicting controls.
        prediction.result_ff = 32'h0000_0000;
        prediction.error     = 1'b1;
        predicted_operation  = BMU_OP_INVALID_CONTROL;
      end

      return 1'b1;
    end

    // Bit Invert
    if (request.ap.binv === 1'b1) begin
      prediction = bmu_sequence_item::type_id::create("binv_prediction");

      if (prediction == null) begin
        `uvm_fatal("NO_PREDICTION", "Failed to create the BINV prediction")
        return 1'b0;
      end

      prediction.copy(request);

      legal_binv_ap      = '0;
      legal_binv_ap.binv = 1'b1;

      if ((request.csr_ren_in === 1'b0) && (request.ap === legal_binv_ap)) begin
        // BINV-01 through BINV-06:
        // only b_in[4:0] selects the bit toggled in operand A.
        prediction.result_ff = request.a_in ^ (32'b1 << request.b_in[4:0]);
        prediction.error     = 1'b0;
        predicted_operation  = BMU_OP_BINV;
      end else begin
        // BINV-I-01: accepted BINV request with conflicting controls.
        prediction.result_ff = 32'h0000_0000;
        prediction.error     = 1'b1;
        predicted_operation  = BMU_OP_INVALID_CONTROL;
      end

      return 1'b1;
    end

    // Shift Left by Two and Add
    if (request.ap.sh2add === 1'b1) begin
      prediction = bmu_sequence_item::type_id::create("sh2add_prediction");

      if (prediction == null) begin
        `uvm_fatal("NO_PREDICTION", "Failed to create the SH2ADD prediction")
        return 1'b0;
      end

      prediction.copy(request);

      legal_sh2add_ap        = '0;
      legal_sh2add_ap.sh2add = 1'b1;
      legal_sh2add_ap.zba    = 1'b1;

      if ((request.csr_ren_in === 1'b0) && (request.ap === legal_sh2add_ap)) begin
        // SH2-01 through SH2-04:
        // A is always shifted left by exactly two. The 32-bit assignment
        // retains the low 32 bits of the modular addition.
        prediction.result_ff =
            ($unsigned(request.a_in) << 2) + $unsigned(request.b_in);
        prediction.error    = 1'b0;
        predicted_operation = BMU_OP_SH2ADD;
      end else begin
        // SH2-I-01 and SH2-I-02: missing Zba mode or conflicting controls.
        prediction.result_ff = 32'h0000_0000;
        prediction.error     = 1'b1;
        predicted_operation  = BMU_OP_INVALID_CONTROL;
      end

      return 1'b1;
    end

    // Subtraction
    if ((request.ap.sub === 1'b1) && (request.ap.slt === 1'b0) && (request.ap.max === 1'b0)) begin
      prediction = bmu_sequence_item::type_id::create("sub_prediction");

      if (prediction == null) begin
        `uvm_fatal("NO_PREDICTION", "Failed to create the SUB prediction")
        return 1'b0;
      end

      prediction.copy(request);

      legal_sub_ap     = '0;
      legal_sub_ap.sub = 1'b1;

      if ((request.csr_ren_in === 1'b0) && (request.ap === legal_sub_ap)) begin
        // SUB-01 through SUB-04:
        prediction.result_ff = $unsigned(request.a_in) - $unsigned(request.b_in);
        prediction.error     = 1'b0;
        predicted_operation  = BMU_OP_SUB;
      end else begin
        // SUB-I-01 and SUB-I-02: prohibited Zba mode or another
        // conflicting control.
        prediction.result_ff = 32'h0000_0000;
        prediction.error     = 1'b1;
        predicted_operation  = BMU_OP_INVALID_CONTROL;
      end

      return 1'b1;
    end

    // Set Less Than
    if (request.ap.slt === 1'b1) begin
      prediction = bmu_sequence_item::type_id::create("slt_prediction");

      if (prediction == null) begin
        `uvm_fatal("NO_PREDICTION", "Failed to create the SLT/SLTU prediction")
        return 1'b0;
      end

      prediction.copy(request);

      legal_slt_ap        = '0;
      legal_slt_ap.slt    = 1'b1;
      legal_slt_ap.sub    = 1'b1;
      legal_slt_ap.unsign = request.ap.unsign;

      if ((request.csr_ren_in === 1'b0) &&
          ((request.ap.unsign === 1'b0) ||
           (request.ap.unsign === 1'b1)) &&
          (request.ap === legal_slt_ap)) begin
        if (request.ap.unsign === 1'b1) begin
          // SLT-01 through SLT-07 in unsigned SLTU mode.
          prediction.result_ff = {31'b0, ($unsigned(request.a_in) < $unsigned(request.b_in))};
          predicted_operation  = BMU_OP_SLTU;
        end else begin
          // SLT-01 through SLT-07 in signed SLT mode.
          prediction.result_ff = {31'b0, ($signed(request.a_in) < $signed(request.b_in))};
          predicted_operation  = BMU_OP_SLT;
        end

        prediction.error = 1'b0;
      end else begin
        // SLT-I-01: missing required controls or conflicting controls.
        prediction.result_ff = 32'h0000_0000;
        prediction.error     = 1'b1;
        predicted_operation  = BMU_OP_INVALID_CONTROL;
      end

      return 1'b1;
    end

    // Count Trailing Zeros
    if (request.ap.ctz === 1'b1) begin
      prediction = bmu_sequence_item::type_id::create("ctz_prediction");

      if (prediction == null) begin
        `uvm_fatal("NO_PREDICTION", "Failed to create the CTZ prediction")
        return 1'b0;
      end

      prediction.copy(request);

      legal_ctz_ap     = '0;
      legal_ctz_ap.ctz = 1'b1;

      if ((request.csr_ren_in === 1'b0) && (request.ap === legal_ctz_ap)) begin
        // CTZ-01 through CTZ-06:
        // independently scan A from its least-significant bit.
        prediction.result_ff = count_trailing_zeros(request.a_in);
        prediction.error     = 1'b0;
        predicted_operation  = BMU_OP_CTZ;
      end else begin
        // CTZ-I-01: accepted CTZ request with conflicting controls.
        prediction.result_ff = 32'h0000_0000;
        prediction.error     = 1'b1;
        predicted_operation  = BMU_OP_INVALID_CONTROL;
      end

      return 1'b1;
    end

    return 1'b0;  // Request not supported.
  endfunction : predict

endclass : bmu_reference_model
