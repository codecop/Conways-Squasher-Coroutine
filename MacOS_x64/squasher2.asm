bits 64
default rel

card_len equ    80

        section .bss

%macro coro 2
        mov     rbx, %%_cnt
        mov     [route_%1], rbx
        jmp     %2
%%_cnt: nop
%endmacro

route_SQUASHER: resq 1                  ; storage of IP, module global data for SQUASHER
route_WRITE:    resq 1                  ; storage of IP, module global data for WRITE

i:      resq    1                       ; module global data for RDCRD and SQUASHER
card:   resb    card_len                ; module global data for RDCRD and SQUASHER

t1:     resq    1                       ; module global data for SQUASHER
t2:     resq    1                       ; module global data for SQUASHER

out:    resq    1                       ; module global data for SQUASHER, WRITE

        section .text

; --------------------------------------------------------------------------------
SYS_READ equ    0x2000003
STDIN   equ     0

RDCRD:
        mov     rax, [i]
        cmp     rax, card_len
        jne     .exit

        mov     qword [i], 0

        ; read card into card[1:80]

        mov     rdx, card_len           ; maximum number of bytes to read
        mov     rsi, card               ; buffer to read into
        mov     rdi, STDIN              ; file descriptor
        mov     rax, SYS_READ
        syscall

.exit:
        ret

; --------------------------------------------------------------------------------
; router
SQUASHER:
        jmp     [route_SQUASHER]

; coroutine
SQUASHER_CORO:                          ; label 1
        call    RDCRD

        mov     rsi, [i]
        mov     rdi, card
        xor     rax, rax
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
        mov     rdi, card
        xor     rax, rax
        mov     al, [rdi + rsi]
        mov     [t2], rax

        inc     rsi
        mov     [i], rsi

        mov     rax, [t2]               ; redundant, value still in register
        cmp     rax, '*'
        jne     .not_equal_second_ast

.equal_second_ast:
        mov     qword [t1], '^'
        jmp     .not_equal_ast

.not_equal_second_ast:
        mov     rax, [t1]
        mov     [out], rax
        coro    SQUASHER, WRITE

        mov     rax, [t2]
        mov     [out], rax
        coro    SQUASHER, WRITE

        jmp     SQUASHER_CORO

.not_equal_ast:                         ; label 2
        mov     rax, [t1]
        mov     [out], rax
        coro    SQUASHER, WRITE

        jmp     SQUASHER_CORO

; --------------------------------------------------------------------------------
SYS_WRITE equ   0x2000004
STDOUT  equ     1

printRbx:
        mov     rdx, 1                  ; message length
        mov     rsi, rbx                ; message to write
        mov     rdi, STDOUT             ; file descriptor
        mov     rax, SYS_WRITE
        syscall

        ret

; --------------------------------------------------------------------------------
; router
WRITE:
        jmp     [route_WRITE]

; coroutine
WRITE_CORO:
.loop:
        coro    WRITE, SQUASHER

        ; out is output area of SQUASHER and only holds a single byte,
        ; so it can only return a single read element. The look ahead
        ; reads a second element and thus needs a switch to return the
        ; looked "ahead" element on next call.
        mov     rbx, out
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
        ; set up coroutine routers
        mov     rbx, SQUASHER_CORO
        mov     [route_SQUASHER], rbx

        mov     rbx, WRITE_CORO
        mov     [route_WRITE], rbx

        ; set up global data
        mov     qword [i], card_len

        call    WRITE

.finished:
        jmp     _exitProgram
