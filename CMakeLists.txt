# Set the minimum required version of cmake for a project.
cmake_minimum_required(VERSION 3.16)

project(TetGen
  VERSION 1.6.0
  DESCRIPTION "A Quality Tetrahedral Mesh Generator and 3D Delaunay Triangulator"
  LANGUAGES CXX
)

# Add an executable to the project using the specified source files.
add_executable(tetgen ${INC} ${SRC})

# Add a library to the project using the specified source files.
# In Linux/Unix, it will create libtet.a
add_library(tet STATIC tetgen.cxx predicates.cxx)

# Set properties on a target.
# We use this here to set -DTETLIBRARY for when compiling the library.
set_target_properties(tet PROPERTIES "COMPILE_DEFINITIONS" TETLIBRARY)

###############################################################################
# Testing infrastructure using CTest
# SPDX-License-Identifier: AGPL-3.0-or-later OR MIT
# Copyright (c) 2025 Jürgen Fuhrmann
###############################################################################
#
# Usage:
#
#   cmake -B <build-dir> -DTESTFILES_REPO=<url_or_path>
#   cmake --build <build-dir>
#   ctest --test-dir <build-dir> --output-on-failure
#
# The TESTFILES_REPO should point to a Git repository containing .smesh,
# .poly, and .mesh test input files. It will be shallow-cloned at configure
# time.
#
# TetGen return code dispatch:
#   0  -> PASSED
#   3  -> SKIPPED (PLC error detected)
#   4  -> SKIPPED (Small feature detected)
#   5  -> SKIPPED (Try -Y option)
#   10 -> SKIPPED (Input error detected)
#   *  -> FAILED
#
# Per-test log files are written to <build-dir>/Testing/Logs/<inputfile>_<flags>.log
#

include(CTest)

# --- Configurable options ---------------------------------------------------

set(TESTFILES_REPO "https://codeberg.org/TetGen/TetGenTests.git" CACHE STRING
  "URL or local path to the Git repository containing TetGen test files")

# --- Fetch test files and register tests ------------------------------------

if(BUILD_TESTING AND TESTFILES_REPO)

  set(TESTFILES_DIR "${CMAKE_BINARY_DIR}/testfiles")

  # Shallow-clone the testfiles repository at configure time (once).
  if(NOT EXISTS "${TESTFILES_DIR}/.git")
    message(STATUS "Cloning testfiles repository: ${TESTFILES_REPO}")
    execute_process(
      COMMAND git clone --depth 1 "${TESTFILES_REPO}" "${TESTFILES_DIR}"
      RESULT_VARIABLE _git_result
      OUTPUT_VARIABLE _git_output
      ERROR_VARIABLE  _git_error
    )
    if(NOT _git_result EQUAL 0)
      message(WARNING
        "Failed to clone testfiles repository (exit code ${_git_result}):\n"
        "${_git_error}\n"
        "Testing will be disabled."
      )
    endif()
  endif()

  # Load the explicit list of test entries (file + per-file flags).
  # Edit cmake/TetGenTestFiles.cmake to add, remove, or change tests.
  include("${CMAKE_SOURCE_DIR}/cmake/TetGenTestFiles.cmake")

  if(NOT TETGEN_TESTS)
    message(WARNING "No test entries listed in cmake/TetGenTestFiles.cmake")
  endif()

  # Path to the pure-CMake test wrapper script (no shell dependency)
  set(_test_wrapper "${CMAKE_SOURCE_DIR}/cmake/run_tetgen_test.cmake")

  # Directory for per-test log files
  set(TETGEN_LOG_DIR "${CMAKE_BINARY_DIR}/Testing/Logs")
  file(MAKE_DIRECTORY "${TETGEN_LOG_DIR}")

  set(_num_tests 0)

  foreach(_entry IN LISTS TETGEN_TESTS)
    # Each entry is "inputfile|flags1|flags2|..." using '|' as separator
    # (';' would be swallowed by CMake's list semantics).
    # Convert to a proper CMake list, then split.
    string(REPLACE "|" ";" _entry_list "${_entry}")
    list(GET _entry_list 0 _input_file)
    list(REMOVE_AT _entry_list 0)
    # _entry_list now contains only the flag sets

    set(_full_path "${TESTFILES_DIR}/${_input_file}")
    if(NOT EXISTS "${_full_path}")
      message(WARNING "Test file listed but not found: ${_full_path}")
    endif()

    # File extension label for ctest -L filtering
    get_filename_component(_ext "${_input_file}" LAST_EXT)
    string(SUBSTRING "${_ext}" 1 -1 _ext_label)  # strip leading dot

    foreach(_flags IN LISTS _entry_list)
      # Build a unique test name: tetgen/<inputfile>/<flags>
      # e.g. tetgen/smesh/Cow_cut.smesh/-pqQ
      set(_test_name "tetgen/${_input_file}/${_flags}")

      # Log file: flatten subdirectory separators and strip dashes from flags
      string(REPLACE "/" "_" _file_id "${_input_file}")
      string(REPLACE "-" "" _flags_id "${_flags}")
      set(_logfile "${TETGEN_LOG_DIR}/${_file_id}_${_flags_id}.log")

      add_test(
        NAME    "${_test_name}"
        COMMAND "${CMAKE_COMMAND}"
                "-DTETGEN=$<TARGET_FILE:tetgen>"
                "-DFLAGS=${_flags}"
                "-DINPUT=${_full_path}"
                "-DLOGFILE=${_logfile}"
                -P "${_test_wrapper}"
        WORKING_DIRECTORY "${TESTFILES_DIR}"
      )

      # The CMake wrapper prints TETGEN_TEST_SKIPPED for known harmless
      # return codes (3, 4, 5, 10).  CTest matches this marker and marks
      # the test as skipped instead of failed.
      set_tests_properties("${_test_name}" PROPERTIES
        SKIP_REGULAR_EXPRESSION "TETGEN_TEST_SKIPPED"
        TIMEOUT                 30
        LABELS                  "${_ext_label}"
      )

      math(EXPR _num_tests "${_num_tests} + 1")
    endforeach()
  endforeach()

  message(STATUS "Registered ${_num_tests} TetGen test(s) from ${TESTFILES_DIR}")

else()
  if(BUILD_TESTING AND NOT TESTFILES_REPO)
    message(STATUS
      "Testing is enabled but TESTFILES_REPO is not set. "
      "Set -DTESTFILES_REPO=<url_or_path> to enable TetGen tests."
    )
  endif()
endif()
