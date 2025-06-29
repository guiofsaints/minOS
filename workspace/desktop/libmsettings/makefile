ifeq (,$(CROSS_COMPILE))
$(error missing CROSS_COMPILE for this toolchain)
endif
ifeq (,$(PREFIX))
$(error missing PREFIX for this toolchain)
endif

TARGET=msettings

.PHONY: build
.PHONY: clean

CC = $(CROSS_COMPILE)gcc

CFLAGS = 
#LDFLAGS = -ldl -lrt -s
LDFLAGS = -ldl

OPTM=-Ofast

build: 
	$(CC) -c -Werror -fpic "$(TARGET).c" $(CFLAGS) -Wl,--no-as-needed $(LDFLAGS)
	$(CC) -shared -o "lib$(TARGET).so" "$(TARGET).o" $(LDFLAGS)
	mkdir -p "build/$(PLATFORM)/include"
	mkdir -p "build/$(PLATFORM)/lib"
	cp "$(TARGET).h" "build/$(PLATFORM)/include"
	cp "lib$(TARGET).so" "build/$(PLATFORM)/lib"

clean:
	rm -f *.o
	rm -f "lib$(TARGET).so"
	rm -rf build/