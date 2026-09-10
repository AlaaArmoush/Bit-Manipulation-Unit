class bmu_monitor extends uvm_monitor;
  `uvm_component_utils(bmu_monitor)

  virtual bmu_interface.monitor_mp vif;

  uvm_analysis_port #(bmu_sequence_item) analysis_port;

  function new(string name = "bmu_monitor", uvm_component parent);
    super.new(name, parent);
    analysis_port = new("analysis_port", this);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(virtual bmu_interface.monitor_mp)::get(this, "", "vif", vif)) begin
      `uvm_fatal("NO_VIF", $sformatf("%s could not retrieve virtual interface 'vif'",
                                     get_full_name()))
    end
  endfunction : build_phase

  virtual task run_phase(uvm_phase phase);
    forever begin
      @(vif.monitor_cb);
      broadcast_snapshot();
    end
  endtask : run_phase

  protected function void broadcast_snapshot();
    bmu_sequence_item snapshot;

    snapshot               = bmu_sequence_item::type_id::create("snapshot");

    snapshot.valid_in      = vif.monitor_cb.valid_in;
    snapshot.ap            = vif.monitor_cb.ap;
    snapshot.csr_ren_in    = vif.monitor_cb.csr_ren_in;
    snapshot.csr_rddata_in = vif.monitor_cb.csr_rddata_in;
    snapshot.a_in          = vif.monitor_cb.a_in;
    snapshot.b_in          = vif.monitor_cb.b_in;

    snapshot.rst_l         = vif.monitor_cb.rst_l;
    snapshot.scan_mode     = vif.monitor_cb.scan_mode;
    snapshot.result_ff     = vif.monitor_cb.result_ff;
    snapshot.error         = vif.monitor_cb.error;

    analysis_port.write(snapshot);
  endfunction : broadcast_snapshot
endclass
