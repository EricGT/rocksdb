# Windows Sandbox Installation Guide: RocksDB + rocks-predicates with MSYS2

## Overview

This guide provides a complete procedure for installing and testing SWI-Prolog with the RocksDB pack and rocks-predicates module using MSYS2 in Windows Sandbox. This approach uses MSYS2's package manager (pacman) to install pre-built packages, making it simpler and faster than the vcpkg approach.

**Estimated Time**: 1-2 hours

**What You'll Install**:
- MSYS2 (Unix-like environment for Windows)
- MinGW-w64 GCC compiler
- RocksDB library (via MSYS2 packages)
- SWI-Prolog (via MSYS2 packages)
- rocksdb pack (SWI-Prolog interface for RocksDB) - using official JanWielemaker repository
- rocks-predicates module (persistent predicate storage) - using official JanWielemaker repository

**Other Installation Options**:
- For Windows installation with vcpkg: See [Windows-Sandbox-vcpkg-Guide.md](Windows-Sandbox-vcpkg-Guide.md)
- For Linux installation: See [WSL2-Ubuntu-Guide.md](WSL2-Ubuntu-Guide.md)
- For macOS installation: See [macOS-Homebrew-Guide.md](macOS-Homebrew-Guide.md)

**Key Advantages**:
- No Visual Studio Build Tools required (uses MinGW GCC)
- No patches needed (uses standard build process)
- Faster installation (~1-2 hours vs 4-6 hours for vcpkg)
- Unix-like environment on Windows

---

## Repositories Used

- **rocksdb pack**: https://github.com/JanWielemaker/rocksdb (official repository)
- **rocks-predicates**: https://github.com/JanWielemaker/rocks-predicates (official repository)

---

## Folder Structure

```
%USERPROFILE%\sandbox\
├── shared/                      (mapped to C:\Shared in sandbox)
│   ├── installers/              (cached installer executables)
│   │   └── msys2-x86_64-*.exe
│   └── logs/                    (output logs)
└── CleanInstallTest.wsb         (sandbox configuration file)
```

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

## Important: Sandbox Display Behavior

Windows Sandbox runs as a lightweight Hyper-V virtual machine and uses Remote Desktop Protocol (RDP) to display the guest desktop in the host window.

When the Sandbox window is minimized or not the active window on the host, the display may appear frozen or stuck. **The sandbox is still running** - only the screen rendering is paused to conserve system resources.

To update the display:
1. Click on the Sandbox window to make it active
2. Click inside any window that appears frozen
3. The output will refresh and show current status

---

## Stages

### Stage 1: Manual Downloads

💡 **Purpose**
Download MSYS2 installer to shared folder for sandbox access.

| | |
|---|---|
| 🖥️ **Environment** | HOST (Windows 11, non-sandbox) |
| 🔧 **App** | Web browser (Edge, Chrome, etc.) |
| 👤 **Admin** | No |

**Download this file and save to `%USERPROFILE%\sandbox\shared\installers\`:**

| Download | URL |
|----------|-----|
| MSYS2 | https://github.com/msys2/msys2-installer/releases/latest |

- Download the latest `msys2-x86_64-YYYYMMDD.exe` file
- Save to `%USERPROFILE%\sandbox\shared\installers\`

---

### Stage 2: Sandbox Setup

💡 **Purpose**
Launch sandbox and pin frequently used tools for easy access.

**Step 1: Create .wsb configuration file**

| | |
|---|---|
| 🖥️ **Environment** | HOST |
| 🔧 **App** | Text editor (Notepad, VS Code, etc.) |
| 👤 **Admin** | No |

- Create file `%USERPROFILE%\sandbox\CleanInstallTest.wsb` with this content:

```xml
<Configuration>
  <MappedFolders>
    <MappedFolder>
      <HostFolder>%USERPROFILE%\sandbox\shared</HostFolder>
      <SandboxFolder>C:\Shared</SandboxFolder>
      <ReadOnly>false</ReadOnly>
    </MappedFolder>
  </MappedFolders>
  <MemoryInMB>8192</MemoryInMB>
  <Networking>Enable</Networking>
