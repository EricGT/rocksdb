# Windows Sandbox Installation Guide: RocksDB + rocks-predicates with vcpkg

## Overview

This guide provides a complete, standalone procedure for installing and testing SWI-Prolog with the RocksDB pack and rocks-predicates module using vcpkg in Windows Sandbox. This approach uses the patched `pack_install` system that integrates vcpkg as the C++ dependency manager.

**Estimated Time**: 4-6 hours (VS Build Tools installation takes 3+ hours)

**What You'll Install**:
- Visual Studio Build Tools 2022 (C++ compiler and Windows SDK)
- CMake (standalone)
- Git for Windows
- vcpkg (C++ package manager)
- RocksDB library (via vcpkg)
- SWI-Prolog 10.0.0
- rocksdb pack (SWI-Prolog interface for RocksDB) - using EricGT fork
- rocks-predicates module (persistent predicate storage) - using EricGT fork

**Other Installation Options**:
- For simpler Windows installation without Visual Studio: See [Windows-Sandbox-MSYS2-Guide.md](Windows-Sandbox-MSYS2-Guide.md)
- For Linux installation: See [WSL2-Ubuntu-Guide.md](WSL2-Ubuntu-Guide.md)
- For macOS installation: See [macOS-Homebrew-Guide.md](macOS-Homebrew-Guide.md)

---

## Repositories Used

- **rocksdb pack**: https://github.com/EricGT/rocksdb @ `feature/windows-vcpkg-support`
  - This fork contains Windows-specific patches for vcpkg integration that are being tested
- **rocks-predicates**: https://github.com/EricGT/rocks-predicates @ `feature/windows-support`
  - This fork contains Windows compatibility fixes

---

## Folder Structure

```
%USERPROFILE%\sandbox\
├── shared/                      (mapped to C:\Shared in sandbox)
│   ├── installers/              (cached installer executables)
│   │   ├── vs_BuildTools.exe
│   │   ├── swipl-*.exe
│   │   ├── Git-*.exe
│   │   └── cmake-*.msi
│   ├── swipl-patches/           (SWI-Prolog patch files)
│   │   ├── cmake.pl.patched
│   │   ├── tools.pl.patched
│   │   └── apply-patches.ps1
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

## Important: Windows Sandbox User Context

Apps in Windows Sandbox run under the **container user account**, which may be an administrator account. All operations within the sandbox run with elevated privileges automatically. This differs from typical Windows environments where standard users must explicitly request elevation.

📝 **Note**
While most operations in this guide are marked with "👤 Admin: No", this indicates that no additional elevation beyond the sandbox's default admin context is required. Only Stage 9 Step 2 (applying patches) explicitly requires running PowerShell "as administrator" to get the necessary permissions to modify files in `C:\Program Files\`.

📝 **Note**
In essence, this means that when using Windows Sandbox you will almost always be operating as an administrator. At present, I am not aware of a way to switch to a non-administrator user, though I would be interested in learning if such an option exists.

For more information about Windows Sandbox configuration and security context, see [Windows Sandbox Overview](https://learn.microsoft.com/en-us/windows/security/application-security/application-isolation/windows-sandbox/windows-sandbox-overview) and [Logon Command](https://learn.microsoft.com/en-us/windows/security/application-security/application-isolation/windows-sandbox/windows-sandbox-configure-using-wsb-file#logon-command).

---

## Important: Sandbox Display Behavior

Windows Sandbox runs as a lightweight Hyper-V virtual machine and uses Remote Desktop Protocol (RDP) to display the guest desktop in the host window (see [Windows Sandbox configuration](https://learn.microsoft.com/en-us/windows/security/application-security/application-isolation/windows-sandbox/windows-sandbox-configure-using-wsb-file)).

When the Sandbox window is minimized or not the active window on the host, the display may appear frozen or stuck. **The sandbox is still running** - only the screen rendering is paused to conserve system resources. This is standard RDP behavior: the connection remains active but image rendering pauses for inactive windows.

To update the display:
1. Click on the Sandbox window to make it active
2. Click inside any window that appears frozen (e.g., command prompt)
   * For dialogs may need to move the dialog to get a refresh
   * For terminals may need to press space bar or such to get a refresh (be careful as a space may also be a command and trigger an action)
3. The output will refresh and show current status

See [Microsoft Q&A: How to Prevent Minimized RDP Sessions from Freezing](https://learn.microsoft.com/en-us/answers/questions/2196906/how-to-prevent-minimized-rdp-sessions-from-freezin) for technical details on RDP rendering behavior.

---

## Stages

### Stage 1: Manual Downloads

💡 **Purpose**
Download installer files to shared folder for sandbox access.

📝 **Note**
By downloading and saving the installer files, if there is a problem and the steps have to be restarted, having the exact same installer will negate accidentally picking a wrong or different installer during a restart.

**Download these files and save to `%USERPROFILE%\sandbox\shared\installers\`:**

| | |
|---|---|
| 🖥️ **Environment** | HOST (Windows 11, non-sandbox) |
| 🔧 **App** | Web browser (Edge, Chrome, etc.) |
| 👤 **Admin** | No |

| Download | URL | Filename |
|----------|-----|----------|
| VS Build Tools | https://aka.ms/vs/17/release/vs_BuildTools.exe | `vs_BuildTools.exe` |
| SWI-Prolog | https://www.swi-prolog.org/download/stable/bin/swipl-10.0.0-1.x64.exe | `swipl-10.0.0-1.x64.exe` |
| Git for Windows | https://github.com/git-for-windows/git/releases/download/v2.52.0.windows.1/Git-2.52.0-64-bit.exe | `Git-2.52.0-64-bit.exe` |
| CMake | https://github.com/Kitware/CMake/releases/download/v4.2.1/cmake-4.2.1-windows-x86_64.msi | `cmake-4.2.1-windows-x86_64.msi` |

📝 **Note**
CMake and Git are installed as standalone tools per [vcpkg prerequisites](https://learn.microsoft.com/en-us/vcpkg/get_started/get-started).

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
| **Directory** | %USERPROFILE%\sandbox |

- Double-click `CleanInstallTest.wsb`
- Wait for sandbox to fully load

📝 **Note**
You will need to click inside the Windows sandbox window to make it the active window otherwise the next actions will be occurring in the host when they should be occurring inside the sandbox.

**Step 3: Pin Command Prompt to taskbar**

| | |
|---|---|
| 🖥️ **Environment** | SANDBOX |
| 🔧 **App** | Start Menu |
| 👤 **Admin** | No |

- Click Start menu (or press Windows key)
- Type `command prompt`
- Right-click "Command rompt" in search results → "Pin to taskbar"

**Step 4: Pin PowerShell to taskbar**

| | |
|---|---|
| 🖥️ **Environment** | SANDBOX |
| 🔧 **App** | Start Menu |
| 👤 **Admin** | No |

- Click Start menu (or press Windows key)
- Type `powershell`
- Right-click "Windows PowerShell" in search results → "Pin to taskbar"

**Step 5: Pin Task Manager to taskbar**

| | |
|---|---|
| 🖥️ **Environment** | SANDBOX |
| 🔧 **App** | Start Menu |
| 👤 **Admin** | No |

- Click Start menu (or press Windows key)
- Type `task manager`
- Right-click "Task Manager" in search results → "Pin to taskbar"
- **Tip**: Use Task Manager to monitor installation progress (Ctrl+Shift+Esc)

**Step 6: Pin C:\Shared to Quick Access**

| | |
|---|---|
| 🖥️ **Environment** | SANDBOX |
| 🔧 **App** | File Explorer |
| 👤 **Admin** | No |
| **Directory** | C:\Shared |

- Open File Explorer (Win+E)
- Navigate to `C:\Shared`
- Right-click `C:\Shared` in the address bar or folder → "Pin to Quick access"

---

### Stage 3: VS Build Tools Installation

💡 **Purpose**
Install Visual Studio Build Tools with C++ components and Windows SDK.

**Step 1: Navigate to installers**

| | |
|---|---|
| 🖥️ **Environment** | SANDBOX |
| 🔧 **App** | File Explorer |
| 👤 **Admin** | No |
| **Directory** | C:\Shared\installers |

- Double-click `vs_BuildTools.exe` to launch installer

**Step 2: Install components**

| | |
|---|---|
| 🖥️ **Environment** | SANDBOX |
| 🔧 **App** | VS Installer GUI |
| 👤 **Admin** | No |
| ⏱️ **Time** | ~3.5+ hours |

- Click "Continue"
- Select "Desktop development with C++" workload
- **UNCHECK everything** in right panel except:
  - C++ Build Tools core features
  - C++ 2022 Redistributable Update
  - C++ core desktop features
  - MSVC v143 - VS 2022 C++ x64/x86 build tools (Latest)
  - Windows 11 SDK (10.0.26100.0)
  - C++ CMake tools for Windows
- Click "Install" and wait installation to finish

**IMPORTANT - Installation Time**:
- The Windows 11 SDK component may take **3+ hours** to install
- The installer may appear stuck or frozen during SDK installation - this is normal
- **Be very patient and leave it alone** 
  - Do Not 
    - press "Pause"
    - close window
    - Reboot machine
    - Shutdown machine
    - etc.
- Open Windows Task Manager (Ctrl+Shift+Esc) to verify activity:
  - Check **Processes** tab: "Visual Studio Installer" should be listed under "Apps" and may/may not be active

**Step 3: Verify installation manually**

| | |
|---|---|
| 🖥️ **Environment** | SANDBOX |
| 🔧 **App** | Command Prompt |
| 👤 **Admin** | No |

Run these verification commands after Visual Studio Installer completes:


💡 **Purpose** Check vcvarsall.bat  
**Command Prompt**
```
dir /B "%ProgramFiles(x86)%\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvarsall.bat"
```

**Expected output**:
```text
vcvarsall.bat
```

💡 **Purpose** Check MSVC compiler (cl.exe)  
**Command Prompt**
```
dir /S /B "%ProgramFiles(x86)%\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC\cl.exe"
```

**Expected output**:
```text
C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC\14.44.35207\bin\Hostx64\x64\cl.exe
C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC\14.44.35207\bin\Hostx64\x86\cl.exe
C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC\14.44.35207\bin\Hostx86\x64\cl.exe
C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC\14.44.35207\bin\Hostx86\x86\cl.exe
```

💡 **Purpose** Check x64 compiler (cl.exe) version  
**Command Prompt**
```
"C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC\14.44.35207\bin\Hostx64\x64\cl.exe" 2>&1 | findstr "Compiler Version"
```

**Expected output**:
```text
Microsoft (R) C/C++ Optimizing Compiler Version 19.44.35222 for x64
```

💡 **Purpose** Check Windows SDK  
**Command Prompt**
```
dir /S /B "%ProgramFiles(x86)%\Windows Kits\10\Lib" | findstr "um\\x64$"
```

**Expected output**:
```text
C:\Program Files (x86)\Windows Kits\10\Lib\10.0.26100.0\um\x64
```

💡 **Purpose** Check VS CMake tools version
**Command Prompt**
```
"%ProgramFiles(x86)%\Microsoft Visual Studio\2022\BuildTools\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe"  --version
```

**Expected output**:
```text
cmake version 3.31.6-msvc6

CMake suite maintained and supported by Kitware (kitware.com/cmake).
```

**Expected**: All commands should find the respective files/directories.

**Step 4: Pin BuildTools folder to Quick Access**

| | |
|---|---|
| 🖥️ **Environment** | SANDBOX |
| 🔧 **App** | File Explorer |
| 👤 **Admin** | No |
| **Directory** | %ProgramFiles(x86)%\Microsoft Visual Studio\2022\BuildTools |

- Navigate to `%ProgramFiles(x86)%\Microsoft Visual Studio\2022\BuildTools`
- Right-click the folder → "Pin to Quick access"

**Step 5: Find and pin x64 Native Tools Command Prompt**

| | |
|---|---|
| 🖥️ **Environment** | SANDBOX |
| 🔧 **App** | Start Menu |
| 👤 **Admin** | No |

- Click Start menu (or press Windows key)
- Type `x64 native tools`
- Look for "x64 Native Tools Command Prompt for VS 2022" in search results
- **Pin to taskbar**: Right-click → "Pin to taskbar"
- **Tip**: Hover over the taskbar icon to see "x64 Native Tools Command Prompt for VS 2022"

⚠️ **Important**: Use **x64 Native Tools** (not "Developer Command Prompt") because RocksDB and SWI-Prolog are 64-bit. The regular Developer Command Prompt defaults to x86 which causes architecture mismatch errors during CMake configuration.

---

### Stage 4: Install Standalone CMake

💡 **Purpose**
Install standalone CMake (vcpkg prerequisite) per vcpkg documentation.

📝 **Note**
vcpkg requires both CMake and Git. Git is installed in Stage 5, vcpkg is cloned in Stage 6, and RocksDB is installed in Stage 7.

**Step 1: Install CMake**

| | |
|---|---|
| 🖥️ **Environment** | SANDBOX |
| 🔧 **App** | File Explorer |
| 👤 **Admin** | No |
| **Directory** | C:\Shared\installers |
| ⏱️ **Time** | ~5 min |

- Run `cmake-4.2.1-windows-x86_64.msi`
- Follow the installer prompts
- **Important**: Select "Add CMake to the PATH environment variable" when prompted

**Step 2: Verify CMake installation manually**

| | |
|---|---|
| 🖥️ **Environment** | SANDBOX |
| 🔧 **Terminal** | x64 Native Tools Command Prompt for VS 2022 |
| 👤 **Admin** | No |

- Click the pinned x64 Native Tools Command Prompt for VS 2022 icon in taskbar to open
- Run these commands:

```cmd
where cmake
cmake --version
```

📝 **Note: Understanding `where` command output**
The order in `where` output **IS** the precedence order. Windows searches PATH from left to right, so:
- **First result** = what gets executed when you run the command
- **Subsequent results** = shadowed/ignored unless you call them explicitly with full path

If you see multiple locations, the first one listed is the active executable.


**Expected output**:
```
C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools>where cmake
C:\Program Files\CMake\bin\cmake.exe
C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe

C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools>cmake --version
cmake version 4.2.1

