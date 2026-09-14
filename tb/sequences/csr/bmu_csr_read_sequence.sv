class bmu_csr_read_sequence extends bmu_base_sequence;
  `uvm_object_utils(bmu_csr_read_sequence)

  localparam int unsigned RANDOM_TRIAL_COUNT = 100;
  localparam int unsigned TOTAL_REQUEST_COUNT = RANDOM_TRIAL_COUNT + 4;

  function new(string name = "bmu_csr_read_sequence");
    super.new(name);
  endfunction

  virtual task body();
    bmu_sequence_item request;

    send_legal_csr_read("directed_request", 32'hA5C3_5A3C);

    send_legal_csr_read("all_zero_request", '0);

    send_legal_csr_read("all_one_request", '1);

    for (int unsigned i = 0; i < RANDOM_TRIAL_COUNT; i++) begin
      request = create_request($sformatf("random_request_%0d", i));
      apply_legal_defaults(request);
      if (!request.randomize() with {
            csr_rddata_in != 32'h0000_0000;
            csr_rddata_in != 32'hFFFF_FFFF;
            a_in == 32'sh0000_0000;
            b_in == 32'h0000_0000;
          }) begin
        `uvm_fatal("CSR_READ_RANDOMIZE", $sformatf("Failed to randomize CSR read trial %0d", i))
      end

      request.csr_ren_in = 1'b1;

      `uvm_info("CSR_READ_STIMULUS", $sformatf(
                "CSR-R-04 random trial %0d: csr_rddata_in=0x%08h", i, request.csr_rddata_in),
                UVM_MEDIUM)

      send_bmu_request(request);
    end

    request = create_request("invalid_or_conflict_request");
    apply_legal_defaults(request);
    request.csr_ren_in    = 1'b1;
    request.csr_rddata_in = 32'h1357_9BDF;
    request.ap.lor        = 1'b1;
    request.ap.zbb        = 1'b0;
    `uvm_info("CSR_READ_STIMULUS",
              "CSR-R-05 invalid conflict: CSR read combined with in-scope OR control", UVM_MEDIUM)
    send_bmu_request(request);
  endtask : body

  protected function bmu_sequence_item create_request(string request_name);
    bmu_sequence_item request;
    request = bmu_sequence_item::type_id::create(request_name);
    if (request == null) begin
      `uvm_fatal("NO_CSR_READ_REQUEST", $sformatf("Failed to create CSR read request '%s'",
                                                  request_name))
    end
    return request;
  endfunction : create_request

  protected task send_legal_csr_read(string request_name, logic [31:0] csr_data);
    bmu_sequence_item request;
    request = create_request(request_name);
    apply_legal_defaults(request);

    request.csr_ren_in = 1'b1;
    request.csr_rddata_in = csr_data;

    `uvm_info("CSR_READ_STIMULUS", $sformatf("Sending legal CSR read '%s': csr_rddata_in=0x%08h",
                                             request_name, csr_data), UVM_MEDIUM)

    send_bmu_request(request);
  endtask : send_legal_csr_read

endclass : bmu_csr_read_sequence
