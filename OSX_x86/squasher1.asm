bits 32

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
SYS_READ equ    3
STDIN   equ     2

RDCRD:
        mov     eax, [i]
        cmp     eax, card_len
        jne     .exit

        mov     [i], dword 0

        ; read card into card[1:80]

        push    dword card_len          ; message length
        push    dword card              ; message to write
        push    dword STDIN             ; file descriptor
        mov     eax, SYS_READ
        sub     esp, 4                  ; OS X (and BSD) system calls needs "extra space" on stack
        int     0x80
        add     esp, 16

.exit:
        ret

; --------------------------------------------------------------------------------
SQUASHER:
        mov     eax, [switch]
        cmp     eax, OFF
        je      .off
.on:
        mov     eax, [t2]
        mov     [out], eax

        mov     [switch], OFF
        jmp     .exit

.off:
        call    RDCRD

        mov     esi, [i]
        xor     eax, eax
        mov     al, [card + esi]
        mov     [t1], eax

        inc     esi
        mov     [i], esi

        mov     eax, [t1]               ; redundant, value still in register
        cmp     eax, '*'
        jne     .not_equal_ast

.equal_ast:
        call    RDCRD

        mov     esi, [i]                ; redundant, value still in register
        xor     eax, eax
        mov     al, [card + esi]
        mov     [t2], eax

        inc     esi
        mov     [i], esi

        mov     eax, [t2]               ; redundant, value still in register
        cmp     eax, '*'
        jne     .not_equal_second_ast

.equal_second_ast:
        mov     [t1], dword '^'
        jmp     .not_equal_ast

.not_equal_second_ast:
        mov     [switch], ON
        jmp     .not_equal_ast

.not_equal_ast:                         ; label 1
        mov     eax, [t1]
        mov     [out], eax

.exit:
        ret

; --------------------------------------------------------------------------------
SYS_WRITE equ   4
STDOUT  equ     1

printEbx:
        ; 1 character
        push    dword 1                 ; message length
        push    ebx                     ; message to write
        push    dword STDOUT            ; file descriptor
        mov     eax, SYS_WRITE
        sub     esp, 4                  ; OS X (and BSD) system calls needs "extra space" on stack
        int     0x80
        add     esp, 16

        ret

; --------------------------------------------------------------------------------
WRITE:
.loop:
        call    SQUASHER

        ; out is output area of SQUASHER and only holds a single byte,
        ; so it can only return a single read element. The look ahead
        ; reads a second element and thus needs a switch to return the
        ; looked "ahead" element on next call.
        lea     ebx, [out]
        call    printEbx

        mov     eax, [i]
        cmp     eax, card_len
        jne     .loop

        ret

; --------------------------------------------------------------------------------
SYS_EXIT equ    1

_exitProgram:
        mov     eax, SYS_EXIT
        mov     ebx, 0                  ; return code = 0
        int     0x80
        hlt                             ; never here

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
