class bmu_driver extends uvm_driver #(bmu_sequence_item);
  `uvm_component_utils(bmu_driver)

  virtual bmu_interface.driver_mp vif;

  function new(string name = "bmu_driver", uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(virtual bmu_interface.driver_mp)::get(this, "", "vif", vif)) begin
      `uvm_fatal("NO_VIF", $sformatf("%s could not retrieve virtual interface 'vif'",
                                     get_full_name()))
    end
  endfunction : build_phase

  task run_phase(uvm_phase phase);
    bmu_sequence_item req;

    drive_default();

    forever begin
      seq_item_port.get_next_item(req);

      if (req == null) begin
        `uvm_fatal("NULL_REQ", "get_next_item returned a null request")
      end

      forever begin
        while (vif.driver_cb.rst_l !== 1'b1) begin
          drive_default();
          @(vif.driver_cb);
        end

        drive_request(req);
        @(vif.driver_cb);

        if (vif.driver_cb.rst_l === 1'b1) begin
          break;
        end

        drive_default();
      end

      seq_item_port.item_done();
      drive_default();
    end
  endtask

  protected task drive_request(bmu_sequence_item req);
    if ($isunknown(
            {req.valid_in, req.ap, req.csr_ren_in, req.csr_rddata_in, req.a_in, req.b_in}
        )) begin
      `uvm_fatal("UNKNOWN_REQ", $sformatf("Request contains X/Z values: %s", req.convert2string()))
    end

    vif.driver_cb.valid_in      <= req.valid_in;
    vif.driver_cb.ap            <= req.ap;
    vif.driver_cb.csr_ren_in    <= req.csr_ren_in;
    vif.driver_cb.csr_rddata_in <= req.csr_rddata_in;
    vif.driver_cb.a_in          <= req.a_in;
    vif.driver_cb.b_in          <= req.b_in;
  endtask

  protected task drive_default();
    vif.driver_cb.valid_in      <= 1'b0;
    vif.driver_cb.ap            <= '0;
    vif.driver_cb.csr_ren_in    <= 1'b0;
    vif.driver_cb.csr_rddata_in <= '0;
    vif.driver_cb.a_in          <= '0;
    vif.driver_cb.b_in          <= '0;
  endtask
endclass
