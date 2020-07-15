# https://www.nasm.us/
# https://ftp.gnu.org/old-gnu/Manuals/ld-2.9.1/html_mono/ld.html
# http://www.godevtool.com/GolinkFrame.htm

SRC_DIR := .
SRC_SRC := $(wildcard $(SRC_DIR)/*.asm)
SRC_OBJ := $(SRC_SRC:.asm=.obj)
SRC_EXE := $(SRC_SRC:.asm=.exe)

$(SRC_DIR)/%.obj: $(SRC_DIR)/%.asm
	nasm -fwin32 -w+all $< -o $@

$(SRC_DIR)/%.exe: $(SRC_DIR)/%.obj
	ld $< -o $@ -e _main -lkernel32 --enable-stdcall-fixup
#   GoLink $< /fo $@ /console C:\Windows\SysWOW64\kernel32.dll

build: ${SRC_EXE}