</Configuration>
```

**Step 2: Launch the sandbox**

| | |
|---|---|
| 🖥️ **Environment** | HOST |
| 🔧 **App** | File Explorer |
| 👤 **Admin** | No |

- Double-click `%USERPROFILE%\sandbox\CleanInstallTest.wsb`
- Wait for sandbox to fully load

**Step 3: Pin Task Manager to taskbar**

| | |
|---|---|
| 🖥️ **Environment** | SANDBOX |
| 🔧 **App** | Start Menu |
| 👤 **Admin** | No |

- Click Start menu (or press Windows key)
- Type `task manager`
- Right-click "Task Manager" → "Pin to taskbar"
- **Tip**: Use to monitor installation progress

**Step 4: Pin C:\Shared to Quick Access**

| | |
|---|---|
| 🖥️ **Environment** | SANDBOX |
| 🔧 **App** | File Explorer |
| 👤 **Admin** | No |

- Open File Explorer (Win+E)
- Navigate to `C:\Shared`
- Right-click `C:\Shared` → "Pin to Quick access"

---

### Stage 3: Install MSYS2

💡 **Purpose**
Install MSYS2 Unix-like environment on Windows.

**Step 1: Run MSYS2 installer**

| | |
|---|---|
| 🖥️ **Environment** | SANDBOX |
| 🔧 **App** | File Explorer |
| 👤 **Admin** | No |
| **Directory** | C:\Shared\installers |
| ⏱️ **Time** | ~5 min |

- Run the MSYS2 installer (`msys2-x86_64-*.exe`)
- Accept default installation path: `C:\msys64`
- Complete installation

**Step 2: Initial system update**

| | |
|---|---|
| 🖥️ **Environment** | SANDBOX |
| 🔧 **Terminal** | MSYS2 MSYS (default terminal) |
| 👤 **Admin** | No |

- MSYS2 terminal opens automatically after installation
- Run:

```bash
pacman -Syu
```

📝 **Note**: If prompted to close the terminal and restart, do so, then run `pacman -Syu` again.

**Step 3: Verify MSYS2 installation**

| | |
|---|---|
| 🖥️ **Environment** | SANDBOX |
| 🔧 **Terminal** | MSYS2 MSYS |
| 👤 **Admin** | No |

```bash
pacman --version
uname -a
```

**Expected**: Shows pacman version and MSYS system information.

---

### Stage 4: Pin MINGW64 Terminal

💡 **Purpose**
Find and pin the MINGW64 terminal, which is required for building native Windows applications.

| | |
|---|---|
| 🖥️ **Environment** | SANDBOX |
| 🔧 **App** | Start Menu |
| 👤 **Admin** | No |

⚠️ **Important**: Use **MINGW64** terminal (purple/blue icon), NOT the regular "MSYS2 MSYS" terminal.

- Click Start menu
- Type `mingw64`
- Look for "MSYS2 MINGW64" (purple/blue icon)
- Right-click → "Pin to taskbar"

📝 **Note**: MSYS2 provides three main terminals:
- **MINGW64**: For building 64-bit Windows applications (use this one)
- **MINGW32**: For building 32-bit Windows applications
- **MSYS**: For Unix utilities (not for building)

---

### Stage 5: Install Required Packages

💡 **Purpose**
Install Git, GCC compiler, RocksDB, and SWI-Prolog via MSYS2 package manager.

| | |
|---|---|
| 🖥️ **Environment** | SANDBOX |
| 🔧 **Terminal** | MSYS2 MINGW64 (purple/blue icon) |
| 👤 **Admin** | No |
| ⏱️ **Time** | ~10-15 min |

- Click the pinned MINGW64 terminal icon
- Run these commands:

```bash
# Install Git
pacman -S git

# Install GCC compiler
pacman -S mingw-w64-x86_64-gcc

# Install RocksDB library
pacman -S mingw-w64-x86_64-rocksdb

# Install SWI-Prolog
pacman -S mingw-w64-x86_64-swi-prolog
```

**Verify installations**:

```bash
git --version
gcc --version
swipl --version
pkg-config --modversion rocksdb
```

**Expected output**:
```
git version 2.xx.x
gcc (Rev...) xx.x.x
SWI-Prolog version x.x.x for x86_64-w64-mingw32
x.x.x
```

---

### Stage 6: Clone and Build rocksdb Pack

💡 **Purpose**
Clone the official rocksdb pack and build it with MSYS2's RocksDB library.

**Step 1: Clone rocksdb repository**

| | |
|---|---|
| 🖥️ **Environment** | SANDBOX |
| 🔧 **Terminal** | MSYS2 MINGW64 |
| 👤 **Admin** | No |

```bash
cd ~
git clone https://github.com/JanWielemaker/rocksdb.git
cd rocksdb
mkdir -p lib/x64-win64
```

**Step 2: Apply MSYS2 compatibility fixes**

| | |
|---|---|
| 🖥️ **Environment** | SANDBOX |
| 🔧 **Terminal** | MSYS2 MINGW64 |
| 👤 **Admin** | No |

The official repository needs minor fixes for MSYS2 compatibility:

```bash
# Fix include paths
sed -i 's/#include <SWI-Prolog.h>/#include <swipl\/SWI-Prolog.h>/' cpp/rocksdb4pl.cpp

