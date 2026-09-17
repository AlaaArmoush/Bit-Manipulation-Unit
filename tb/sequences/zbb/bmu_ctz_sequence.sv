class bmu_ctz_sequence extends bmu_base_sequence;
  `uvm_object_utils(bmu_ctz_sequence)

  localparam int unsigned RANDOM_TRIAL_COUNT = 100;
  localparam int unsigned DIRECTED_REQUEST_COUNT = 5;
  localparam int unsigned INVALID_REQUEST_COUNT = 2;
  localparam int unsigned TOTAL_REQUEST_COUNT =
      DIRECTED_REQUEST_COUNT + RANDOM_TRIAL_COUNT + INVALID_REQUEST_COUNT;

  function new(string name = "bmu_ctz_sequence");
    super.new(name);
  endfunction : new

  virtual task body();
    bmu_sequence_item request;

    // CTZ-01: LSB set gives no trailing zeros.
    send_legal_ctz("lsb_set_request", 32'h0000_0001, "CTZ-01");

    // CTZ-02: a single trailing zero.
    send_legal_ctz("one_trailing_zero_request", 32'h0000_0002, "CTZ-02");

    // CTZ-03: representative interior count.
    send_legal_ctz("eight_trailing_zeros_request", 32'h0000_0100, "CTZ-03");

    // CTZ-04: only MSB set gives 31 zeros
    send_legal_ctz("only_msb_set_request", 32'h8000_0000, "CTZ-04");

    // CTZ-05: the all-zero operand returns the 32-bit width.
    send_legal_ctz("all_zero_request", 32'h0000_0000, "CTZ-05");

    // CTZ-06: randomized operands checked by the independent model.
    for (int unsigned i = 0; i < RANDOM_TRIAL_COUNT; i++) begin
      request = create_request($sformatf("random_request_%0d", i));
      apply_legal_defaults(request);

      if (!request.randomize(
              a_in
          ) with {
            a_in != 32'h0000_0000;
            a_in != 32'h0000_0001;
            a_in != 32'h0000_0002;
            a_in != 32'h0000_0100;
            a_in != 32'h8000_0000;
          }) begin
        `uvm_fatal("CTZ_RANDOMIZE", $sformatf("Failed to randomize CTZ trial %0d", i))
      end

      request.ap.ctz = 1'b1;

      `uvm_info("CTZ_STIMULUS", $sformatf("CTZ-06 random trial %0d: a_in=0x%08h", i, request.a_in),
                UVM_MEDIUM)

      send_bmu_request(request);
    end

    // CTZ-I-01: CTZ combined with the in-scope SRL control.
    request = create_request("invalid_srl_conflict_request");
    apply_legal_defaults(request);

    request.ap.ctz = 1'b1;
    request.ap.srl = 1'b1;
    request.a_in   = 32'h0000_0100;

    `uvm_info("CTZ_STIMULUS", "CTZ-I-01 invalid control: CTZ combined with in-scope SRL",
              UVM_MEDIUM)

    send_bmu_request(request);

    // CTZ-I-01: CTZ combined with the in-scope CSR-read control.
    request = create_request("invalid_csr_read_conflict_request");
    apply_legal_defaults(request);

    request.ap.ctz        = 1'b1;
    request.csr_ren_in    = 1'b1;
    request.csr_rddata_in = 32'hCAFE_BABE;
    request.a_in          = 32'h8000_0000;

    `uvm_info("CTZ_STIMULUS", "CTZ-I-01 invalid control: CTZ combined with in-scope CSR read",
              UVM_MEDIUM)

    send_bmu_request(request);
  endtask : body

  protected task send_legal_ctz(string request_name, logic [31:0] a_value, string scenario_id);
    bmu_sequence_item request;

    request = create_request(request_name);
    apply_legal_defaults(request);

    request.ap.ctz = 1'b1;
    request.a_in   = a_value;

    `uvm_info("CTZ_STIMULUS", $sformatf("%s legal CTZ '%s': a_in=0x%08h", scenario_id,
                                        request_name, a_value), UVM_MEDIUM)

    send_bmu_request(request);
  endtask : send_legal_ctz

endclass : bmu_ctz_sequence
