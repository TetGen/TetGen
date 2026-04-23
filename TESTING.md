# TetGen Testing with CTest

TetGen uses [CTest](https://cmake.org/cmake/help/latest/manual/ctest.1.html) to
run automated tests against a collection of mesh input files. Each input file
becomes an individual test with its own pass/fail/skip status, making it easy to
identify regressions and track results in a dashboard.

## Prerequisites

- CMake ≥ 3.16
- Git (to clone the test-file repository)
- A C++ compiler

## Quick Start

```bash
# Configure (uses the default test-file repository)
cmake -B <build-dir>

# Build
cmake --build <build-dir>

# Run all tests
ctest --test-dir <build-dir> --output-on-failure
```

Replace `<build-dir>` with a build directory of your choice (e.g. `build`,
`out/debug`, etc.). All subsequent commands in this document use the same
placeholder — substitute your chosen directory throughout.

By default, `TESTFILES_REPO` points to
`https://codeberg.org/TetGen/TetGenTests.git`, and `TESTFILES_BRANCH` points to `main`. To override, pass a different
URL or local path:

```bash
cmake -B <build-dir> -DTESTFILES_REPO=<url_or_path> -DTESTFILES_BRANCH=<branchname>
```

The value can be:

- a **remote URL**, e.g. `https://codeberg.org/TetGen/TetGenTests.git`
- a **local path** to a bare or regular Git repository

The test files repository is **shallow-cloned** (`--single-branch --depth 1`) into
`<build-dir>/testfiles/` at configure time. Only committed files are picked up.

## CMake Options

| Variable | Default | Description |
|---|---|---|
| `BUILD_TESTING` | `ON` | Master switch for CTest (standard CMake variable) |
| `TESTFILES_REPO` | `https://codeberg.org/TetGen/TetGenTests.git` | URL or local path to the test-file Git repository |

## Test Discovery

Tests are registered from the explicit list in `TetGenTestFiles.cmake` **inside
the cloned test-file repository** (`<build-dir>/testfiles/TetGenTestFiles.cmake`).
Each entry in the `TETGEN_TESTS` variable has the form:

```cmake
"inputfile|flags1|flags2|..."
```

where `inputfile` is a path relative to the test-file repository root (may
include subdirectories, e.g. `smesh/foo.smesh`), and `flags1`, `flags2`, … are
one or more TetGen flag strings. The pipe character `|` is used as separator
because semicolons are interpreted as list separators by CMake. A **separate
CTest test** is created for every (inputfile, flags) combination, named
`tetgen/<inputfile>/<flags>`, for example:

```
tetgen/smesh/slit-1.smesh/-pQ
tetgen/smesh/stanfordbunny.smesh/-pqQ
tetgen/smesh/wedge-5.smesh/-pQ
```

The default flag set `TETGEN_DEFAULT_FLAGS` is defined at the top of
`TetGenTestFiles.cmake` and can be referenced with `${TETGEN_DEFAULT_FLAGS}` in
entries.  To test a file with multiple flag sets, add several flags to the
entry:

```cmake
"smesh/Cow_cut.smesh|-pqQ|-pq1.2|-pqO"
```

To **add or remove tests**, edit `TetGenTestFiles.cmake` in the test-file
repository. At configure time, CMake warns about any listed file that is not
found in the cloned repository.

> **Note:** `.node` files are companion data for `.smesh` and `.poly` inputs.
> They are not tested independently.

## Running Tests

### Run all tests

```bash
ctest --test-dir <build-dir> --output-on-failure
```

### List available tests (without running)

```bash
ctest --test-dir <build-dir> -N
```

### Filter by test name

```bash
ctest --test-dir <build-dir> -R blade          # run tests whose name contains "blade"
ctest --test-dir <build-dir> -R "\.mesh$"      # run only .mesh tests
```

### Filter by label

Every test is labeled with its file extension (`smesh`, `poly`, or `mesh`):

```bash
ctest --test-dir <build-dir> -L smesh          # run all .smesh tests
ctest --test-dir <build-dir> -L poly           # run all .poly tests
ctest --test-dir <build-dir> --print-labels    # show all available labels
```

### Verbose output

```bash
ctest --test-dir <build-dir> -V                # verbose: show full TetGen output for every test
ctest --test-dir <build-dir> -VV               # extra verbose
```

### Parallel execution

```bash
ctest --test-dir <build-dir> -j4               # run up to 4 tests in parallel
```

## Log Files

Every test run writes a per-test log file to:

```
<build-dir>/Testing/Logs/<flattened_file>_<stripped_flags>.log
```

The file name is constructed by replacing `/` with `_` in the input path and
stripping `-` from the flags. For example, running
`tetgen/smesh/stanfordbunny.smesh/-pqQ` produces:

```
<build-dir>/Testing/Logs/smesh_stanfordbunny.smesh_pqQ.log
```

Each log file contains:

- the TetGen binary, flags, and input file used
- a UTC timestamp
- the complete TetGen console output (stdout and stderr)
- the exit code and the resulting CTest status (PASSED / SKIPPED / FAILED)

Log files are overwritten on every test run so they always reflect the latest
results. You can inspect them after a run with, for example:

```bash
# Show the log for a specific test
cat <build-dir>/Testing/Logs/Cow_cut.smesh.log

# Search all logs for failures
grep -l "FAILED" <build-dir>/Testing/Logs/*.log

# Show the tail of every log
tail -n 5 <build-dir>/Testing/Logs/*.log
```

In addition, CTest itself can write a single combined log of the entire run:

```bash
ctest --test-dir <build-dir> --output-on-failure --output-log ctest.log
```

This creates `ctest.log` in the current working directory with the aggregated
output of all tests.

## Return Code Dispatch

TetGen returns different exit codes depending on the outcome. The CMake test
wrapper ([cmake/run_tetgen_test.cmake](cmake/run_tetgen_test.cmake)) translates
these into CTest-compatible results:

| TetGen exit code | Meaning | CTest result |
|---|---|---|
| 0 | Success | **Passed** |
| 3 | PLC error detected | **Skipped** |
| 4 | Small feature detected | **Skipped** |
| 5 | Try `-Y` option | **Skipped** |
| 10 | Input error detected | **Skipped** |
| *any other* | Unexpected failure | **Failed** |

Skipped tests are detected via CTest's `SKIP_REGULAR_EXPRESSION` property: the
wrapper prints the marker `TETGEN_TEST_SKIPPED` for known harmless return codes,
and CTest matches that string in the output. Skipped tests appear clearly in
the results and do not count as failures.

## Standalone Test Script

For quick batch testing without CMake/CTest, the shell script
[runtest.sh](runtest.sh) can be used directly:

```bash
./runtest.sh <tetgen-binary> <options> <directory> [filetypes]
```

For example:

```bash
./runtest.sh ./build/tetgen -pqQ path/to/testfiles
```

The script iterates over all `*.smesh`, `*.poly`, and `*.mesh` files (or the
file types given as the optional fourth argument) in `<directory>`, runs TetGen
on each one, and writes a summary report to
`<directory><options>-report.txt` (e.g. `path/to/testfiles-pqQ-report.txt`).
The report lists every test with its result (passed / PLC error / small
feature / input error / failed) and ends with aggregate statistics.

> **Note:** This script is independent of the CMake build system and does not
> produce per-test log files or integrate with CTest. For full integration
> (skip handling, labels, per-test logs), use the CTest workflow described
> above.

## CI Integration

### Codeberg CI (Woodpecker)

Example `.woodpecker.yml`:

```yaml
steps:
  build-and-test:
    image: gcc
    commands:
      - apt-get update && apt-get install -y cmake git
      - cmake -B build
      - cmake --build build
      - ctest --test-dir build --output-on-failure
```

### GitHub Actions

Example `.github/workflows/test.yml`:

```yaml
name: TetGen Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Configure
        run: cmake -B build
      - name: Build
        run: cmake --build build
      - name: Test
        run: ctest --test-dir build --output-on-failure
```

## Project Structure

```
TetGen/
├── CMakeLists.txt              # Build + CTest configuration
├── runtest.sh                  # Standalone batch test script (no CMake needed)
├── cmake/
│   └── run_tetgen_test.cmake   # Test wrapper (return code dispatch + logging)
├── tetgen.cxx                  # TetGen source
├── tetgen.h                    # TetGen header
├── predicates.cxx              # Geometric predicates
└── <build-dir>/                # Build directory (user-chosen, e.g. build/)
    ├── testfiles/              # Shallow clone of test-file repo (generated)
    │   ├── TetGenTestFiles.cmake  # Authoritative test list (from test repo)
    │   └── smesh/              # Test input files
    └── Testing/
        └── Logs/               # Per-test log files (generated)
```
