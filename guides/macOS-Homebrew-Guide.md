# Getting Started with SWI-Prolog RocksDB on macOS using Homebrew

## Introduction

This guide provides complete step-by-step instructions for installing and testing SWI-Prolog's RocksDB integration on macOS (both Intel x86_64 and Apple Silicon arm64) using Homebrew packages.

**What you'll accomplish**:
- Install SWI-Prolog and RocksDB via Homebrew
- Build and test the rocksdb pack
- Build and test the rocks-predicates module

**Installation Options**:

1. **Native Installation** (Recommended for most users):
   - Direct installation on your macOS system
   - Simpler and faster (~20-40 minutes)
   - No VM overhead
   - Uses your existing macOS environment

2. **VM Isolation** (Optional - for production testing):
   - Install in a macOS virtual machine
   - Provides snapshot/rollback capability
   - Isolated from host system
   - Requires VM software: Parallels Desktop (commercial) or UTM (free, https://mac.getutm.app/)
   - Requires macOS license and significant disk space (~40-60 GB)
   - Best for testing changes before deploying to production

**Other Installation Guides**:

For other platforms and toolchains, see:
- **Windows (vcpkg)**: Windows-Sandbox-vcpkg-Guide.md
- **Windows (MSYS2)**: Windows-Sandbox-MSYS2-Guide.md
- **Linux (WSL2/Ubuntu)**: WSL2-Ubuntu-Guide.md

---

## Icon Reference

Throughout this guide, icons indicate the environment and permissions required for each command:

| Icon | Meaning |
|------|---------|
| 🖥️ | **Environment**: Which terminal or application to use |
| 🔧 | **Admin Required**: Command requires administrator/sudo privileges |
| 👤 | **User Mode**: Command runs with normal user privileges |
| 💡 | **Note**: Important information or clarification |
| ⚠️ | **Warning**: Critical step or common mistake to avoid |
| 📝 | **Action**: Manual action required (not a command) |
| ⏱️ | **Time Estimate**: Approximate duration for this stage |
| ✅ | **Checkpoint**: Verification step to confirm success |

---

## Prerequisites

Before starting, ensure you have:

- **macOS 11 (Big Sur) or later** (Intel or Apple Silicon)
- **Administrator access** (for Homebrew installation and sudo commands)
- **Stable internet connection** (for downloading packages)
- **20 GB free disk space** (minimum for native installation)
- **Optional**: VM software (Parallels Desktop or UTM) if using VM isolation approach

---

## Stage 1: Install Homebrew

⏱️ **Estimated time**: 5-10 minutes

If you already have Homebrew installed, skip to Stage 2.

### Step 1: Install Homebrew

🖥️ **Terminal** | 👤 **User Mode**

Run the official Homebrew installation script:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Follow the prompts. The installer will:
- Download and install Homebrew
- Install Xcode Command Line Tools if not already present
- Set up the correct installation path for your architecture

**Expected output**:
```
==> Checking for `sudo` access (which may request your password)...
Password:
==> This script will install:
/opt/homebrew/bin/brew           [Apple Silicon]
  OR
/usr/local/bin/brew              [Intel]
...
==> Installation successful!
```

### Step 2: Add Homebrew to PATH (if needed)

After installation, Homebrew may prompt you to add it to your PATH. Follow the instructions shown in the terminal.

**For Apple Silicon** (if prompted):

```bash
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```

**For Intel** (if prompted):

```bash
echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/usr/local/bin/brew shellenv)"
```

### ✅ Verification

🖥️ **Terminal** | 👤 **User Mode**

```bash
brew --version
```

**Expected output**:
```
Homebrew 4.x.x
Homebrew/homebrew-core (git revision xxxxx; last commit 2025-xx-xx)
```

```bash
which brew
```

**Expected output (Apple Silicon)**:
```
/opt/homebrew/bin/brew
```

**Expected output (Intel)**:
```
/usr/local/bin/brew
```

---

## Stage 2: Install Xcode Command Line Tools

⏱️ **Estimated time**: 5-15 minutes

Xcode Command Line Tools provides the compilers and build tools needed for compiling C++ code.

💡 **Note**: If you installed Homebrew in Stage 1, Xcode Command Line Tools may already be installed. This stage verifies installation.

### Step 1: Check if already installed

🖥️ **Terminal** | 👤 **User Mode**

```bash
xcode-select -p
```

**If installed**, you'll see:
```
/Library/Developer/CommandLineTools
```

Skip to Stage 3.

**If not installed**, you'll see:
```
xcode-select: error: unable to get active developer directory...
```

Continue with Step 2.

### Step 2: Install Xcode Command Line Tools

🖥️ **Terminal** | 👤 **User Mode**

```bash
xcode-select --install
```

A dialog will appear prompting you to install the tools. Click "Install" and wait for the download and installation to complete.

**Expected output**:
```
xcode-select: note: install requested for command line developer tools
```

### ✅ Verification

🖥️ **Terminal** | 👤 **User Mode**

```bash
xcode-select -p
```

**Expected output**:
```
/Library/Developer/CommandLineTools
```

```bash
gcc --version
```

**Expected output**:
```
Apple clang version 15.x.x (clang-xxxx.x.xx.x)
Target: arm64-apple-darwin23.x.x    [Apple Silicon]
  OR
Target: x86_64-apple-darwin23.x.x   [Intel]
Thread model: posix
InstalledDir: /Library/Developer/CommandLineTools/usr/bin
```

---

## Stage 3: Install SWI-Prolog via Homebrew

⏱️ **Estimated time**: 2-5 minutes

### Step 1: Install SWI-Prolog

🖥️ **Terminal** | 👤 **User Mode**

```bash
brew install swi-prolog
```

Homebrew will download and install SWI-Prolog along with its dependencies.

**Expected output**:
```
==> Downloading https://ghcr.io/v2/homebrew/core/swi-prolog/manifests/x.x.x
==> Fetching swi-prolog
==> Downloading https://ghcr.io/v2/homebrew/core/swi-prolog/blobs/sha256:...
==> Pouring swi-prolog--x.x.x.arm64_ventura.bottle.tar.gz
🍺  /opt/homebrew/Cellar/swi-prolog/x.x.x: xxx files, xxxMB
```

💡 **Note**: Homebrew's SWI-Prolog formula provides a recent stable version suitable for production use.

### ✅ Verification

🖥️ **Terminal** | 👤 **User Mode**

**Check version**:

```bash
swipl --version
```

**Expected output**:
```
SWI-Prolog version 9.x.x for arm64-darwin    [Apple Silicon]
  OR
SWI-Prolog version 9.x.x for x86_64-darwin  [Intel]
```

**Check binary location**:

```bash
which swipl
```

**Expected output (Apple Silicon)**:
```
/opt/homebrew/bin/swipl
```

**Expected output (Intel)**:
```
/usr/local/bin/swipl
```

**Check library path**:

```bash
swipl --dump-runtime-variables | grep PLBASE
```

**Expected output (Apple Silicon)**:
```
PLBASE="/opt/homebrew/Cellar/swi-prolog/x.x.x/libexec/lib/swipl";
```

**Expected output (Intel)**:
```
PLBASE="/usr/local/Cellar/swi-prolog/x.x.x/libexec/lib/swipl";
```

---

## Stage 4: Install RocksDB via Homebrew

⏱️ **Estimated time**: 2-5 minutes

### Step 1: Install RocksDB

🖥️ **Terminal** | 👤 **User Mode**

```bash
brew install rocksdb
```

Homebrew will download and install RocksDB.

**Expected output**:
```
==> Downloading https://ghcr.io/v2/homebrew/core/rocksdb/manifests/x.x.x
==> Fetching rocksdb
==> Downloading https://ghcr.io/v2/homebrew/core/rocksdb/blobs/sha256:...
==> Pouring rocksdb--x.x.x.arm64_ventura.bottle.tar.gz
🍺  /opt/homebrew/Cellar/rocksdb/x.x.x: xxx files, xxxMB
```

### ✅ Verification

🖥️ **Terminal** | 👤 **User Mode**

**List installed RocksDB files**:

```bash
brew list rocksdb
```

**Expected output** (partial listing):
```
/opt/homebrew/Cellar/rocksdb/x.x.x/include/rocksdb/ (many header files)
/opt/homebrew/Cellar/rocksdb/x.x.x/lib/librocksdb.dylib
/opt/homebrew/Cellar/rocksdb/x.x.x/lib/librocksdb.x.x.x.dylib
/opt/homebrew/Cellar/rocksdb/x.x.x/lib/librocksdb.a
...
```

**Check installation prefix**:

```bash
brew --prefix rocksdb
```

**Expected output (Apple Silicon)**:
```
/opt/homebrew/opt/rocksdb
```

**Expected output (Intel)**:
```
/usr/local/opt/rocksdb
```

**Check headers**:

```bash
ls "$(brew --prefix rocksdb)/include/rocksdb/"
```

**Expected output** (partial listing):
```
cache.h
db.h
iterator.h
options.h
slice.h
status.h
...
```

---

## Stage 5: Clone and Build rocksdb Pack

⏱️ **Estimated time**: 5-10 minutes

### Step 1: Create pack directory

🖥️ **Terminal** | 👤 **User Mode**

```bash
mkdir -p ~/Library/Application\ Support/SWI-Prolog/pack
cd ~/Library/Application\ Support/SWI-Prolog/pack
```

💡 **Note**: `~/Library/Application Support/SWI-Prolog/pack/` is the standard macOS location for SWI-Prolog packs.

### Step 2: Clone rocksdb pack repository

🖥️ **Terminal** | 👤 **User Mode**

```bash
git clone https://github.com/JanWielemaker/rocksdb.git
cd rocksdb
```

### Step 3: Build the pack

🖥️ **Terminal** | 👤 **User Mode**

```bash
mkdir -p build
cd build
cmake -DCMAKE_PREFIX_PATH="$(brew --prefix rocksdb)" ..
cmake --build .
```

**Expected output** (partial):
```
-- The C compiler identification is AppleClang x.x.x
-- The CXX compiler identification is AppleClang x.x.x
-- Detecting C compiler ABI info
-- Detecting C compiler ABI info - done
...
-- Found RocksDB: /opt/homebrew/opt/rocksdb/include
...
[ 50%] Building CXX object CMakeFiles/rocksdb4pl.dir/cpp/rocksdb4pl.cpp.o
[100%] Linking CXX shared library librocksdb4pl.dylib
[100%] Built target rocksdb4pl
```

💡 **Note**: The build system uses pkg-config or CMAKE_PREFIX_PATH to locate Homebrew's RocksDB installation. The `-DCMAKE_PREFIX_PATH` flag ensures CMake finds the correct libraries.

### ✅ Verification

🖥️ **Terminal** | 👤 **User Mode**

**Check build output**:

```bash
ls ~/Library/Application\ Support/SWI-Prolog/pack/rocksdb/build/
```

**Expected output**:
```
CMakeCache.txt
CMakeFiles/
Makefile
cmake_install.cmake
librocksdb4pl.dylib
```

**Verify shared library was created**:

```bash
file ~/Library/Application\ Support/SWI-Prolog/pack/rocksdb/build/librocksdb4pl.dylib
```

**Expected output (Apple Silicon)**:
```
.../librocksdb4pl.dylib: Mach-O 64-bit dynamically linked shared library arm64
```

**Expected output (Intel)**:
```
.../librocksdb4pl.dylib: Mach-O 64-bit dynamically linked shared library x86_64
```

---

## Stage 6: Test rocksdb Pack

⏱️ **Estimated time**: 2-5 minutes

### Step 1: Load the library in SWI-Prolog

🖥️ **Terminal** | 👤 **User Mode**

```bash
cd ~/Library/Application\ Support/SWI-Prolog/pack/rocksdb
swipl
```

At the SWI-Prolog prompt, load the library:

```prolog
?- use_module(library(rocksdb)).
```

**Expected output**:
```
true.
```

If you see an error about the library not being found, ensure the build completed successfully in Stage 5.

### Step 2: Run basic operations test

Still in the SWI-Prolog REPL:

```prolog
?- rocks_open('/tmp/test_rocks.db', DB, []).
```

**Expected output**:
```
DB = <rocksdb>(0x...).
```

```prolog
?- rocks_put(DB, foo, bar).
```

**Expected output**:
```
true.
```

```prolog
?- rocks_get(DB, foo, Value).
```

**Expected output**:
```
Value = bar.
```

```prolog
?- rocks_close(DB).
```

**Expected output**:
```
true.
```

```prolog
?- halt.
```

✅ **Checkpoint**: If all commands succeeded, the rocksdb pack is working correctly!

### Step 3: Run test suite (if available)

🖥️ **Terminal** | 👤 **User Mode**

Check if test files exist:

```bash
ls ~/Library/Application\ Support/SWI-Prolog/pack/rocksdb/test/
```

If test files exist (e.g., `test_rocksdb.pl`), run them:

```bash
cd ~/Library/Application\ Support/SWI-Prolog/pack/rocksdb/test
swipl -g "consult('test_rocksdb.pl'), run_tests, halt"
```

**Expected output**:
```
% PL-Unit: rocksdb .......... done
% All XX tests passed
```

💡 **Note**: If no test directory exists, skip this step. The manual tests in Step 1-2 confirm functionality.

---

## Stage 7: Clone and Test rocks-predicates

⏱️ **Estimated time**: 3-5 minutes

### Step 1: Clone rocks-predicates repository

🖥️ **Terminal** | 👤 **User Mode**

```bash
cd ~/Library/Application\ Support/SWI-Prolog/pack
git clone https://github.com/JanWielemaker/rocks-predicates.git
cd rocks-predicates
```

### Step 2: Run rocks-predicates tests

🖥️ **Terminal** | 👤 **User Mode**

Check for test runner script:

```bash
ls *.pl
```

Look for a file like `run_all_tests.pl` or similar.

If found, run:

```bash
swipl run_all_tests.pl
```

**Expected output**:
```
% Loading test files...
% Running tests...
% PL-Unit: rocks_predicates .......... done
% All XX tests passed
```

Alternatively, if tests are structured differently:

```bash
swipl -g "consult('test/test_suite.pl'), run_tests, halt"
```

### Step 3: Verify rocks-predicates module loads

🖥️ **Terminal** | 👤 **User Mode**

```bash
swipl
```

At the SWI-Prolog prompt:

```prolog
?- use_module(library(rocksdb)).
```

**Expected output**:
```
true.
```

```prolog
?- use_module('rocks-predicates.pl').
```

**Expected output**:
```
true.
```

Or if rocks-predicates has a library path:

```prolog
?- use_module(library(rocks_predicates)).
```

```prolog
?- halt.
```

✅ **Checkpoint**: If the module loads without errors, rocks-predicates is installed correctly!

---

## Architecture-Specific Notes

### Homebrew Installation Paths

**Apple Silicon (M1/M2/M3)**:
- Homebrew prefix: `/opt/homebrew`
- Binaries: `/opt/homebrew/bin`
- Libraries: `/opt/homebrew/lib`
- Headers: `/opt/homebrew/include`

**Intel (x86_64)**:
- Homebrew prefix: `/usr/local`
- Binaries: `/usr/local/bin`
- Libraries: `/usr/local/lib`
- Headers: `/usr/local/include`

### Universal Binaries vs Architecture-Specific

Most Homebrew packages install architecture-specific binaries. You can check with:

```bash
file $(which swipl)
```

**Apple Silicon output**:
```
/opt/homebrew/bin/swipl: Mach-O 64-bit executable arm64
```

**Intel output**:
```
/usr/local/bin/swipl: Mach-O 64-bit executable x86_64
```

⚠️ **Warning**: Avoid using Rosetta 2 translation for running Intel binaries on Apple Silicon when native arm64 versions are available. This impacts performance significantly.

### Library Linking

CMake and pkg-config automatically detect the correct library paths based on Homebrew's architecture-specific installation:

```bash
pkg-config --cflags rocksdb
```

**Expected output (Apple Silicon)**:
```
-I/opt/homebrew/opt/rocksdb/include
```

**Expected output (Intel)**:
```
-I/usr/local/opt/rocksdb/include
```

---

## Troubleshooting

### Xcode Command Line Tools Not Found

**Symptom**:
```
xcrun: error: invalid active developer path (/Library/Developer/CommandLineTools)
```

**Solution**:
Re-install Xcode Command Line Tools:
```bash
sudo rm -rf /Library/Developer/CommandLineTools
xcode-select --install
```

### Homebrew Path Issues

**Symptom**:
```bash
brew: command not found
```

**Solution (Apple Silicon)**:
Add Homebrew to PATH:
```bash
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```

**Solution (Intel)**:
```bash
echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/usr/local/bin/brew shellenv)"
```

Restart your terminal or run:
```bash
source ~/.zprofile
```

### Library Linking Errors

**Symptom**:
```
dyld: Library not loaded: @rpath/librocksdb.dylib
```

**Solution**:
Ensure RocksDB is installed and verify library path:

```bash
brew list rocksdb | grep dylib
```

Check if CMake found the correct library during build:

```bash
cd ~/Library/Application\ Support/SWI-Prolog/pack/rocksdb/build
cmake -DCMAKE_PREFIX_PATH="$(brew --prefix rocksdb)" .. -LAH | grep ROCKSDB
```

### System Integrity Protection (SIP) and DYLD_LIBRARY_PATH

**Symptom**:
Setting `DYLD_LIBRARY_PATH` doesn't affect library loading.

**Explanation**:
macOS SIP strips `DYLD_LIBRARY_PATH` from the environment for protected binaries. This is intentional security behavior.

**Solution**:
Don't rely on `DYLD_LIBRARY_PATH`. Instead:
1. Use `CMAKE_PREFIX_PATH` during build (as shown in Stage 5)
2. Ensure libraries are installed in standard Homebrew locations
3. Use `install_name_tool` to fix library paths if necessary

### RocksDB Not Found by CMake

**Symptom**:
```
CMake Error: Could not find RocksDB
```

**Solution**:
Explicitly set CMAKE_PREFIX_PATH:

```bash
cd ~/Library/Application\ Support/SWI-Prolog/pack/rocksdb/build
cmake -DCMAKE_PREFIX_PATH="$(brew --prefix rocksdb)" ..
```

Verify RocksDB installation:

```bash
brew list rocksdb
brew --prefix rocksdb
```

### SWI-Prolog Can't Find Pack

**Symptom**:
```prolog
?- use_module(library(rocksdb)).
ERROR: source_sink `library(rocksdb)' does not exist
```

**Solution**:
Verify pack directory structure:

```bash
ls -la ~/Library/Application\ Support/SWI-Prolog/pack/rocksdb/
```

Expected structure:
```
prolog/
build/
  librocksdb4pl.dylib
CMakeLists.txt
pack.pl (or similar metadata)
```

Verify SWI-Prolog's pack search path:

```prolog
?- absolute_file_name(pack(.), Dir, [file_type(directory), solutions(all)]).
```

Should include:
```
Dir = '/Users/yourname/Library/Application Support/SWI-Prolog/pack'
```

### Architecture Mismatch

**Symptom**:
```
dyld: mach-o file, but is an incompatible architecture (have 'x86_64', need 'arm64')
```

**Solution**:
This occurs when mixing Intel and Apple Silicon binaries. Ensure all components (SWI-Prolog, RocksDB, compiled pack) are built for the same architecture.

Check architecture of each component:

```bash
file $(which swipl)
file $(brew --prefix rocksdb)/lib/librocksdb.dylib
file ~/Library/Application\ Support/SWI-Prolog/pack/rocksdb/build/librocksdb4pl.dylib
```

All should show either `arm64` or `x86_64`, not mixed.

If mismatched, reinstall the incompatible package:

```bash
brew uninstall swi-prolog rocksdb
brew install swi-prolog rocksdb
```

Then rebuild the rocksdb pack (Stage 5).

---

## VM-Based Testing (Optional)

For users who want isolated testing environments with snapshot capability:

### Using Parallels Desktop (Commercial)

1. **Create macOS VM**:
   - Launch Parallels Desktop
   - Create new VM with macOS installer
   - Allocate at least 40 GB disk, 4 GB RAM

2. **Take snapshots**:
   - Before each major stage, use Parallels' snapshot feature
   - Right-click VM → Manage Snapshots → Take Snapshot
   - Name snapshots descriptively (e.g., "After Homebrew Install", "After SWI-Prolog Install")

3. **Restore snapshots**:
   - Right-click VM → Manage Snapshots
   - Select snapshot → Restore

### Using UTM (Free, Open-Source)

1. **Download UTM**: https://mac.getutm.app/

2. **Create macOS VM**:
   - Download macOS installer from Apple
   - Create new VM in UTM
   - Allocate at least 40 GB disk, 4 GB RAM

3. **Take snapshots**:
   - Stop the VM
   - Right-click VM → Clone
   - Name the clone descriptively

4. **Restore snapshots**:
   - Delete or archive the current VM
   - Use the cloned VM as your working copy

### Native Backup (Time Machine)

If installing natively, use macOS Time Machine for system-level backups:

1. **Set up Time Machine**:
   - System Settings → General → Time Machine
   - Add backup disk

2. **Restore specific files**:
   - Enter Time Machine
   - Navigate to `~/Library/Application Support/SWI-Prolog/pack/`
   - Restore previous version

💡 **Note**: Time Machine backs up your entire system, not just the pack directory. For granular control, VM snapshots are more flexible.

---

## Summary

You have successfully:

✅ Installed Homebrew and Xcode Command Line Tools
✅ Installed SWI-Prolog via Homebrew
✅ Installed RocksDB via Homebrew
✅ Built and tested the rocksdb pack
✅ Installed and tested rocks-predicates

**Total time**: ~20-40 minutes (native installation)

**Next Steps**:

1. **Develop with rocks-predicates**: Start building applications using the rocks-predicates module
2. **Explore RocksDB features**: Read the SWI-Prolog rocksdb pack documentation
3. **Run benchmarks**: Test performance for your use case
4. **Contribute**: Report issues or improvements to the upstream repositories

**Resources**:

- SWI-Prolog Documentation: https://www.swi-prolog.org/
- RocksDB Pack Repository: https://github.com/JanWielemaker/rocksdb
- rocks-predicates Repository: https://github.com/JanWielemaker/rocks-predicates
- Homebrew Documentation: https://docs.brew.sh/

---

## Comparison with Other Platforms

| Aspect | macOS (Homebrew) | Windows (vcpkg) | Windows (MSYS2) | Linux (WSL2/Ubuntu) |
|--------|------------------|-----------------|-----------------|---------------------|
| **Package Manager** | Homebrew | vcpkg | MSYS2/pacman | APT + PPA |
| **Build Tools** | Xcode CLT | VS Build Tools | MinGW GCC | build-essential |
| **Install Time** | 20-40 min | 4-6 hours | 1-2 hours | 30-60 min |
| **Complexity** | Low | High | Medium | Low |
| **Patches Required** | No | Yes (vcpkg) | No | No |
| **Isolation** | VM optional | Sandbox | Sandbox | WSL2 VM |
| **Snapshots** | VM or Time Machine | Ephemeral (restart) | Ephemeral (restart) | wsl --export/import |
| **Repository** | Official (JanWielemaker) | Fork (EricGT) | Official (JanWielemaker) | Official (JanWielemaker) |

**macOS Advantages**:
- Fast installation using system packages
- No patches required (RocksDB works out of box)
- Native Unix environment (like Linux)
- Homebrew provides recent stable versions
- Supports both Intel and Apple Silicon architectures

---

**End of Guide**