CMake suite maintained and supported by Kitware (kitware.com/cmake).
```

---

### Stage 5: Install Git for Windows

💡 **Purpose**
Install Git for Windows (vcpkg prerequisite).

**Step 1: Install Git for Windows**

| | |
|---|---|
| 🖥️ **Environment** | SANDBOX |
| 🔧 **App** | File Explorer |
| 👤 **Admin** | No |
| **Directory** | C:\Shared\installers |
| ⏱️ **Time** | ~2 min |

- Run `Git-2.52.0-64-bit.exe`
- Accept all defaults and complete installation

**Step 2: Verify Git installation manually**

| | |
|---|---|
| 🖥️ **Environment** | SANDBOX |
| 🔧 **Terminal** | x64 Native Tools Command Prompt for VS 2022 |
| 👤 **Admin** | No |

```cmd
where git
git --version
```

**Expected output**:
```
C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools>where git
C:\Program Files\Git\cmd\git.exe

C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools>git --version
git version 2.52.0.windows.1
```

---

### Stage 6: Clone and Bootstrap vcpkg

💡 **Purpose**
Clone and bootstrap vcpkg package manager for C++ dependencies.

📝 **Note**
This guide uses `C:\vcpkg` as the standard vcpkg installation location. This is the recommended location per [vcpkg documentation](https://learn.microsoft.com/en-us/vcpkg/get_started/get-started).

**Step 1: Clone vcpkg from GitHub**

| | |
|---|---|
| 🖥️ **Environment** | SANDBOX |
| 🔧 **Terminal** | x64 Native Tools Command Prompt for VS 2022 |
| 👤 **Admin** | No |

```cmd
git clone https://github.com/microsoft/vcpkg.git C:\vcpkg
```

**Expected output**:
```
C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools>git clone https://github.com/microsoft/vcpkg.git C:\vcpkg
Cloning into 'C:\vcpkg'...
remote: Enumerating objects: 300607, done.
remote: Counting objects: 100% (343/343), done.
remote: Compressing objects: 100% (188/188), done.
remote: Total 300607 (delta 270), reused 155 (delta 155), pack-reused 300264 (from 3)
Receiving objects: 100% (300607/300607), 94.67 MiB | 32.18 MiB/s, done.
Resolving deltas: 100% (201725/201725), done.
Updating files: 100% (13304/13304), done.
```

**Step 2: Bootstrap vcpkg**

| | |
|---|---|
| 🖥️ **Environment** | SANDBOX |
| 🔧 **Terminal** | x64 Native Tools Command Prompt for VS 2022 |
| 👤 **Admin** | No |
| ⏱️ **Time** | ~2-3 min |

```cmd
cd C:\vcpkg
.\bootstrap-vcpkg.bat
```

**Expected output**:
```
C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools>cd C:\vcpkg

C:\vcpkg>.\bootstrap-vcpkg.bat
Downloading https://github.com/microsoft/vcpkg-tool/releases/download/2025-12-16/vcpkg.exe -> C:\vcpkg\vcpkg.exe... done.
Validating signature... done.

vcpkg package management program version 2025-12-16-44bb3ce006467fc13ba37ca099f64077b8bbf84d

See LICENSE.txt for license information.
Telemetry
---------
vcpkg collects usage data in order to help us improve your experience.
The data collected by Microsoft is anonymous.
You can opt-out of telemetry by re-running the bootstrap-vcpkg script with -disableMetrics,
passing --disable-metrics to vcpkg on the command line,
or by setting the VCPKG_DISABLE_METRICS environment variable.

Read more about vcpkg telemetry at docs/about/privacy.md
```

**Step 3: Verify vcpkg manually**

| | |
|---|---|
| 🖥️ **Environment** | SANDBOX |
| 🔧 **Terminal** | x64 Native Tools Command Prompt for VS 2022 |
| 👤 **Admin** | No |

```cmd
where vcpkg
vcpkg --version
dir /B C:\vcpkg\scripts\buildsystems\vcpkg.cmake
```

**Expected output**:
```
C:\vcpkg>where vcpkg
C:\vcpkg\vcpkg.exe

C:\vcpkg>vcpkg --version
vcpkg package management program version 2025-12-16-44bb3ce006467fc13ba37ca099f64077b8bbf84d

See LICENSE.txt for license information.

C:\vcpkg>dir /B C:\vcpkg\scripts\buildsystems\vcpkg.cmake
vcpkg.cmake
```

**Expected**: Commands should show vcpkg version and confirm files exist.

---

### Stage 7: Install RocksDB via vcpkg

💡 **Purpose**
Install RocksDB library with compression support via vcpkg.

**Step 1: Set VCPKG_ROOT environment variable**

| | |
|---|---|
| 🖥️ **Environment** | SANDBOX |
| 🔧 **Terminal** | x64 Native Tools Command Prompt for VS 2022 |
| 👤 **Admin** | No |

```cmd
set VCPKG_ROOT=C:\vcpkg
echo %VCPKG_ROOT%
```

**Expected output**:
```
C:\vcpkg>set VCPKG_ROOT=C:\vcpkg

C:\vcpkg>echo %VCPKG_ROOT%
C:\vcpkg
```

**Step 2: Install RocksDB with compression libraries**

| | |
|---|---|
| 🖥️ **Environment** | SANDBOX |
| 🔧 **Terminal** | x64 Native Tools Command Prompt for VS 2022 |
| 👤 **Admin** | No |
| ⏱️ **Time** | ~20-25 min (RocksDB compilation) |

```cmd
vcpkg install rocksdb[lz4,snappy,zlib,zstd]:x64-windows
```

📝 **Note**
This takes ~20-25 minutes for RocksDB compilation. Select window and press space bar to get output to update.

**Expected output**:
```
C:\vcpkg>vcpkg install rocksdb[lz4,snappy,zlib,zstd]:x64-windows
Computing installation plan...
The following packages will be built and installed:
  * lz4:x64-windows@1.10.0
    rocksdb[core,lz4,snappy,zlib,zstd]:x64-windows@10.4.2
  * snappy:x64-windows@1.2.2#1
  * vcpkg-cmake:x64-windows@2024-04-23
  * vcpkg-cmake-config:x64-windows@2024-05-23
  * zlib:x64-windows@1.3.1
  * zstd:x64-windows@1.5.7
Additional packages (*) will be modified to complete this operation.
Detecting compiler hash for triplet x64-windows...
A suitable version of powershell-core was not found (required v7.5.4).
Downloading https://github.com/PowerShell/PowerShell/releases/download/v7.5.4/PowerShell-7.5.4-win-x64.zip -> PowerShell-7.5.4-win-x64.zip
Successfully downloaded PowerShell-7.5.4-win-x64.zip
Extracting powershell-core...
A suitable version of 7zip was not found (required v25.1.0).
Downloading https://github.com/ip7z/7zip/releases/download/25.01/7z2501.exe -> 7z2501.7z.exe
Successfully downloaded 7z2501.7z.exe
Extracting 7zip...
A suitable version of 7zr was not found (required v25.1.0).
Downloading https://github.com/ip7z/7zip/releases/download/25.01/7zr.exe -> 7d84fcad-7zr.exe
Successfully downloaded 7d84fcad-7zr.exe
Compiler found: C:/Program Files (x86)/Microsoft Visual Studio/2022/BuildTools/VC/Tools/MSVC/14.44.35207/bin/Hostx64/x64/cl.exe
Restored 0 package(s) from C:\Users\WDAGUtilityAccount\AppData\Local\vcpkg\archives in 205 us. Use --debug to see more details.
Installing 1/7 vcpkg-cmake:x64-windows@2024-04-23...
Building vcpkg-cmake:x64-windows@2024-04-23...
-- Installing: C:/vcpkg/packages/vcpkg-cmake_x64-windows/share/vcpkg-cmake/vcpkg_cmake_configure.cmake
-- Installing: C:/vcpkg/packages/vcpkg-cmake_x64-windows/share/vcpkg-cmake/vcpkg_cmake_build.cmake
-- Installing: C:/vcpkg/packages/vcpkg-cmake_x64-windows/share/vcpkg-cmake/vcpkg_cmake_install.cmake
-- Installing: C:/vcpkg/packages/vcpkg-cmake_x64-windows/share/vcpkg-cmake/vcpkg-port-config.cmake
-- Installing: C:/vcpkg/packages/vcpkg-cmake_x64-windows/share/vcpkg-cmake/copyright
-- Performing post-build validation
Starting submission of vcpkg-cmake:x64-windows@2024-04-23 to 1 binary cache(s) in the background
Elapsed time to handle vcpkg-cmake:x64-windows: 114 ms
vcpkg-cmake:x64-windows package ABI: 9e686886ddd2bba2667a758f0df5ba2a4e02e7dbfb831c4f261801b93985d3ce
Installing 2/7 vcpkg-cmake-config:x64-windows@2024-05-23...
Building vcpkg-cmake-config:x64-windows@2024-05-23...
-- Installing: C:/vcpkg/packages/vcpkg-cmake-config_x64-windows/share/vcpkg-cmake-config/vcpkg_cmake_config_fixup.cmake
-- Installing: C:/vcpkg/packages/vcpkg-cmake-config_x64-windows/share/vcpkg-cmake-config/vcpkg-port-config.cmake
-- Installing: C:/vcpkg/packages/vcpkg-cmake-config_x64-windows/share/vcpkg-cmake-config/copyright
-- Skipping post-build validation due to VCPKG_POLICY_EMPTY_PACKAGE
Starting submission of vcpkg-cmake-config:x64-windows@2024-05-23 to 1 binary cache(s) in the background
Elapsed time to handle vcpkg-cmake-config:x64-windows: 106 ms
vcpkg-cmake-config:x64-windows package ABI: 43067825c5419f5465b832f158f920cd31f9b73848b571323b25cb5eea694d8b
Completed submission of vcpkg-cmake:x64-windows@2024-04-23 to 1 binary cache(s) in 71.8 ms
Installing 3/7 lz4:x64-windows@1.10.0...
Building lz4:x64-windows@1.10.0...
Downloading https://github.com/lz4/lz4/archive/v1.10.0.tar.gz -> lz4-lz4-v1.10.0.tar.gz
Successfully downloaded lz4-lz4-v1.10.0.tar.gz
-- Extracting source C:/vcpkg/downloads/lz4-lz4-v1.10.0.tar.gz
-- Applying patch target-lz4-lz4.diff
-- Using source at C:/vcpkg/buildtrees/lz4/src/v1.10.0-61bd08d80e.clean
-- Configuring x64-windows
-- Building x64-windows-dbg
-- Building x64-windows-rel
-- Fixing pkgconfig file: C:/vcpkg/packages/lz4_x64-windows/lib/pkgconfig/liblz4.pc
Downloading msys2-mingw-w64-x86_64-pkgconf-1~2.5.1-1-any.pkg.tar.zst, trying https://mirror.msys2.org/mingw/mingw64/mingw-w64-x86_64-pkgconf-1~2.5.1-1-any.pkg.tar.zst
Successfully downloaded msys2-mingw-w64-x86_64-pkgconf-1~2.5.1-1-any.pkg.tar.zst
Downloading msys2-msys2-runtime-3.6.5-1-x86_64.pkg.tar.zst, trying https://mirror.msys2.org/msys/x86_64/msys2-runtime-3.6.5-1-x86_64.pkg.tar.zst
Successfully downloaded msys2-msys2-runtime-3.6.5-1-x86_64.pkg.tar.zst
-- Using msys root at C:/vcpkg/downloads/tools/msys2/3e71d1f8e22ab23f
-- Fixing pkgconfig file: C:/vcpkg/packages/lz4_x64-windows/debug/lib/pkgconfig/liblz4.pc
-- Installing: C:/vcpkg/packages/lz4_x64-windows/share/lz4/usage
-- Installing: C:/vcpkg/packages/lz4_x64-windows/share/lz4/copyright
-- Performing post-build validation
Starting submission of lz4:x64-windows@1.10.0 to 1 binary cache(s) in the background
Elapsed time to handle lz4:x64-windows: 9.5 s
lz4:x64-windows package ABI: 70ba67e78ac490822a29e3486bad43480c86dc70021928b75fa5561072d0b825
Completed submission of vcpkg-cmake-config:x64-windows@2024-05-23 to 1 binary cache(s) in 77.2 ms
Installing 4/7 snappy:x64-windows@1.2.2#1...
Building snappy:x64-windows@1.2.2#1...
Downloading https://github.com/google/snappy/archive/1.2.2.tar.gz -> google-snappy-1.2.2.tar.gz
Successfully downloaded google-snappy-1.2.2.tar.gz
-- Extracting source C:/vcpkg/downloads/google-snappy-1.2.2.tar.gz
-- Applying patch no-werror.patch
-- Applying patch pkgconfig.diff
-- Applying patch rtti.diff
-- Using source at C:/vcpkg/buildtrees/snappy/src/1.2.2-62cd140f38.clean
-- Configuring x64-windows
-- Building x64-windows-dbg
-- Building x64-windows-rel
-- Fixing pkgconfig file: C:/vcpkg/packages/snappy_x64-windows/lib/pkgconfig/snappy.pc
-- Using cached msys2-mingw-w64-x86_64-pkgconf-1~2.5.1-1-any.pkg.tar.zst
-- Using cached msys2-msys2-runtime-3.6.5-1-x86_64.pkg.tar.zst
-- Using msys root at C:/vcpkg/downloads/tools/msys2/3e71d1f8e22ab23f
-- Fixing pkgconfig file: C:/vcpkg/packages/snappy_x64-windows/debug/lib/pkgconfig/snappy.pc
-- Installing: C:/vcpkg/packages/snappy_x64-windows/share/snappy/copyright
-- Performing post-build validation
Starting submission of snappy:x64-windows@1.2.2#1 to 1 binary cache(s) in the background
Elapsed time to handle snappy:x64-windows: 11 s
snappy:x64-windows package ABI: fb47ca1eb5922d180d42cb7497ced72e379946e277a7d1af2eb886932e7c628f
Completed submission of lz4:x64-windows@1.10.0 to 1 binary cache(s) in 158 ms
Installing 5/7 zlib:x64-windows@1.3.1...
Building zlib:x64-windows@1.3.1...
Downloading https://github.com/madler/zlib/archive/v1.3.1.tar.gz -> madler-zlib-v1.3.1.tar.gz
Successfully downloaded madler-zlib-v1.3.1.tar.gz
-- Extracting source C:/vcpkg/downloads/madler-zlib-v1.3.1.tar.gz
-- Applying patch 0001-Prevent-invalid-inclusions-when-HAVE_-is-set-to-0.patch
-- Applying patch 0002-build-static-or-shared-not-both.patch
-- Applying patch 0003-android-and-mingw-fixes.patch
-- Using source at C:/vcpkg/buildtrees/zlib/src/v1.3.1-2e5db616bf.clean
-- Configuring x64-windows
-- Building x64-windows-dbg
-- Building x64-windows-rel
-- Installing: C:/vcpkg/packages/zlib_x64-windows/share/zlib/vcpkg-cmake-wrapper.cmake
-- Fixing pkgconfig file: C:/vcpkg/packages/zlib_x64-windows/lib/pkgconfig/zlib.pc
-- Using cached msys2-mingw-w64-x86_64-pkgconf-1~2.5.1-1-any.pkg.tar.zst
-- Using cached msys2-msys2-runtime-3.6.5-1-x86_64.pkg.tar.zst
-- Using msys root at C:/vcpkg/downloads/tools/msys2/3e71d1f8e22ab23f
-- Fixing pkgconfig file: C:/vcpkg/packages/zlib_x64-windows/debug/lib/pkgconfig/zlib.pc
-- Installing: C:/vcpkg/packages/zlib_x64-windows/share/zlib/copyright
-- Performing post-build validation
Starting submission of zlib:x64-windows@1.3.1 to 1 binary cache(s) in the background
Elapsed time to handle zlib:x64-windows: 6 s
zlib:x64-windows package ABI: c33d592dd282e1dbe0a07b82a985df96648eb585331faade4469bd52f27f3825
Completed submission of snappy:x64-windows@1.2.2#1 to 1 binary cache(s) in 219 ms
Installing 6/7 zstd:x64-windows@1.5.7...
Building zstd:x64-windows@1.5.7...
Downloading https://github.com/facebook/zstd/archive/v1.5.7.tar.gz -> facebook-zstd-v1.5.7.tar.gz
Successfully downloaded facebook-zstd-v1.5.7.tar.gz
-- Extracting source C:/vcpkg/downloads/facebook-zstd-v1.5.7.tar.gz
-- Applying patch no-static-suffix.patch
-- Applying patch fix-emscripten-and-clang-cl.patch
-- Applying patch fix-windows-rc-compile.patch
-- Using source at C:/vcpkg/buildtrees/zstd/src/v1.5.7-bb6cae2b2e.clean
-- Configuring x64-windows
-- Building x64-windows-dbg
-- Building x64-windows-rel
-- Fixing pkgconfig file: C:/vcpkg/packages/zstd_x64-windows/lib/pkgconfig/libzstd.pc
-- Using cached msys2-mingw-w64-x86_64-pkgconf-1~2.5.1-1-any.pkg.tar.zst
-- Using cached msys2-msys2-runtime-3.6.5-1-x86_64.pkg.tar.zst
-- Using msys root at C:/vcpkg/downloads/tools/msys2/3e71d1f8e22ab23f
-- Fixing pkgconfig file: C:/vcpkg/packages/zstd_x64-windows/debug/lib/pkgconfig/libzstd.pc
-- Installing: C:/vcpkg/packages/zstd_x64-windows/share/zstd/usage
-- Performing post-build validation
Starting submission of zstd:x64-windows@1.5.7 to 1 binary cache(s) in the background
Elapsed time to handle zstd:x64-windows: 36 s
zstd:x64-windows package ABI: 0ddde10ef24760e9304aeef59282c1ddd1fd8a751f870ce64a89a1384cbab8e1
Completed submission of zlib:x64-windows@1.3.1 to 1 binary cache(s) in 160 ms
Installing 7/7 rocksdb[core,lz4,snappy,zlib,zstd]:x64-windows@10.4.2...
Building rocksdb[core,lz4,snappy,zlib,zstd]:x64-windows@10.4.2...
Downloading https://github.com/facebook/rocksdb/archive/v10.4.2.tar.gz -> facebook-rocksdb-v10.4.2.tar.gz
Successfully downloaded facebook-rocksdb-v10.4.2.tar.gz
-- Extracting source C:/vcpkg/downloads/facebook-rocksdb-v10.4.2.tar.gz
-- Applying patch 0001-fix-dependencies.patch
-- Applying patch 0002-fix-android.patch
-- Applying patch 0003-include_cstdint.patch
-- Using source at C:/vcpkg/buildtrees/rocksdb/src/v10.4.2-bc61bfee41.clean
-- Configuring x64-windows
-- Building x64-windows-dbg
-- Building x64-windows-rel
-- Fixing pkgconfig file: C:/vcpkg/packages/rocksdb_x64-windows/lib/pkgconfig/rocksdb.pc
-- Using cached msys2-mingw-w64-x86_64-pkgconf-1~2.5.1-1-any.pkg.tar.zst
-- Using cached msys2-msys2-runtime-3.6.5-1-x86_64.pkg.tar.zst
-- Using msys root at C:/vcpkg/downloads/tools/msys2/3e71d1f8e22ab23f
-- Fixing pkgconfig file: C:/vcpkg/packages/rocksdb_x64-windows/debug/lib/pkgconfig/rocksdb.pc
-- Performing post-build validation
Starting submission of rocksdb[core,lz4,snappy,zlib,zstd]:x64-windows@10.4.2 to 1 binary cache(s) in the background
Elapsed time to handle rocksdb:x64-windows: 35 min
rocksdb:x64-windows package ABI: d0ed02416c64d3dd1033a8656774a1f15a4e3826f0fa830bb73e7b8d5b74fdb8
Total install time: 36 min
Installed contents are licensed to you by owners. Microsoft is not responsible for, nor does it grant any licenses to, third-party packages.
Some packages did not declare an SPDX license. Check the `copyright` file for each package for more information about their licensing.
Packages installed in this vcpkg installation declare the following licenses:
(BSD-3-Clause OR GPL-2.0-only)
(GPL-2.0-only OR Apache-2.0)
BSD-2-Clause
MIT
Zlib
rocksdb provides CMake targets:

  # this is heuristically generated, and may not be correct
  find_package(RocksDB CONFIG REQUIRED)
  target_link_libraries(main PRIVATE RocksDB::rocksdb RocksDB::rocksdb-shared)

