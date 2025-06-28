# NextUI

# NOTE: this runs on the host system (eg. macOS) not in a docker image
# it has to, otherwise we'd be running a docker in a docker and oof

# prevent accidentally triggering a full build with invalid calls
ifneq (,$(PLATFORM))
ifeq (,$(MAKECMDGOALS))
$(error found PLATFORM arg but no target, did you mean "make PLATFORM=$(PLATFORM) shell"?)
endif
endif

ifeq (,$(PLATFORMS))
PLATFORMS = tg5040 desktop
endif

###########################################################

BUILD_HASH:=$(shell git rev-parse --short HEAD)
BUILD_BRANCH:=$(shell git rev-parse --abbrev-ref HEAD)
RELEASE_TIME:=$(shell TZ=GMT date +%Y%m%d)
ifeq ($(BUILD_BRANCH),main)
  RELEASE_BETA :=
else
  RELEASE_BETA := -$(BUILD_BRANCH)
endif
ifeq ($(PLATFORM), desktop)
	TOOLCHAIN_FILE := makefile.native
else
	TOOLCHAIN_FILE := makefile.toolchain
endif
RELEASE_BASE=NextUI-$(RELEASE_TIME)$(RELEASE_BETA)
RELEASE_DOT:=$(shell find ./releases/. -regex ".*/${RELEASE_BASE}-[0-9]+-base\.zip" | wc -l | sed 's/ //g')
RELEASE_NAME ?= $(RELEASE_BASE)-$(RELEASE_DOT)

###########################################################

.PHONY: build

export MAKEFLAGS=--no-print-directory

all: setup $(PLATFORMS) special package done
	
shell:
	make -f $(TOOLCHAIN_FILE) PLATFORM=$(PLATFORM)

name: 
	@echo $(RELEASE_NAME)

build:
	# ----------------------------------------------------
	make build -f $(TOOLCHAIN_FILE) PLATFORM=$(PLATFORM) COMPILE_CORES=$(COMPILE_CORES)
	# ----------------------------------------------------

build-cores:
	make build-cores -f $(TOOLCHAIN_FILE) PLATFORM=$(PLATFORM) COMPILE_CORES=true
	# ----------------------------------------------------

cores-json:
	@cat workspace/$(PLATFORM)/cores/makefile | grep ^CORES | cut -d' ' -f2 | jq  --raw-input .  | jq --slurp -cM .

build-core:
ifndef CORE
	$(error CORE is not set)
endif
	make build-core -f $(TOOLCHAIN_FILE) PLATFORM=$(PLATFORM) COMPILE_CORES=true CORE=$(CORE)

system:
	make -f ./workspace/$(PLATFORM)/platform/makefile.copy PLATFORM=$(PLATFORM)
	
	# populate system
ifneq ($(PLATFORM), desktop)
	cp ./workspace/$(PLATFORM)/keymon/keymon.elf ./build/SYSTEM/$(PLATFORM)/bin/
	cp ./workspace/all/syncsettings/build/$(PLATFORM)/syncsettings.elf ./build/SYSTEM/$(PLATFORM)/bin/
endif
	cp ./workspace/$(PLATFORM)/libmsettings/libmsettings.so ./build/SYSTEM/$(PLATFORM)/lib
	cp ./workspace/all/nextui/build/$(PLATFORM)/nextui.elf ./build/SYSTEM/$(PLATFORM)/bin/
	cp ./workspace/all/minarch/build/$(PLATFORM)/minarch.elf ./build/SYSTEM/$(PLATFORM)/bin/
	cp ./workspace/all/nextval/build/$(PLATFORM)/nextval.elf ./build/SYSTEM/$(PLATFORM)/bin/
	cp ./workspace/all/clock/build/$(PLATFORM)/clock.elf ./build/EXTRAS/Tools/$(PLATFORM)/Clock.pak/
	cp ./workspace/all/minput/build/$(PLATFORM)/minput.elf ./build/EXTRAS/Tools/$(PLATFORM)/Input.pak/

	# battery tracking
	cp ./workspace/all/libbatmondb/build/$(PLATFORM)/libbatmondb.so ./build/SYSTEM/$(PLATFORM)/lib
	cp ./workspace/all/batmon/build/$(PLATFORM)/batmon.elf ./build/SYSTEM/$(PLATFORM)/bin/
	cp ./workspace/all/battery/build/$(PLATFORM)/battery.elf ./build/EXTRAS/Tools/$(PLATFORM)/Battery.pak/

	# game time tracking
	cp ./workspace/all/libgametimedb/build/$(PLATFORM)/libgametimedb.so ./build/SYSTEM/$(PLATFORM)/lib
	cp ./workspace/all/gametimectl/build/$(PLATFORM)/gametimectl.elf ./build/SYSTEM/$(PLATFORM)/bin/
	cp ./workspace/all/gametime/build/$(PLATFORM)/gametime.elf ./build/EXTRAS/Tools/$(PLATFORM)/Game\ Tracker.pak/
  
	cp ./workspace/all/settings/build/$(PLATFORM)/settings.elf ./build/EXTRAS/Tools/$(PLATFORM)/Settings.pak/
