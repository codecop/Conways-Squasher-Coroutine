SRC_DIR := .

CC := nasm
ARCH := win32
FLAGS := -f$(ARCH) -w+all
LINK := ld

SRC_SRC := $(wildcard $(SRC_DIR)/*.asm)
SRC_OBJ := $(SRC_SRC:.asm=.o)
SRC_EXE := $(SRC_SRC:.asm=.exe)

$(SRC_DIR)/%.o: $(SRC_DIR)/%.asm
	$(CC) $(FLAGS) $< -o $@

$(SRC_DIR)/%.exe: $(SRC_DIR)/%.o
	${LINK} -o $@ $< -e_main -lkernel32 --enable-stdcall-fixup C:\Windows\SysWOW64\kernel32.dll

build: clean ${SRC_EXE}

.PHONY: clean
clean:
	- rm -f "$(SRC_DIR)/*.exe"
