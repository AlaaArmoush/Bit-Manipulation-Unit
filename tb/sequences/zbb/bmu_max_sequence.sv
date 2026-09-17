class bmu_max_sequence extends bmu_base_sequence;
  `uvm_object_utils(bmu_max_sequence)

  localparam int unsigned RANDOM_TRIAL_COUNT = 100;
  localparam int unsigned DIRECTED_REQUEST_COUNT = 10;
  localparam int unsigned INVALID_REQUEST_COUNT = 2;
  localparam int unsigned TOTAL_REQUEST_COUNT =
      DIRECTED_REQUEST_COUNT + RANDOM_TRIAL_COUNT + INVALID_REQUEST_COUNT;

  function new(string name = "bmu_max_sequence");
    super.new(name);
  endfunction : new

  virtual task body();
    bmu_sequence_item request;

    // MAX-01/MAX-02: positive operands in both operand orders.
    send_legal_max("positive_a_less_request", 32'h0000_000A, 32'h0000_0014, "MAX-02");

    send_legal_max("positive_a_greater_request", 32'h0000_0014, 32'h0000_000A, "MAX-01");

    // MAX-03: equal nonnegative operands.
    send_legal_max("positive_equal_request", 32'h0000_0014, 32'h0000_0014, "MAX-03");

    // MAX-04: compare postive with negative
    send_legal_max("negative_a_positive_b_request", 32'hFFFF_FFF6, 32'h0000_000A, "MAX-02/MAX-04");

    send_legal_max("positive_a_negative_b_request", 32'h0000_000A, 32'hFFFF_FFF6, "MAX-01/MAX-04");

    // MAX-05: two negative operands in both signed relationships.
    send_legal_max("negative_a_less_request", 32'hFFFF_FFEC, 32'hFFFF_FFF6, "MAX-02/MAX-05");

    send_legal_max("negative_a_greater_request", 32'hFFFF_FFF6, 32'hFFFF_FFEC, "MAX-01/MAX-05");

    // MAX-03/MAX-05: equal negative operands.
    send_legal_max("negative_equal_request", 32'hFFFF_FFF6, 32'hFFFF_FFF6, "MAX-03/MAX-05");

    // MAX-06: signed limits in both operand orders. In either case,
    // 32'h7FFF_FFFF is the signed maximum.
    send_legal_max("signed_min_a_signed_max_b_request", 32'h8000_0000, 32'h7FFF_FFFF, "MAX-06");

    send_legal_max("signed_max_a_signed_min_b_request", 32'h7FFF_FFFF, 32'h8000_0000, "MAX-06");

    // Random trials exercise the approved MAX-01 through MAX-05 rule.
    for (int unsigned i = 0; i < RANDOM_TRIAL_COUNT; i++) begin
      request = create_request($sformatf("random_request_%0d", i));
      apply_legal_defaults(request);

      if (!request.randomize(a_in, b_in)) begin
        `uvm_fatal("MAX_RANDOMIZE", $sformatf("Failed to randomize signed MAX trial %0d", i))
      end

      request.ap.max = 1'b1;
      request.ap.sub = 1'b1;

      `uvm_info("MAX_STIMULUS", $sformatf(
                {
                  "MAX-01 through MAX-05 random trial %0d: ", "a_in=0x%08h (%0d) b_in=0x%08h (%0d)"
                },
                i,
                request.a_in,
                $signed(
                    request.a_in
                ),
                request.b_in,
                $signed(
                    request.b_in
                )
                ), UVM_MEDIUM)

      send_bmu_request(request);
    end

    // MAX-I-01: combine MAX with the in-scope SRL control.
    request = create_request("invalid_srl_conflict_request");
    apply_legal_defaults(request);

    request.ap.max = 1'b1;
    request.ap.sub = 1'b1;
    request.ap.srl = 1'b1;
    request.a_in   = 32'hFFFF_FFF6;
    request.b_in   = 32'h0000_000A;

    `uvm_info("MAX_STIMULUS", "MAX-I-01 invalid control: signed MAX combined with in-scope SRL",
              UVM_MEDIUM)

    send_bmu_request(request);

    // MAX-I-01: combine MAX with the in-scope CSR-read control.
    request = create_request("invalid_csr_read_conflict_request");
    apply_legal_defaults(request);

    request.ap.max        = 1'b1;
    request.ap.sub        = 1'b1;
    request.csr_ren_in    = 1'b1;
    request.csr_rddata_in = 32'hCAFE_BABE;
    request.a_in          = 32'h8000_0000;
    request.b_in          = 32'h7FFF_FFFF;

    `uvm_info("MAX_STIMULUS",
              "MAX-I-01 invalid control: signed MAX combined with in-scope CSR read", UVM_MEDIUM)

    send_bmu_request(request);
  endtask : body

  protected task send_legal_max(string request_name, logic [31:0] a_value, logic [31:0] b_value,
                                string scenario_id);
    bmu_sequence_item request;

    request = create_request(request_name);
    apply_legal_defaults(request);

    request.ap.max = 1'b1;
    request.ap.sub = 1'b1;
    request.a_in   = a_value;
    request.b_in   = b_value;

    `uvm_info("MAX_STIMULUS", $sformatf({"%s legal signed MAX '%s': ",
                                         "a_in=0x%08h (%0d) b_in=0x%08h (%0d)"}, scenario_id,
                                          request_name, a_value, $signed(a_value), b_value,
                                          $signed(b_value)), UVM_MEDIUM)

    send_bmu_request(request);
  endtask : send_legal_max

endclass : bmu_max_sequence