ifeq ($(PLATFORM), tg5040)
	cp ./workspace/all/ledcontrol/build/$(PLATFORM)/ledcontrol.elf ./build/EXTRAS/Tools/$(PLATFORM)/LedControl.pak/
	cp ./workspace/all/bootlogo/build/$(PLATFORM)/bootlogo.elf ./build/EXTRAS/Tools/$(PLATFORM)/Bootlogo.pak/
	
	# lib dependencies
	cp ./workspace/all/minarch/build/$(PLATFORM)/libsamplerate.* ./build/SYSTEM/$(PLATFORM)/lib/
	# This is a bandaid fix, needs to be cleaned up if/when we expand to other platforms.
	cp ./workspace/all/minarch/build/$(PLATFORM)/libzip.* ./build/SYSTEM/$(PLATFORM)/lib/
	cp ./workspace/all/minarch/build/$(PLATFORM)/libbz2.* ./build/SYSTEM/$(PLATFORM)/lib/
	cp ./workspace/all/minarch/build/$(PLATFORM)/liblzma.* ./build/SYSTEM/$(PLATFORM)/lib/
	cp ./workspace/all/minarch/build/$(PLATFORM)/libzstd.* ./build/SYSTEM/$(PLATFORM)/lib/
endif


ifeq ($(PLATFORM), desktop)
cores:
	# stock cores
	# cp ./workspace/$(PLATFORM)/cores/output/gambatte_libretro.so ./build/SYSTEM/$(PLATFORM)/cores
