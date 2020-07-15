# https://www.nasm.us/
# https://ftp.gnu.org/old-gnu/Manuals/ld-2.9.1/html_mono/ld.html
# http://www.godevtool.com/GolinkFrame.htm

SRC_DIR := .
SRC_SRC := $(wildcard $(SRC_DIR)/*.asm)
SRC_OBJ := $(SRC_SRC:.asm=.obj)
SRC_EXE := $(SRC_SRC:.asm=.exe)

$(SRC_DIR)/%.obj: $(SRC_DIR)/%.asm
	nasm -fwin64 -w+all $< -o $@

$(SRC_DIR)/%.exe: $(SRC_DIR)/%.obj
	ld $< -o $@ -e _main -LC:\Windows\system32 -lkernel32
#	GoLink $< /fo $@ /entry _main /console C:\Windows\system32\kernel32.dll
#	gcc $< -o $@ -LC:\Windows\system32 -lkernel32

build: ${SRC_EXE}
