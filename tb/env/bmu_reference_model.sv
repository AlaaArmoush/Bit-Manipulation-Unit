class bmu_reference_model extends uvm_object;
  `uvm_object_utils(bmu_reference_model)

  function new(string name = "bmu_reference_model");
    super.new(name);
  endfunction : new

  virtual function bit predict(const ref bmu_sequence_item request,
                               output bmu_sequence_item prediction,
                               output bmu_operation_e predicted_operation);
    rtl_pkg::rtl_alu_pkt_t legal_csr_write_ap;
    rtl_pkg::rtl_alu_pkt_t legal_or_orn_ap;
    rtl_pkg::rtl_alu_pkt_t legal_xor_xnor_ap;
    rtl_pkg::rtl_alu_pkt_t legal_srl_ap;
    rtl_pkg::rtl_alu_pkt_t legal_sra_ap;
    rtl_pkg::rtl_alu_pkt_t legal_ror_ap;

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

    return 1'b0;  // Request not supported.
  endfunction : predict

endclass : bmu_reference_model