else
cores: # TODO: can't assume every platform will have the same stock cores (platform should be responsible for copy too)
	# stock cores
	@echo "Checking for cores in ./workspace/$(PLATFORM)/cores/output/"
	@if [ -f ./workspace/$(PLATFORM)/cores/output/fceumm_libretro.so ]; then \
		cp ./workspace/$(PLATFORM)/cores/output/fceumm_libretro.so ./build/SYSTEM/$(PLATFORM)/cores; \
	else \
		echo "Warning: fceumm_libretro.so not found, skipping"; \
	fi
	@if [ -f ./workspace/$(PLATFORM)/cores/output/gambatte_libretro.so ]; then \
		cp ./workspace/$(PLATFORM)/cores/output/gambatte_libretro.so ./build/SYSTEM/$(PLATFORM)/cores; \
	else \
		echo "Warning: gambatte_libretro.so not found, skipping"; \
	fi
	@if [ -f ./workspace/$(PLATFORM)/cores/output/gpsp_libretro.so ]; then \
		cp ./workspace/$(PLATFORM)/cores/output/gpsp_libretro.so ./build/SYSTEM/$(PLATFORM)/cores; \
	else \
		echo "Warning: gpsp_libretro.so not found, skipping"; \
	fi
	@if [ -f ./workspace/$(PLATFORM)/cores/output/picodrive_libretro.so ]; then \
		cp ./workspace/$(PLATFORM)/cores/output/picodrive_libretro.so ./build/SYSTEM/$(PLATFORM)/cores; \
	else \
		echo "Warning: picodrive_libretro.so not found, skipping"; \
	fi
	@if [ -f ./workspace/$(PLATFORM)/cores/output/snes9x_libretro.so ]; then \
		cp ./workspace/$(PLATFORM)/cores/output/snes9x_libretro.so ./build/SYSTEM/$(PLATFORM)/cores; \
	else \
		echo "Warning: snes9x_libretro.so not found, skipping"; \
	fi
	@if [ -f ./workspace/$(PLATFORM)/cores/output/pcsx_rearmed_libretro.so ]; then \
		cp ./workspace/$(PLATFORM)/cores/output/pcsx_rearmed_libretro.so ./build/SYSTEM/$(PLATFORM)/cores; \
	else \
		echo "Warning: pcsx_rearmed_libretro.so not found, skipping"; \
	fi
	
	# extras - checking if files exist before copying
	@if [ -f ./workspace/$(PLATFORM)/cores/output/fake08_libretro.so ]; then \
		cp ./workspace/$(PLATFORM)/cores/output/fake08_libretro.so ./build/EXTRAS/Emus/$(PLATFORM)/P8.pak; \
	else \
		echo "Warning: fake08_libretro.so not found, skipping"; \
	fi
	@if [ -f ./workspace/$(PLATFORM)/cores/output/mgba_libretro.so ]; then \
		cp ./workspace/$(PLATFORM)/cores/output/mgba_libretro.so ./build/EXTRAS/Emus/$(PLATFORM)/MGBA.pak; \
		cp ./workspace/$(PLATFORM)/cores/output/mgba_libretro.so ./build/EXTRAS/Emus/$(PLATFORM)/SGB.pak; \
	else \
		echo "Warning: mgba_libretro.so not found, skipping"; \
	fi
	@if [ -f ./workspace/$(PLATFORM)/cores/output/mednafen_pce_fast_libretro.so ]; then \
		cp ./workspace/$(PLATFORM)/cores/output/mednafen_pce_fast_libretro.so ./build/EXTRAS/Emus/$(PLATFORM)/PCE.pak; \
	else \
		echo "Warning: mednafen_pce_fast_libretro.so not found, skipping"; \
	fi
	@if [ -f ./workspace/$(PLATFORM)/cores/output/pokemini_libretro.so ]; then \
		cp ./workspace/$(PLATFORM)/cores/output/pokemini_libretro.so ./build/EXTRAS/Emus/$(PLATFORM)/PKM.pak; \
	else \
		echo "Warning: pokemini_libretro.so not found, skipping"; \
	fi
	@if [ -f ./workspace/$(PLATFORM)/cores/output/race_libretro.so ]; then \
		cp ./workspace/$(PLATFORM)/cores/output/race_libretro.so ./build/EXTRAS/Emus/$(PLATFORM)/NGP.pak; \
		cp ./workspace/$(PLATFORM)/cores/output/race_libretro.so ./build/EXTRAS/Emus/$(PLATFORM)/NGPC.pak; \
	else \
		echo "Warning: race_libretro.so not found, skipping"; \
	fi
	@if [ -f ./workspace/$(PLATFORM)/cores/output/fbneo_libretro.so ]; then \
		cp ./workspace/$(PLATFORM)/cores/output/fbneo_libretro.so ./build/EXTRAS/Emus/$(PLATFORM)/FBN.pak; \
	else \
		echo "Warning: fbneo_libretro.so not found, skipping"; \
	fi
	@if [ -f ./workspace/$(PLATFORM)/cores/output/mednafen_supafaust_libretro.so ]; then \
		cp ./workspace/$(PLATFORM)/cores/output/mednafen_supafaust_libretro.so ./build/EXTRAS/Emus/$(PLATFORM)/SUPA.pak; \
	else \
		echo "Warning: mednafen_supafaust_libretro.so not found, skipping"; \
	fi
	@if [ -f ./workspace/$(PLATFORM)/cores/output/mednafen_vb_libretro.so ]; then \
		cp ./workspace/$(PLATFORM)/cores/output/mednafen_vb_libretro.so ./build/EXTRAS/Emus/$(PLATFORM)/VB.pak; \
	else \
		echo "Warning: mednafen_vb_libretro.so not found, skipping"; \
	fi
	@if [ -f ./workspace/$(PLATFORM)/cores/output/cap32_libretro.so ]; then \
		cp ./workspace/$(PLATFORM)/cores/output/cap32_libretro.so ./build/EXTRAS/Emus/$(PLATFORM)/CPC.pak; \
	else \
		echo "Warning: cap32_libretro.so not found, skipping"; \
	fi
	@if [ -f ./workspace/$(PLATFORM)/cores/output/puae2021_libretro.so ]; then \
		cp ./workspace/$(PLATFORM)/cores/output/puae2021_libretro.so ./build/EXTRAS/Emus/$(PLATFORM)/PUAE.pak; \
	else \
		echo "Warning: puae2021_libretro.so not found, skipping"; \
	fi
	@if [ -f ./workspace/$(PLATFORM)/cores/output/prboom_libretro.so ]; then \
		cp ./workspace/$(PLATFORM)/cores/output/prboom_libretro.so ./build/EXTRAS/Emus/$(PLATFORM)/PRBOOM.pak; \
	else \
		echo "Warning: prboom_libretro.so not found, skipping"; \
	fi
	@if [ -f ./workspace/$(PLATFORM)/cores/output/vice_x64_libretro.so ]; then \
		cp ./workspace/$(PLATFORM)/cores/output/vice_x64_libretro.so ./build/EXTRAS/Emus/$(PLATFORM)/C64.pak; \
	else \
		echo "Warning: vice_x64_libretro.so not found, skipping"; \
	fi
	@if [ -f ./workspace/$(PLATFORM)/cores/output/vice_x128_libretro.so ]; then \
		cp ./workspace/$(PLATFORM)/cores/output/vice_x128_libretro.so ./build/EXTRAS/Emus/$(PLATFORM)/C128.pak; \
	else \
		echo "Warning: vice_x128_libretro.so not found, skipping"; \
	fi
	@if [ -f ./workspace/$(PLATFORM)/cores/output/vice_xplus4_libretro.so ]; then \
		cp ./workspace/$(PLATFORM)/cores/output/vice_xplus4_libretro.so ./build/EXTRAS/Emus/$(PLATFORM)/PLUS4.pak; \
	else \
		echo "Warning: vice_xplus4_libretro.so not found, skipping"; \
	fi
	@if [ -f ./workspace/$(PLATFORM)/cores/output/vice_xpet_libretro.so ]; then \
		cp ./workspace/$(PLATFORM)/cores/output/vice_xpet_libretro.so ./build/EXTRAS/Emus/$(PLATFORM)/PET.pak; \
	else \
		echo "Warning: vice_xpet_libretro.so not found, skipping"; \
	fi
	@if [ -f ./workspace/$(PLATFORM)/cores/output/vice_xvic_libretro.so ]; then \
		cp ./workspace/$(PLATFORM)/cores/output/vice_xvic_libretro.so ./build/EXTRAS/Emus/$(PLATFORM)/VIC.pak; \
	else \
		echo "Warning: vice_xvic_libretro.so not found, skipping"; \
	fi
