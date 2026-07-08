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

Testing is **disabled by default**. To enable it, pass the `-DTETGEN_ENABLE_TESTING=ON` flag to CMake:

```bash
# Configure (enables testing and uses the default test-file repository)
cmake -B <build-dir> -DTETGEN_ENABLE_TESTING=ON

# Build
cmake --build <build-dir>

# Run all tests
ctest --test-dir <build-dir> --output-on-failure
```

Replace `<build-dir>` with a build directory of your choice (e.g. `build`).
All subsequent commands in this document use the same placeholder — substitute your chosen directory throughout.

Without `-DTETGEN_ENABLE_TESTING=ON`, the build completes normally but no tests are registered.

By default, `TESTFILES_REPO` points to
`https://codeberg.org/TetGen/TetGenTests.git`. To override, pass a different
URL or local path (in addition to enabling testing):

```bash
cmake -B <build-dir> -DTETGEN_ENABLE_TESTING=ON -DTESTFILES_REPO=<url_or_path>
```

Other useful options when enabling testing:

```bash
cmake -B <build-dir> -DTETGEN_ENABLE_TESTING=ON -DTESTFILES_BRANCH=<branch>
cmake -B <build-dir> -DTETGEN_ENABLE_TESTING=ON -DTETGEN_TEST_TIMEOUT=<seconds>
```

The value can be:

- a **remote URL**, e.g. `https://codeberg.org/TetGen/TetGenTests.git`
- a **local path** to a bare or regular Git repository

The test files repository is **shallow-cloned** (`--depth 1`) into
`<build-dir>/testfiles/` at configure time. Only committed files are picked up.

## CMake Options

| Variable | Default | Description |
|---|---|---|
| `TETGEN_ENABLE_TESTING` | `OFF` | Enable CTest testing infrastructure (must be set to `ON` to register tests) |
| `BUILD_TESTING` | `ON` (when enabled) | Master switch for CTest (standard CMake variable; only used if `TETGEN_ENABLE_TESTING` is `ON`) |
| `TESTFILES_REPO` | `https://codeberg.org/TetGen/TetGenTests.git` | URL or local path to the test-file Git repository |
| `TESTFILES_BRANCH` | `main` | Branch in test files repo to be used |
| `TETGEN_TEST_TIMEOUT` | `60` | Timeout for each test in seconds |

## Test Discovery

Tests are registered from the explicit list in `cmake/TetGenTestFiles.cmake`.
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
"tetgen/smesh/slit-1.smesh|-pQ|-pY"
"tetgen/smesh/stanfordbunny.smesh|-pqQ"
"tetgen/smesh/wedge-5.smesh|-pQ"
```

To test a file with multiple flag sets, add several flags to the entry:

```cmake
"smesh/Cow_cut.smesh|-pqQ|-pq1.2|-pqO"
```

To **add or remove tests**, edit `cmake/TetGenTestFiles.cmake`. 

> **Note:** `.node` files are companion data for `.smesh` and `.poly` inputs.
> They are not tested independently.

## Running Tests

### Run all tests

```bash
ctest --test-dir <build-dir> --output-on-failure
```

> **Note:** Tests must be enabled with `-DTETGEN_ENABLE_TESTING=ON` during configure to be available.

To **re-run tests** after editing  `cmake/TetGenTestFiles.cmake`, perform

```bash
cmake -B <build-dir> -DTETGEN_ENABLE_TESTING=ON
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

### Showing skip reasons

CTest's own "The following tests did not run:" summary only reports
`(Skipped)`, without saying why. The [ctest-report.sh](ctest-report.sh) wrapper
runs ctest normally and appends an extra block with the actual reason, taken
from each test's per-test log file:

```bash
./ctest-report.sh --test-dir <build-dir> --output-on-failure
```

```
The following tests did not run:
        132 - tetgen/cgal/bunny00.off/-pqQ (Skipped)

The following tests did not run: (with reasons)
        132 - tetgen/cgal/bunny00.off/-pqQ (Skipped: The input surface mesh contain self-intersections.)
```

It accepts the same options as `ctest` and forwards its exit code, so it can
be used as a drop-in replacement in scripts or CI.

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
      - cmake -B build -DTETGEN_ENABLE_TESTING=ON
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
        run: cmake -B build -DTETGEN_ENABLE_TESTING=ON
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
│   ├── TetGenConfig.cmake.in   # CMake package config template
│   ├── TetGenTestFiles.cmake   # Authoritative test list (from test repo)
│   └── run_tetgen_test.cmake   # Test wrapper (return code dispatch + logging)
├── tetgen.cxx                  # TetGen source
├── tetgen.h                    # TetGen header
├── predicates.cxx              # Geometric predicates
└── <build-dir>/                # Build directory (user-chosen, e.g. build/)
    ├── testfiles/              # Shallow clone of test-file repo (generated, if testing enabled)
    └── Testing/
        └── Logs/               # Per-test log files (generated, if testing enabled)
```
