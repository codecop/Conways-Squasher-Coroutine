SRC_DIR := .
SRC_SRC := $(wildcard $(SRC_DIR)/*.asm)
SRC_EXE := $(SRC_SRC:.asm=)

$(SRC_DIR)/%.o: $(SRC_DIR)/%.asm
	command -v nasm || sudo apt-get install nasm
	nasm -felf64 -w+all $< -o $@

$(SRC_DIR)/%: $(SRC_DIR)/%.o
	ld $< -o $@ -e _main -m elf_x86_64

build: ${SRC_EXE}

.PHONY: test
test: ${SRC_EXE}
	command -v ./smoke || wget https://github.com/SamirTalwar/smoke/releases/download/v2.1.0/smoke-v2.1.0-Linux-x86_64 -O smoke && chmod +x ./smoke
	./smoke --command ./squasher1 ${SRC_DIR} && \
    ./smoke --command ./squasher2 ${SRC_DIR}
