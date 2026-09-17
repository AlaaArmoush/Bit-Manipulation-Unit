class bmu_grev_sequence extends bmu_base_sequence;
  `uvm_object_utils(bmu_grev_sequence)

  localparam int unsigned RANDOM_TRIAL_COUNT = 100;
  localparam int unsigned DIRECTED_REQUEST_COUNT = 2;
  localparam int unsigned INVALID_MODE_REQUEST_COUNT = 3;
  localparam int unsigned INVALID_CONTROL_REQUEST_COUNT = 2;
  localparam int unsigned TOTAL_REQUEST_COUNT =
      DIRECTED_REQUEST_COUNT +
      RANDOM_TRIAL_COUNT +
      INVALID_MODE_REQUEST_COUNT +
      INVALID_CONTROL_REQUEST_COUNT;

  function new(string name = "bmu_grev_sequence");
    super.new(name);
  endfunction : new

  virtual task body();
    bmu_sequence_item request;

    // GREV-01 and GREV-02:
    // legal byte-reverse mode with four distinct bytes.
    send_legal_grev("distinct_bytes_request", 32'h1234_5678, "GREV-01/GREV-02");

    // GREV-03: alternating byte pattern.
    send_legal_grev("alternating_bytes_request", 32'h55AA_55AA, "GREV-03");

    // GREV-04: random A values in legal byte-reverse mode.
    for (int unsigned i = 0; i < RANDOM_TRIAL_COUNT; i++) begin
      request = create_request($sformatf("random_request_%0d", i));
      apply_legal_defaults(request);

      if (!request.randomize(
              a_in
          ) with {
            a_in != 32'h1234_5678;
            a_in != 32'h55AA_55AA;
          }) begin
        `uvm_fatal("GREV_RANDOMIZE", $sformatf("Failed to randomize GREV trial %0d", i))
      end

      request.ap.grev = 1'b1;
      request.b_in    = 32'd24;

      `uvm_info("GREV_STIMULUS", $sformatf(
                "GREV-04 random trial %0d: a_in=0x%08h mode=%0d", i, request.a_in, request.b_in[4:0]
                ), UVM_MEDIUM)

      send_bmu_request(request);
    end

    // GREV-I-01:
    // invalid mode applied to each byte-pattern class required by the
    // mode-validity versus byte-pattern coverage cross.
    send_invalid_mode_grev("invalid_mode_distinct_bytes_request", 32'h1234_5678);
    send_invalid_mode_grev("invalid_mode_alternating_bytes_request", 32'h55AA_55AA);
    send_invalid_mode_grev("invalid_mode_other_bytes_request", 32'hDEAD_BEEF);

    // GREV-I-02: combine GREV with the in-scope PACK control.
    request = create_request("invalid_pack_conflict_request");
    apply_legal_defaults(request);

    request.ap.grev = 1'b1;
    request.ap.pack = 1'b1;
    request.a_in    = 32'h1234_5678;
    request.b_in    = 32'd24;

    `uvm_info("GREV_STIMULUS", "GREV-I-02 invalid control: GREV combined with in-scope PACK",
              UVM_MEDIUM)

    send_bmu_request(request);

    // GREV-I-02: combine GREV with the in-scope CSR-read control.
    request = create_request("invalid_csr_read_conflict_request");
    apply_legal_defaults(request);

    request.ap.grev       = 1'b1;
    request.csr_ren_in    = 1'b1;
    request.csr_rddata_in = 32'hCAFE_BABE;
    request.a_in          = 32'h1234_5678;
    request.b_in          = 32'd24;

    `uvm_info("GREV_STIMULUS", "GREV-I-02 invalid control: GREV combined with in-scope CSR read",
              UVM_MEDIUM)

    send_bmu_request(request);
  endtask : body

  protected task send_legal_grev(string request_name, logic [31:0] a_value, string scenario_id);
    bmu_sequence_item request;

    request = create_request(request_name);
    apply_legal_defaults(request);

    request.ap.grev = 1'b1;
    request.a_in    = a_value;
    request.b_in    = 32'd24;

    `uvm_info("GREV_STIMULUS", $sformatf("%s legal GREV '%s': a_in=0x%08h mode=%0d", scenario_id,
                                         request_name, a_value, request.b_in[4:0]), UVM_MEDIUM)

    send_bmu_request(request);
  endtask : send_legal_grev

  protected task send_invalid_mode_grev(string request_name, logic [31:0] a_value);
    bmu_sequence_item request;

    request = create_request(request_name);
    apply_legal_defaults(request);

    request.ap.grev = 1'b1;
    request.a_in    = a_value;
    request.b_in    = 32'd23;

    `uvm_info("GREV_STIMULUS", $sformatf("GREV-I-01 invalid mode '%s': a_in=0x%08h mode=%0d",
                                         request_name, a_value, request.b_in[4:0]), UVM_MEDIUM)

    send_bmu_request(request);
  endtask : send_invalid_mode_grev

endclass : bmu_grev_sequence
