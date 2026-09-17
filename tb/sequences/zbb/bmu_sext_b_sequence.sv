class bmu_sext_b_sequence extends bmu_base_sequence;
  `uvm_object_utils(bmu_sext_b_sequence)

  localparam int unsigned RANDOM_TRIAL_COUNT = 100;
  localparam int unsigned DIRECTED_REQUEST_COUNT = 4;
  localparam int unsigned INVALID_REQUEST_COUNT = 2;
  localparam int unsigned TOTAL_REQUEST_COUNT =
      DIRECTED_REQUEST_COUNT + RANDOM_TRIAL_COUNT + INVALID_REQUEST_COUNT;

  function new(string name = "bmu_sext_b_sequence");
    super.new(name);
  endfunction : new

  virtual task body();
    bmu_sequence_item request;

    // SEXB-01: 8'h7F is the largest byte with sign bit 7 clear.
    send_legal_sext_b("maximum_positive_byte_request", 32'hA5A5_A57F, "SEXB-01");

    // SEXB-02: 8'h80 is the smallest signed byte with sign bit 7 set.
    send_legal_sext_b("minimum_negative_byte_request", 32'h5A5A_5A80, "SEXB-02");

    // SEXB-03: changing only a_in[31:8] must not affect the result.
    send_legal_sext_b("invariance_upper_zero_request", 32'h0000_00A5, "SEXB-03");

    send_legal_sext_b("invariance_upper_one_request", 32'hFFFF_FFA5, "SEXB-03");

    // SEXB-04: random non-boundary low-byte values.
    for (int unsigned i = 0; i < RANDOM_TRIAL_COUNT; i++) begin
      request = create_request($sformatf("random_request_%0d", i));
      apply_legal_defaults(request);

      if (!request.randomize(
              a_in
          ) with {
            a_in[7] == (i % 2);
            a_in[7:0] inside {[8'h01 : 8'h7E], [8'h81 : 8'hFE]};
          }) begin
        `uvm_fatal("SEXT_B_RANDOMIZE", $sformatf("Failed to randomize SEXT.B trial %0d", i))
      end

      request.ap.siext_b = 1'b1;

      `uvm_info("SEXT_B_STIMULUS", $sformatf(
                "SEXB-04 random trial %0d: a_in=0x%08h low_byte=0x%02h",
                i,
                request.a_in,
                request.a_in[7:0]
                ), UVM_MEDIUM)

      send_bmu_request(request);
    end

    // SEXB-I-01: combine SEXT.B with the in-scope CPOP control.
    request = create_request("invalid_cpop_conflict_request");
    apply_legal_defaults(request);

    request.ap.siext_b = 1'b1;
    request.ap.cpop    = 1'b1;
    request.a_in       = 32'h1234_5680;

    `uvm_info("SEXT_B_STIMULUS", "SEXB-I-01 invalid control: SEXT.B combined with in-scope CPOP",
              UVM_MEDIUM)

    send_bmu_request(request);

    // SEXB-I-01: combine SEXT.B with the in-scope CSR-read control.
    request = create_request("invalid_csr_read_conflict_request");
    apply_legal_defaults(request);

    request.ap.siext_b    = 1'b1;
    request.csr_ren_in    = 1'b1;
    request.csr_rddata_in = 32'hCAFE_BABE;
    request.a_in          = 32'h8765_437F;

    `uvm_info("SEXT_B_STIMULUS",
              "SEXB-I-01 invalid control: SEXT.B combined with in-scope CSR read", UVM_MEDIUM)

    send_bmu_request(request);
  endtask : body

  protected task send_legal_sext_b(string request_name, logic [31:0] a_value, string scenario_id);
    bmu_sequence_item request;

    request = create_request(request_name);
    apply_legal_defaults(request);

    request.ap.siext_b = 1'b1;
    request.a_in       = a_value;

    `uvm_info("SEXT_B_STIMULUS", $sformatf("%s legal SEXT.B '%s': a_in=0x%08h low_byte=0x%02h",
                                           scenario_id, request_name, a_value, a_value[7:0]),
              UVM_MEDIUM)

    send_bmu_request(request);
  endtask : send_legal_sext_b

endclass : bmu_sext_b_sequence
