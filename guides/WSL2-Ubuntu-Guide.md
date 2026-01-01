# WSL2 Ubuntu Installation Guide: RocksDB + rocks-predicates

## Overview

This guide provides a complete procedure for installing and testing SWI-Prolog with the RocksDB pack and rocks-predicates module on Ubuntu running in WSL2 (Windows Subsystem for Linux). This approach uses APT system packages and provides a true Linux environment on Windows.

**Estimated Time**: 30-60 minutes

**What You'll Install**:
- WSL2 (Windows Subsystem for Linux 2)
- Ubuntu (latest LTS)
- Build tools (gcc, cmake, ninja, git)
- RocksDB library (via APT)
- SWI-Prolog (via PPA for latest version)
- rocksdb pack (SWI-Prolog interface for RocksDB) - using official JanWielemaker repository
- rocks-predicates module (persistent predicate storage) - using official JanWielemaker repository

**Other Installation Options**:
- For Windows installation with vcpkg: See [Windows-Sandbox-vcpkg-Guide.md](Windows-Sandbox-vcpkg-Guide.md)
- For Windows installation with MSYS2: See [Windows-Sandbox-MSYS2-Guide.md](Windows-Sandbox-MSYS2-Guide.md)
- For macOS installation: See [macOS-Homebrew-Guide.md](macOS-Homebrew-Guide.md)

**Key Advantages**:
- Fastest installation method (~30-60 minutes)
- True Linux environment
- Latest SWI-Prolog via PPA
- User-controlled snapshots via `wsl --export/import`
- No Windows Sandbox needed (WSL2 provides isolation)

---

## Repositories Used

- **rocksdb pack**: https://github.com/JanWielemaker/rocksdb (official repository)
- **rocks-predicates**: https://github.com/JanWielemaker/rocks-predicates (official repository)

---

## Icon Reference

| Icon | Field |
|------|-------|
| 🖥️ | Environment |
| 🔧 | Terminal/App |
| 👤 | Admin |
| 💡 | Purpose |
| ⚠️ | Warning |
| 📝 | Note |
| ⏱️ | Time |
| ✅ | Checkpoint |

---

## Prerequisites

- Windows 10 version 2004 or later, OR Windows 11
- At least 4 GB RAM
- At least 10 GB free disk space
- Administrator access on Windows

---

## Stages

### Stage 1: Enable WSL2

💡 **Purpose**
Install and configure Windows Subsystem for Linux 2 with Ubuntu.

**Step 1: Install WSL2 and Ubuntu**

| | |
|---|---|
| 🖥️ **Environment** | HOST (Windows, PowerShell) |
| 🔧 **Terminal** | PowerShell |
| 👤 **Admin** | **Yes** |
| ⏱️ **Time** | ~10-15 min |

- Right-click Start menu → "Windows PowerShell (Admin)" or "Windows Terminal (Admin)"
- Run:

```powershell
wsl --install
```

📝 **Note**: This installs WSL2 and Ubuntu (default distribution) automatically.

**Step 2: Reboot if required**

| | |
|---|---|
| 🖥️ **Environment** | HOST |
| 👤 **Admin** | Yes |

- If prompted, reboot Windows
- After reboot, Ubuntu will launch automatically to complete setup

**Step 3: Set up Ubuntu username and password**

| | |
|---|---|
| 🖥️ **Environment** | WSL2 Ubuntu |
| 🔧 **Terminal** | Ubuntu terminal |
| 👤 **Admin** | No |

