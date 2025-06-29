# NextUI Assets & Customization Map

## Overview

This document provides a comprehensive map of all branding, text, and image assets in the NextUI firmware project that can be safely modified for customization or rebranding to `minOS` or other names.

---

## 1. **Project Name References**

Files containing project name references that should be updated:

| File/Path | Current Reference | Suggested New Value | Notes |
|-----------|-------------------|---------------------|-------|
| `README.md` | NextUI | minOS | Main project documentation |
| `docs/README.md` | NextUI | minOS | Documentation overview |
| `docs/build-quick.md` | NextUI | minOS | Quick build guide |
| `makefile` | NextUI | minOS | Main makefile header comment |
| `workspace/all/nextui/nextui.c:2146` | `LOG_info("NextUI\n");` | `LOG_info("minOS\n");` | Boot log message |
| `workspace/all/minarch/minarch.c:6542` | `"NextUI (" BUILD_DATE " " BUILD_HASH ")"` | `"minOS (" BUILD_DATE " " BUILD_HASH ")"` | Frontend version string |
| `workspace/all/settings/settings.cpp:318` | `"NextUI version"` | `"minOS version"` | Settings menu label |
| `workspace/tg5040/platform/platform.c:2554` | `/tmp/nextui_exec` | `/tmp/minos_exec` | Temporary execution file |
| `workspace/tg5040/other/NextCommander/Makefile:16` | `NEXTUI_SYSTEM_PATH` | `MINOS_SYSTEM_PATH` | Build variable |
| `workspace/all/common/config.h:91` | `NextUISettings` | `minOSSettings` | Settings structure name |
| `workspace/all/common/config.c:5,21,26` | `NextUISettings` | `minOSSettings` | Settings implementation |
| `skeleton/BASE/README.txt` | NextUI | minOS | Installation instructions |
| `skeleton/EXTRAS/README.txt` | NextUI | minOS | Extras documentation |
| `todo.txt` | NextUI references | minOS | Development notes |

---

## 2. **Image & Logo Assets**

Visual assets that can be replaced for branding:

| File/Path | Description | Editable? | Notes |
|-----------|-------------|-----------|-------|
| `skeleton/SYSTEM/res/assets@1x.png` | UI icons 1x resolution | ✅ | Main UI icon set |
| `skeleton/SYSTEM/res/assets@2x.png` | UI icons 2x resolution | ✅ | High-DPI UI icons |
| `skeleton/SYSTEM/res/assets@3x.png` | UI icons 3x resolution | ✅ | Ultra-high-DPI icons |
| `skeleton/SYSTEM/res/assets@4x.png` | UI icons 4x resolution | ✅ | Maximum resolution icons |
| `skeleton/SYSTEM/res/background.png` | Default background | ✅ | Main menu background |
| `skeleton/SYSTEM/res/charging-640-480.png` | Charging screen | ✅ | Battery charging indicator |
| `skeleton/EXTRAS/Tools/tg5040/Bootlogo.pak/smartpro/bootlogo_minui_next.bmp` | NextUI boot logo (Smart Pro) | ✅ | NextUI-branded boot screen |
| `skeleton/EXTRAS/Tools/tg5040/Bootlogo.pak/smartpro/bootlogo_minui.bmp` | MinUI boot logo (Smart Pro) | ✅ | Legacy MinUI boot screen |
| `skeleton/EXTRAS/Tools/tg5040/Bootlogo.pak/brick/bootlogo_minui_next.bmp` | NextUI boot logo (Brick) | ✅ | NextUI-branded boot screen |
| `skeleton/EXTRAS/Tools/tg5040/Bootlogo.pak/brick/bootlogo_minui.bmp` | MinUI boot logo (Brick) | ✅ | Legacy MinUI boot screen |
| `workspace/tg5040/install/installing.png` | Installation screen | ✅ | Shows during firmware install |
| `workspace/tg5040/install/updating.png` | Update screen | ✅ | Shows during firmware update |
| `docs/minos-archtecture.png` | Architecture diagram | ✅ | Technical documentation image |

---

## 3. **Textual Content & Messages**

User-facing strings and text for branding customization:

| Location/File | Example String | Editable? | Notes |
|---------------|----------------|-----------|-------|
| `workspace/all/minarch/minarch.c:6542` | Frontend version display | ✅ | Shows in emulator menu |
| `workspace/all/settings/settings.cpp:318` | "NextUI version" | ✅ | Settings menu item |
| `workspace/all/settings/settings.cpp:251,253,257,259` | Save format references to MinUI | ✅ | Configuration options |
| `skeleton/BASE/README.txt` | Installation instructions | ✅ | User documentation |
| `skeleton/EXTRAS/README.txt` | Extras documentation | ✅ | User documentation |
| `workspace/tg5040/libmsettings/msettings.c` | Settings format comments | ✅ | Code comments (internal) |
| `workspace/desktop/libmsettings/msettings.c` | Settings format comments | ✅ | Code comments (internal) |