rocksdb provides pkg-config modules:

  # An embeddable persistent key-value store for fast storage
  rocksdb

Completed submission of zstd:x64-windows@1.5.7 to 1 binary cache(s) in 518 ms
Waiting for 1 remaining binary cache submissions...
Completed submission of rocksdb[core,lz4,snappy,zlib,zstd]:x64-windows@10.4.2 to 1 binary cache(s) in 3.7 min (1/1)
All requested installations completed successfully in: 36 min
```

**Step 3: Verify RocksDB installation manually**

| | |
|---|---|
| 🖥️ **Environment** | SANDBOX |
| 🔧 **Terminal** | x64 Native Tools Command Prompt for VS 2022 |
| 👤 **Admin** | No |

```cmd
vcpkg list
dir /B C:\vcpkg\installed\x64-windows\lib\rocksdb.lib
dir /B C:\vcpkg\installed\x64-windows\bin\rocksdb-shared.dll
```

**Expected output**:
```
C:\vcpkg>vcpkg list
lz4:x64-windows                                   1.10.0              Lossless compression algorithm, providing compre...
rocksdb:x64-windows                               10.4.2              A library that provides an embeddable, persisten...
rocksdb[lz4]:x64-windows                                              build with lz4
rocksdb[snappy]:x64-windows                                           build with SNAPPY
rocksdb[zlib]:x64-windows                                             build with zlib
rocksdb[zstd]:x64-windows                                             build with zstd
snappy:x64-windows                                1.2.2#1             A fast compressor/decompressor.
vcpkg-cmake-config:x64-windows                    2024-05-23
vcpkg-cmake:x64-windows                           2024-04-23
zlib:x64-windows                                  1.3.1               A compression library
zstd:x64-windows                                  1.5.7               Zstandard - Fast real-time compression algorithm

C:\vcpkg>dir /B C:\vcpkg\installed\x64-windows\lib\rocksdb.lib
rocksdb.lib

C:\vcpkg>dir /B C:\vcpkg\installed\x64-windows\bin\rocksdb-shared.dll
rocksdb-shared.dll
```


**Expected**: Commands should show rocksdb in the package list and confirm library files exist.

---

### Stage 8: SWI-Prolog Installation

💡 **Purpose**
Install SWI-Prolog runtime environment.

**Step 1: Install SWI-Prolog**

| | |
|---|---|
| 🖥️ **Environment** | SANDBOX |
| 🔧 **App** | File Explorer |
| 👤 **Admin** | No |
| **Directory** | C:\Shared\installers |
| ⏱️ **Time** | ~2-3 min |

- Run `swipl-10.0.0-1.x64.exe`
- Follow the installer prompts and complete installation

**Step 2: Verify SWI-Prolog installation manually**

| | |
|---|---|
| 🖥️ **Environment** | SANDBOX |
| 🔧 **Terminal** | x64 Native Tools Command Prompt for VS 2022 |
| 👤 **Admin** | No |

```cmd
set PATH=%ProgramFiles%\swipl\bin;%PATH%
where swipl
swipl --version
dir /B "%ProgramFiles%\swipl\library\build\cmake.pl"
```

**Expected output**:
```
C:\vcpkg>set PATH=%ProgramFiles%\swipl\bin;%PATH%

C:\vcpkg>where swipl
C:\Program Files\swipl\bin\swipl.exe

C:\vcpkg>swipl --version
SWI-Prolog version 10.0.0 for x64-win64

C:\vcpkg>dir /B "%ProgramFiles%\swipl\library\build\cmake.pl"
cmake.pl
```

---

### Stage 9: Apply Patches and Test pack_install

💡 **Purpose**
Apply SWI-Prolog patches for vcpkg integration and test pack_install with the rocksdb pack.

**Step 1: Create patch files**

| | |
|---|---|
| 🖥️ **Environment** | HOST (Windows 11, non-sandbox) |
| 🔧 **App** | Text editor (Notepad, VS Code, etc.) |
| 👤 **Admin** | No |
| **Directory** | `%USERPROFILE%\sandbox\shared\swipl-patches` |

- Create folder: `%USERPROFILE%\sandbox\shared\swipl-patches`
- Create the three files below by copying the contents from the collapsible sections

<details>
<summary>tools.pl.patched - Click to reveal section</summary>

```
/*  Part of SWI-Prolog

    Author:        Jan Wielemaker
    E-mail:        jan@swi-prolog.org
    WWW:           https://www.swi-prolog.org
    Copyright (c)  2021-2024, SWI-Prolog Solutions b.v.
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions
    are met:

    1. Redistributions of source code must retain the above copyright
       notice, this list of conditions and the following disclaimer.

    2. Redistributions in binary form must reproduce the above copyright
       notice, this list of conditions and the following disclaimer in
       the documentation and/or other materials provided with the
       distribution.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
    COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
    POSSIBILITY OF SUCH DAMAGE.
*/

:- module(build_tools,
	  [ build_steps/3,              % +Steps, +SrcDir, +Options
	    prolog_install_prefix/1,    % -Prefix
	    run_process/3,              % +Executable, +Argv, +Options
	    has_program/3,              % +Spec, -Path, +Env
	    ensure_build_dir/3          % +Dir, +State0, -State
	  ]).
:- autoload(library(lists), [selectchk/3, member/2, append/3, last/2]).
:- autoload(library(option), [option/2, option/3, dict_options/2]).
:- autoload(library(pairs), [pairs_values/2]).
:- autoload(library(process), [process_create/3, process_wait/2]).
:- autoload(library(readutil), [read_stream_to_codes/3]).
:- autoload(library(dcg/basics), [string/3]).
:- autoload(library(apply), [foldl/4, maplist/2]).
:- autoload(library(filesex), [directory_file_path/3, make_directory_path/1]).
:- autoload(library(prolog_config), [prolog_config/2]).
:- autoload(library(solution_sequences), [distinct/2]).

% The plugins.  Load them in the order of preference.
:- use_module(conan).
:- use_module(cmake).
:- use_module(make).

:- multifile
    prolog:build_file/2,                % ?File, ?Toolchain
    prolog:build_step/4,                % ?Step, ?Tool, ?SrcDir, ?BuildDir
    prolog:build_environment/2,         % ?Name, ?Value
    prolog_pack:environment/2.          % ?Name, ?Value (backward compatibility)

/** <module> Utilities for building foreign resources

This module implements the build system   that is used by pack_install/1
and pack_rebuild/1. The build system is a plugin based system where each
plugin knows about a specific  build   toolchain.  The plugins recognise
whether they are applicable based on  the   existence  of files that are
unique to the toolchain.   Currently it supports

  - [conan](https://conan.io/) for the installation of dependencies
  - [cmake](https://cmake.org/) for configuration and building
  - [GNU tools](https://www.gnu.org) including `automake` and `autoconf`
    for configuration and building
*/

%!  build_steps(+Steps:list, SrcDir:atom, +Options) is det.
%
%   Run the desired build steps.  Normally,   Steps  is  the list below,
%   optionally prefixed with `distclean` or `clean`. `[test]` may be
%   omited if ``--no-test`` is effective.
%
%       [[dependencies], [configure], build, [test], install]
%
%   Each step finds an applicable toolchain  based on known unique files
%   and calls the matching plugin to perform  the step. A step may fail,
%   which causes the system to try an  alternative. A step that wants to
%   abort the build process must  throw  an   exception.
%
%   If a step fails, a warning message is printed. The message can be
%   suppressed by enclosing the step in square brackets.  Thus, in the
%   above example of Steps, only failure  by the `build` and `install`
%   steps result in warning messages; failure of the other steps is
%   silent.
%
%   The failure of a step can be made into an error by enclosing it
%   in curly brackets, e.g. `[[dependencies], [configure], {build}, [test], {install}]`
%   would throw an exception if either the `build` or `install` step failed.
%
%   Options are:
%   * pack_version(N)
%     where N is 1 or 2 (default: 1).
%     This determines the form of environment names that are set before
%     the  build tools are calledd.
%     For version 1, names such as `SWIPLVERSION` or `SWIHOME` are used.
%     For version 2, names such as `SWIPL_VERSION` or `SWIPL_HOME_DIR` are used.
%
%   @tbd If no tool  is  willing  to   execute  some  step,  the step is
%   skipped. This is ok for some steps such as `dependencies` or `test`.
%   Possibly we should force the `install` step to succeed?