endif

common: build system cores
	
clean:
	rm -rf ./build
	make clean -f $(TOOLCHAIN_FILE) PLATFORM=$(PLATFORM) COMPILE_CORES=$(COMPILE_CORES)

setup: name
	# ----------------------------------------------------
	# make sure we're running in an input device
	tty -s || echo "No tty detected"
	
	# ready fresh build
	rm -rf ./build
	mkdir -p ./releases
	cp -R ./skeleton ./build
	
	# remove authoring detritus
	cd ./build && find . -type f -name '.keep' -delete
	cd ./build && find . -type f -name '*.meta' -delete
	echo $(BUILD_HASH) > ./workspace/hash.txt
	
	# copy readmes to workspace so we can use Linux fmt instead of host's
	mkdir -p ./workspace/readmes
	cp ./skeleton/BASE/README.txt ./workspace/readmes/BASE-in.txt
	cp ./skeleton/EXTRAS/README.txt ./workspace/readmes/EXTRAS-in.txt
	
done:
	say "done" 2>/dev/null || true

special:
	# setup trimui family .tmp_update in BOOT
	mv ./build/BOOT/common ./build/BOOT/.tmp_update
	mv ./build/BOOT/trimui ./build/BASE/
	cp -R ./build/BOOT/.tmp_update ./build/BASE/trimui/app/