# Fix swiplVersion if needed
sed -i 's/swiplVersion/SWIPL_VERSION_GIT/' cpp/rocksdb4pl.cpp 2>/dev/null || true
```

**Step 3: Compile the foreign library**

| | |
|---|---|
| 🖥️ **Environment** | SANDBOX |
| 🔧 **Terminal** | MSYS2 MINGW64 |
| 👤 **Admin** | No |
| ⏱️ **Time** | ~2-3 min |

```bash
g++ -shared -D__SWI_PROLOG__ \
    -I/mingw64/lib/swipl/include \
    cpp/rocksdb4pl.cpp \
    /mingw64/lib/librocksdb.a \
    -L/mingw64/lib/swipl/lib/x64-win64 -lswipl \
    -lsnappy -lzstd -lz -llz4 -lbz2 -lshlwapi -lrpcrt4 \
    -o lib/x64-win64/rocksdb4pl.dll
```

**Verify compilation**:

```bash
ls -lh lib/x64-win64/rocksdb4pl.dll
```

**Expected**: Should show the compiled DLL file.

**Step 4: Install pack to SWI-Prolog**

| | |
|---|---|
| 🖥️ **Environment** | SANDBOX |
| 🔧 **Terminal** | MSYS2 MINGW64 |
| 👤 **Admin** | No |

```bash
# Create pack directory structure
mkdir -p ~/.local/share/swi-prolog/pack/rocksdb/lib/x64-win64

# Copy pack metadata
cp pack.pl ~/.local/share/swi-prolog/pack/rocksdb/

# Copy Prolog source files
cp -r prolog ~/.local/share/swi-prolog/pack/rocksdb/

