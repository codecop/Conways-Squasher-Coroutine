SRC_DIR := .
SRC_SRC := $(wildcard $(SRC_DIR)/*.asm)
SRC_EXE := $(SRC_SRC:.asm=)

$(SRC_DIR)/%.o: $(SRC_DIR)/%.asm
	command -v nasm || brew install nasm
	nasm -fmacho64 -w+all $< -o $@

$(SRC_DIR)/%: $(SRC_DIR)/%.o
	ld $< -o $@ -e _main -lSystem -no_pie

build: ${SRC_EXE}

.PHONY: test
test: ${SRC_EXE}
	command -v ./smoke || curl -L https://github.com/SamirTalwar/smoke/releases/download/v2.1.0/smoke-v2.1.0-Darwin-x86_64 -o smoke && chmod +x ./smoke
	./smoke --command ./squasher1 ${SRC_DIR} && \
    ./smoke --command ./squasher2 ${SRC_DIR}
