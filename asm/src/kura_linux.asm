; Kyto kura - x86-64 Linux ELF (NASM) entry point

bits 64
default rel

%include "inc/const.inc"

%define SYS_exit 60

section .data
    proc_self_exe   db "/proc/self/exe", 0
    local_dir       db "/.local", 0
    bin_dir         db "/bin", 0
    kura_name       db "/kura", 0
    msg_installed   db "installed kura -> ", 0
    msg_nl          db 10, 0
    spc_chr         db " ", 0

section .bss
global kyto_environ_ptr
kyto_environ_ptr:   resq 1
global cmdline_rest
cmdline_rest:       resq 1
cmdline_buf:        resb 2048
path_buf:   resb PATH_MAX
home_buf:   resb PATH_MAX
self_path:  resb PATH_MAX

%define KYTO_LINUX 1
%include "str.asm"
%include "linux_io.asm"
%include "config.asm"
%include "toml_min.asm"
%include "emit_env.asm"
%include "emit_users.asm"
%include "emit_deploy.asm"
%include "cmd_init.asm"
%include "crypto.asm"
%include "cmd_crypto.asm"
%include "lexer.asm"
%include "parse_util.asm"
%include "kyto_eval.asm"
%include "kyto_compile.asm"
%include "inc/kura_cmds.asm"

section .text
global _start

_start:
    mov     r15, rsp
    mov     eax, [r15]
    lea     rbx, [r15]
    add     rax, 2
    shl     rax, 3
    add     rbx, rax
    mov     [kyto_environ_ptr], rbx
    push    rbx
    mov     ebx, [r15]
    cmp     ebx, 3
    jl      .no_rest
    mov     esi, 2
    lea     rcx, [cmdline_buf]
    mov     rdx, [r15 + 8 + rsi * 8]
    call    strcpy
    inc     esi
.rest_loop:
    cmp     esi, ebx
    jge     .rest_done
    lea     rcx, [cmdline_buf]
    lea     rdx, [spc_chr]
    call    strcat
    lea     rcx, [cmdline_buf]
    mov     rdx, [r15 + 8 + rsi * 8]
    call    strcat
    inc     esi
    jmp     .rest_loop
.rest_done:
    lea     rax, [cmdline_buf]
    mov     [cmdline_rest], rax
    jmp     .dispatch
.no_rest:
    mov     qword [cmdline_rest], 0
.dispatch:
    pop     rbx
    mov     rcx, [rsp + 16]
    call    dispatch_argv
    mov     rdi, rax
    mov     rax, SYS_exit
    syscall

global cmd_install
cmd_install:
    push    rbx
    mov     rax, 89
    lea     rdi, [proc_self_exe]
    lea     rsi, [self_path]
    mov     rdx, PATH_MAX - 1
    syscall
    cmp     rax, 0
    jle     .fail
    mov     byte [self_path + rax], 0
    call    find_home
    test    rax, rax
    jz      .fail
    lea     rcx, [path_buf]
    lea     rdx, [home_buf]
    call    strcpy
    lea     rcx, [path_buf]
    lea     rdx, [local_dir]
    call    strcat
    lea     rcx, [path_buf]
    call    ensure_dir
    lea     rcx, [path_buf]
    lea     rdx, [bin_dir]
    call    strcat
    lea     rcx, [path_buf]
    call    ensure_dir
    lea     rcx, [path_buf]
    lea     rdx, [kura_name]
    call    strcat
    lea     rcx, [self_path]
    lea     rdx, [path_buf]
    call    copy_file_path
    lea     rcx, [msg_installed]
    call    print_str
    lea     rcx, [path_buf]
    call    print_str
    lea     rcx, [msg_nl]
    call    print_str
    xor     eax, eax
    jmp     .done
.fail:
    mov     eax, 1
.done:
    pop     rbx
    ret

; rax=1 if home_buf filled from environ
global find_home
find_home:
    push    rbx
    mov     rbx, [kyto_environ_ptr]
    test    rbx, rbx
    jz      .none
.env:
    mov     rsi, [rbx]
    test    rsi, rsi
    jz      .none
    cmp     dword [rsi], 'HOME'
    jne     .next
    cmp     byte [rsi + 4], '='
    jne     .next
    lea     rdx, [rsi + 5]
    lea     rcx, [home_buf]
    call    strcpy
    mov     rax, 1
    jmp     .done
.next:
    add     rbx, 8
    jmp     .env
.none:
    xor     rax, rax
.done:
    pop     rbx
    ret