build_steps(Steps, SrcDir, Options) :-
    dict_options(Dict0, Options),
    setup_path,
    build_environment(BuildEnv, Options),
    State0 = Dict0.put(#{ env: BuildEnv,
			  src_dir: SrcDir
			}),

    foldl(build_step, Steps, State0, _State).

build_step(Spec, State0, State) :-
    build_step_(Spec, State0, State),
    post_step(Spec, State).

build_step_(Spec, State0, State) :-
    step_name(Spec, Step),
    prolog:build_file(File, Tool),
    directory_file_path(State0.src_dir, File, Path),
    exists_file(Path),
    prolog:build_step(Step, Tool, State0, State),
    !.
build_step_([_], State, State) :-
    !.
build_step_({Step}, State, State) :-
    !,
    print_message(error, build(step_failed(Step))),
    throw(error(build(step_failed(Step)))).
build_step_(Step, State, State) :-
    print_message(warning, build(step_failed(Step))).

step_name([Step], Name) => Name = Step.
step_name({Step}, Name) => Name = Step.
step_name(Step,   Name) => Name = Step.

%!  post_step(+Step, +State) is det.
%
%   Run code after completion of a step.

post_step(Step, State) :-
    step_name(Step, configure),
    !,
    save_build_environment(State).
post_step(_, _).


%!  ensure_build_dir(+Dir, +State0, -State) is det.
%
%   Create the build directory. Dir is normally   either '.' to build in
%   the source directory or `build` to create a `build` subdir.

ensure_build_dir(_, State0, State) :-
    _ = State0.get(bin_dir),
    !,
    State = State0.
ensure_build_dir(., State0, State) :-
    !,
    State = State0.put(bin_dir, State0.src_dir).
ensure_build_dir(Dir, State0, State) :-
    directory_file_path(State0.src_dir, Dir, BinDir),
    make_directory_path(BinDir),
    !,
    State = State0.put(bin_dir, BinDir).


		 /*******************************
		 *          ENVIRONMENT		*
		 *******************************/

%!  build_environment(-Env, +Options) is det.
%
%   Options are documented under build_steps/3.
%
%   Assemble a clean  build  environment   for  creating  extensions  to
%   SWI-Prolog. Env is a list of   `Var=Value` pairs. The variable names
%   depend on the `pack_version(Version)`  term   from  `pack.pl`.  When
%   absent or `1`, the old names are used. These names are confusing and
%   conflict with some build environments. Using `2` (or later), the new
%   names are used. The list below  first   names  the new name and than
%   between parenthesis, the old name.  Provided variables are:
%
%     $ ``PATH`` :
%     contains the environment path with the directory
%     holding the currently running SWI-Prolog instance prepended
%     in front of it.  As a result, `swipl` is always present and
%     runs the same SWI-Prolog instance as the current Prolog process.
%     $ ``SWIPL`` :
%     contains the absolute file name of the running executable.
%     $ ``SWIPL_PACK_VERSION`` :
%     Version of the pack system (1 or 2)
%     $ ``SWIPL_VERSION`` (``SWIPLVERSION``) :
%     contains the numeric SWI-Prolog version defined as
%     _|Major*10000+Minor*100+Patch|_.
%     $ ``SWIPL_HOME_DIR`` (``SWIHOME``) :
%     contains the directory holding the SWI-Prolog home.
%     $ ``SWIPL_ARCH`` (``SWIARCH``) :
%     contains the machine architecture identifier.
%     $ ``SWIPL_MODULE_DIR`` (``PACKSODIR``) :
%     constains the destination directory for shared objects/DLLs
%     relative to a Prolog pack, i.e., ``lib/$SWIARCH``.
%     $ ``SWIPL_MODULE_LIB`` (``SWISOLIB``) :
%     The SWI-Prolog library or an empty string when it is not required
%     to link modules against this library (e.g., ELF systems)
%     $ ``SWIPL_LIB`` (``SWILIB``) :
%     The SWI-Prolog library we need to link to for programs that
%     _embed_ SWI-Prolog (normally ``-lswipl``).
%     $ ``SWIPL_INCLUDE_DIRS`` :
%     CMake style variable that contains the directory holding
%     ``SWI-Prolog.h``, ``SWI-Stream.h`` and ``SWI-cpp.h``.
%     $ ``SWIPL_LIBRARIES_DIR`` :
%     CMake style variable that contains the directory holding `libswipl`
%     $ ``SWIPL_CC`` (``CC``) :
%     Prefered C compiler
%     $ ``SWIPL_CXX`` (``CXX``) :
%     Prefered C++ compiler
%     $ ``SWIPL_LD`` (``LD``) :
%     Prefered linker
%     $ ``SWIPL_CFLAGS`` (``CFLAGS``) :
%     C-Flags for building extensions. Always contains ``-ISWIPL-INCLUDE-DIR``.
%     $ ``SWIPL_MODULE_LDFLAGS`` (``LDSOFLAGS``) :
%     Link flags for linking modules.
%     $ ``SWIPL_MODULE_EXT`` (``SOEXT``) :
%     File name extension for modules (e.g., `so` or `dll`)
%     $ ``SWIPL_PREFIX`` (``PREFIX``) :
%     Install prefix for global binaries, libraries and include files.
%     $ ``VCPKG_ROOT`` :
%     If set in the user's environment, passed through to enable vcpkg
%     integration in CMake-based pack builds.

build_environment(Env, Options) :-
    findall(Name=Value,
	    distinct(Name, user_environment(Name, Value)),
	    UserEnv),
    findall(Name=Value,
	    ( def_environment(Name, Value, Options),
	      \+ memberchk(Name=_, UserEnv)
	    ),
	    DefEnv),
    append(UserEnv, DefEnv, Env).

user_environment(Name, Value) :-
    prolog:build_environment(Name, Value).
user_environment(Name, Value) :-
    prolog_pack:environment(Name, Value).

%!  prolog:build_environment(-Name, -Value) is nondet.
%
%   Hook  to  define  the  environment   for  building  packs.  This
%   Multifile hook extends the  process   environment  for  building
%   foreign extensions. A value  provided   by  this  hook overrules
%   defaults provided by def_environment/3. In  addition to changing
%   the environment, this may be used   to pass additional values to
%   the environment, as in:
%
%     ==
%     prolog:build_environment('USER', User) :-
%         getenv('USER', User).
%     ==
%
%   @arg Name is an atom denoting a valid variable name
%   @arg Value is either an atom or number representing the
%          value of the variable.


%!  def_environment(-Name, -Value, +Options) is nondet.
%
%   True if Name=Value must appear in   the environment for building
%   foreign extensions.

def_environment('PATH', Value, _) :-
    getenv('PATH', PATH),
    current_prolog_flag(executable, Exe),
    file_directory_name(Exe, ExeDir),
    prolog_to_os_filename(ExeDir, OsExeDir),
    current_prolog_flag(path_sep, Sep),
    atomic_list_concat([OsExeDir, Sep, PATH], Value).
def_environment('SWIPL', Value, _) :-
    current_prolog_flag(executable, Value).
def_environment('SWIPL_PACK_VERSION', Value, Options) :-
    option(pack_version(Value), Options, 1).
def_environment('SWIPL_PACK_PATH', Value, _Options) :-
    prolog_config(pack_path, Value).
%   vcpkg integration: Pass through VCPKG_ROOT if set, enabling
%   cmake.pl to inject the vcpkg toolchain file.
def_environment('VCPKG_ROOT', Value, _Options) :-
    getenv('VCPKG_ROOT', Value).
def_environment(VAR, Value, Options) :-
    env_name(version, VAR, Options),
    current_prolog_flag(version, Value).
def_environment(VAR, Value, Options) :-
    env_name(home, VAR, Options),
    current_prolog_flag(home, Value).
def_environment(VAR, Value, Options) :-
    env_name(arch, VAR, Options),
    current_prolog_flag(arch, Value).
def_environment(VAR, Value, Options) :-
    env_name(module_dir, VAR, Options),
    current_prolog_flag(arch, Arch),
    atom_concat('lib/', Arch, Value).
def_environment(VAR, Value, Options) :-
    env_name(module_lib, VAR, Options),
    current_prolog_flag(c_libplso, Value).
def_environment(VAR, '-lswipl', Options) :-
    env_name(lib, VAR, Options).
def_environment(VAR, Value, Options) :-
    env_name(cc, VAR, Options),
    default_c_compiler(Value).
def_environment(VAR, Value, Options) :-
    env_name(cxx, VAR, Options),
    default_cxx_compiler(Value).
def_environment(VAR, Value, Options) :-
    env_name(ld, VAR, Options),
    (   getenv('LD', Value)
    ->  true
    ;   default_c_compiler(Value)
    ).
def_environment('SWIPL_INCLUDE_DIRS', Value, _) :- % CMake style environment
    current_prolog_flag(home, Home),
    atom_concat(Home, '/include', Value).
def_environment('SWIPL_LIBRARIES_DIR', Value, _) :-
    swipl_libraries_dir(Value).
def_environment(VAR, Value, Options) :-
    env_name(cflags, VAR, Options),
    (   getenv('CFLAGS', SystemFlags)
    ->  Extra = [' ', SystemFlags]
    ;   Extra = []
    ),
    current_prolog_flag(c_cflags, Value0),
    current_prolog_flag(home, Home),
    atomic_list_concat([Value0, ' -I"', Home, '/include"' | Extra], Value).
def_environment(VAR, Value, Options) :-
    env_name(module_ldflags, VAR, Options),
    (   getenv('LDFLAGS', SystemFlags)
    ->  Extra = [SystemFlags|System]
    ;   Extra = System
    ),
    (   current_prolog_flag(windows, true)
    ->  prolog_library_dir(LibDir),
	atomic_list_concat(['-L"', LibDir, '"'], SystemLib),
	System = [SystemLib]
    ;   prolog_config(apple_bundle_libdir, LibDir)
    ->  atomic_list_concat(['-L"', LibDir, '"'], SystemLib),
	System = [SystemLib]
    ;   current_prolog_flag(c_libplso, '')
    ->  System = []                 % ELF systems do not need this
    ;   prolog_library_dir(SystemLibDir),
	atomic_list_concat(['-L"',SystemLibDir,'"'], SystemLib),
	System = [SystemLib]
    ),
    current_prolog_flag(c_ldflags, LDFlags),
    atomic_list_concat([LDFlags, '-shared' | Extra], ' ', Value).
def_environment(VAR, Value, Options) :-
    env_name(module_ext, VAR, Options),
    current_prolog_flag(shared_object_extension, Value).
def_environment(VAR, Value, Options) :-
    env_name(prefix, VAR, Options),
    prolog_install_prefix(Value).

swipl_libraries_dir(Dir) :-
    current_prolog_flag(windows, true),
    !,
    current_prolog_flag(home, Home),
    atom_concat(Home, '/bin', Dir).
swipl_libraries_dir(Dir) :-
    prolog_config(apple_bundle_libdir, Dir),
    !.
swipl_libraries_dir(Dir) :-
    prolog_library_dir(Dir).

env_name(Id, Name, Options) :-
    option(pack_version(V), Options, 1),
    must_be(oneof([1,2]), V),
    env_name_v(Id, V, Name).

env_name_v(version,        1, 'SWIPLVERSION').
env_name_v(version,        2, 'SWIPL_VERSION').
env_name_v(home,           1, 'SWIHOME').
env_name_v(home,           2, 'SWIPL_HOME_DIR').
env_name_v(module_dir,     1, 'PACKSODIR').
env_name_v(module_dir,     2, 'SWIPL_MODULE_DIR').
env_name_v(module_lib,     1, 'SWISOLIB').
env_name_v(module_lib,     2, 'SWIPL_MODULE_LIB').
env_name_v(lib,            1, 'SWILIB').
env_name_v(lib,            2, 'SWIPL_LIB').
env_name_v(arch,           1, 'SWIARCH').
env_name_v(arch,           2, 'SWIPL_ARCH').
env_name_v(cc,             1, 'CC').
env_name_v(cc,             2, 'SWIPL_CC').
env_name_v(cxx,            1, 'CXX').
env_name_v(cxx,            2, 'SWIPL_CXX').
env_name_v(ld,             1, 'LD').
env_name_v(ld,             2, 'SWIPL_LD').
env_name_v(cflags,         1, 'CFLAGS').
env_name_v(cflags,         2, 'SWIPL_CFLAGS').
env_name_v(module_ldflags, 1, 'LDSOFLAGS').
env_name_v(module_ldflags, 2, 'SWIPL_MODULE_LDFLAGS').
env_name_v(module_ext,     1, 'SOEXT').
env_name_v(module_ext,     2, 'SWIPL_MODULE_EXT').
env_name_v(prefix,         1, 'PREFIX').
env_name_v(prefix,         2, 'SWIPL_PREFIX').

%!  prolog_library_dir(-Dir) is det.
%
%   True when Dir is the directory holding ``libswipl.$SOEXT``

:- multifile
    prolog:runtime_config/2.

prolog_library_dir(Dir) :-
    prolog:runtime_config(c_libdir, Dir),
    !.
prolog_library_dir(Dir) :-
    current_prolog_flag(windows, true),
    \+ current_prolog_flag(msys2, true),
    current_prolog_flag(home, Home),
    !,
    atomic_list_concat([Home, bin], /, Dir).
prolog_library_dir(Dir) :-
    current_prolog_flag(home, Home),
    (   current_prolog_flag(c_libdir, Rel)
    ->  atomic_list_concat([Home, Rel], /, Dir)
    ;   current_prolog_flag(arch, Arch)
    ->  atomic_list_concat([Home, lib, Arch], /, Dir)
    ).

%!  default_c_compiler(-CC) is semidet.
%
%   Try to find a  suitable  C   compiler  for  compiling  packages with
%   foreign code.
%
%   @tbd Needs proper defaults for Windows.  Find MinGW?  Find MSVC?

default_c_compiler(CC) :-
    getenv('CC', CC),
    !.
default_c_compiler(CC) :-
    preferred_c_compiler(CC0),
    has_program(CC0, CC),
    !.

default_cxx_compiler(CXX) :-
    getenv('CXX', CXX),
    !.
