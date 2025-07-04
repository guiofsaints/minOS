###########################################################

ifeq (,$(PLATFORM))
PLATFORM=$(UNION_PLATFORM)
endif

ifeq (,$(PLATFORM))
	$(error please specify PLATFORM, eg. PLATFORM=trimui make)
endif

ifeq (,$(CROSS_COMPILE))
	$(error missing CROSS_COMPILE for this toolchain)
endif

###########################################################

include ../../$(PLATFORM)/platform/makefile.env
SDL?=SDL

###########################################################

TARGET = minarch
PRODUCT= build/$(PLATFORM)/$(TARGET).elf
INCDIR = -I. -I./libretro-common/include/ -I../common/ -I../../$(PLATFORM)/platform/
SOURCE = $(TARGET).c ../common/scaler.c ../common/utils.c ../common/config.c ../common/api.c ../../$(PLATFORM)/platform/platform.c

CC = $(CROSS_COMPILE)gcc
CFLAGS  += $(ARCH) -fomit-frame-pointer
CFLAGS  += $(INCDIR) -DPLATFORM=\"$(PLATFORM)\" -std=gnu99

# Performance optimizations
CFLAGS  += -O3 -march=native -mtune=native
CFLAGS  += -ffast-math -funroll-loops -finline-functions
CFLAGS  += -fno-strict-aliasing -Wno-unused-result
CFLAGS  += -DPREFETCH_ENABLE

# Enable specific optimizations for video processing
ifdef ENABLE_SIMD
	CFLAGS += -msse2 -msse3 -mssse3 -msse4.1
endif

LDFLAGS	 += -lmsettings -lsamplerate
# TrimUI Brick only - use libretro-common and libsrm
LDFLAGS	 +=  -Llibretro-common -lsrm -lzip
CFLAGS   += -DHAS_SRM
# CFLAGS  += -Wall -Wno-unused-variable -Wno-unused-function -Wno-format-overflow
# CFLAGS  += -fsanitize=address -fno-common
# LDFLAGS += -lasan

AR=$(CROSS_COMPILE)ar
ARFLAGS=rc

BUILD_DATE!=date +%Y.%m.%d
BUILD_HASH!=cat ../../hash.txt
CFLAGS += -DBUILD_DATE=\"${BUILD_DATE}\" -DBUILD_HASH=\"${BUILD_HASH}\"

# TrimUI Brick only build
all: libretro-common libsrm.a $(PREFIX_LOCAL)/include/msettings.h
	mkdir -p build/$(PLATFORM)
	cp /usr/lib/aarch64-linux-gnu/libsamplerate.so.0 build/$(PLATFORM)
	# This is a bandaid fix, needs to be cleaned up if/when we expand to other platforms.
	cp /usr/local/lib/libzip.so.5 build/$(PLATFORM)
	cp /lib/aarch64-linux-gnu/libbz2.so.1.0 build/$(PLATFORM)
	cp /lib/aarch64-linux-gnu/liblzma.so.5 build/$(PLATFORM)
	cp /usr/lib/aarch64-linux-gnu/libzstd.so.1 build/$(PLATFORM)
	$(CC) $(SOURCE) -o $(PRODUCT) $(CFLAGS) $(LDFLAGS)
endif

libretro-common:
	git clone https://github.com/libretro/libretro-common
	
$(PREFIX_LOCAL)/include/msettings.h:
	cd ../../$(PLATFORM)/libmsettings && make

### libsrm stuff
OBJECTS = streams/rzip_stream.o streams/file_stream.o vfs/vfs_implementation.o file/file_path.o file/file_path_io.o compat/compat_strl.o time/rtime.o string/stdstring.o encodings/encoding_utf.o streams/trans_stream.o streams/trans_stream_pipe.o streams/trans_stream_zlib.o

$(OBJECTS) : 
	cd libretro-common && $(CC) $(CFLAGS) -DHAVE_ZLIB -c -o $@ $(subst .o,.c,$@) -I include/

libsrm.a: $(OBJECTS)
	cd libretro-common && $(AR) $(ARFLAGS) $@ $?

clean:
	rm -f $(PRODUCT)
	rm -f $(OBJECTS) $(LIBRARY)