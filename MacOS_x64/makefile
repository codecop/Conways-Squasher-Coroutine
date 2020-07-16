SRC_DIR := .
SRC_SRC := $(wildcard $(SRC_DIR)/*.asm)
SRC_EXE := $(SRC_SRC:.asm=)

$(SRC_DIR)/%.o: $(SRC_DIR)/%.asm
	nasm -fmacho64 -w+all $< -o $@

$(SRC_DIR)/%: $(SRC_DIR)/%.o
	ld $< -o $@ -e _main -lSystem -no_pie -macosx_version_min 10.9

build: ${SRC_EXE}

.PHONY: test
test: ${SRC_EXE}
	~/smoke-v2.1.0-Darwin-x86_64 ${SRC_DIR}
