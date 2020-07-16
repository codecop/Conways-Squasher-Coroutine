bits 64
default rel

%define NULL    dword 0

card_len equ    80

        section .bss

switch: resd    1                       ; module global data for SQUASHER
%define ON      dword 1
%define OFF     dword 0

i:      resd    1                       ; module global data for RDCRD and SQUASHER
card:   resb    card_len                ; module global data for RDCRD and SQUASHER

t1:     resd    1                       ; module global data for SQUASHER
t2:     resd    1                       ; module global data for SQUASHER

bytesRead: resd 1                       ; module local data for SQUASHER

out:    resd    1                       ; module global data for SQUASHER, WRITE

        section .text

; --------------------------------------------------------------------------------
SYS_READ equ    0x2000003
STDIN   equ     0

RDCRD:
        mov     rax, [i]
        cmp     rax, card_len
        jne     .exit

        mov     [i], dword 0

        ; read card into card[1:80]
		mov     rdx, card_len           ; maximum number of bytes to read
		mov     rsi, card               ; buffer to read into
		mov     rdi, STDIN              ; file descriptor
        mov     rax, SYS_READ
        syscall

.exit:
        ret

; --------------------------------------------------------------------------------
SQUASHER:
        mov     eax, [switch]
        cmp     eax, OFF
        je      .off
.on:
        mov     rax, [t2]
        mov     [out], rax

        mov     [switch], OFF
        jmp     .exit

.off:
        call    RDCRD

        mov     rsi, [i]
        xor     rax, rax
        mov     rdi, card
        mov     al, [rdi + rsi]
        mov     [t1], rax

        inc     rsi
        mov     [i], rsi

        mov     rax, [t1]               ; redundant, value still in register
        cmp     rax, '*'
        jne     .not_equal_ast

.equal_ast:
        call    RDCRD

        mov     rsi, [i]                ; redundant, value still in register
        xor     rax, rax
        mov     rdi, [card]
        mov     al, [rdi + rsi]
        mov     [t2], rax

        inc     rsi
        mov     [i], rsi

        mov     rax, [t2]               ; redundant, value still in register
        cmp     rax, '*'
        jne     .not_equal_second_ast

.equal_second_ast:
        mov     [t1], dword '^'
        jmp     .not_equal_ast

.not_equal_second_ast:
        mov     [switch], ON
        jmp     .not_equal_ast

.not_equal_ast:                         ; label 1
        mov     rax, [t1]
        mov     [out], rax

.exit:
        ret

; --------------------------------------------------------------------------------
SYS_WRITE equ   0x2000004
STDOUT  equ     1

printRbx:
        ; 1 character
        mov     rdx, 1                  ; message length
        mov     rsi, rbx                ; message to write
        mov     rdi, STDOUT             ; file descriptor
        mov     rax, SYS_WRITE
        syscall

        ret

; --------------------------------------------------------------------------------
WRITE:
.loop:
        call    SQUASHER

        ; out is output area of SQUASHER and only holds a single byte,
        ; so it can only return a single read element. The look ahead
        ; reads a second element and thus needs a switch to return the
        ; looked "ahead" element on next call.
        lea     rbx, [out]
        call    printRbx

        mov     rax, [i]
        cmp     rax, card_len
        jne     .loop

        ret

; --------------------------------------------------------------------------------
SYS_EXIT equ    0x2000001

_exitProgram:
        mov     rax, SYS_EXIT
        mov     rdi, 0                  ; return code = 0
        syscall

; --------------------------------------------------------------------------------
        global  _main

_main:
        ; set up switch
        mov     [switch], OFF

        ; set up global data
        mov     [i], dword card_len

        call    WRITE

.finished:
        jmp     _exitProgram