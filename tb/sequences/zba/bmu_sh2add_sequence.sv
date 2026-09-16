class bmu_sh2add_sequence extends bmu_base_sequence;
  `uvm_object_utils(bmu_sh2add_sequence)

  localparam int unsigned RANDOM_TRIAL_COUNT = 100;
  localparam int unsigned TOTAL_REQUEST_COUNT = RANDOM_TRIAL_COUNT + 8;

  function new(string name = "bmu_sh2add_sequence");
    super.new(name);
  endfunction : new

  virtual task body();
    bmu_sequence_item request;

    // SH2-01: B equal zero
    send_legal_sh2add("b_zero_request", 32'h1234_5678, 32'h0000_0000, "SH2-01");

    // SH2-02: A equal zero
    send_legal_sh2add("a_zero_request", 32'h0000_0000, 32'h89AB_CDEF, "SH2-02");

    // SH2-03: normal directed arithmetic.
    send_legal_sh2add("normal_request", 32'h0000_0004, 32'h0000_0007, "SH2-03");

    // SH2-03 boundary: the result is truncated to the low 32 bits.
    send_legal_sh2add("wraparound_request", 32'hFFFF_FFFF, 32'hFFFF_FFFF, "SH2-03");

    // SH2-04: only B[4:0] changes.
    send_legal_sh2add("b_low_bits_zero_request", 32'h1357_9BDF, 32'h1111_1100, "SH2-04");

    send_legal_sh2add("b_low_bits_max_request", 32'h1357_9BDF, 32'h1111_111F, "SH2-04");

    // SH2-03: constrained-random legal operands.
    for (int unsigned i = 0; i < RANDOM_TRIAL_COUNT; i++) begin
      request = create_request($sformatf("random_request_%0d", i));
      apply_legal_defaults(request);

      if (!request.randomize() with {csr_rddata_in == 32'h0000_0000;}) begin
        `uvm_fatal("SH2ADD_RANDOMIZE", $sformatf("Failed to randomize SH2ADD trial %0d", i))
      end

      request.ap.sh2add = 1'b1;
      request.ap.zba    = 1'b1;

      `uvm_info("SH2ADD_STIMULUS", $sformatf(
                "SH2-03 random trial %0d: a_in=0x%08h b_in=0x%08h", i, request.a_in, request.b_in),
                UVM_MEDIUM)

      send_bmu_request(request);
    end

    // SH2-I-01: SH2ADD without its required Zba mode.
    request = create_request("missing_zba_request");
    apply_legal_defaults(request);

    request.ap.sh2add = 1'b1;
    request.ap.zba    = 1'b0;
    request.a_in      = 32'h1234_5678;
    request.b_in      = 32'h89AB_CDEF;

    `uvm_info("SH2ADD_STIMULUS", "SH2-I-01 invalid control: sh2add asserted with zba clear",
              UVM_MEDIUM)

    send_bmu_request(request);

    // SH2-I-02: conflict with the in-scope SRL operation control.
    request = create_request("invalid_srl_conflict_request");
    apply_legal_defaults(request);

    request.ap.sh2add = 1'b1;
    request.ap.zba    = 1'b1;
    request.ap.srl    = 1'b1;
    request.a_in      = 32'hA5A5_5A5A;
    request.b_in      = 32'h0000_0003;

    `uvm_info("SH2ADD_STIMULUS", "SH2-I-02 invalid control: sh2add combined with in-scope srl",
              UVM_MEDIUM)

    send_bmu_request(request);
  endtask : body

  protected task send_legal_sh2add(string request_name, logic [31:0] a_value, logic [31:0] b_value,
                                   string scenario_id);
    bmu_sequence_item request;

    request = create_request(request_name);
    apply_legal_defaults(request);

    request.ap.sh2add = 1'b1;
    request.ap.zba    = 1'b1;
    request.a_in      = a_value;
    request.b_in      = b_value;

    `uvm_info("SH2ADD_STIMULUS", $sformatf("%s legal SH2ADD '%s': a_in=0x%08h b_in=0x%08h",
                                           scenario_id, request_name, a_value, b_value), UVM_MEDIUM)

    send_bmu_request(request);
  endtask : send_legal_sh2add

endclass : bmu_sh2add_sequence
