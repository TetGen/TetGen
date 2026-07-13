#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later OR MIT
# Copyright (c) 2026 Jürgen Fuhrmann

# ctest-report.sh
#
#   Runs ctest and augments the "The following tests did not run:" summary
#   with the actual skip reason for each test, pulled from its per-test log
#   file under <build-dir>/Testing/Logs/.
#
#   CTest itself has no way to show a custom skip reason in that summary
#   block (it always prints a bare "(Skipped)"); this wrapper adds an extra
#   annotated block right after it.
#
# Syntax:
#
#   ./ctest-report.sh [ctest options...]
#
#   Run from the build directory (like a normal `ctest` invocation), or pass
#   --test-dir <dir> as you would to ctest.
#
set -o pipefail

# ---------------------------------------------------------------------------
# Determine the build/test directory (mirrors ctest's --test-dir option) so
# we know where to find Testing/Logs/.
# ---------------------------------------------------------------------------
test_dir="."
args=("$@")
for ((i = 0; i < ${#args[@]}; i++)); do
  case "${args[$i]}" in
    --test-dir)
      test_dir="${args[$((i + 1))]}"
      ;;
    --test-dir=*)
      test_dir="${args[$i]#--test-dir=}"
      ;;
  esac
done

log_dir="${test_dir}/Testing/Logs"

tmpfile="$(mktemp)"
trap 'rm -f "$tmpfile"' EXIT

# Run ctest, streaming output live to the terminal while also capturing it
# for post-processing.
stdbuf -oL -eL ctest "$@" 2>&1 | tee "$tmpfile"
ctest_status="${PIPESTATUS[0]}"

# ---------------------------------------------------------------------------
# Look for the "did not run" block and, for each skipped test, look up its
# reason in the corresponding per-test log file.
# ---------------------------------------------------------------------------
if grep -q "^The following tests did not run:" "$tmpfile"; then
  echo
  echo "The following tests did not run: (with reasons)"

  in_block=0
  while IFS= read -r line; do
    if [[ "$line" == "The following tests did not run:"* ]]; then
      in_block=1
      continue
    fi
    if [[ $in_block -eq 1 ]]; then
      if [[ -z "$line" ]]; then
        break
      fi
      if [[ "$line" =~ ^[[:space:]]*([0-9]+)\ -\ (.+)\ \(Skipped\)$ ]]; then
        test_num="${BASH_REMATCH[1]}"
        test_name="${BASH_REMATCH[2]}"

        # Reconstruct the log file name using the same transform as
        # CMakeLists.txt: test name is "tetgen/<input_file>/<flags>",
        # where <flags> is always the last '/'-separated component and
        # starts with '-'.
        rest="${test_name#tetgen/}"
        flags="${rest##*/}"
        input_file="${rest%/*}"
        file_id="${input_file//\//_}"
        flags_id="${flags//-/}"
        logfile="${log_dir}/${file_id}_${flags_id}.log"

        reason=""
        if [[ -f "$logfile" ]]; then
          reason="$(sed -n 's/^Status: SKIPPED (\(.*\))$/\1/p' "$logfile" | tail -n1)"
        fi

        if [[ -n "$reason" ]]; then
          printf '\t%s - %s (Skipped: %s)\n' "$test_num" "$test_name" "$reason"
        else
          printf '\t%s - %s (Skipped: reason unknown, see log)\n' "$test_num" "$test_name"
        fi
      fi
    fi
  done < "$tmpfile"
fi

exit "$ctest_status"