default_cxx_compiler(CXX) :-
    preferred_cxx_compiler(CXX0),
    has_program(CXX0, CXX),
    !.

preferred_c_compiler(CC) :-
    current_prolog_flag(c_cc, CC).
preferred_c_compiler(gcc).
preferred_c_compiler(clang).
preferred_c_compiler(cc).

preferred_cxx_compiler(CXX) :-
    current_prolog_flag(c_cxx, CXX).
preferred_cxx_compiler('g++').
preferred_cxx_compiler('clang++').
preferred_cxx_compiler('c++').


%!  save_build_environment(+State:dict) is det.
%
%   Create  a  shell-script  ``buildenv.sh``  that  contains  the  build
%   environment. This may be _sourced_ in the build directory to run the
%   build steps outside Prolog. It  may   also  be  useful for debugging
%   purposes.

:- det(save_build_environment/1).
save_build_environment(State) :-
    Env = State.get(env),
    !,
    (   BuildDir = State.get(bin_dir)
    ->  true
    ;   BuildDir = State.get(src_dir)
    ),
    directory_file_path(BuildDir, 'buildenv.sh', EnvFile),
    setup_call_cleanup(
	open(EnvFile, write, Out),
	write_env_script(Out, Env),
	close(Out)).
save_build_environment(_).

write_env_script(Out, Env) :-
    format(Out,
	   '# This file contains the environment that can be used to\n\c
	    # build the foreign pack outside Prolog.  This file must\n\c
	    # be loaded into a bourne-compatible shell using\n\c
	    #\n\c
	    #   $ source buildenv.sh\n\n',
	   []),
    forall(member(Var=Value, Env),
	   format(Out, '~w=\'~w\'\n', [Var, Value])),
    format(Out, '\nexport ', []),
    forall(member(Var=_, Env),
	   format(Out, ' ~w', [Var])),
    format(Out, '\n', []).

%!  prolog_install_prefix(-Prefix) is semidet.
%
%   Return the directory that can be  passed into `configure` or `cmake`
%   to install executables and other  related   resources  in  a similar
%   location as SWI-Prolog itself.  Tries these rules:
%
%     1. If the Prolog flag `pack_prefix` at a writable directory, use
%        this.
%     2. If the current executable can be found on $PATH and the parent
%        of the directory of the executable is writable, use this.
%     3. If the user has a writable ``~/bin`` directory, use ``~``.

prolog_install_prefix(Prefix) :-
    current_prolog_flag(pack_prefix, Prefix),
    access_file(Prefix, write),
    !.
prolog_install_prefix(Prefix) :-
    current_prolog_flag(os_argv, [Name|_]),
    has_program(path(Name), EXE),
    file_directory_name(EXE, Bin),
    file_directory_name(Bin, Prefix0),
    (   local_prefix(Prefix0, Prefix1)
    ->  Prefix = Prefix1
    ;   Prefix = Prefix0
    ),
    access_file(Prefix, write),
    !.
prolog_install_prefix(Prefix) :-
    expand_file_name(~, [UserHome]),
    directory_file_path(UserHome, bin, BinDir),
    exists_directory(BinDir),
    access_file(BinDir, write),
    !,
    Prefix = UserHome.

local_prefix('/usr', '/usr/local').


		 /*******************************
		 *          RUN PROCESSES       *
		 *******************************/

%!  run_process(+Executable, +Argv, +Options) is det.
%
%   Run Executable.  Defined options:
%
%     - directory(+Dir)
%       Execute in the given directory
%     - output(-Out)
%       Unify Out with a list of codes representing stdout of the
%       command.  Otherwise the output is handed to print_message/2
%       with level =informational=.
%     - error(-Error)
%       As output(Out), but messages are printed at level =error=.
%     - env(+Environment)
%       Environment passed to the new process.
%
%   If Executable is path(Program) and we   have  an environment we make
%   sure to use  the  ``PATH``  from   this  environment  for  searching
%   `Program`.

run_process(path(Exe), Argv, Options) :-
    option(env(BuildEnv), Options),
    !,
    setup_call_cleanup(
	b_setval('$build_tool_env', BuildEnv),
	run_process(pack_build_path(Exe), Argv, Options),
	nb_delete('$build_tool_env')).
run_process(Executable, Argv, Options) :-
    \+ option(output(_), Options),
    \+ option(error(_), Options),
    current_prolog_flag(unix, true),
    current_prolog_flag(threads, true),
    !,
    process_create_options(Options, Extra),
    process_create(Executable, Argv,
		   [ stdout(pipe(Out)),
		     stderr(pipe(Error)),
		     process(PID)
		   | Extra
		   ]),
    thread_create(relay_output([output-Out, error-Error]), Id, []),
    process_wait(PID, Status),
    thread_join(Id, _),
    (   Status == exit(0)
    ->  true
    ;   throw(error(process_error(process(Executable, Argv), Status), _))
    ).
run_process(Executable, Argv, Options) :-
    process_create_options(Options, Extra),
    setup_call_cleanup(
	process_create(Executable, Argv,
		       [ stdout(pipe(Out)),
			 stderr(pipe(Error)),
			 process(PID)
		       | Extra
		       ]),
	(   read_stream_to_codes(Out, OutCodes, []),
	    read_stream_to_codes(Error, ErrorCodes, []),
	    process_wait(PID, Status)
	),
	(   close(Out),
	    close(Error)
	)),
    print_error(ErrorCodes, Options),
    print_output(OutCodes, Options),
    (   Status == exit(0)
    ->  true
    ;   throw(error(process_error(process(Executable, Argv), Status), _))
    ).

process_create_options(Options, Extra) :-
    option(directory(Dir), Options, .),
    (   option(env(Env), Options)
    ->  Extra = [cwd(Dir), environment(Env)]
    ;   Extra = [cwd(Dir)]
    ).

relay_output([]) :- !.
relay_output(Output) :-
    pairs_values(Output, Streams),
    wait_for_input(Streams, Ready, infinite),
    relay(Ready, Output, NewOutputs),
    relay_output(NewOutputs).

relay([], Outputs, Outputs).
relay([H|T], Outputs0, Outputs) :-
    selectchk(Type-H, Outputs0, Outputs1),
    (   at_end_of_stream(H)
    ->  close(H),
	relay(T, Outputs1, Outputs)
    ;   read_pending_codes(H, Codes, []),
	relay(Type, Codes),
	relay(T, Outputs0, Outputs)
    ).

relay(error,  Codes) :-
    set_prolog_flag(message_context, []),
    print_error(Codes, []).
relay(output, Codes) :-
    print_output(Codes, []).

print_output(OutCodes, Options) :-
    option(output(Codes), Options),
    !,
    Codes = OutCodes.
print_output(OutCodes, _) :-
    print_message(informational, build(process_output(OutCodes))).

print_error(OutCodes, Options) :-
    option(error(Codes), Options),
    !,
    Codes = OutCodes.
print_error(OutCodes, _) :-
    phrase(classify_message(Level), OutCodes, _),
    print_message(Level, build(process_output(OutCodes))).

classify_message(error) -->
    string(_), "fatal:",
    !.
classify_message(error) -->
    string(_), "error:",
    !.
classify_message(warning) -->
    string(_), "warning:",
    !.
classify_message(informational) -->
    [].


:- multifile user:file_search_path/2.
user:file_search_path(pack_build_path, Dir) :-
    nb_current('$build_tool_env', Env),
    memberchk('PATH'=Path, Env),
    current_prolog_flag(path_sep, Sep),
    atomic_list_concat(Dirs, Sep, Path),
    member(Dir, Dirs),
    Dir \== ''.

%!  has_program(+Spec) is semidet.
%!  has_program(+Spec, -Path) is semidet.
%!  has_program(+Spec, -Path, +Env:list) is semidet.
%
%   True when the OS has the program  Spec at the absolute file location
%   Path. Normally called as   e.g.  has_program(path(cmake), CMakeExe).
%   The second allows passing in an  environment as Name=Value pairs. If
%   this contains a value for ``PATH``,  this   is  used rather than the
%   current path variable.

has_program(Prog) :-
    has_program(Prog, _).
has_program(Program, Path) :-
    has_program(Program, Path, []).

has_program(path(Program), Path, Env), memberchk('PATH'=_, Env) =>
    setup_call_cleanup(
	b_setval('$build_tool_env', Env),
	has_program(pack_build_path(Program), Path, []),
	nb_delete('$build_tool_env')).
has_program(Name, Path, Env), plain_program_name(Name) =>
    has_program(path(Name), Path, Env).
has_program(Program, Path, _Env) =>
    exe_options(ExeOptions),
    absolute_file_name(Program, Path,
		       [ file_errors(fail)
		       | ExeOptions
		       ]).

plain_program_name(Name) :-
    atom(Name),
    \+ sub_atom(Name, _, _, _, '/').

exe_options(Options) :-
    current_prolog_flag(windows, true),
    !,
    Options = [ extensions(['',exe,com]), access(read) ].
exe_options(Options) :-
    Options = [ access(execute) ].


		 /*******************************
		 *             OS PATHS		*
		 *******************************/

setup_path :-
    current_prolog_flag(windows, true),
    \+ current_prolog_flag(msys2, true),
    !,
    (   vcpkg_available
    ->  print_message(informational, build(using_vcpkg)),
        setup_path_vcpkg      % vcpkg + MSVC: need cmake, not make/gcc
    ;   setup_path([make, gcc])  % MinGW: need make/gcc
    ).
setup_path.

%!  vcpkg_available is semidet.
%
%   True if vcpkg is configured and available for use.
%   Uses absolute_file_name/3 for proper Windows path normalization.

vcpkg_available :-
    getenv('VCPKG_ROOT', Root),
    Root \== '',
    atomic_list_concat([Root, '/scripts/buildsystems/vcpkg.cmake'], ToolchainFile),
    absolute_file_name(ToolchainFile, _, [access(read), file_errors(fail)]).

%!  setup_path_vcpkg is det.
%
%   Setup path for vcpkg + MSVC builds. Requires cmake but not make/gcc.
%   MSVC compiler (cl.exe) should be available via VS Developer Command Prompt.

setup_path_vcpkg :-
    (   has_program(cmake)
    ->  true
    ;   print_message(error, build(no_cmake_for_vcpkg))
    ).

%!  setup_path(+Programs) is det.
%
%   Deals  with  specific  platforms  to  add  specific  directories  to
%   ``$PATH`` such that we can  find   the  tools.  Currently deals with
%   MinGW on Windows to provide `make` and `gcc`.

setup_path(Programs) :-
    maplist(has_program, Programs).
setup_path(_) :-
    current_prolog_flag(windows, true),
    !,
    (   mingw_extend_path
    ->  true
    ;   print_message(error, build(no_mingw))
    ).
setup_path(_).

%!  mingw_extend_path is semidet.
%
%   Check that gcc.exe is on ``%PATH%``  and if not, try to extend the
%   search path.

mingw_extend_path :-
    absolute_file_name(path('gcc.exe'), _,
		       [ access(exist),
			 file_errors(fail)
		       ]),
    !.
mingw_extend_path :-
    mingw_root(MinGW),
    directory_file_path(MinGW, bin, MinGWBinDir),
    atom_concat(MinGW, '/msys/*/bin', Pattern),
    expand_file_name(Pattern, MsysDirs),
    last(MsysDirs, MSysBinDir),
    prolog_to_os_filename(MinGWBinDir, WinDirMinGW),
    prolog_to_os_filename(MSysBinDir, WinDirMSYS),
    getenv('PATH', Path0),
    atomic_list_concat([WinDirMSYS, WinDirMinGW, Path0], ';', Path),
    setenv('PATH', Path),
    print_message(informational,
		  build(mingw_extend_path(WinDirMSYS, WinDirMinGW))).

mingw_root(MinGwRoot) :-
    current_prolog_flag(executable, Exe),
    sub_atom(Exe, 1, _, _, :),
    sub_atom(Exe, 0, 1, _, PlDrive),
    Drives = [PlDrive,c,d],
    member(Drive, Drives),
    format(atom(MinGwRoot), '~a:/MinGW', [Drive]),
    exists_directory(MinGwRoot),
    !.

		 /*******************************
		 *            MESSAGES          *
		 *******************************/

:- multifile prolog:message//1.

prolog:message(build(Msg)) -->
    message(Msg).

message(no_mingw) -->
    [ 'Cannot find MinGW and/or MSYS.'-[] ].
message(no_cmake_for_vcpkg) -->
    [ 'VCPKG_ROOT is set but cmake is not found on PATH.'-[], nl,
      'Install CMake and ensure it is in PATH, or use VS Developer Command Prompt.'-[]
    ].
message(using_vcpkg) -->
    [ 'Using vcpkg toolchain (VCPKG_ROOT detected)'-[] ].
message(process_output(Codes)) -->
    process_output(Codes).
message(step_failed(Step)) -->
    [ 'No build plugin could execute build step ~p'-[Step] ].
message(mingw_extend_path(WinDirMSYS, WinDirMinGW)) -->
    [ 'Extended %PATH% with ~p and ~p'-[WinDirMSYS, WinDirMinGW] ].

%!  process_output(+Codes)//
%
%   Emit process output  using  print_message/2.   This  preserves  line
%   breaks.

process_output([]) -->
    !.
process_output(Codes) -->
    { string_codes(String, Codes),
      split_string(String, "\n", "\r", Lines)
    },
    [ at_same_line ],
    process_lines(Lines).

process_lines([H|T]) -->
    [ '~s'-[H] ],
    (   {T==[""]}
    ->  [nl]
    ;   {T==[]}
    ->  [flush]
    ;   [nl], process_lines(T)
    ).
```

</details>

<details>
<summary>cmake.pl.patched - Click to reveal section</summary>

```
/*  Part of SWI-Prolog

    Author:        Jan Wielemaker
    E-mail:        jan@swi-prolog.org
    WWW:           http://www.swi-prolog.org
    Copyright (c)  2021, SWI-Prolog Solutions b.v.
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions
    are met:

    1. Redistributions of source code must retain the above copyright
       notice, this list of conditions and the following disclaimer.

    2. Redistributions in binary form must reproduce the above copyright
       notice, this list of conditions and the following disclaimer in
       the documentation and/or other materials provided with the
       distribution.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
    "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
    LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
    FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
    COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
    INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
    LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
    CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
    LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
    POSSIBILITY OF SUCH DAMAGE.
*/

