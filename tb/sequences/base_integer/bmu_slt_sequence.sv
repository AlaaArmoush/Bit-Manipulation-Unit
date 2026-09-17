class bmu_slt_sequence extends bmu_base_sequence;
  `uvm_object_utils(bmu_slt_sequence)

  localparam int unsigned RANDOM_TRIAL_COUNT = 100;
  localparam int unsigned DIRECTED_REQUEST_COUNT = 16;
  localparam int unsigned INVALID_REQUEST_COUNT = 2;
  localparam int unsigned TOTAL_REQUEST_COUNT =
      DIRECTED_REQUEST_COUNT + RANDOM_TRIAL_COUNT + INVALID_REQUEST_COUNT;

  function new(string name = "bmu_slt_sequence");
    super.new(name);
  endfunction : new

  virtual task body();
    bmu_sequence_item request;

    // SLT-01: A less than B, signed and unsigned.
    send_legal_slt("positive_less_signed_request", 32'h0000_0000, 32'h0000_0001, 1'b0, "SLT-01");
    send_legal_slt("positive_less_unsigned_request", 32'h0000_0000, 32'h0000_0001, 1'b1, "SLT-01");

    // SLT-02: A greater than B, signed and unsigned.
    send_legal_slt("positive_greater_signed_request", 32'h0000_0001, 32'h0000_0000, 1'b0, "SLT-02");
    send_legal_slt("positive_greater_unsigned_request", 32'h0000_0001, 32'h0000_0000, 1'b1,
                   "SLT-02");

    // SLT-03: A equal to B, signed and unsigned.
    send_legal_slt("positive_equal_signed_request", 32'h0000_0001, 32'h0000_0001, 1'b0, "SLT-03");
    send_legal_slt("positive_equal_unsigned_request", 32'h0000_0001, 32'h0000_0001, 1'b1, "SLT-03");

    // SLT-01/SLT-05: A less than B with MSBs set, signed.
    send_legal_slt("negative_less_signed_request", 32'h8000_0000, 32'hFFFF_FFFF, 1'b0,
                   "SLT-01/SLT-05");
    // SLT-01/SLT-06: same operands, unsigned.
    send_legal_slt("unsigned_msb_set_less_request", 32'h8000_0000, 32'hFFFF_FFFF, 1'b1,
                   "SLT-01/SLT-06");

    // SLT-02/SLT-05: A greater than B with MSBs set, signed.
    send_legal_slt("negative_greater_signed_request", 32'hFFFF_FFFF, 32'h8000_0000, 1'b0,
                   "SLT-02/SLT-05");
    // SLT-02/SLT-06: same operands, unsigned.
    send_legal_slt("unsigned_msb_set_greater_request", 32'hFFFF_FFFF, 32'h8000_0000, 1'b1,
                   "SLT-02/SLT-06");

    // SLT-03: A equal to B, all-one operand boundary, signed.
    send_legal_slt("negative_equal_signed_request", 32'hFFFF_FFFF, 32'hFFFF_FFFF, 1'b0, "SLT-03");
    // SLT-03: same operands, unsigned.
    send_legal_slt("unsigned_equal_all_one_request", 32'hFFFF_FFFF, 32'hFFFF_FFFF, 1'b1, "SLT-03");

    // SLT-04/SLT-05/SLT-07: mixed-sign operands, A negative, signed.
    send_legal_slt("mixed_sign_a_negative_signed_request", 32'hFFFF_FFFE, 32'h0000_0001, 1'b0,
                   "SLT-04/SLT-05/SLT-07");
    // SLT-04/SLT-06/SLT-07: same operands, unsigned.
    send_legal_slt("mixed_sign_a_large_unsigned_request", 32'hFFFF_FFFE, 32'h0000_0001, 1'b1,
                   "SLT-04/SLT-06/SLT-07");

    // SLT-04/SLT-05/SLT-07: mixed-sign operands, B negative, signed.
    send_legal_slt("mixed_sign_b_negative_signed_request", 32'h0000_0001, 32'hFFFF_FFFE, 1'b0,
                   "SLT-04/SLT-05/SLT-07");
    // SLT-04/SLT-06/SLT-07: same operands, unsigned.
    send_legal_slt("mixed_sign_b_large_unsigned_request", 32'h0000_0001, 32'hFFFF_FFFE, 1'b1,
                   "SLT-04/SLT-06/SLT-07");

    // SLT-01 through SLT-07: randomized trials, alternating unsign.
    for (int unsigned i = 0; i < RANDOM_TRIAL_COUNT; i++) begin
      request = create_request($sformatf("random_request_%0d", i));
      apply_legal_defaults(request);

      if (!request.randomize() with {csr_rddata_in == 32'h0000_0000;}) begin
        `uvm_fatal("SLT_RANDOMIZE", $sformatf("Failed to randomize SLT/SLTU trial %0d", i))
      end

      request.ap.slt    = 1'b1;
      request.ap.sub    = 1'b1;
      request.ap.unsign = i[0];

      `uvm_info("SLT_STIMULUS", $sformatf(
                {
                  "SLT-01 through SLT-07 random trial %0d: ", "mode=%s a_in=0x%08h b_in=0x%08h"
                },
                i,
                request.ap.unsign ? "SLTU" : "SLT",
                request.a_in,
                request.b_in
                ), UVM_MEDIUM)

      send_bmu_request(request);
    end

    // SLT-I-01: SLT combined with in-scope SRL control.
    request = create_request("invalid_srl_conflict_request");
    apply_legal_defaults(request);

    request.ap.slt = 1'b1;
    request.ap.sub = 1'b1;
    request.ap.srl = 1'b1;
    request.a_in   = 32'hFFFF_FFFE;
    request.b_in   = 32'h0000_0001;

    `uvm_info("SLT_STIMULUS", "SLT-I-01 invalid control: SLT combined with in-scope SRL",
              UVM_MEDIUM)

    send_bmu_request(request);

    // SLT-I-01: SLTU combined with in-scope CSR-read control.
    request = create_request("invalid_csr_read_conflict_request");
    apply_legal_defaults(request);

    request.ap.slt        = 1'b1;
    request.ap.sub        = 1'b1;
    request.ap.unsign     = 1'b1;
    request.csr_ren_in    = 1'b1;
    request.csr_rddata_in = 32'hCAFE_BABE;
    request.a_in          = 32'h0000_0001;
    request.b_in          = 32'hFFFF_FFFE;

    `uvm_info("SLT_STIMULUS", "SLT-I-01 invalid control: SLTU combined with in-scope CSR read",
              UVM_MEDIUM)

    send_bmu_request(request);
  endtask : body

  protected task send_legal_slt(string request_name, logic [31:0] a_value, logic [31:0] b_value,
                                logic unsigned_mode, string scenario_id);
    bmu_sequence_item request;

    request = create_request(request_name);
    apply_legal_defaults(request);

    request.ap.slt    = 1'b1;
    request.ap.sub    = 1'b1;
    request.ap.unsign = unsigned_mode;
    request.a_in      = a_value;
    request.b_in      = b_value;

    `uvm_info("SLT_STIMULUS", $sformatf("%s legal %s '%s': a_in=0x%08h b_in=0x%08h", scenario_id,
                                        unsigned_mode ? "SLTU" : "SLT", request_name, a_value,
                                        b_value), UVM_MEDIUM)

    send_bmu_request(request);
  endtask : send_legal_slt

endclass : bmu_slt_sequence
