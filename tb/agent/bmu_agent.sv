class bmu_agent extends uvm_agent;
  `uvm_component_utils(bmu_agent)

  bmu_driver                                 driver;
  bmu_monitor                                monitor;
  bmu_sequencer                              sequencer;

  protected virtual bmu_interface            vif;
  protected virtual bmu_interface.driver_mp  driver_vif;
  protected virtual bmu_interface.monitor_mp monitor_vif;

  function new(string name = "bmu_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(virtual bmu_interface)::get(this, "", "vif", vif)) begin
      `uvm_fatal("NO_VIF", $sformatf("%s could not retrieve mandatory virtual interface 'vif'",
                                     get_full_name()))
    end

    monitor_vif = vif;
    uvm_config_db#(virtual bmu_interface.monitor_mp)::set(this, "monitor", "vif", monitor_vif);

    monitor = bmu_monitor::type_id::create("monitor", this);

    case (get_is_active())
      UVM_ACTIVE: begin
        driver_vif = vif;
        uvm_config_db#(virtual bmu_interface.driver_mp)::set(this, "driver", "vif", driver_vif);

        sequencer = bmu_sequencer::type_id::create("sequencer", this);
        driver    = bmu_driver::type_id::create("driver", this);
      end

      UVM_PASSIVE: begin
        // just observes
      end

      default: begin
        `uvm_fatal("BAD_AGENT_MODE", $sformatf(
                   "%s has an invalid active/passive configuration", get_full_name()))
      end
    endcase
  endfunction : build_phase

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    if (get_is_active() == UVM_ACTIVE) begin
      driver.seq_item_port.connect(sequencer.seq_item_export);
    end
  endfunction : connect_phase
endclass