:- module(build_cmake,
          []).
:- use_module(tools).

/** <module> CMake plugin to deal with build steps

Manage a CMake project. This prefers  the `ninja` generator if available
in ``$PATH``.
*/

:- multifile
    cmake_option/2.                     % +Env, -Option

:- multifile
    prolog:build_file/2,
    prolog:build_step/4.                % Step, Tool, SrcDir, BuildDir

prolog:build_file('CMakeLists.txt', cmake).

prolog:build_step(configure, cmake, State0, State) :-
    ensure_build_dir(build, State0, State),
    findall(Opt, cmake_option(State, Opt), Argv, [..]),
    run_process(path(cmake), Argv,
                [ directory(State.bin_dir),
                  env(State.env)
                ]).
prolog:build_step(build, cmake, State0, State) :-
    ensure_build_dir(build, State0, State),
    run_process(path(cmake), ['--build', '.'],
                [ directory(State.bin_dir),
                  env(State.env)
                ]).
prolog:build_step(test, cmake, State0, State) :-
    ensure_build_dir(build, State0, State),
    (   directory_file_path(State.bin_dir, 'CTestTestfile.cmake', TestFile),
        exists_file(TestFile)
    ->  test_jobs(Jobs),
        run_process(path(ctest), ['-j', Jobs, '--output-on-failure'],
                    [ directory(State.bin_dir),
                      env(State.env)
                    ])
    ;   true
    ).
prolog:build_step(install, cmake, State0, State) :-
    ensure_build_dir(build, State0, State),
    run_process(path(cmake), ['--install', '.'],
                [ directory(State.bin_dir),
                  env(State.env)
                ]).
prolog:build_step(clean, cmake, State0, State) :-
    ensure_build_dir(build, State0, State),
    run_cmake_target(State, clean).
prolog:build_step(distclean, cmake, State, State) :-
    directory_file_path(State.src_dir, build, BinDir),
    (   exists_directory(BinDir)
    ->  delete_directory_and_contents(BinDir)
    ;   true
    ).

%!  cmake_option(+State, -Define) is nondet.

cmake_option(_, CDEF) :-
    current_prolog_flag(executable, Exe),
    format(atom(CDEF), '-DSWIPL=~w', [Exe]).
cmake_option(_, CDEF) :-
    prolog_install_prefix(Prefix),
    format(atom(CDEF), '-DCMAKE_INSTALL_PREFIX=~w', [Prefix]).
cmake_option(State, CDEF) :-
    cmake_build_type(State, Type),
    format(atom(CDEF), '-DCMAKE_BUILD_TYPE=~w', [Type]).
cmake_option(State, Opt) :-
    has_program(path(ninja), _, State.env),
    member(Opt, ['-G', 'Ninja']).

%!  cmake_option(+State, -Define) is nondet.
%
%   vcpkg integration: If VCPKG_ROOT is set in the environment,
%   inject the toolchain file to enable vcpkg package discovery.

cmake_option(State, CDEF) :-
    vcpkg_toolchain_file(State, ToolchainFile),
    format(atom(CDEF), '-DCMAKE_TOOLCHAIN_FILE=~w', [ToolchainFile]).

%!  cmake_option(+State, -Define) is nondet.
%
%   vcpkg integration: On Windows, set the target triplet based on
%   SWI-Prolog's architecture (x64-windows for 64-bit).

cmake_option(_, '-DVCPKG_TARGET_TRIPLET=x64-windows') :-
    current_prolog_flag(windows, true),
    current_prolog_flag(arch, Arch),
    sub_atom(Arch, _, _, _, '64').
cmake_option(_, '-DVCPKG_TARGET_TRIPLET=x86-windows') :-
    current_prolog_flag(windows, true),
    current_prolog_flag(arch, Arch),
    \+ sub_atom(Arch, _, _, _, '64').

%!  vcpkg_toolchain_file(+State, -ToolchainFile) is semidet.
%
%   Determine the vcpkg toolchain file path from VCPKG_ROOT in
%   the build environment or system environment.

vcpkg_toolchain_file(State, ToolchainFile) :-
    % First check the build environment
    memberchk('VCPKG_ROOT'=Root, State.env),
    !,
    vcpkg_toolchain_path(Root, ToolchainFile).
vcpkg_toolchain_file(_, ToolchainFile) :-
    % Fallback to system environment
    getenv('VCPKG_ROOT', Root),
    vcpkg_toolchain_path(Root, ToolchainFile).

%!  vcpkg_toolchain_path(+Root, -ToolchainFile) is semidet.
%
%   Construct and verify the vcpkg toolchain file path.

vcpkg_toolchain_path(Root, ToolchainFile) :-
    atom_concat(Root, '/scripts/buildsystems/vcpkg.cmake', ToolchainFile),
    exists_file(ToolchainFile).

run_cmake_target(State, Target) :-
    cmake_generator_file(Generator, File),
    directory_file_path(State.bin_dir, File, AbsFile),
    exists_file(AbsFile),
    run_process(path(Generator), [Target],
                [ directory(State.bin_dir),
                  env(State.env)
                ]).

cmake_generator_file(ninja, 'build.ninja').
cmake_generator_file(make,  'Makefile').

cmake_build_type(State, Type) :-
    Type = State.get(build_type),
    !.
cmake_build_type(_, Type) :-
    current_prolog_flag(cmake_build_type, PlType),
    project_build_type(PlType, Type),
    !.
cmake_build_type(_, 'Release').

project_build_type('PGO', 'Release').
project_build_type('DEB', 'Release').
project_build_type(Type, Type).


