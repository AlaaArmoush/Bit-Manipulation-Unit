class bmu_sub_sequence extends bmu_base_sequence;
  `uvm_object_utils(bmu_sub_sequence)

  localparam int unsigned RANDOM_TRIAL_COUNT = 100;
  localparam int unsigned TOTAL_REQUEST_COUNT = RANDOM_TRIAL_COUNT + 10;

  function new(string name = "bmu_sub_sequence");
    super.new(name);
  endfunction : new

  virtual task body();
    bmu_sequence_item request;

    // SUB-01: A greater than B.
    send_legal_sub("a_greater_request", 32'h0000_0014, 32'h0000_0007, "SUB-01");

    // SUB-02: A minus itself must be zero.
    send_legal_sub("equal_operands_request", 32'h1234_5678, 32'h1234_5678, "SUB-02");

    // SUB-03: A less than B.
    send_legal_sub("a_less_request", 32'h0000_0007, 32'h0000_0014, "SUB-03");

    // SUB-04: all zero/all-one operand boundary pairs.
    send_legal_sub("zero_zero_request", 32'h0000_0000, 32'h0000_0000, "SUB-04");
    send_legal_sub("zero_all_one_request", 32'h0000_0000, 32'hFFFF_FFFF, "SUB-04");
    send_legal_sub("all_one_zero_request", 32'hFFFF_FFFF, 32'h0000_0000, "SUB-04");
    send_legal_sub("all_one_all_one_request", 32'hFFFF_FFFF, 32'hFFFF_FFFF, "SUB-04");

    // SUB-01 through SUB-03: random operands are checked by the
    // independent modular-subtraction reference-model rule.
    for (int unsigned i = 0; i < RANDOM_TRIAL_COUNT; i++) begin
      request = create_request($sformatf("random_request_%0d", i));
      apply_legal_defaults(request);

      if (!request.randomize() with {csr_rddata_in == 32'h0000_0000;}) begin
        `uvm_fatal("SUB_RANDOMIZE", $sformatf("Failed to randomize SUB trial %0d", i))
      end

      request.ap.sub = 1'b1;

      `uvm_info("SUB_STIMULUS", $sformatf(
                "SUB-01/SUB-02/SUB-03 random trial %0d: a_in=0x%08h b_in=0x%08h",
                i,
                request.a_in,
                request.b_in
                ), UVM_MEDIUM)

      send_bmu_request(request);
    end

    // SUB-I-01: Zba mode is prohibited for ordinary subtraction.
    request = create_request("invalid_zba_request");
    apply_legal_defaults(request);

    request.ap.sub = 1'b1;
    request.ap.zba = 1'b1;
    request.a_in   = 32'h1234_5678;
    request.b_in   = 32'h0102_0304;

    `uvm_info("SUB_STIMULUS", "SUB-I-01 invalid control: sub asserted with zba set", UVM_MEDIUM)

    send_bmu_request(request);

    // SUB-I-02: conflict with the in-scope CSR-read control.
    request = create_request("invalid_csr_read_conflict_request");
    apply_legal_defaults(request);

    request.ap.sub        = 1'b1;
    request.csr_ren_in    = 1'b1;
    request.csr_rddata_in = 32'hCAFE_BABE;
    request.a_in          = 32'h1234_5678;
    request.b_in          = 32'h0102_0304;

    `uvm_info("SUB_STIMULUS", "SUB-I-02 invalid control: sub combined with CSR read", UVM_MEDIUM)

    send_bmu_request(request);

    // SUB-I-02: conflict with the in-scope SRL operation control.
    request = create_request("invalid_srl_conflict_request");
    apply_legal_defaults(request);

    request.ap.sub = 1'b1;
    request.ap.srl = 1'b1;
    request.a_in   = 32'h8000_0000;
    request.b_in   = 32'h0000_0004;

    `uvm_info("SUB_STIMULUS", "SUB-I-02 invalid control: sub combined with in-scope srl",
              UVM_MEDIUM)

    send_bmu_request(request);
  endtask : body

  protected task send_legal_sub(string request_name, logic [31:0] a_value, logic [31:0] b_value,
                                string scenario_id);
    bmu_sequence_item request;

    request = create_request(request_name);
    apply_legal_defaults(request);

    request.ap.sub = 1'b1;
    request.a_in   = a_value;
    request.b_in   = b_value;

    `uvm_info("SUB_STIMULUS", $sformatf("%s legal SUB '%s': a_in=0x%08h b_in=0x%08h", scenario_id,
                                        request_name, a_value, b_value), UVM_MEDIUM)

    send_bmu_request(request);
  endtask : send_legal_sub

endclass : bmu_sub_sequence
