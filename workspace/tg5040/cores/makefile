CORES= fceumm
CORES+= gambatte
CORES+= gpsp
CORES+= libretro-cap32
CORES+= libretro-uae
CORES+= mednafen_pce_fast
CORES+= mednafen_supafaust
CORES+= mednafen_vb
CORES+= mgba
CORES+= pcsx_rearmed
CORES+= picodrive
CORES+= pokemini
CORES+= race
CORES+= snes9x
CORES+= prboom

###############################

# optional core vars
# *_REPO=
# *_HASH=
# *_CORE=
# *_FLAGS=
# *_MAKEFILE=
# *_BUILD_PATH=
# *_SUBMODULES=

mednafen_pce_fast_REPO = https://github.com/libretro/beetle-pce-fast-libretro
mednafen_vb_REPO = https://github.com/libretro/beetle-vb-libretro

fceumm_REPO = https://github.com/libretro/libretro-fceumm

gambatte_REPO = https://github.com/libretro/gambatte-libretro

mednafen_supafaust_REPO = https://github.com/libretro/supafaust

pcsx_rearmed_MAKEFILE = Makefile.libretro
# pcsx has a disabled submodule for gnulib, which takes forever to check out and is unused - skil checkout
pcsx_rearmed_SUBMODULES = frontend/libpicofe

picodrive_REPO = https://github.com/irixxxx/picodrive
picodrive_MAKEFILE = Makefile.libretro
# No background Audio on Sega CD
# https://github.com/guiofsaints/minOS/issues/68
picodrive_HASH = b0be121

pokemini_REPO = https://github.com/libretro/PokeMini
pokemini_MAKEFILE = Makefile.libretro
# Our patchfile doesn't work on latest Pokemon mini commits, pinning to last working hash for now
pokemini_HASH = 78656d4

prboom_REPO = https://github.com/libretro/libretro-prboom

snes9x2005_plus_REPO = https://github.com/libretro/snes9x2005
snes9x2005_plus_FLAGS = USE_BLARGG_APU=1

snes9x_REPO = https://github.com/libretro/snes9x
snes9x_CORE = snes9x_libretro.so
snes9x_BUILD_PATH = snes9x/libretro

libretro-uae_REPO = https://github.com/libretro/libretro-uae
libretro-uae_HASH = 2.6.1
libretro-uae_CORE = puae2021_libretro.so

libretro-cap32_REPO = https://github.com/libretro/libretro-cap32
libretro-cap32_CORE = cap32_libretro.so

###############################

include ../../all/cores/makefile