test_jobs(Jobs) :-
    current_prolog_flag(cpu_count, Cores),
    Jobs is max(1, max(min(4,Cores), Cores//2)).
```

</details>

<details>
<summary>apply-patches.ps1 - Click to reveal section</summary>

```powershell
# Apply vcpkg pack_install patches to SWI-Prolog
# Run as Administrator in PowerShell

param(
    [string]$SwiplPath = "C:\Program Files\swipl",
    [switch]$Restore
)

$BuildDir = Join-Path $SwiplPath "library\build"

if ($Restore) {
    Write-Host "Restoring original files..." -ForegroundColor Yellow

    if (Test-Path "$BuildDir\cmake.pl.backup") {
        Copy-Item "$BuildDir\cmake.pl.backup" "$BuildDir\cmake.pl" -Force
        Write-Host "  Restored cmake.pl" -ForegroundColor Green
    }

    if (Test-Path "$BuildDir\tools.pl.backup") {
        Copy-Item "$BuildDir\tools.pl.backup" "$BuildDir\tools.pl" -Force
        Write-Host "  Restored tools.pl" -ForegroundColor Green
    }

    Write-Host "Restore complete." -ForegroundColor Green
    exit 0
}

# Check if SWI-Prolog exists
if (-not (Test-Path $BuildDir)) {
    Write-Error "SWI-Prolog build directory not found: $BuildDir"
    exit 1
}

# Check if patch files exist
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$CmakePatch = Join-Path $ScriptDir "cmake.pl.patched"
$ToolsPatch = Join-Path $ScriptDir "tools.pl.patched"

if (-not (Test-Path $CmakePatch)) {
    Write-Error "cmake.pl.patched not found in $ScriptDir"
    exit 1
}

if (-not (Test-Path $ToolsPatch)) {
    Write-Error "tools.pl.patched not found in $ScriptDir"
    exit 1
}

Write-Host "Applying vcpkg patches to SWI-Prolog..." -ForegroundColor Cyan
Write-Host "  Target: $BuildDir" -ForegroundColor Gray

# Backup originals
if (-not (Test-Path "$BuildDir\cmake.pl.backup")) {
    Copy-Item "$BuildDir\cmake.pl" "$BuildDir\cmake.pl.backup"
    Write-Host "  Backed up cmake.pl" -ForegroundColor Gray
}

if (-not (Test-Path "$BuildDir\tools.pl.backup")) {
    Copy-Item "$BuildDir\tools.pl" "$BuildDir\tools.pl.backup"
    Write-Host "  Backed up tools.pl" -ForegroundColor Gray
}

# Apply patches
Copy-Item $CmakePatch "$BuildDir\cmake.pl" -Force
Write-Host "  Applied cmake.pl patch" -ForegroundColor Green

Copy-Item $ToolsPatch "$BuildDir\tools.pl" -Force
Write-Host "  Applied tools.pl patch" -ForegroundColor Green

# Verify VCPKG_ROOT
$VcpkgRoot = [Environment]::GetEnvironmentVariable("VCPKG_ROOT", "User")
if (-not $VcpkgRoot) {
    $VcpkgRoot = [Environment]::GetEnvironmentVariable("VCPKG_ROOT", "Machine")
}

if ($VcpkgRoot) {
    Write-Host "`nVCPKG_ROOT is set: $VcpkgRoot" -ForegroundColor Green
    $Toolchain = Join-Path $VcpkgRoot "scripts\buildsystems\vcpkg.cmake"
    if (Test-Path $Toolchain) {
        Write-Host "  vcpkg toolchain found" -ForegroundColor Green
    } else {
        Write-Host "  WARNING: vcpkg toolchain not found at $Toolchain" -ForegroundColor Yellow
    }
} else {
    Write-Host "`nWARNING: VCPKG_ROOT not set. Set it with:" -ForegroundColor Yellow
    Write-Host '  [Environment]::SetEnvironmentVariable("VCPKG_ROOT", "C:\vcpkg", "User")' -ForegroundColor Gray
}

Write-Host "`nPatches applied successfully!" -ForegroundColor Green
Write-Host "Restart SWI-Prolog to use the patched build system." -ForegroundColor Cyan
Write-Host "`nTo test: pack_install(rocksdb, [rebuild(true)])." -ForegroundColor Cyan
Write-Host "To restore: .\apply-patches.ps1 -Restore" -ForegroundColor Gray
```

</details>

---

**Step 2: Apply patches to SWI-Prolog**

| | |
|---|---|
| 🖥️ **Environment** | SANDBOX |
| 🔧 **Terminal** | PowerShell (Administrator) |
| 👤 **Admin** | **Yes** |

⚠️ **Important**: Must run PowerShell as Administrator because SWI-Prolog is installed in `C:\Program Files\`.

- Click Start menu (or press Windows key)
- Type `powershell`
- Right-click "Windows PowerShell" → "Run as administrator"

```powershell
cd C:\Shared\swipl-patches
powershell -ExecutionPolicy Bypass -File .\apply-patches.ps1
```

**Expected output**:
```
PS C:\Windows\system32> cd C:\Shared\swipl-patches
PS C:\Shared\swipl-patches> powershell -ExecutionPolicy Bypass -File .\apply-patches.ps1
Applying vcpkg patches to SWI-Prolog...
  Target: C:\Program Files\swipl\library\build
  Backed up cmake.pl
  Backed up tools.pl
  Applied cmake.pl patch
  Applied tools.pl patch

WARNING: VCPKG_ROOT not set. Set it with:
  [Environment]::SetEnvironmentVariable("VCPKG_ROOT", "C:\vcpkg", "User")

Patches applied successfully!
Restart SWI-Prolog to use the patched build system.

To test: pack_install(rocksdb, [rebuild(true)]).
To restore: .\apply-patches.ps1 -Restore
```

✅ **Checkpoint**: Backups created at:
- `%ProgramFiles%\swipl\library\build\cmake.pl.backup`
- `%ProgramFiles%\swipl\library\build\tools.pl.backup`

---

**Step 2.1: Generate and View Patch Diffs (Optional)**

💡 **Purpose**
Verify what changes were applied to SWI-Prolog by generating unified diff files comparing the original and patched versions.

| | |
|---|---|
| 🖥️ **Environment** | SANDBOX |
| 🔧 **Terminal** | Command Prompt |
| 👤 **Admin** | No |

```cmd
cd C:\Shared\swipl-patches

REM Generate unified diff files comparing backup (original) vs patched files
"%ProgramFiles%\Git\usr\bin\diff.exe" -u "%ProgramFiles%\swipl\library\build\cmake.pl.backup" "%ProgramFiles%\swipl\library\build\cmake.pl" > cmake.pl.diff

"%ProgramFiles%\Git\usr\bin\diff.exe" -u "%ProgramFiles%\swipl\library\build\tools.pl.backup" "%ProgramFiles%\swipl\library\build\tools.pl" > tools.pl.diff

REM View the generated diffs
echo.
echo === cmake.pl.diff ===
type cmake.pl.diff
echo.
echo === tools.pl.diff ===
type tools.pl.diff
```

📝 **Note**
- The `.backup` files are the originals created by the patch script in Step 2
- Git for Windows (installed in Stage 5) includes the `diff` utility at `C:\Program Files\Git\usr\bin\diff.exe`
- The `-u` flag creates unified diff format (standard for patches)
- Lines starting with `+` show additions to the original SWI-Prolog files
- Lines starting with `-` show removals (if any)
- The diff files are saved to `C:\Shared\swipl-patches\` for later reference

**Expected output**:
```text
C:\Shared\swipl-patches>"%ProgramFiles%\Git\usr\bin\diff.exe" -u "%ProgramFiles%\swipl\library\build\cmake.pl.backup" "%ProgramFiles%\swipl\library\build\cmake.pl" > cmake.pl.diff

"%ProgramFiles%\Git\usr\bin\diff.exe" -u "%ProgramFiles%\swipl\library\build\tools.pl.backup" "%ProgramFiles%\swipl\library\build\tools.pl" > tools.pl.diff

C:\Shared\swipl-patches>echo.

C:\Shared\swipl-patches>echo === cmake.pl.diff ===
=== cmake.pl.diff ===

C:\Shared\swipl-patches>type cmake.pl.diff
--- "C:\\Program Files\\swipl\\library\\build\\cmake.pl.backup" 2022-11-23 10:25:58.000000000 -0500
+++ "C:\\Program Files\\swipl\\library\\build\\cmake.pl"        2025-12-29 18:03:42.143904000 -0500
@@ -106,6 +106,52 @@
     has_program(path(ninja), _, State.env),
     member(Opt, ['-G', 'Ninja']).

+%!  cmake_option(+State, -Define) is nondet.
+%
+%   vcpkg integration: If VCPKG_ROOT is set in the environment,
+%   inject the toolchain file to enable vcpkg package discovery.
+
+cmake_option(State, CDEF) :-
+    vcpkg_toolchain_file(State, ToolchainFile),
+    format(atom(CDEF), '-DCMAKE_TOOLCHAIN_FILE=~w', [ToolchainFile]).
+
+%!  cmake_option(+State, -Define) is nondet.
+%
+%   vcpkg integration: On Windows, set the target triplet based on
+%   SWI-Prolog's architecture (x64-windows for 64-bit).
+
+cmake_option(_, '-DVCPKG_TARGET_TRIPLET=x64-windows') :-
+    current_prolog_flag(windows, true),
+    current_prolog_flag(arch, Arch),
+    sub_atom(Arch, _, _, _, '64').
+cmake_option(_, '-DVCPKG_TARGET_TRIPLET=x86-windows') :-
+    current_prolog_flag(windows, true),
+    current_prolog_flag(arch, Arch),
+    \+ sub_atom(Arch, _, _, _, '64').
+
+%!  vcpkg_toolchain_file(+State, -ToolchainFile) is semidet.
+%
+%   Determine the vcpkg toolchain file path from VCPKG_ROOT in
+%   the build environment or system environment.
+
+vcpkg_toolchain_file(State, ToolchainFile) :-
+    % First check the build environment
+    memberchk('VCPKG_ROOT'=Root, State.env),
+    !,
+    vcpkg_toolchain_path(Root, ToolchainFile).
+vcpkg_toolchain_file(_, ToolchainFile) :-
+    % Fallback to system environment
+    getenv('VCPKG_ROOT', Root),
+    vcpkg_toolchain_path(Root, ToolchainFile).
+
+%!  vcpkg_toolchain_path(+Root, -ToolchainFile) is semidet.
+%
+%   Construct and verify the vcpkg toolchain file path.
+
+vcpkg_toolchain_path(Root, ToolchainFile) :-
+    atom_concat(Root, '/scripts/buildsystems/vcpkg.cmake', ToolchainFile),
+    exists_file(ToolchainFile).
+
 run_cmake_target(State, Target) :-
     cmake_generator_file(Generator, File),
     directory_file_path(State.bin_dir, File, AbsFile),

C:\Shared\swipl-patches>echo.


C:\Shared\swipl-patches>echo === tools.pl.diff ===
=== tools.pl.diff ===

C:\Shared\swipl-patches>type tools.pl.diff
--- "C:\\Program Files\\swipl\\library\\build\\tools.pl.backup" 2024-07-23 04:36:54.000000000 -0400
+++ "C:\\Program Files\\swipl\\library\\build\\tools.pl"        2025-12-30 08:34:04.372160100 -0500
@@ -234,6 +234,9 @@
 %     File name extension for modules (e.g., `so` or `dll`)
 %     $ ``SWIPL_PREFIX`` (``PREFIX``) :
 %     Install prefix for global binaries, libraries and include files.
+%     $ ``VCPKG_ROOT`` :
+%     If set in the user's environment, passed through to enable vcpkg
+%     integration in CMake-based pack builds.

 build_environment(Env, Options) :-
     findall(Name=Value,
@@ -288,6 +291,10 @@
     option(pack_version(Value), Options, 1).
 def_environment('SWIPL_PACK_PATH', Value, _Options) :-
     prolog_config(pack_path, Value).
+%   vcpkg integration: Pass through VCPKG_ROOT if set, enabling
+%   cmake.pl to inject the vcpkg toolchain file.
+def_environment('VCPKG_ROOT', Value, _Options) :-
+    getenv('VCPKG_ROOT', Value).
 def_environment(VAR, Value, Options) :-
     env_name(version, VAR, Options),
     current_prolog_flag(version, Value).
@@ -728,9 +735,35 @@
     current_prolog_flag(windows, true),
     \+ current_prolog_flag(msys2, true),
     !,
-    setup_path([make, gcc]).
+    (   vcpkg_available
+    ->  print_message(informational, build(using_vcpkg)),
+        setup_path_vcpkg      % vcpkg + MSVC: need cmake, not make/gcc
+    ;   setup_path([make, gcc])  % MinGW: need make/gcc
+    ).
 setup_path.

+%!  vcpkg_available is semidet.
+%
+%   True if vcpkg is configured and available for use.
+%   Uses absolute_file_name/3 for proper Windows path normalization.
+
+vcpkg_available :-
+    getenv('VCPKG_ROOT', Root),
+    Root \== '',
+    atomic_list_concat([Root, '/scripts/buildsystems/vcpkg.cmake'], ToolchainFile),
+    absolute_file_name(ToolchainFile, _, [access(read), file_errors(fail)]).
+
+%!  setup_path_vcpkg is det.
+%
+%   Setup path for vcpkg + MSVC builds. Requires cmake but not make/gcc.
+%   MSVC compiler (cl.exe) should be available via VS Developer Command Prompt.
+
+setup_path_vcpkg :-
+    (   has_program(cmake)
+    ->  true
+    ;   print_message(error, build(no_cmake_for_vcpkg))
+    ).
+
 %!  setup_path(+Programs) is det.
 %
 %   Deals  with  specific  platforms  to  add  specific  directories  to
@@ -794,6 +827,12 @@

 message(no_mingw) -->
     [ 'Cannot find MinGW and/or MSYS.'-[] ].
+message(no_cmake_for_vcpkg) -->
+    [ 'VCPKG_ROOT is set but cmake is not found on PATH.'-[], nl,
+      'Install CMake and ensure it is in PATH, or use VS Developer Command Prompt.'-[]
+    ].
+message(using_vcpkg) -->
+    [ 'Using vcpkg toolchain (VCPKG_ROOT detected)'-[] ].
 message(process_output(Codes)) -->
     process_output(Codes).
 message(step_failed(Step)) -->

C:\Shared\swipl-patches>
```

**What to look for in the diffs:**

**cmake.pl changes:**
- New `cmake_option/2` predicates that inject vcpkg toolchain file when `VCPKG_ROOT` is set
- Automatic `VCPKG_TARGET_TRIPLET` detection based on SWI-Prolog's architecture (x64-windows or x86-windows)
- Helper predicates to locate and verify the vcpkg toolchain file

**tools.pl changes:**
- Documentation and pass-through of `VCPKG_ROOT` environment variable
- Detection of vcpkg availability on Windows
- Switch from MinGW (make/gcc) to MSVC (cmake) toolchain when vcpkg is available
- New `vcpkg_available/0` and `setup_path_vcpkg/0` predicates
- Informational/error messages for vcpkg build process

✅ **Checkpoint**: Diff files created at `C:\Shared\swipl-patches\cmake.pl.diff` and `C:\Shared\swipl-patches\tools.pl.diff`

---

**Step 3: Set VCPKG_ROOT environment variable (persistent)**

| | |
|---|---|
| 🖥️ **Environment** | SANDBOX |
| 🔧 **Terminal** | PowerShell (Administrator) |
| 👤 **Admin** | **Yes** |

```powershell
[System.Environment]::SetEnvironmentVariable("VCPKG_ROOT", "C:\vcpkg", "Machine")
[Environment]::GetEnvironmentVariable("VCPKG_ROOT", "Machine")
```

**Expected output**:
```
PS C:\Shared\swipl-patches> [System.Environment]::SetEnvironmentVariable("VCPKG_ROOT", "C:\vcpkg", "Machine")
PS C:\Shared\swipl-patches> [Environment]::GetEnvironmentVariable("VCPKG_ROOT", "Machine")
C:\vcpkg
```

📝 **Note**: Using "Machine" scope ensures all terminals see the variable. Close and reopen any terminals after setting.

**Verify environment variable**:

| | |
|---|---|
| 🖥️ **Environment** | SANDBOX |
| 🔧 **Terminal** | x64 Native Tools Command Prompt for VS 2022 |
| 👤 **Admin** | No |

Open a **new** x64 Native Tools Command Prompt and run:

```cmd
echo %VCPKG_ROOT%
```

**Expected output**: `C:\vcpkg`

**Step 4: Test pack_install for rocksdb pack**

| | |
|---|---|
| 🖥️ **Environment** | SANDBOX |
| 🔧 **Terminal** | x64 Native Tools Command Prompt for VS 2022 |
| 👤 **Admin** | No |
| ⏱️ **Time** | ~5-10 min |

⚠️ **Important**:
- Use x64 Native Tools Command Prompt to ensure MSVC compiler is available
- Must use EricGT/rocksdb fork which has CMakeLists.txt with vcpkg support
- SSL certificate issues in Sandbox may require running the command twice

```cmd
echo %TEMP%
mkdir "%TEMP%\swipl_test"
swipl -g "pack_install(rocksdb, [url('https://github.com/EricGT/rocksdb.git'), branch('feature/windows-vcpkg-support'), rebuild(true), interactive(false)]), halt"
```

📝 **Note**: If you get "certificate verify failed" error, run the same command again.

**Expected output**:
```
C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools>echo %TEMP%
C:\Users\WDAGUtilityAccount\AppData\Local\Temp

C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools>mkdir "%TEMP%\swipl_test"

C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools>swipl -g "pack_install(rocksdb, [url('https://github.com/EricGT/rocksdb.git'), branch('feature/windows-vcpkg-support'), rebuild(true), interactive(false)]), halt"
% Building pack rocksdb in directory c:/users/wdagutilityaccount/appdata/local/swi-prolog/pack/rocksdb
% Using vcpkg toolchain (VCPKG_ROOT detected)
Platform needs to link against libswipl.
-- Running vcpkg install
% Detecting compiler hash for triplet x64-windows...
% Compiler found: C:/Program Files (x86)/Microsoft Visual Studio/2022/BuildTools/VC/Tools/MSVC/14.44.35207/bin/Hostx64/x64/cl.exe
% The following packages will be built and installed:
%   * lz4:x64-windows@1.10.0
%     rocksdb[core,lz4,snappy,zlib,zstd]:x64-windows@10.4.2
%   * snappy:x64-windows@1.2.2#1
%   * vcpkg-cmake:x64-windows@2024-04-23
%   * vcpkg-cmake-config:x64-windows@2024-05-23
%   * zlib:x64-windows@1.3.1
%   * zstd:x64-windows@1.5.7
% Additional packages (*) will be modified to complete this operation.
% Restored 7 package(s) from C:\Users\WDAGUtilityAccount\AppData\Local\vcpkg\archives in 56 s. Use --debug to see more details.
% Installing 1/7 vcpkg-cmake-config:x64-windows@2024-05-23...
% Elapsed time to handle vcpkg-cmake-config:x64-windows: 39.4 ms
% vcpkg-cmake-config:x64-windows package ABI: 43067825c5419f5465b832f158f920cd31f9b73848b571323b25cb5eea694d8b
% Installing 2/7 vcpkg-cmake:x64-windows@2024-04-23...
% Elapsed time to handle vcpkg-cmake:x64-windows: 19.5 ms
% vcpkg-cmake:x64-windows package ABI: 9e686886ddd2bba2667a758f0df5ba2a4e02e7dbfb831c4f261801b93985d3ce
% Installing 3/7 zstd:x64-windows@1.5.7...
% Elapsed time to handle zstd:x64-windows: 40.5 ms
% zstd:x64-windows package ABI: 0ddde10ef24760e9304aeef59282c1ddd1fd8a751f870ce64a89a1384cbab8e1
% Installing 4/7 zlib:x64-windows@1.3.1...
% Elapsed time to handle zlib:x64-windows: 27 ms
% zlib:x64-windows package ABI: c33d592dd282e1dbe0a07b82a985df96648eb585331faade4469bd52f27f3825
% Installing 5/7 snappy:x64-windows@1.2.2#1...
% Elapsed time to handle snappy:x64-windows: 26.3 ms
% snappy:x64-windows package ABI: fb47ca1eb5922d180d42cb7497ced72e379946e277a7d1af2eb886932e7c628f
% Installing 6/7 lz4:x64-windows@1.10.0...
% Elapsed time to handle lz4:x64-windows: 30.5 ms
% lz4:x64-windows package ABI: 70ba67e78ac490822a29e3486bad43480c86dc70021928b75fa5561072d0b825
% Installing 7/7 rocksdb[core,lz4,snappy,zlib,zstd]:x64-windows@10.4.2...
% Elapsed time to handle rocksdb:x64-windows: 76.1 ms
% rocksdb:x64-windows package ABI: d0ed02416c64d3dd1033a8656774a1f15a4e3826f0fa830bb73e7b8d5b74fdb8
% Installed contents are licensed to you by owners. Microsoft is not responsible for, nor does it grant any licenses to, third-party packages.
% Some packages did not declare an SPDX license. Check the `copyright` file for each package for more information about their licensing.
% Packages installed in this vcpkg installation declare the following licenses:
% (BSD-3-Clause OR GPL-2.0-only)
% (GPL-2.0-only OR Apache-2.0)
% BSD-2-Clause
% MIT
% Zlib
% rocksdb provides CMake targets:
%
%   # this is heuristically generated, and may not be correct
%   find_package(RocksDB CONFIG REQUIRED)
%   target_link_libraries(main PRIVATE RocksDB::rocksdb RocksDB::rocksdb-shared)
%
% rocksdb provides pkg-config modules:
%
%   # An embeddable persistent key-value store for fast storage
%   rocksdb
%
% All requested installations completed successfully in: 273 ms
% -- Running vcpkg install - done
% -- The CXX compiler identification is MSVC 19.44.35222.0
% -- Detecting CXX compiler ABI info
% -- Detecting CXX compiler ABI info - done
% -- Check for working CXX compiler: C:/Program Files (x86)/Microsoft Visual Studio/2022/BuildTools/VC/Tools/MSVC/14.44.35207/bin/Hostx64/x64/cl.exe - skipped
% -- Detecting CXX compile features
% -- Detecting CXX compile features - done
% -- Loading swipl.cmake from pack_install context: c:/program files/swipl/cmake/swipl.cmake
% -- Found ZLIB: optimized;C:/Users/WDAGUtilityAccount/AppData/Local/swi-prolog/pack/rocksdb/build/vcpkg_installed/x64-windows/lib/zlib.lib;debug;C:/Users/WDAGUtilityAccount/AppData/Local/swi-prolog/pack/rocksdb/build/vcpkg_installed/x64-windows/debug/lib/zlibd.lib (found version "1.3.1")
% -- Performing Test CMAKE_HAVE_LIBC_PTHREAD
% -- Performing Test CMAKE_HAVE_LIBC_PTHREAD - Failed
% -- Looking for pthread_create in pthreads
% -- Looking for pthread_create in pthreads - not found
% -- Looking for pthread_create in pthread
% -- Looking for pthread_create in pthread - not found
% -- Found Threads: TRUE
% -- Found RocksDB: C:/Users/WDAGUtilityAccount/AppData/Local/swi-prolog/pack/rocksdb/build/vcpkg_installed/x64-windows/share/rocksdb
% -- Creating swipl::libswipl target manually (swipl.cmake workaround)
% -- Using target_link_swipl() for SWI-Prolog linking
% -- Using module directory from swipl.cmake: C:/Users/WDAGUtilityAccount/AppData/Local/swi-prolog/pack/rocksdb/lib/x64-win64
% -- vcpkg bin directory: C:\vcpkg/installed/x64-windows/bin
% -- ========================================
% -- SWI-Prolog RocksDB Pack Configuration
% -- ========================================
% -- Build type: Release
% -- C++ Compiler: MSVC 19.44.35222.0
% -- C++ Standard: C++20
% -- swipl.cmake loaded: TRUE
% -- Output directory: C:/Users/WDAGUtilityAccount/AppData/Local/swi-prolog/pack/rocksdb/lib/x64-win64
% -- ========================================
% -- Configuring done (66.6s)
% -- Generating done (0.1s)
% -- Build files have been written to: C:/users/wdagutilityaccount/appdata/local/swi-prolog/pack/rocksdb/build
[1/2] Building CXX object CMakeFiles\rocksdb4pl.dir\cpp\rocksdb4pl.cpp.obj
% C:\Users\WDAGUtilityAccount\AppData\Local\swi-prolog\pack\rocksdb\cpp\rocksdb4pl.cpp(356) : warning C4715: 'get_slice': not all control paths return a value
% [2/2] Linking CXX shared module C:\Users\WDAGUtilityAccount\AppData\Local\swi-prolog\pack\rocksdb\lib\x64-win64\rocksdb4pl.dll; Copying RocksDB DLL dependencies to pack lib directory
% Copying vcpkg DLLs to C:/Users/WDAGUtilityAccount/AppData/Local/swi-prolog/pack/rocksdb/lib/x64-win64
-- Install configuration: "Release"
```


**What to watch for in the output**:
1. CMake should show `-DCMAKE_TOOLCHAIN_FILE=C:/vcpkg/scripts/buildsystems/vcpkg.cmake`
2. CMake should show `-DVCPKG_TARGET_TRIPLET=x64-windows`
3. RocksDB should be found: `-- Found RocksDB: ...`
4. Should see: `Copying vcpkg DLLs to <pack-lib-directory>`
5. Build should complete without errors

📝 **Note on Path Separators**
CMake uses forward slashes (`/`) in toolchain paths (e.g., `C:/vcpkg/scripts/buildsystems/vcpkg.cmake`), while Windows CMD commands use backslashes (`\`). Both formats are correct for their respective contexts and are shown in the expected output examples throughout this guide.

**Step 5: Verify library loads**

| | |
|---|---|
| 🖥️ **Environment** | SANDBOX |
| 🔧 **Terminal** | x64 Native Tools Command Prompt for VS 2022 |
| 👤 **Admin** | No |

```cmd
swipl -g "use_module(library(rocksdb)), writeln('rocksdb loaded successfully'), halt"
```

**Expected output**: `rocksdb loaded successfully`

**Step 6: Run functional test**

| 🖥️ **Environment** | SANDBOX |
| 🔧 **Terminal** | x64 Native Tools Command Prompt for VS 2022 |
| 👤 **Admin** | No |

```cmd
swipl -g "use_module(library(rocksdb)), rocks_open('C:/Users/WDAGUtilityAccount/AppData/Local/Temp/swipl_test/test_db', Db, []), rocks_put(Db, hello, world), rocks_get(Db, hello, V), format('Got: ~w~n', [V]), rocks_close(Db), halt"
```

**Expected output**: `Got: world`

**Step 7: Run full test suite**

| | |
|---|---|
| 🖥️ **Environment** | SANDBOX |
| 🔧 **Terminal** | x64 Native Tools Command Prompt for VS 2022 |
| 👤 **Admin** | No |
| ⏱️ **Time** | ~1-2 min |

```cmd
cd "%LOCALAPPDATA%\swi-prolog\pack\rocksdb\test"
swipl -g "consult('test_rocksdb.pl'), run_tests, halt" -t "halt(1)"
```

✅ **Expected**: All 28 tests pass

---

### Stage 10: Test rocks-predicates Module

💡 **Purpose**
Test the rocks-predicates module, which provides persistent predicate storage using RocksDB.

📝 **Note**
rocks-predicates is **not a pack** - it's a standalone Prolog module that users add to their projects. It depends on the rocksdb pack being installed (completed in Stage 9).

**Step 1: Clone rocks-predicates**

| | |
|---|---|
| 🖥️ **Environment** | SANDBOX |
| 🔧 **Terminal** | x64 Native Tools Command Prompt for VS 2022 |
| 👤 **Admin** | No |

```cmd
mkdir "%USERPROFILE%\projects\rocks-predicates demo"
cd "%USERPROFILE%\projects\rocks-predicates demo"
git clone https://github.com/EricGT/rocks-predicates.git .
git checkout feature/windows-support
```

📝 **Note**: SSL certificate errors may occur on first clone attempt. If so, run the command again.

**Expected output**:
```
C:\Users\WDAGUtilityAccount\AppData\Local\swi-prolog\pack\rocksdb\test>mkdir "%USERPROFILE%\projects\rocks-predicates demo"

C:\Users\WDAGUtilityAccount\AppData\Local\swi-prolog\pack\rocksdb\test>cd "%USERPROFILE%\projects\rocks-predicates demo"

C:\Users\WDAGUtilityAccount\projects\rocks-predicates demo>git clone https://github.com/EricGT/rocks-predicates.git .
Cloning into '.'...
remote: Enumerating objects: 181, done.
remote: Counting objects: 100% (181/181), done.
remote: Compressing objects: 100% (110/110), done.
remote: Total 181 (delta 76), reused 171 (delta 66), pack-reused 0 (from 0)
Receiving objects: 100% (181/181), 60.99 KiB | 1.97 MiB/s, done.
Resolving deltas: 100% (76/76), done.

C:\Users\WDAGUtilityAccount\projects\rocks-predicates demo>git checkout feature/windows-support
branch 'feature/windows-support' set up to track 'origin/feature/windows-support'.
Switched to a new branch 'feature/windows-support'
```

**Step 2: Verify module loads**

| | |
|---|---|
| 🖥️ **Environment** | SANDBOX |
| 🔧 **Terminal** | x64 Native Tools Command Prompt for VS 2022 |
| 👤 **Admin** | No |
| 📂 **Working Dir** | `%USERPROFILE%\projects\rocks-predicates demo` |

```cmd
swipl -g "use_module(rocks_preds), writeln('rocks_preds loaded successfully'), halt"
```

**Expected output**: `rocks_preds loaded successfully`

**Step 3: Run functional test**

| | |
|---|---|
| 🖥️ **Environment** | SANDBOX |
| 🔧 **Terminal** | x64 Native Tools Command Prompt for VS 2022 |
| 👤 **Admin** | No |
| 📂 **Working Dir** | `%USERPROFILE%\projects\rocks-predicates demo` |

```cmd
swipl -g "use_module(rocks_preds), rdb_open('test_db', _), rdb_assertz(test_fact(hello)), rdb_clause(test_fact(X), true), format('Got: ~w~n', [X]), rdb_close, halt"
```

**Expected output**: `Got: hello`

**Step 4: Run full test suite**

| | |
|---|---|
| 🖥️ **Environment** | SANDBOX |
| 🔧 **Terminal** | x64 Native Tools Command Prompt for VS 2022 |
| 👤 **Admin** | No |
| 📂 **Working Dir** | `%USERPROFILE%\projects\rocks-predicates demo` |
| ⏱️ **Time** | ~1-2 min |

```cmd
mkdir dbs
swipl run_all_tests.pl
```

📝 **Note**: The `mkdir dbs` creates the test database directory (excluded from git).

✅ **Checkpoint**: All 73 tests pass successfully

---

## Testing Workflow Summary

| Stage | Environment | Terminal/App | Admin? | Time | Action |
|-------|-------------|--------------|--------|------|--------|
| 1 | HOST | Browser | No | ~15 min | Download installers to `shared\installers\` |
| 2 | HOST/SANDBOX | File Explorer, Start Menu | No | ~5 min | Create .wsb, launch sandbox, pin tools |
| 3 | SANDBOX | VS Installer GUI | No* | ~3.5+ hours | Install VS Build Tools with MSVC and SDK |
| 4 | SANDBOX | File Explorer, PowerShell | No | ~5 min | Install CMake, verify installation |
| 5 | SANDBOX | File Explorer, Command Prompt | No | ~2 min | Install Git, verify installation |
| 6 | SANDBOX | Command Prompt | No | ~5 min | Clone and bootstrap vcpkg |
| 7 | SANDBOX | Command Prompt | No | ~25 min | Install RocksDB via vcpkg |
| 8 | SANDBOX | File Explorer, Command Prompt | No | ~5 min | Install SWI-Prolog, verify |
| 9 | HOST/SANDBOX | File Explorer, PowerShell (Admin), Command Prompt | Yes** | ~15 min | Copy patches, apply patches, test pack_install |
| 10 | SANDBOX | Command Prompt | No | ~5 min | Clone and test rocks-predicates |

\*VS Installer handles elevation internally within the sandbox  
\**Only Step 2 (applying patches) requires admin

---

## Troubleshooting

### CMake doesn't show vcpkg toolchain

| Symptom | Cause | 🔧 Terminal/App | Fix |
|---------|-------|-----------------|-----|
| No `-DCMAKE_TOOLCHAIN_FILE` in output | `VCPKG_ROOT` not set | x64 Native Tools Command Prompt | Verify with `echo %VCPKG_ROOT%`, set via Stage 9 Step 3 |
| No `-DCMAKE_TOOLCHAIN_FILE` in output | Patches not applied | PowerShell (Administrator) | Re-run `apply-patches.ps1` from Stage 9 Step 2 |
| Toolchain file not found | Wrong `VCPKG_ROOT` path | x64 Native Tools Command Prompt | Verify path exists: `dir %VCPKG_ROOT%\scripts\buildsystems\vcpkg.cmake` |

### RocksDB not found during CMake

| Symptom | Cause | 🔧 Terminal/App | Fix |
|---------|-------|-----------------|-----|
| `Could NOT find RocksDB` | vcpkg packages not installed | x64 Native Tools Command Prompt | Run `vcpkg list` to verify, reinstall if needed |
| `Could NOT find RocksDB` | Wrong triplet | x64 Native Tools Command Prompt | Verify triplet is `x64-windows` |

### DLL not found at runtime

| Symptom | Cause | 🔧 Terminal/App | Fix |
|---------|-------|-----------------|-----|
| `rocksdb4pl.dll` not found | Pack not properly installed | File Explorer | Check `%LOCALAPPDATA%\swi-prolog\pack\rocksdb\lib\x64-win64\` |
| `rocksdb-shared.dll` not found | vcpkg DLLs missing | File Explorer | Verify all 6 DLLs present (rocksdb4pl, rocksdb-shared, lz4, snappy, zlib1, zstd) |

### Verifying patch application

Check if patches were applied successfully:

| | |
|---|---|
| 🖥️ **Environment** | SANDBOX |
| 🔧 **Terminal** | PowerShell |
| 👤 **Admin** | No |

```powershell
Select-String -Path "$env:ProgramFiles\swipl\library\build\cmake.pl" -Pattern "vcpkg_toolchain_file"
```

**Expected**: Should show the `vcpkg_toolchain_file` predicate definition.

### Rollback to original SWI-Prolog files

If patches cause issues, restore the original files:

| | |
|---|---|
| 🖥️ **Environment** | SANDBOX |
| 🔧 **Terminal** | PowerShell (Administrator) |
| 👤 **Admin** | **Yes** |

```powershell
# Run as Administrator
$SWIPL_LIB = "$env:ProgramFiles\swipl\library\build"
Copy-Item "$SWIPL_LIB\cmake.pl.backup" "$SWIPL_LIB\cmake.pl" -Force
Copy-Item "$SWIPL_LIB\tools.pl.backup" "$SWIPL_LIB\tools.pl" -Force
```

---

## Success Criteria

✅ VS Build Tools installed with MSVC and Windows SDK  
✅ CMake found in PATH  
✅ Git found in PATH  
✅ vcpkg bootstrapped successfully  
✅ RocksDB installed via vcpkg  
✅ SWI-Prolog 10.0.0 installed  
✅ Patches applied to SWI-Prolog build system  
✅ pack_install successfully builds rocksdb pack with vcpkg integration  
✅ rocksdb pack loads: `use_module(library(rocksdb))`  
✅ rocksdb test suite passes (28 tests)  
✅ rocks-predicates module loads: `use_module(rocks_preds)`  
✅ rocks-predicates test suite passes (73 tests)  

---

## Files Referenced

| File | Purpose |
|------|---------|
| `%USERPROFILE%\sandbox\CleanInstallTest.wsb` | Windows Sandbox configuration |
| `%USERPROFILE%\sandbox\shared\installers\` | Downloaded installers |
| `%USERPROFILE%\sandbox\shared\swipl-patches\` | SWI-Prolog patch files |
| `%ProgramFiles%\swipl\library\build\cmake.pl` | SWI-Prolog CMake build file (patched) |
| `%ProgramFiles%\swipl\library\build\tools.pl` | SWI-Prolog build tools (patched) |
| `C:\vcpkg\` | vcpkg root directory |
| `%LOCALAPPDATA%\swi-prolog\pack\rocksdb\` | Installed rocksdb pack |

---

**End of Guide**

For questions or issues, refer to:
- SWI-Prolog Discourse: https://swi-prolog.discourse.group/
- vcpkg GitHub: https://github.com/microsoft/vcpkg
- EricGT/rocksdb: https://github.com/EricGT/rocksdb
- EricGT/rocks-predicates: https://github.com/EricGT/rocks-predicates
