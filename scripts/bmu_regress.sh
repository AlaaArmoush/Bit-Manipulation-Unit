#!/usr/bin/env bash

set -u -o pipefail

if [[ $# -ne 3 ]]; then
    echo "Usage: $0 <suite> <seed> <seeds>" >&2
    exit 2
fi

suite=$1
single_seed=$2
multiple_seeds=$3

if [[ ! $suite =~ ^[[:alnum:]_]+$ ]]; then
    echo "ERROR: invalid suite name: $suite" >&2
    exit 2
fi

suite_file="regress/${suite}.list"

if [[ ! -f $suite_file ]]; then
    echo "ERROR: regression suite does not exist: $suite_file" >&2
    exit 2
fi

if [[ ! -s $suite_file ]]; then
    echo "ERROR: regression suite is empty: $suite_file" >&2
    exit 2
fi

mapfile -t tests < "$suite_file"

if (( ${#tests[@]} == 0 )); then
    echo "ERROR: regression suite contains no tests: $suite_file" >&2
    exit 2
fi

for test_name in "${tests[@]}"; do
    if [[ ! $test_name =~ ^bmu_[[:alnum:]_]+_test$ ]]; then
        echo "ERROR: malformed test entry in $suite_file: '$test_name'" >&2
        exit 2
    fi
done

# A nonempty SEEDS value takes precedence over SEED.
if [[ -n ${multiple_seeds//[[:space:]]/} ]]; then
    selected_seeds=$multiple_seeds
else
    selected_seeds=$single_seed
fi

read -r -a seeds <<< "$selected_seeds"

if (( ${#seeds[@]} == 0 )); then
    echo "ERROR: at least one seed must be supplied" >&2
    exit 2
fi

for seed in "${seeds[@]}"; do
    if [[ ! $seed =~ ^[1-9][0-9]*$ ]]; then
        echo "ERROR: seed must be a positive decimal integer: '$seed'" >&2
        exit 2
    fi
done

make_bin=${MAKE_BIN:-make}

seed_tag=$(IFS=_; echo "${seeds[*]}")
summary_dir="build/regress/${suite}_seeds_${seed_tag}"
summary_file="${summary_dir}/summary.tsv"

mkdir -p "$summary_dir"

printf 'suite\ttest\tseed\tresult\treason\tlog_path\tcoverage_path\n' \
    > "$summary_file"

declare -a result_tests=()
declare -a result_seeds=()
declare -a result_verdicts=()

total_count=0
passed_count=0
failed_count=0

append_reason()
{
    local new_reason=$1

    if [[ -z $reason ]]; then
        reason=$new_reason
    else
        reason="${reason},${new_reason}"
    fi
}

for test_name in "${tests[@]}"; do
    for seed in "${seeds[@]}"; do
        run_dir="build/runs/${test_name}_seed_${seed}"
        run_log="${run_dir}/xrun.log"
        coverage_dir="${run_dir}/cov_work"

        echo "RUN: suite=$suite test=$test_name seed=$seed"

        if "$make_bin" --no-print-directory test \
            TEST="$test_name" \
            SEED="$seed"; then
            make_status=0
        else
            make_status=$?
        fi

        verdict="FAIL"
        reason=""

        if (( make_status != 0 )); then
            append_reason "make_test_exit_${make_status}"
        fi

        if [[ ! -f $run_log ]]; then
            append_reason "missing_xrun_log"
        else
            # Match only the actual final verdict message. UVM's report
            # summary repeats the report ID and must not be counted.
            pass_verdict_count=$(
                grep -Ec '^UVM_INFO .*\[BMU_TEST_PASS\] PASS:' \
                    "$run_log" || true
            )
            fail_verdict_count=$(
                grep -Ec '^UVM_ERROR .*\[BMU_TEST_FAIL\] FAIL:' \
                    "$run_log" || true
            )

            if (( pass_verdict_count == 1 &&
                  fail_verdict_count == 0 )); then
                :
            elif (( pass_verdict_count == 0 &&
                    fail_verdict_count == 1 )); then
                append_reason "BMU_TEST_FAIL"
            elif (( pass_verdict_count == 0 &&
                    fail_verdict_count == 0 )); then
                append_reason "missing_final_BMU_verdict"
            else
                append_reason "malformed_final_BMU_verdict"
            fi

            if grep -Eq '^UVM_FATAL[[:space:]]+@' "$run_log"; then
                append_reason "UVM_FATAL"
            fi

            # Assertion errors can be legitimate DUT failures, so only
            # Cadence fatal diagnostics are classified as simulator failures.
            if grep -Eq \
                '^(xrun|xmsim|xmelab|xmvlog): \*F,' \
                "$run_log"; then
                append_reason "simulator_failure"
            fi
        fi

        coverage_file=""

        if [[ -d $coverage_dir ]]; then
            coverage_file=$(
                find "$coverage_dir" \
                    -type f \
                    -name '*.ucd' \
                    -print \
                    -quit 2>/dev/null
            )
        fi

        if [[ -z $coverage_file ]]; then
            append_reason "missing_coverage_data"
        fi

        if [[ -z $reason ]]; then
            verdict="PASS"
            reason="-"
            ((passed_count += 1))
        else
            ((failed_count += 1))
        fi

        ((total_count += 1))

        result_tests+=("$test_name")
        result_seeds+=("$seed")
        result_verdicts+=("$verdict")

        printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
            "$suite" \
            "$test_name" \
            "$seed" \
            "$verdict" \
            "$reason" \
            "$run_log" \
            "$coverage_dir" >> "$summary_file"
    done
done

echo
printf '%-14s %-34s %-12s %-6s\n' \
    "SUITE" "TEST" "SEED" "RESULT"
printf '%-14s %-34s %-12s %-6s\n' \
    "--------------" \
    "----------------------------------" \
    "------------" \
    "------"

for ((index = 0; index < total_count; index += 1)); do
    printf '%-14s %-34s %-12s %-6s\n' \
        "$suite" \
        "${result_tests[index]}" \
        "${result_seeds[index]}" \
        "${result_verdicts[index]}"
done

echo
printf 'Total:  %d\n' "$total_count"
printf 'Passed: %d\n' "$passed_count"
printf 'Failed: %d\n' "$failed_count"
printf 'Summary: %s\n' "$summary_file"

if (( failed_count != 0 )); then
    exit 1
fi

exit 0
