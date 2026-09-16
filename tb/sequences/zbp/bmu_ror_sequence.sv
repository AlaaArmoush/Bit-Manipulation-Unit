class bmu_ror_sequence extends bmu_base_sequence;
  `uvm_object_utils(bmu_ror_sequence)

  localparam int unsigned RANDOM_TRIAL_COUNT = 100;
  localparam int unsigned TOTAL_REQUEST_COUNT = RANDOM_TRIAL_COUNT + 10;

  function new(string name = "bmu_ror_sequence");
    super.new(name);
  endfunction : new

  virtual task body();
    bmu_sequence_item request;

    // ROR-01
    send_legal_ror("directed_rotate_request", 32'h89AB_CDEF, 32'h0000_0004, "ROR-01");

    // ROR-02: bit leaving LSB re-enter MSB
    send_legal_ror("lsb_wrap_request", 32'h0000_0001, 32'h0000_0001, "ROR-02");

    // ROR-04: rotating by zero -> result equlas a_in
    send_legal_ror("rotate_zero_lsb_clear_request", 32'h1234_5678, 32'h0000_0000, "ROR-04");
    send_legal_ror("rotate_zero_lsb_set_request", 32'h8765_4321, 32'h0000_0000, "ROR-04");

    // ROR-05: rotating right by 31 is equivalent to rotating left by one.
    send_legal_ror("rotate_31_lsb_clear_request", 32'h4000_0000, 32'h0000_001F, "ROR-05");
    send_legal_ror("rotate_31_lsb_set_request", 32'h8000_0001, 32'h0000_001F, "ROR-05");

    // ROR-06: both B values have b_in[4:0] == 5'd13.
    // Changing only b_in[31:5] must not affect the result.
    send_legal_ror("upper_b_zero_request", 32'hC3A5_5A3D, 32'h0000_000D, "ROR-06");

    send_legal_ror("upper_b_one_request", 32'hC3A5_5A3D, 32'hFFFF_FFED, "ROR-06");

    // ROR-01 and ROR-02: randomized legal interior rotations.
    for (int unsigned i = 0; i < RANDOM_TRIAL_COUNT; i++) begin
      request = create_request($sformatf("random_request_%0d", i));
      apply_legal_defaults(request);

      if (!request.randomize() with {
            csr_rddata_in == 32'h0000_0000;
            b_in[4:0] inside {[5'd1 : 5'd30]};
            a_in[0] == i[0];
          }) begin
        `uvm_fatal("ROR_RANDOMIZE", $sformatf("Failed to randomize ROR trial %0d", i))
      end

      request.ap.ror = 1'b1;

      `uvm_info("ROR_STIMULUS", $sformatf(
                {
                  "ROR-01/ROR-02 random trial %0d: ",
                  "a_in=0x%08h b_in=0x%08h rotate_amount=%0d lsb=%0b"
                },
                i,
                request.a_in,
                request.b_in,
                request.b_in[4:0],
                request.a_in[0]
                ), UVM_MEDIUM)

      send_bmu_request(request);
    end

    // ROR-03: ROR combined with the in-scope SRA control.
    request = create_request("invalid_sra_conflict_request");
    apply_legal_defaults(request);

    request.ap.ror = 1'b1;
    request.ap.sra = 1'b1;
    request.a_in   = 32'h89AB_CDEF;
    request.b_in   = 32'h0000_0004;

    `uvm_info("ROR_STIMULUS", "ROR-03 invalid conflict: ror combined with in-scope sra", UVM_MEDIUM)

    send_bmu_request(request);

    // ROR-03: ROR combined with the in-scope CSR-read control.
    request = create_request("invalid_csr_read_conflict_request");
    apply_legal_defaults(request);

    request.ap.ror        = 1'b1;
    request.csr_ren_in    = 1'b1;
    request.csr_rddata_in = 32'hCAFE_BABE;
    request.a_in          = 32'h89AB_CDEF;
    request.b_in          = 32'h0000_0004;

    `uvm_info("ROR_STIMULUS", "ROR-03 invalid conflict: ror combined with in-scope CSR read",
              UVM_MEDIUM)

    send_bmu_request(request);
  endtask : body

  protected task send_legal_ror(string request_name, logic [31:0] a_value, logic [31:0] b_value,
                                string scenario_id);
    bmu_sequence_item request;

    request = create_request(request_name);
    apply_legal_defaults(request);

    request.ap.ror = 1'b1;
    request.a_in   = a_value;
    request.b_in   = b_value;

    `uvm_info("ROR_STIMULUS",
              $sformatf({"%s legal ROR '%s': a_in=0x%08h ", "b_in=0x%08h rotate_amount=%0d"},
                          scenario_id, request_name, a_value, b_value, b_value[4:0]), UVM_MEDIUM)

    send_bmu_request(request);
  endtask : send_legal_ror

endclass : bmu_ror_sequence
