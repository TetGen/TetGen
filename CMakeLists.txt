# Set the minimum required version of cmake for a project.
cmake_minimum_required(VERSION 3.16)

project(TetGen
  VERSION 1.6.0
  DESCRIPTION "A Quality Tetrahedral Mesh Generator and 3D Delaunay Triangulator"
  LANGUAGES CXX
)

# Add an executable to the project using the specified source files.
add_executable(tetgen tetgen.cxx predicates.cxx)

# Add a library to the project using the specified source files.
# In Linux/Unix, it will create libtet.a
add_library(tet STATIC tetgen.cxx predicates.cxx)

# Set properties on a target.
# We use this here to set -DTETLIBRARY for when compiling the library.
set_target_properties(tet PROPERTIES "COMPILE_DEFINITIONS" TETLIBRARY)

###############################################################################
# Testing infrastructure using CTest
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
# Per-test log files are written to <build-dir>/Testing/Logs/<inputfile>.log
#

include(CTest)

# --- Configurable options ---------------------------------------------------

set(TESTFILES_REPO "" CACHE STRING
  "URL or local path to the Git repository containing TetGen test files")

set(TETGEN_TEST_FLAGS "-pqQ" CACHE STRING
  "TetGen command-line flags used during testing")

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

  # Discover test input files (.smesh, .poly, .mesh).
  # .node files accompany .smesh/.poly files and are not tested separately.
  file(GLOB _test_inputs
    "${TESTFILES_DIR}/*.smesh"
    "${TESTFILES_DIR}/*.poly"
    "${TESTFILES_DIR}/*.mesh"
  )

  list(SORT _test_inputs)

  if(NOT _test_inputs)
    message(WARNING "No test input files found in ${TESTFILES_DIR}")
  endif()

  # Path to the pure-CMake test wrapper script (no shell dependency)
  set(_test_wrapper "${CMAKE_SOURCE_DIR}/cmake/run_tetgen_test.cmake")

  # Directory for per-test log files
  set(TETGEN_LOG_DIR "${CMAKE_BINARY_DIR}/Testing/Logs")
  file(MAKE_DIRECTORY "${TETGEN_LOG_DIR}")

  foreach(_input IN LISTS _test_inputs)
    # Derive a descriptive test name: tetgen/<basename>  (e.g. tetgen/Cow_cut.smesh)
    get_filename_component(_basename "${_input}" NAME)
    set(_test_name "tetgen/${_basename}")

    add_test(
      NAME    "${_test_name}"
      COMMAND "${CMAKE_COMMAND}"
              "-DTETGEN=$<TARGET_FILE:tetgen>"
              "-DFLAGS=${TETGEN_TEST_FLAGS}"
              "-DINPUT=${_input}"
              "-DLOGFILE=${TETGEN_LOG_DIR}/${_basename}.log"
              -P "${_test_wrapper}"
      WORKING_DIRECTORY "${TESTFILES_DIR}"
    )

    # The CMake wrapper prints TETGEN_TEST_SKIPPED for known harmless
    # return codes (3, 4, 5, 10).  CTest matches this marker and marks
    # the test as skipped instead of failed.
    set_tests_properties("${_test_name}" PROPERTIES
      SKIP_REGULAR_EXPRESSION "TETGEN_TEST_SKIPPED"
      TIMEOUT                 300
    )

    # Add a label based on the file extension for filtering, e.g.:
    #   ctest -L smesh
    #   ctest -L poly
    get_filename_component(_ext "${_input}" LAST_EXT)
    string(SUBSTRING "${_ext}" 1 -1 _ext_label)  # strip leading dot
    set_tests_properties("${_test_name}" PROPERTIES
      LABELS "${_ext_label}"
    )
  endforeach()

  list(LENGTH _test_inputs _num_tests)
  message(STATUS "Registered ${_num_tests} TetGen test(s) from ${TESTFILES_DIR}")

else()
  if(BUILD_TESTING AND NOT TESTFILES_REPO)
    message(STATUS
      "Testing is enabled but TESTFILES_REPO is not set. "
      "Set -DTESTFILES_REPO=<url_or_path> to enable TetGen tests."
    )
  endif()
endif()
