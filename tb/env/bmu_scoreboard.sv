class bmu_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(bmu_scoreboard)

  uvm_analysis_imp #(bmu_sequence_item, bmu_scoreboard) analysis_imp;
  bmu_reference_model reference_model;

  int unsigned match_count;
  int unsigned mismatch_count;

  function new(string name = "bmu_scoreboard", uvm_component parent = null);
    super.new(name, parent);

    analysis_imp = new("analysis_imp", this);
    match_count = 0;
    mismatch_count = 0;
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    reference_model = bmu_reference_model::type_id::create("reference_model", this);

    if (reference_model == null) begin
      `uvm_fatal("NO_MODEL", "Failed to create the BMU reference model")
    end
  endfunction : build_phase

  virtual function void write(bmu_sequence_item monitor_transaction);
    bmu_sequence_item observation;
    bmu_sequence_item prediction;
    bmu_operation_e   predicted_operation;

    if (monitor_transaction == null) begin
      `uvm_fatal("NULL_MONITOR_TRANSACTION", "The scoreboard received a null monitor transaction")
      return;
    end

    observation = bmu_sequence_item::type_id::create("scoreboard_observation");

    if (observation == null) begin
      `uvm_fatal("NO_SCOREBOARD_OBSERVATION", "Failed to create a stable scoreboard observation")
      return;
    end

    observation.copy(monitor_transaction);

    if (observation.rst_l === 1'b0) begin
      return;
    end

    if (observation.rst_l !== 1'b1) begin
      mismatch_count++;

      `uvm_error("SB_UNKNOWN_RESET", $sformatf(
                                         "Reset is X/Z at a monitor observation\nObservation: %s",
                                         observation.convert2string()))
      return;
    end

    if (observation.valid_in === 1'b1) begin
      if (!reference_model.predict(observation, prediction, predicted_operation)) begin
        mismatch_count++;

        `uvm_error("SB_UNSUPPORTED_REQUEST",
                   $sformatf({"Transaction %0d FAILED\n",
                              "Reason  : no implemented reference-model rule\n", "Request : %s"},
                               match_count + mismatch_count, observation.convert2string()))
        return;
      end

      check_prediction(observation, prediction, predicted_operation);

    end else if (observation.valid_in !== 1'b0) begin
      mismatch_count++;

      `uvm_error("SB_UNKNOWN_VALID",
                 $sformatf("valid_in is X/Z at a monitor observation\nObservation: %s",
                           observation.convert2string()))
    end
  endfunction : write

  protected function void check_prediction(const ref bmu_sequence_item observation,
                                           const ref bmu_sequence_item prediction,
                                           input bmu_operation_e predicted_operation);
    int unsigned transaction_number;
    bit          result_mismatch;
    bit          error_mismatch;
    string       operation_name;
    string       failed_fields;

    transaction_number = match_count + mismatch_count + 1;
    result_mismatch    = observation.result_ff !== prediction.result_ff;
    error_mismatch     = observation.error !== prediction.error;
    operation_name     = predicted_operation.name();
    failed_fields      = "";

    if (result_mismatch) begin
      failed_fields = "RESULT";
    end

    if (error_mismatch) begin
      if (failed_fields.len() != 0) begin
        failed_fields = {failed_fields, ", ERROR"};
      end else begin
        failed_fields = "ERROR";
      end
    end

    if (result_mismatch || error_mismatch) begin
      mismatch_count++;

      `uvm_error("SB_MISMATCH",
                 $sformatf({"Transaction %0d FAILED\n", "Operation : %s\n", "CSR data  : 0x%08h\n",
                            "A         : 0x%08h\n", "B         : 0x%08h\n", "csr_imm   : %0b\n",
                            "AP        : 0x%0h\n", "Result    : expected=0x%08h actual=0x%08h\n",
                            "Error     : expected=%0b actual=%0b\n", "Failed fields: %s"},
                             transaction_number, operation_name, prediction.csr_rddata_in,
                             prediction.a_in, prediction.b_in, prediction.ap.csr_imm,
                             prediction.ap, prediction.result_ff, observation.result_ff,
                             prediction.error, observation.error, failed_fields))
    end else begin
      match_count++;

      `uvm_info("SB_MATCH", $sformatf(
                {
                  "Transaction %0d PASSED: operation=%s ", "result=0x%08h error=%0b"
                },
                transaction_number,
                operation_name,
                observation.result_ff,
                observation.error
                ), UVM_HIGH)
    end
  endfunction : check_prediction

  virtual function void check_phase(uvm_phase phase);
    super.check_phase(phase);

    if ((match_count == 0) && (mismatch_count == 0)) begin
      `uvm_error("SB_NO_CHECKS",
                 "The scoreboard completed without checking any accepted transaction")
    end
  endfunction : check_phase

  virtual function void report_phase(uvm_phase phase);
    int unsigned checked_count;

    super.report_phase(phase);

    checked_count = match_count + mismatch_count;

    if ((checked_count > 0) && (mismatch_count == 0)) begin
      `uvm_info("SB_PASS", $sformatf("SCOREBOARD PASS: checked=%0d matches=%0d mismatches=0",
                                     checked_count, match_count), UVM_NONE)
    end else begin
      `uvm_error("SB_FAIL", $sformatf(
                 "SCOREBOARD FAIL: checked=%0d matches=%0d mismatches=%0d",
                 checked_count,
                 match_count,
                 mismatch_count
                 ))
    end
  endfunction : report_phase

endclass : bmu_scoreboard
