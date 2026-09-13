class bmu_base_test extends uvm_test;
  `uvm_component_utils(bmu_base_test)

  bmu_environment env;
  time            test_timeout;
  int unsigned    run_seed;

  function new(string name = "bmu_base_test", uvm_component parent = null);
    super.new(name, parent);

    test_timeout = 1us;
    run_seed     = 0;
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    void'(uvm_config_db#(time)::get(this, "", "test_timeout", test_timeout));

    uvm_config_db#(uvm_active_passive_enum)::set(this, "env.agent", "is_active", UVM_ACTIVE);

    env = bmu_environment::type_id::create("env", this);

    if (env == null) begin
      `uvm_fatal("NO_ENV", "Failed to create the BMU environment")
    end

    if (!$value$plusargs("BMU_SEED=%d", run_seed)) begin
      `uvm_warning("NO_REPORTED_SEED", "No +BMU_SEED value was supplied for result reporting")
    end
  endfunction : build_phase

  virtual function void start_of_simulation_phase(uvm_phase phase);
    uvm_root root;

    super.start_of_simulation_phase(phase);

    root = uvm_root::get();
    root.set_timeout(test_timeout, 1'b0);

    `uvm_info("TEST_CONFIGURATION", $sformatf(
              "test=%s seed=%0d timeout=%0t", get_type_name(), run_seed, test_timeout), UVM_NONE)
  endfunction : start_of_simulation_phase

  virtual function void report_phase(uvm_phase phase);
    uvm_report_server report_server;
    int error_count;
    int fatal_count;

    super.report_phase(phase);

    report_server = uvm_report_server::get_server();
    error_count   = report_server.get_severity_count(UVM_ERROR);
    fatal_count   = report_server.get_severity_count(UVM_FATAL);

    if ((error_count == 0) && (fatal_count == 0)) begin
      `uvm_info("BMU_TEST_PASS", $sformatf("PASS: test=%s seed=%0d errors=%0d fatals=%0d",
                                           get_type_name(), run_seed, error_count, fatal_count),
                UVM_NONE)
    end else begin
      `uvm_error("BMU_TEST_FAIL", $sformatf(
                 "FAIL: test=%s seed=%0d errors=%0d fatals=%0d",
                 get_type_name(),
                 run_seed,
                 error_count,
                 fatal_count
                 ))
    end
  endfunction : report_phase
endclass