tidy:
	rm -f releases/$(RELEASE_NAME)-base.zip 
	rm -f releases/$(RELEASE_NAME)-extras.zip
	rm -f releases/$(RELEASE_NAME)-all.zip

package: tidy
	# ----------------------------------------------------
	# zip up build
		
	# move formatted readmes from workspace to build
	cp ./workspace/readmes/BASE-out.txt ./build/BASE/README.txt
	cp ./workspace/readmes/EXTRAS-out.txt ./build/EXTRAS/README.txt
	rm -rf ./workspace/readmes
	
	cd ./build/SYSTEM && echo "$(RELEASE_NAME)\n$(BUILD_HASH)" > version.txt
	# ./commits.sh > ./build/SYSTEM/commits.txt
	cd ./build && find . -type f -name '.DS_Store' -delete
	mkdir -p ./build/PAYLOAD
	mv ./build/SYSTEM ./build/PAYLOAD/.system
	cp -R ./build/BOOT/.tmp_update ./build/PAYLOAD/
	cp -R ./build/EXTRAS/Tools ./build/PAYLOAD/
	
	cd ./build/PAYLOAD && zip -r MinUI.zip .system .tmp_update Tools
	mv ./build/PAYLOAD/MinUI.zip ./build/BASE
	
	# TODO: can I just add everything in BASE to zip?
	cd ./build/BASE && zip -r ../../releases/$(RELEASE_NAME)-base.zip Bios Roms Saves Shaders trimui em_ui.sh MinUI.zip README.txt
	cd ./build/EXTRAS && zip -r ../../releases/$(RELEASE_NAME)-extras.zip Bios Emus Roms Saves Shaders Tools README.txt
	echo "$(RELEASE_VERSION)" > ./build/latest.txt

	# compound zip (brew install libzip needed) 
	cd ./releases && zipmerge $(RELEASE_NAME)-all.zip $(RELEASE_NAME)-base.zip  && zipmerge $(RELEASE_NAME)-all.zip $(RELEASE_NAME)-extras.zip
	
###########################################################

.DEFAULT:
	# ----------------------------------------------------
	# $@
	@echo "$(PLATFORMS)" | grep -q "\b$@\b" && (make common PLATFORM=$@) || (exit 1)

build-essential-cores:
	# Build only essential, stable cores
	make build-core PLATFORM=$(PLATFORM) CORE=fceumm || echo "Warning: fceumm failed"
	make build-core PLATFORM=$(PLATFORM) CORE=gambatte || echo "Warning: gambatte failed"
	make build-core PLATFORM=$(PLATFORM) CORE=gpsp || echo "Warning: gpsp failed"
	make build-core PLATFORM=$(PLATFORM) CORE=picodrive || echo "Warning: picodrive failed"
	make build-core PLATFORM=$(PLATFORM) CORE=snes9x || echo "Warning: snes9x failed"
	make build-core PLATFORM=$(PLATFORM) CORE=mgba || echo "Warning: mgba failed"
	
build-all-safe:
	# Build everything with safe error handling
	@echo "Building NextUI with essential cores..."
	make build PLATFORM=$(PLATFORM)
	make build-essential-cores PLATFORM=$(PLATFORM)
	make system PLATFORM=$(PLATFORM)
	make cores PLATFORM=$(PLATFORM)
	@echo "Build completed!"

full-build:
	# Complete build process from start to finish
	make setup
	make build-all-safe PLATFORM=$(PLATFORM)
	make special
	make package
	make done

build-stable-cores:
	# Skip known problematic cores like fake-08
	@echo "Building stable cores only..."
	@$(foreach core,fceumm gambatte gpsp picodrive snes9x mgba pcsx_rearmed mednafen_pce_fast pokemini race mednafen_vb, \
		echo "Building $(core)..." && \
		(make build-core PLATFORM=$(PLATFORM) CORE=$(core) || echo "Warning: $(core) failed, continuing...") && )
	@echo "Stable cores build completed"

