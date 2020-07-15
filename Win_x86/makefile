SRC_DIR := .

# https://www.nasm.us/
# https://ftp.gnu.org/old-gnu/Manuals/ld-2.9.1/html_mono/ld.html
# http://www.godevtool.com/GolinkFrame.htm

CC := nasm
ARCH := win32
FLAGS := -f$(ARCH) -w+all
LINK := ld
# LINK := GoLink

SRC_SRC := $(wildcard $(SRC_DIR)/*.asm)
SRC_OBJ := $(SRC_SRC:.asm=.obj)
SRC_EXE := $(SRC_SRC:.asm=.exe)

$(SRC_DIR)/%.obj: $(SRC_DIR)/%.asm
	$(CC) $(FLAGS) $< -o $@

$(SRC_DIR)/%.exe: $(SRC_DIR)/%.obj
	${LINK} -o $@ $< -mi386pe -e_main -lkernel32 --enable-stdcall-fixup C:\Windows\system32\kernel32.dll
#   ${LINK} /fo $@ $< /console C:\Windows\system32\kernel32.dll

build: ${SRC_EXE}