---

## 4. **UI Layout & Screen Elements**

UI elements where logos or branding can be customized:

| File/Path | Element | Editable? | Notes |
|-----------|---------|-----------|-------|
| `skeleton/SYSTEM/res/assets@*.png` | Menu icons and UI elements | ✅ | Complete icon redesign possible |
| `skeleton/SYSTEM/res/font1.ttf` | Primary UI font | ✅ | Can be replaced for branding |
| `skeleton/SYSTEM/res/font2.ttf` | Secondary UI font | ✅ | Can be replaced for branding |
| `skeleton/SYSTEM/res/BPreplayBold-unhinted*.otf` | Bold font files | ✅ | Typography customization |
| `skeleton/SYSTEM/res/grid-*.png` | Grid layout assets | ✅ | UI layout components |
| `skeleton/SYSTEM/res/line-*.png` | Line separator assets | ✅ | UI decoration elements |

---

## 5. **Other Branding Elements**

Additional customizable elements:

| Element | Description | Editable? | Notes |
|---------|-------------|-----------|-------|
| **Package Names** | `MinUI.zip`, `NextUI.zip` | ✅ | Installation package naming |
| **PAK System** | `MinUI.pak` folder structure | ✅ | Core system PAK naming |
| **Directory Paths** | `.minui` hidden directories | ✅ | User data storage paths |
| **Build Variables** | `BUILD_HASH`, `BUILD_DATE` in version strings | ✅ | Version identification |
| **Log Messages** | Boot and debug log entries | ✅ | System logging output |
| **Settings Structure** | `NextUISettings` struct and variables | ✅ | Internal configuration naming |
| **Temporary Files** | `/tmp/nextui_exec` execution marker | ✅ | Runtime file naming |
| **Source URLs** | GitHub references in documentation | ✅ | Repository and source links |

---

## 6. **File System Structure**

Core directory and file naming conventions:

| Current Path/Name | New Path/Name | Editable? | Notes |
|-------------------|---------------|-----------|-------|
| `workspace/all/nextui/` | `workspace/all/minos/` | ✅ | Main UI module directory |
| `MinUI.pak` | `minOS.pak` | ✅ | Core system PAK |
| `MinUI.zip` | `minOS.zip` | ✅ | Installation package |
| `.minui` directories | `.minos` directories | ✅ | User data storage |
| `nextui.elf` executable | `minos.elf` executable | ✅ | Main UI binary |

---

## 7. **Documentation Files**

Documentation that requires branding updates:

| File | Content to Update | Priority |
|------|-------------------|----------|
| `README.md` | Project name, descriptions, links | High |
| `docs/*.md` | All documentation files | High |
| `skeleton/BASE/README.txt` | Installation instructions | High |
| `skeleton/EXTRAS/README.txt` | Feature descriptions | High |
| `PAKS.md` | PAK system documentation | Medium |
| `todo.txt` | Development notes | Low |

---

## 8. **Conditional Compilation & Build**

Build system elements for customization:

| Element | Current Value | Customizable? | Notes |
|---------|---------------|---------------|-------|
| Project root directory name | `NextUI/` | ✅ | Can be renamed |
| Makefile project header | `# NextUI` | ✅ | Build system branding |
| Build hash generation | Git-based versioning | ✅ | Version string customization |
| Docker container naming | `nextui-*-toolchain` | ✅ | Build environment naming |

---

## 9. **Critical System Paths**

**⚠️ Important**: These paths are used by the system and emulators. Changing them requires careful coordination:

| Path | Usage | Impact |
|------|-------|--------|
| `.minui/` | Save states, screenshots, configuration | High - affects save compatibility |
| `MinUI.pak/` | Core system launcher | High - affects boot process |
| `/tmp/nextui_exec` | Runtime execution marker | Medium - affects platform code |

---

## 🚨 **Safety Notes**

1. **Save Compatibility**: Changing `.minui` directory paths will break existing save states and user data
2. **PAK System**: Renaming `MinUI.pak` requires updating all installation and boot scripts
3. **Binary Names**: Changing executable names requires makefile and installation script updates
4. **Version Strings**: Update build system to maintain proper versioning
5. **Documentation**: Ensure all user-facing documentation reflects the new branding

---

## ✅ **Recommended Rebranding Steps**

1. **Phase 1**: Update documentation and README files
2. **Phase 2**: Replace visual assets (logos, icons, boot screens)
3. **Phase 3**: Update source code string references
4. **Phase 4**: Rename core directories and executables
5. **Phase 5**: Update build system and package naming
6. **Phase 6**: Test full build and installation process

This systematic approach ensures a complete and consistent rebranding while maintaining system functionality.
