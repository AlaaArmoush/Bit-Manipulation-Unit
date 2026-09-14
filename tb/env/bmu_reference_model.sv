class bmu_reference_model extends uvm_object;
  `uvm_object_utils(bmu_reference_model)

  function new(string name = "bmu_reference_model");
    super.new(name);
  endfunction : new

  virtual function bit predict(const ref bmu_sequence_item request,
                               output bmu_sequence_item prediction);
    prediction = null;

    if (request == null) begin
      `uvm_fatal("NULL_REQUEST", "The reference model received a null request")
      return 1'b0;
    end

    if (request.csr_ren_in === 1'b1) begin
      prediction = bmu_sequence_item::type_id::create("csr_read_prediction");

      if (prediction == null) begin
        `uvm_fatal("NO_PREDICTION", "Failed to create the CSR-read prediction")
        return 1'b0;
      end

      prediction.copy(request);

      if (request.ap === '0) begin
        // CSR-R-01 - CSR-R-04: legal CSR bypass.
        prediction.result_ff = request.csr_rddata_in;
        prediction.error     = 1'b0;
      end else begin
        // CSR-R-05: Invalid CSR-read control combination
        prediction.result_ff = 32'h0000_0000;
        prediction.error     = 1'b1;
      end

      return 1'b1;
    end
    return 1'b0;  // Request not supported
  endfunction : predict
endclass
