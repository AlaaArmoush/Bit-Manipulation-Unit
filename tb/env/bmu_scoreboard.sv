class bmu_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(bmu_scoreboard)

  typedef struct {
    bmu_sequence_item prediction;
    bit error_matched;
  } pending_entry_t;

  uvm_analysis_imp #(bmu_sequence_item, bmu_scoreboard) analyis_imp;
  bmu_reference_model reference_model;
  protected pending_entry_t pending_predictions[$];
  int unsigned match_count;
  int unsigned mismatch_count;

  function new(string name = "bmu_scoreboard", uvm_component parent = null);
    super.new(name, parent);
    analyis_imp = new("analyis_imp", this);
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
    pending_entry_t entry;
    bit result_matched;
    int unsigned discarded_count;

    if (monitor_transaction == null) begin
      `uvm_fatal("NULL_MONITOR_TRANSACTION", "The scoreboard received a null monitor transaction")
      return;
    end

    observation = bmu_sequence_item::type_id::create("scoreboard_observation");
    observation.copy(monitor_transaction);

    if (observation.rst_l === 1'b0) begin
      discarded_count = pending_predictions.size();
      pending_predictions.delete();
      if (discarded_count != 0) begin
        `uvm_info("RESET_FLUSH", $sformatf("Active reset edge discarded %0d pending prediction(s)",
                                           discarded_count), UVM_MEDIUM)
      end
      return;
    end

    if (observation.rst_l !== 1'b1) begin
      mismatch_count++;
      `uvm_error("UNKNOWN_RESET", $sformatf("Reset is X/Z at a monitor observation: %s",
                                            observation.convert2string()))
      return;
    end

    if (pending_predictions.size() != 0) begin
      entry = pending_predictions.pop_front();
      result_matched = compare_result(observation, entry.prediction);
      if (entry.error_matched && result_matched) begin
        match_count++;
        `uvm_info("TRANSACTION_MATCH",
                  $sformatf("Expected and actual transaction matched: result=0x%08h request={%s}",
                            observation.result_ff, entry.prediction.convert2string()), UVM_LOW)
      end else if (entry.error_matched && !result_matched) begin
        mismatch_count++;
      end
    end

    if (observation.valid_in === 1'b1) begin
      if (!reference_model.predict(observation, prediction)) begin
        mismatch_count++;
        `uvm_error("UNSUPPORTED_REQUEST",
                   $sformatf("Accepted request has no implemented reference-model rule: %s",
                             observation.convert2string()))
        return;
      end
      entry.prediction = prediction;
      entry.error_matched = compare_immediate_error(observation, prediction);
      if (!entry.error_matched) begin
        mismatch_count++;
      end
      pending_predictions.push_back(entry);
    end else if (observation.valid_in !== 1'b0) begin
      mismatch_count++;
      `uvm_error("UNKNOWN_VALID", $sformatf("valid_in is X/Z at a monitor observation: %s",
                                            observation.convert2string()))
    end
  endfunction : write

  protected function bit compare_immediate_error(const ref bmu_sequence_item observation,
                                                 const ref bmu_sequence_item prediction);
    if (observation.error !== prediction.error) begin
      `uvm_error("ERROR_MISMATCH",
                 $sformatf("Immediate error mismatch: expected=%0b actual=%0b request={%s}",
                           prediction.error, observation.error, observation.convert2string()))
      return 1'b0;
    end
    return 1'b1;
  endfunction : compare_immediate_error

  protected function bit compare_result(const ref bmu_sequence_item observation,
                                        const ref bmu_sequence_item prediction);
    if (observation.result_ff !== prediction.result_ff) begin
      `uvm_error(
          "RESULT_MISMATCH",
          $sformatf(
              "One-cycle result mismatch: expected=0x%08h actual=0x%08h expected_request={%s}",
              prediction.result_ff, observation.result_ff, prediction.convert2string()))
      return 1'b0;
    end
    return 1'b1;
  endfunction : compare_result

  virtual function void check_phase(uvm_phase phase);
    super.check_phase(phase);
    if (pending_predictions.size() != 0) begin
      `uvm_error("PENDING_PREDICTIONS", $sformatf(
                                            "%0d prediction(s) remained pending at end of test",
                                            pending_predictions.size()))
    end
    if ((match_count == 0) && (mismatch_count == 0) && (pending_predictions.size() == 0)) begin
      `uvm_error("NO_CHECKS", "The scoreboard completed without checking any transaction")
    end
  endfunction : check_phase

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    if ((match_count > 0) && (mismatch_count == 0) && (pending_predictions.size() == 0)) begin
      `uvm_info("SCOREBOARD_PASS", $sformatf("PASS: matches=%0d mismatches=%0d pending=%0d",
                                             match_count, mismatch_count,
                                             pending_predictions.size()), UVM_NONE)
    end else begin
      `uvm_error("SCOREBOARD_FAIL", $sformatf(
                 "FAIL: matches=%0d mismatches=%0d pending=%0d",
                 match_count,
                 mismatch_count,
                 pending_predictions.size()
                 ))
    end
  endfunction : report_phase
endclass


