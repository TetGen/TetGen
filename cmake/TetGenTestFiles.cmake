# SPDX-License-Identifier: AGPL-3.0-or-later OR MIT
# Copyright (c) 2025 Jürgen Fuhrmann
#
# cmake/TetGenTestFiles.cmake — Explicit list of TetGen test inputs and flags
#
# This file is included by CMakeLists.txt to register CTest tests.
#
# Each entry has the form:
#
#   "inputfile|flags1|flags2|..."
#
# where inputfile is a path relative to the testfiles directory (may include
# subdirectories, e.g. "smesh/foo.smesh"), and flags1, flags2, ... are one or
# more TetGen flag strings.  The pipe character '|' separates the fields
# (semicolons cannot be used because CMake treats them as list separators).
# A separate CTest test is created for every (inputfile, flags) combination.
#
# The default flag set is defined in TETGEN_DEFAULT_FLAGS below.
# Use it for entries that need only the standard flags; override per-file
# by listing different flag strings.
#
# Generated from the current test repository.  Adapt as needed.

set(TETGEN_DEFAULT_FLAGS "-pQ|-pqQ")

set(TETGEN_TESTS
  # --- smesh/ ---
  "smesh/slit-1.smesh|${TETGEN_DEFAULT_FLAGS}"
  "smesh/slit-2.smesh|${TETGEN_DEFAULT_FLAGS}"
  "smesh/slit-5.smesh|${TETGEN_DEFAULT_FLAGS}"
  "smesh/slit-7.smesh|${TETGEN_DEFAULT_FLAGS}"
  "smesh/slit-10.smesh|${TETGEN_DEFAULT_FLAGS}"
  "smesh/spike-1-7.smesh|${TETGEN_DEFAULT_FLAGS}"
  "smesh/spike-1-10.smesh|${TETGEN_DEFAULT_FLAGS}"
  "smesh/spike-2-7.smesh|${TETGEN_DEFAULT_FLAGS}"
  "smesh/spike-2-10.smesh|${TETGEN_DEFAULT_FLAGS}"
  "smesh/spike-5-7.smesh|${TETGEN_DEFAULT_FLAGS}"
  "smesh/spike-5-10.smesh|${TETGEN_DEFAULT_FLAGS}"
  "smesh/spike-10-4.smesh|${TETGEN_DEFAULT_FLAGS}"
  "smesh/spike-10-7.smesh|${TETGEN_DEFAULT_FLAGS}"
  "smesh/spike-10-10.smesh|${TETGEN_DEFAULT_FLAGS}"
  "smesh/stanfordbunny.smesh|${TETGEN_DEFAULT_FLAGS}"
  "smesh/wedge-1.smesh|${TETGEN_DEFAULT_FLAGS}"
  "smesh/wedge-2.smesh|${TETGEN_DEFAULT_FLAGS}"
  "smesh/wedge-5.smesh|${TETGEN_DEFAULT_FLAGS}"
  "smesh/wedge-7.smesh|${TETGEN_DEFAULT_FLAGS}"
  "smesh/wedge-10.smesh|${TETGEN_DEFAULT_FLAGS}"
)
