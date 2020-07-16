# https://www.nasm.us/
# https://ftp.gnu.org/old-gnu/Manuals/ld-2.9.1/html_mono/ld.html

SRC_DIR := .
SRC_SRC := $(wildcard $(SRC_DIR)/*.asm)
SRC_EXE := $(SRC_SRC:.asm=.exe)

$(SRC_DIR)/%.obj: $(SRC_DIR)/%.asm
	nasm -fwin64 -w+all $< -o $@

$(SRC_DIR)/%.exe: $(SRC_DIR)/%.obj
	ld $< -o $@ -e _main -L "$(LIBRARY_PATH)" -lkernel32
#	gcc $< -o $@

build: ${SRC_EXE}
