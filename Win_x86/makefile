SRC_DIR := .
SRC_SRC := $(wildcard $(SRC_DIR)/*.asm)
SRC_EXE := $(SRC_SRC:.asm=.exe)

$(SRC_DIR)/%.obj: $(SRC_DIR)/%.asm
	nasm -fwin32 -w+all $< -o $@

$(SRC_DIR)/%.exe: $(SRC_DIR)/%.obj
	cmd //C "GoLink /ni /fo $@ $< /entry _main /console kernel32.dll"
#	ld $< -o $@ -e _main -L "$(LIBRARY_PATH)" -lkernel32
#	gcc $< -o $@

build: ${SRC_EXE}

.PHONY: test
test: ${SRC_EXE}
	cmd //C "smoke2 ${SRC_DIR}"