# Copy the DLL
cp lib/x64-win64/rocksdb4pl.dll ~/.local/share/swi-prolog/pack/rocksdb/lib/x64-win64/
```

**Verify pack structure**:

```bash
ls -la ~/.local/share/swi-prolog/pack/rocksdb/
ls -la ~/.local/share/swi-prolog/pack/rocksdb/lib/x64-win64/
```

---

### Stage 7: Test rocksdb Pack

💡 **Purpose**
Verify that the rocksdb pack loads and functions correctly.

**Step 1: Test library loading**

| | |
|---|---|
| 🖥️ **Environment** | SANDBOX |
| 🔧 **Terminal** | MSYS2 MINGW64 |
| 👤 **Admin** | No |

```bash
swipl -g "use_module(library(rocksdb)), writeln('rocksdb loaded successfully'), halt"
```

**Expected output**: `rocksdb loaded successfully`

**Step 2: Run functional test**

| | |
|---|---|
| 🖥️ **Environment** | SANDBOX |
| 🔧 **Terminal** | MSYS2 MINGW64 |
| 👤 **Admin** | No |

```bash
mkdir -p /tmp
swipl -g "use_module(library(rocksdb)), rocks_open('/tmp/test_db', Db, []), rocks_put(Db, hello, world), rocks_get(Db, hello, V), format('Got: ~w~n', [V]), rocks_close(Db), halt"
```

**Expected output**: `Got: world`

**Step 3: Run test suite (if available)**

| | |
|---|---|
| 🖥️ **Environment** | SANDBOX |
| 🔧 **Terminal** | MSYS2 MINGW64 |
| 👤 **Admin** | No |

```bash
cd ~/rocksdb/test
swipl -g "consult('test_rocksdb.pl'), run_tests, halt" -t "halt(1)"
```

✅ **Expected**: Tests pass (if test suite is available)

---

### Stage 8: Clone and Test rocks-predicates

💡 **Purpose**
Clone and test the rocks-predicates module for persistent predicate storage.

**Step 1: Clone rocks-predicates**

| | |
|---|---|
| 🖥️ **Environment** | SANDBOX |
| 🔧 **Terminal** | MSYS2 MINGW64 |
| 👤 **Admin** | No |

```bash
cd ~
git clone https://github.com/JanWielemaker/rocks-predicates.git
cd rocks-predicates
```

**Step 2: Verify module loads**

| | |
|---|---|
| 🖥️ **Environment** | SANDBOX |
| 🔧 **Terminal** | MSYS2 MINGW64 |
| 👤 **Admin** | No |

```bash
swipl -g "use_module(rocks_preds), writeln('rocks_preds loaded successfully'), halt"
```

**Expected output**: `rocks_preds loaded successfully`

**Step 3: Run functional test**

| | |
|---|---|
| 🖥️ **Environment** | SANDBOX |
| 🔧 **Terminal** | MSYS2 MINGW64 |
| 👤 **Admin** | No |

```bash
swipl -g "use_module(rocks_preds), rdb_open('test_db', _), rdb_assertz(test_fact(hello)), rdb_clause(test_fact(X), true), format('Got: ~w~n', [X]), rdb_close, halt"
```

**Expected output**: `Got: hello`

**Step 4: Run test suite**

| | |
|---|---|
| 🖥️ **Environment** | SANDBOX |
| 🔧 **Terminal** | MSYS2 MINGW64 |
| 👤 **Admin** | No |
| ⏱️ **Time** | ~1-2 min |

```bash
mkdir -p dbs
swipl run_all_tests.pl
```

✅ **Expected**: All tests pass

---

## Testing Workflow Summary

| Stage | Environment | Terminal/App | Admin? | Time | Action |
|-------|-------------|--------------|--------|------|--------|
| 1 | HOST | Browser | No | ~5 min | Download MSYS2 installer |
| 2 | HOST/SANDBOX | File Explorer, Start Menu | No | ~5 min | Create .wsb, launch sandbox, pin tools |
| 3 | SANDBOX | MSYS2 installer, MSYS terminal | No | ~10 min | Install MSYS2, initial update |
| 4 | SANDBOX | Start Menu | No | ~1 min | Pin MINGW64 terminal |
| 5 | SANDBOX | MINGW64 terminal | No | ~15 min | Install packages (git, gcc, rocksdb, swi-prolog) |
| 6 | SANDBOX | MINGW64 terminal | No | ~10 min | Clone and build rocksdb pack |
| 7 | SANDBOX | MINGW64 terminal | No | ~5 min | Test rocksdb pack |
| 8 | SANDBOX | MINGW64 terminal | No | ~5 min | Clone and test rocks-predicates |

**Total Time**: ~1-2 hours

---

## Troubleshooting

### Wrong Terminal Selected

| Symptom | Cause | Fix |
|---------|-------|-----|
| Commands not found | Using MSYS terminal instead of MINGW64 | Use **MINGW64** terminal (purple/blue icon) |
| Compilation fails | Wrong compiler environment | Verify you're in MINGW64: `echo $MSYSTEM` should show `MINGW64` |

### Package Installation Issues

| Symptom | Cause | Fix |
|---------|-------|-----|
| `pacman: command not found` | Not in MSYS2 environment | Launch MSYS2/MINGW64 terminal |
| Package not found | Database not updated | Run `pacman -Syu` first |
| Installation fails | Repository mirror issue | Try different mirror or wait and retry |

### DLL Issues

| Symptom | Cause | Fix |
|---------|-------|-----|
| rocksdb4pl.dll not found | DLL not in pack lib directory | Verify: `ls ~/.local/share/swi-prolog/pack/rocksdb/lib/x64-win64/rocksdb4pl.dll` |
| Missing dependency DLLs | MSYS2 libraries not in PATH | Run from MINGW64 terminal (sets up PATH automatically) |

### Build Failures

| Symptom | Cause | Fix |
|---------|-------|-----|
| Compiler not found | gcc not installed | `pacman -S mingw-w64-x86_64-gcc` |
| Header files not found | Include paths wrong | Verify sed commands were run correctly |
| Linker errors | Missing libraries | Verify rocksdb installed: `pacman -Q mingw-w64-x86_64-rocksdb` |

---

## Success Criteria

✅ MSYS2 installed successfully
✅ MINGW64 terminal identified and pinned
✅ Git, GCC, RocksDB, SWI-Prolog packages installed
✅ rocksdb pack compiled successfully
✅ rocksdb pack loads: `use_module(library(rocksdb))`
✅ rocksdb functional test passes
✅ rocks-predicates module loads: `use_module(rocks_preds)`
✅ rocks-predicates tests pass

---

## Key Differences from vcpkg Guide

| Aspect | MSYS2 (This Guide) | vcpkg |
|--------|-------------------|-------|
| **Build Tools** | MinGW GCC | Visual Studio Build Tools |
| **Installation Time** | 1-2 hours | 4-6 hours |
| **Complexity** | Medium | High |
| **Patches Required** | No | Yes |
| **Package Manager** | pacman (MSYS2) | vcpkg |
| **Environment** | Unix-like (MSYS2) | Windows native |
| **Repositories Used** | Official JanWielemaker repos | EricGT forks |

---

**End of Guide**

For questions or issues, refer to:
- SWI-Prolog Discourse: https://swi-prolog.discourse.group/
- MSYS2 Documentation: https://www.msys2.org/docs/
- rocksdb pack: https://github.com/JanWielemaker/rocksdb
- rocks-predicates: https://github.com/JanWielemaker/rocks-predicates
