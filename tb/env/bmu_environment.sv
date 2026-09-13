class bmu_environment extends uvm_env;
  `uvm_component_utils(bmu_environment)

  bmu_agent               agent;
  bmu_scoreboard          scoreboard;
  bmu_coverage_subscriber coverage_subscriber;

  function new(string name = "bmu_environment", uvm_component parent = null);
    super.new(name, parent);
  endfunction : new

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    agent = bmu_agent::type_id::create("agent", this);

    scoreboard = bmu_scoreboard::type_id::create("scoreboard", this);

    coverage_subscriber = bmu_coverage_subscriber::type_id::create("coverage_subscriber", this);

    if (agent == null) begin
      `uvm_fatal("NO_AGENT", "Failed to create the BMU agent")
    end

    if (scoreboard == null) begin
      `uvm_fatal("NO_SCOREBOARD", "Failed to create the BMU scoreboard")
    end

    if (coverage_subscriber == null) begin
      `uvm_fatal("NO_COVERAGE", "Failed to create the BMU coverage subscriber")
    end
  endfunction : build_phase

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    agent.monitor.analysis_port.connect(scoreboard.analysis_imp);

    agent.monitor.analysis_port.connect(coverage_subscriber.analysis_export);
  endfunction : connect_phase

endclass
