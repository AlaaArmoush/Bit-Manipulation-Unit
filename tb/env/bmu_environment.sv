class bmu_environment extends uvm_env;
  `uvm_component_utils(bmu_environment)

  bmu_agent agent;
  bmu_scoreboard scoreboard;
  bmu_coverage_subscriber coverage_subscriber;

  function new(string name = "bmu_environment", uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    scoreboard = bmu_scoreboard::type_id::create("agent", this);
    coverage_subscriber = bmu_coverage_subscriber::type_id::create("coverage_subscriber", this);

    if (agent == null) `uvm_fatal("NO_AGENT", "Failed to create the BMU agent")

    if (scoreboard == null) `uvm_fatal("NO_SCOREBOARD", "Failed to create the BMU scoreboard")

    if (coverage_subscriber == null)
      `uvm_fatal("NO_COVERAGE", "Failed to create the BMU coverage subscriber")
  endfunction : build_phase

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agent.monitor.analysis_port.connect(scoreboard.analysis_imp);
    agent.monitor.analysis_port.connect(coverage_subscriber.analysis_export);
  endfunction : connect_phase
endclass
