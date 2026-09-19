# RISC-V Bit Manipulation Unit Verification

A complete UVM verification environment for a 32-bit RISC-V Bit Manipulation Unit, developed using SystemVerilog, UVM, and Cadence Xcelium.

The project focuses on automatic checking, reproducible stimulus, temporal correctness, functional coverage, and exposing genuine RTL defects.

## Verification Scope

The environment verifies:

| Group | Operations and behavior |
|---|---|
| CSR | Read/bypass and write-data selection |
| Logic | OR, ORN, XOR, and XNOR |
| Shifts | SRL, SRA, and ROR |
| Arithmetic | Subtraction, SH2ADD, signed SLT, unsigned SLTU, and signed MAX |
| Bit manipulation | BINV, CTZ, CPOP, and SEXT.B |
| Permutation | PACK and GREV byte reversal |
| Temporal behavior | Synchronous reset, recovery, result hold, idle error, and back-to-back traffic |

Only operations defined by the approved verification plan are tested.

## Verification Architecture

The environment contains:

- An active UVM agent with a sequencer, driver, and monitor
- A race-free interface using separate driver and monitor clocking blocks
- An independent reference model for expected-result calculation
- A self-checking scoreboard with detailed mismatch diagnostics
- A functional-coverage subscriber with feature-specific covergroups
- Assertions for reset, result hold, known inputs, and error behavior
- A common base test providing timeout control and final PASS/FAIL verdicts

The monitor creates a stable transaction snapshot for every observation so the scoreboard and coverage subscriber never depend on a reused transaction handle.

## Project Structure

```text
.
├── Makefile
├── filelist.f
├── docs/
│   └── BMU_Verification_Plan_pdf.pdf
├── regress/                       # Regression suite lists
├── scripts/
│   └── bmu_regress.sh
├── rtl/
│   ├── files_rtl.f
│   ├── <BMU top-level RTL>
│   └── library/
│       ├── <definitions and macros>
│       ├── <parameters and types>
│       └── <support library>
└── tb/
    ├── interfaces/
    ├── assertions/
    ├── agent/
    ├── env/
    │   ├── bmu_reference_model.sv
    │   ├── bmu_scoreboard.sv
    │   ├── bmu_coverage_subscriber.sv
    │   └── bmu_environment.sv
    ├── sequences/
    │   ├── base_integer/
    │   ├── csr/
    │   ├── temporal/
    │   ├── zba/
    │   ├── zbb/
    │   ├── zbp/
    │   └── zbs/
    ├── tests/
    │   ├── base_integer/
    │   ├── csr/
    │   ├── temporal/
    │   ├── zba/
    │   ├── zbb/
    │   ├── zbp/
    │   └── zbs/
    ├── bmu_pkg.sv
    └── tb_top.sv
```
## Checking Strategy

Every accepted operation is evaluated independently by the reference model and compared against the monitored DUT response.

The checker distinguishes between:

- Registered functional results
- Combinational error behavior
- Legal and invalid control combinations
- Active reset edges
- Idle cycles where the previous result must be retained
- Consecutive operations accepted on adjacent cycles

Each test ends with an explicit `BMU_TEST_PASS` or `BMU_TEST_FAIL` verdict. Compilation, waveform activity, or coverage alone is never treated as proof of correctness.

## Test Organization

The project uses one focused UVM test per verification feature. Each test owns its sequence and remains independent from the regression mechanism.

| Test category | Count |
|---|---:|
| End-to-end sanity | 1 |
| Functional features | 17 |
| Temporal behavior | 3 |
| **Total** | **21** |

The tests are composed externally into CSR, base-integer, Zba, Zbb, Zbp, Zbs, temporal, and complete regression suites.

Regression orchestration runs every selected test and seed independently, continues after failures, and records:

- Test and seed
- PASS/FAIL verdict
- Scoreboard match and mismatch counts
- Failed reference-model operation categories
- Log and functional-coverage locations

## Functional Coverage

Coverage is derived from approved verification scenarios and includes:

- Legal operation modes
- Representative and boundary operand classes
- Shift amounts and bit indices
- Signed and unsigned relationships
- Invalid control combinations
- Reset and recovery
- Idle result retention
- Idle error behavior
- Back-to-back operation transitions

Coverage records whether a scenario occurred. Correctness is determined separately by the scoreboard and assertions.

## RTL Bugs Exposed

| ID | Area | Observed defect |
|---|---|---|
| BUG-001 | CSR write | `csr_imm` selects the opposite operand |
| BUG-002 | Control validation | Simultaneous operation controls are not consistently rejected |
| BUG-003 | CTZ | Returns the neighboring bit index for affected inputs |
| BUG-004 | CPOP | Counts only the lower 16 input bits |
| BUG-005 | Signed MAX | Selects the smaller operand when the operands differ |
| BUG-006 | PACK | Concatenates the lower halfwords in reverse operand order |
| BUG-007 | GREV | Rotates halfwords instead of reversing four bytes |
| BUG-008 | Reset | Clears the registered result asynchronously between clock edges even though reset is specified as synchronous |

## Documentation

The complete scope, scenarios, expected behavior, checking strategy, and coverage intent are defined in the [BMU Verification Plan](docs/BMU_Verification_Plan_pdf.pdf).
