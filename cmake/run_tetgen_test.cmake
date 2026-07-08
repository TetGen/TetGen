# SPDX-License-Identifier: AGPL-3.0-or-later OR MIT
# Copyright (c) 2025 Jürgen Fuhrmann

# cmake/run_tetgen_test.cmake — Pure-CMake test wrapper for TetGen
#
# Replaces the former shell wrapper (run_tetgen_test.sh) so that the test
# infrastructure has no POSIX-shell dependency and works on every platform
# that CMake supports.
#
# Invoked by CTest via:
#
#   cmake -DTETGEN=<binary>
#         -DFLAGS=<flags>
#         -DINPUT=<file>
#         -DLOGFILE=<path>
#         -P cmake/run_tetgen_test.cmake
#
# Return-code dispatch (same semantics as before):
#
# The exit codes and their meaning are defined by terminatetetgen() in
# tetgen.h; the reason strings below are taken verbatim (or paraphrased)
# from the printf() messages in that function so they stay in sync with
# the source code.
#
#   0  -> PASSED   (normal exit, code 0)
#   3  -> SKIPPED  ("The input surface mesh contain self-intersections.")
#   4  -> SKIPPED  ("A very small input feature size was detected.")
#   5  -> SKIPPED  ("Two very close input facets were detected.")
#   10 -> SKIPPED  ("An input error was detected.")
#   *  -> FAILED   (exit 1 via message(FATAL_ERROR))
#
# For skipped tests, the reason is printed along with the SKIPPED status
# and a "TETGEN_TEST_SKIPPED" marker is emitted. CTest detects skipped
# tests through the SKIP_REGULAR_EXPRESSION property matching that marker
# in the test output.
#

cmake_minimum_required(VERSION 3.16)

# ---------------------------------------------------------------------------
# Split the FLAGS string into a proper CMake list so that execute_process
# passes each flag as a separate argv element, just like a shell would.
# ---------------------------------------------------------------------------
separate_arguments(_flags UNIX_COMMAND "${FLAGS}")

string(TIMESTAMP _timestamp "%Y-%m-%d %H:%M:%S UTC" UTC)

# ---------------------------------------------------------------------------
# Header
# ---------------------------------------------------------------------------
set(_header
"============================================================
TetGen Test
  Binary: ${TETGEN}
  Flags:  ${FLAGS}
  Input:  ${INPUT}
  Log:    ${LOGFILE}
  Date:   ${_timestamp}
============================================================")

message("${_header}")

# ---------------------------------------------------------------------------
# Run TetGen
# ---------------------------------------------------------------------------
execute_process(
  COMMAND "${TETGEN}" ${_flags} "${INPUT}"
  RESULT_VARIABLE _result
  OUTPUT_VARIABLE _stdout
  ERROR_VARIABLE  _stderr
)

# Echo captured output so CTest (and the user) can see it.
if(NOT "${_stdout}" STREQUAL "")
  message("${_stdout}")
endif()
if(NOT "${_stderr}" STREQUAL "")
  message("${_stderr}")
endif()

# ---------------------------------------------------------------------------
# Determine test status
# ---------------------------------------------------------------------------
message("")
message("------------------------------------------------------------")
message("TetGen exit code: ${_result}")

set(_is_skip FALSE)
set(_is_fail FALSE)
set(_reason "")

# The reason strings below correspond to the printf() messages emitted by
# terminatetetgen() in tetgen.h for each exit code; keep them in sync with
# that function if it changes.
if("${_result}" EQUAL 0)
  set(_status "PASSED")
elseif("${_result}" EQUAL 3)
  set(_reason "The input surface mesh contain self-intersections.")
  set(_status "SKIPPED (${_reason})")
  set(_is_skip TRUE)
elseif("${_result}" EQUAL 4)
  set(_reason "A very small input feature size was detected.")
  set(_status "SKIPPED (${_reason})")
  set(_is_skip TRUE)
elseif("${_result}" EQUAL 5)
  set(_reason "Two very close input facets were detected (try -Y option).")
  set(_status "SKIPPED (${_reason})")
  set(_is_skip TRUE)
elseif("${_result}" EQUAL 10)
  set(_reason "An input error was detected.")
  set(_status "SKIPPED (${_reason})")
  set(_is_skip TRUE)
else()
  set(_status "FAILED (unexpected return code ${_result})")
  set(_is_fail TRUE)
endif()

message("Status: ${_status}")

# ---------------------------------------------------------------------------
# Write per-test log file
# ---------------------------------------------------------------------------
get_filename_component(_logdir "${LOGFILE}" DIRECTORY)
file(MAKE_DIRECTORY "${_logdir}")

file(WRITE "${LOGFILE}"
"${_header}
${_stdout}
${_stderr}
------------------------------------------------------------
TetGen exit code: ${_result}
Status: ${_status}
")

# ---------------------------------------------------------------------------
# Signal result to CTest
#
#   SKIP : print the reason plus a marker that SKIP_REGULAR_EXPRESSION will
#          match, exit 0
#   FAIL : message(FATAL_ERROR ...) causes cmake to exit with code 1
#   PASS : normal exit (code 0)
# ---------------------------------------------------------------------------
if(_is_skip)
  message("TETGEN_TEST_SKIPPED: ${_reason}")
elseif(_is_fail)
  message(FATAL_ERROR "Test FAILED with exit code ${_result}")
endif()
