class bmu_sanity_sequence extends bmu_base_sequence;
  `uvm_object_utils(bmu_sanity_sequence)

  function new(string name = "bmu_sanity_sequence");
    super.new(name);
  endfunction : new

  virtual task body();
    bmu_sequence_item request;

    request = bmu_sequence_item::type_id::create("csr_read_request");

    if (request == null) begin
      `uvm_fatal("NO_REQUEST", "Failed to create the sanity sequence item")
      return;
    end

    apply_legal_defaults(request);

    request.csr_ren_in    = 1'b1;
    request.csr_rddata_in = 32'hA5C3_5A3C;

    `uvm_info("SANITY_STIMULUS", $sformatf("Sending legal CSR read with expected result 0x%08h",
                                           request.csr_rddata_in), UVM_LOW)

    send_request(request);
  endtask : body

endclass