- Ubuntu will prompt for a username and password on first launch
- Choose a username (lowercase, no spaces)
- Set a password (you'll need this for `sudo` commands)

**Step 4: Verify WSL2 installation**

| | |
|---|---|
| 🖥️ **Environment** | HOST (Windows, PowerShell) |
| 🔧 **Terminal** | PowerShell |
| 👤 **Admin** | No |

```powershell
wsl --list --verbose
```

**Expected output**:
```
  NAME            STATE           VERSION
* Ubuntu          Running         2
```

📝 **Note**: VERSION must be 2 (not 1). If it shows 1, run: `wsl --set-version Ubuntu 2`

---

### WSL2 Snapshot Instructions (Optional)

💡 **Purpose**
Create backups of your WSL2 distribution at key points for easy rollback.

📝 **Note**: **You decide when to create snapshots.** Recommended points are listed below, but snapshots are entirely optional.

**Creating a Snapshot**

| | |
|---|---|
| 🖥️ **Environment** | HOST (Windows, PowerShell) |
| 🔧 **Terminal** | PowerShell |
| 👤 **Admin** | No |

```powershell
# Create backup directory
mkdir C:\WSL-Backups

# Export Ubuntu distribution to a .tar file
wsl --export Ubuntu C:\WSL-Backups\ubuntu-snapshot-20250101.tar
```

📝 **Note**: Replace the date in the filename with the current date (YYYYMMDD format).

**Restoring a Snapshot**

| | |
|---|---|
| 🖥️ **Environment** | HOST (Windows, PowerShell) |
| 🔧 **Terminal** | PowerShell |
| 👤 **Admin** | No |

```powershell
# Import to a new distribution name (keeps original)
wsl --import Ubuntu-Restored C:\WSL-Restored C:\WSL-Backups\ubuntu-snapshot-20250101.tar

# OR: Replace current Ubuntu (WARNING: deletes current distribution)
wsl --unregister Ubuntu
wsl --import Ubuntu C:\Ubuntu C:\WSL-Backups\ubuntu-snapshot-20250101.tar
```

⚠️ **Warning**: `wsl --unregister` permanently deletes the distribution. Make sure you have a valid backup first!

**List All Distributions**

```powershell
wsl --list --verbose
```

**Recommended Snapshot Points** (user choice):
- After Stage 2 (system updated) → `ubuntu-after-update.tar`
- After Stage 4 (SWI-Prolog installed) → `ubuntu-after-swipl.tar`
- Before Stage 5 (before building rocksdb pack) → `ubuntu-before-rocksdb.tar`

📝 **Note**: Export creates a `.tar` file that can be 1-5 GB depending on installed packages.

---

### Stage 2: Update Ubuntu System

💡 **Purpose**
Update the Ubuntu package lists and upgrade installed packages.

| | |
|---|---|
| 🖥️ **Environment** | WSL2 Ubuntu |
| 🔧 **Terminal** | Ubuntu terminal (wsl) |
| 👤 **Admin** | sudo |
| ⏱️ **Time** | ~5-10 min |

```bash
sudo apt update
sudo apt upgrade -y
```

**Verify system is up to date**:

```bash
lsb_release -a
uname -r
```

**Expected**: Shows Ubuntu version and WSL2 kernel version.

---

### Stage 3: Install Build Tools and Dependencies

💡 **Purpose**
Install compilers, build tools, and the RocksDB library.

| | |
|---|---|
| 🖥️ **Environment** | WSL2 Ubuntu |
| 🔧 **Terminal** | Ubuntu terminal |
| 👤 **Admin** | sudo |
| ⏱️ **Time** | ~5 min |

```bash
# Install build tools
sudo apt install -y build-essential cmake ninja-build git

# Install RocksDB library
sudo apt install -y librocksdb-dev
```

**Verify installations**:

```bash
gcc --version
cmake --version
ninja --version
git --version
pkg-config --modversion rocksdb
```

**Expected output**:
```
gcc (Ubuntu ...) ...
cmake version ...
ninja ...
git version ...
x.x.x (RocksDB version)
```

---

### Stage 4: Install SWI-Prolog via PPA

💡 **Purpose**
Install the latest stable version of SWI-Prolog using the official PPA.

📝 **Why PPA?** Ubuntu's default `swi-prolog` package may be outdated. Using the PPA ensures you get the latest stable version with recent features and bug fixes.

| | |
|---|---|
| 🖥️ **Environment** | WSL2 Ubuntu |
| 🔧 **Terminal** | Ubuntu terminal |
| 👤 **Admin** | sudo |
| ⏱️ **Time** | ~3-5 min |

**Step 1: Add SWI-Prolog PPA**

```bash
sudo apt-add-repository ppa:swi-prolog/stable
```

**Step 2: Update package list**

```bash
sudo apt update
```

**Step 3: Install SWI-Prolog**

```bash
sudo apt install -y swi-prolog
```

**Step 4: Verify installation**

```bash
swipl --version
which swipl
swipl --dump-runtime-variables | grep PLBASE
```

**Expected output**:
```
SWI-Prolog version x.x.x for x86_64-linux

/usr/bin/swipl

PLBASE="/usr/lib/swi-prolog";
```

---

### Stage 5: Clone and Build rocksdb Pack

💡 **Purpose**
Clone the official rocksdb pack and build it with system RocksDB.

**Step 1: Clone rocksdb repository**

| | |
|---|---|
| 🖥️ **Environment** | WSL2 Ubuntu |
| 🔧 **Terminal** | Ubuntu terminal |
| 👤 **Admin** | No |

```bash
cd ~
git clone https://github.com/JanWielemaker/rocksdb.git
cd rocksdb
```

**Step 2: Build with CMake**

| | |
|---|---|
| 🖥️ **Environment** | WSL2 Ubuntu |
| 🔧 **Terminal** | Ubuntu terminal |
| 👤 **Admin** | No |
| ⏱️ **Time** | ~2-3 min |

```bash
mkdir -p build
cd build
cmake -G Ninja -DCMAKE_BUILD_TYPE=Release ..
cmake --build . --config Release
```

📝 **Note**: System librocksdb-dev works without patches. CMake should find RocksDB automatically.

**Step 3: Install pack to SWI-Prolog**

| | |
|---|---|
| 🖥️ **Environment** | WSL2 Ubuntu |
| 🔧 **Terminal** | Ubuntu terminal |
| 👤 **Admin** | No |

```bash
# Create pack directory structure
mkdir -p ~/.local/share/swi-prolog/pack/rocksdb/lib/x86_64-linux

# Copy pack metadata
cp ~/rocksdb/pack.pl ~/.local/share/swi-prolog/pack/rocksdb/

# Copy Prolog source files
cp -r ~/rocksdb/prolog ~/.local/share/swi-prolog/pack/rocksdb/

# Copy the compiled library
cp ~/rocksdb/build/librocksdb4pl.so ~/.local/share/swi-prolog/pack/rocksdb/lib/x86_64-linux/
```

**Verify pack structure**:

```bash
ls -la ~/.local/share/swi-prolog/pack/rocksdb/
ls -la ~/.local/share/swi-prolog/pack/rocksdb/lib/x86_64-linux/
```

---

### Stage 6: Test rocksdb Pack

💡 **Purpose**
Verify that the rocksdb pack loads and functions correctly.

**Step 1: Test library loading**

| | |
|---|---|
| 🖥️ **Environment** | WSL2 Ubuntu |
| 🔧 **Terminal** | Ubuntu terminal |
| 👤 **Admin** | No |

```bash
swipl -g "use_module(library(rocksdb)), writeln('rocksdb loaded successfully'), halt"
```

**Expected output**: `rocksdb loaded successfully`

**Step 2: Run functional test**

| | |
|---|---|
| 🖥️ **Environment** | WSL2 Ubuntu |
| 🔧 **Terminal** | Ubuntu terminal |
| 👤 **Admin** | No |

```bash
mkdir -p /tmp
swipl -g "use_module(library(rocksdb)), rocks_open('/tmp/test_db', Db, []), rocks_put(Db, hello, world), rocks_get(Db, hello, V), format('Got: ~w~n', [V]), rocks_close(Db), halt"
```

**Expected output**: `Got: world`

**Step 3: Run test suite**

| | |
|---|---|
| 🖥️ **Environment** | WSL2 Ubuntu |
| 🔧 **Terminal** | Ubuntu terminal |
| 👤 **Admin** | No |

```bash
cd ~/rocksdb/test
swipl -g "consult('test_rocksdb.pl'), run_tests, halt" -t "halt(1)"
```

✅ **Expected**: Tests pass

---

### Stage 7: Clone and Test rocks-predicates

💡 **Purpose**
Clone and test the rocks-predicates module for persistent predicate storage.

**Step 1: Clone rocks-predicates**

| | |
|---|---|
| 🖥️ **Environment** | WSL2 Ubuntu |
| 🔧 **Terminal** | Ubuntu terminal |
| 👤 **Admin** | No |

```bash
cd ~
git clone https://github.com/JanWielemaker/rocks-predicates.git
cd rocks-predicates
```

**Step 2: Verify module loads**

| | |
|---|---|
| 🖥️ **Environment** | WSL2 Ubuntu |
| 🔧 **Terminal** | Ubuntu terminal |
| 👤 **Admin** | No |

```bash
swipl -g "use_module(rocks_preds), writeln('rocks_preds loaded successfully'), halt"
```

**Expected output**: `rocks_preds loaded successfully`

**Step 3: Run functional test**

| | |
|---|---|
| 🖥️ **Environment** | WSL2 Ubuntu |
| 🔧 **Terminal** | Ubuntu terminal |
| 👤 **Admin** | No |

```bash
swipl -g "use_module(rocks_preds), rdb_open('test_db', _), rdb_assertz(test_fact(hello)), rdb_clause(test_fact(X), true), format('Got: ~w~n', [X]), rdb_close, halt"
```

**Expected output**: `Got: hello`

**Step 4: Run test suite**

| | |
|---|---|
| 🖥️ **Environment** | WSL2 Ubuntu |
| 🔧 **Terminal** | Ubuntu terminal |
| 👤 **Admin** | No |
| ⏱️ **Time** | ~1-2 min |

```bash
mkdir -p dbs
swipl run_all_tests.pl
```

✅ **Expected**: All tests pass

---

## File System Notes

💡 **Purpose**
Understand WSL2 file system paths and performance considerations.

**Windows drives in WSL2**:
- Access Windows drives via `/mnt/` prefix
  - C: drive → `/mnt/c/`
  - D: drive → `/mnt/d/`
- Example: `cd /mnt/c/Users/YourName/Documents`

**Linux home directory**:
- Your home: `~/` = `/home/username/`
- Example: `cd ~/projects`

**Performance**:
- **Keep files in Linux filesystem** (`~/`) for best performance
- Accessing Windows filesystem (`/mnt/c/`) is slower due to translation layer
- Database files should be in `~/` for optimal I/O

**Accessing WSL2 files from Windows**:
- Use `\\wsl$\Ubuntu\home\username\` in Windows Explorer
- Or: Run `explorer.exe .` from WSL2 terminal to open current directory in Windows Explorer

---

## Troubleshooting

### WSL2 Installation Issues

| Symptom | Cause | Fix |
|---------|-------|-----|
| `wsl --install` fails | Virtualization not enabled in BIOS | Enable VT-x (Intel) or AMD-V (AMD) in BIOS |
| WSL version is 1 not 2 | WSL2 not set as default | `wsl --set-default-version 2`, then `wsl --set-version Ubuntu 2` |
| Ubuntu not found | Not installed | `wsl --install -d Ubuntu` |

### Network/DNS Issues

| Symptom | Cause | Fix |
|---------|-------|-----|
| `apt update` fails | DNS resolution issue | Edit `/etc/resolv.conf`: `nameserver 8.8.8.8` |
| Cannot reach internet | Windows firewall | Allow WSL2 in Windows Firewall |

### Build Issues

| Symptom | Cause | Fix |
|---------|-------|-----|
| CMake can't find RocksDB | librocksdb-dev not installed | `sudo apt install librocksdb-dev`, verify with `pkg-config --modversion rocksdb` |
| Compilation fails | Build tools missing | `sudo apt install build-essential cmake ninja-build` |
| Wrong architecture | 32-bit vs 64-bit mismatch | Reinstall Ubuntu (WSL2 is 64-bit by default) |

### File Permission Issues

| Symptom | Cause | Fix |
|---------|-------|-----|
| Permission denied | File in Windows filesystem | Move files to Linux filesystem (`~/`) |
| `sudo` doesn't work | Wrong password | Use the password you set during Ubuntu setup |

### Path Translation Issues

| Symptom | Cause | Fix |
|---------|-------|-----|
| Windows paths don't work | Using Windows-style paths in Linux | Convert: `C:\Users\Name` → `/mnt/c/Users/Name` |
| Spaces in paths cause errors | Unquoted paths | Use quotes: `cd "/mnt/c/Program Files/"` |

---

## Testing Workflow Summary

| Stage | Environment | Terminal | Admin? | Time | Action |
|-------|-------------|----------|--------|------|--------|
| 1 | HOST + WSL2 | PowerShell + Ubuntu | Yes/No | ~15 min | Install WSL2 and Ubuntu |
| 2 | WSL2 | Ubuntu | sudo | ~10 min | Update Ubuntu system |
| 3 | WSL2 | Ubuntu | sudo | ~5 min | Install build tools and RocksDB |
| 4 | WSL2 | Ubuntu | sudo | ~5 min | Install SWI-Prolog via PPA |
| 5 | WSL2 | Ubuntu | No | ~5 min | Clone and build rocksdb pack |
| 6 | WSL2 | Ubuntu | No | ~5 min | Test rocksdb pack |
| 7 | WSL2 | Ubuntu | No | ~5 min | Clone and test rocks-predicates |

**Total Time**: ~30-60 minutes

---

## Success Criteria

✅ WSL2 installed and running Ubuntu
✅ Ubuntu system updated
✅ Build tools installed (gcc, cmake, ninja, git)
✅ RocksDB library installed
✅ SWI-Prolog installed via PPA (latest version)
✅ rocksdb pack compiled successfully
✅ rocksdb pack loads: `use_module(library(rocksdb))`
✅ rocksdb functional test passes
✅ rocks-predicates module loads: `use_module(rocks_preds)`
✅ rocks-predicates tests pass

---

## Key Differences from Windows Guides

| Aspect | WSL2 (This Guide) | vcpkg | MSYS2 |
|--------|-------------------|-------|-------|
| **OS** | Linux (Ubuntu) | Windows | Windows |
| **Installation Time** | 30-60 min | 4-6 hours | 1-2 hours |
| **Complexity** | Low | High | Medium |
| **Patches Required** | No | Yes | No |
| **Package Manager** | APT + PPA | vcpkg | pacman |
| **Environment** | True Linux | Windows native | Unix-like |
| **Snapshots** | wsl --export/import | Ephemeral (restart) | Ephemeral (restart) |
| **Repositories Used** | Official JanWielemaker | EricGT forks | Official JanWielemaker |

---

**End of Guide**

For questions or issues, refer to:
- SWI-Prolog Discourse: https://swi-prolog.discourse.group/
- WSL2 Documentation: https://learn.microsoft.com/en-us/windows/wsl/
- Ubuntu Documentation: https://help.ubuntu.com/
- rocksdb pack: https://github.com/JanWielemaker/rocksdb
- rocks-predicates: https://github.com/JanWielemaker/rocks-predicates
