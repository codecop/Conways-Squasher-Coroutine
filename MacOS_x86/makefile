SRC_DIR := .

CC := nasm
ARCH := macho32
FLAGS := -f$(ARCH) -w+all
LINK := ld

SRC_SRC := $(wildcard $(SRC_DIR)/*.asm)
SRC_OBJ := $(SRC_SRC:.asm=.o)
SRC_EXE := $(SRC_SRC:.asm=.exe)

$(SRC_DIR)/%.o: $(SRC_DIR)/%.asm
	$(CC) $(FLAGS) $< -o $@

$(SRC_DIR)/%.exe: $(SRC_DIR)/%.o
	${LINK} -o $@ $< -e _main -lSystem -no_pie -macosx_version_min 10.9

build: clean ${SRC_EXE}

.PHONY: clean
clean:
	- rm -f $(SRC_DIR)/*.exe
