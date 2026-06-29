; Kyto kura - x86-64 Windows (NASM) entry point

bits 64
default rel

%include "inc/const.inc"

extern ExitProcess
extern GetCommandLineA
extern CopyFileA
extern GetModuleFileNameA
extern ExpandEnvironmentStringsA

section .data
    msg_installed   db "installed kura -> ", 0
    msg_nl          db 10, 0
    home_var        db "%USERPROFILE%", 0
    bin_suffix      db "/kura.exe", 0
    local_dir       db "/.local", 0
    bin_dir         db "/bin", 0

section .bss
    path_buf:   resb PATH_MAX
    home_buf:   resb PATH_MAX
    self_path:  resb PATH_MAX
global cmdline_rest
cmdline_rest:   resq 1
    cmd_token_buf: resb 64

%include "str.asm"
%include "win_io.asm"
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
global main

main:
    sub     rsp, 40
    call    GetCommandLineA
    mov     rsi, rax
    call    skip_exe_token
    call    skip_spaces_cmd
    cmp     byte [rsi], 0
    je      .noarg
    lea     rdi, [cmd_token_buf]
.copy_tok:
    mov     al, [rsi]
    cmp     al, 0
    je      .tok_end
    cmp     al, ' '
    je      .tok_done
    cmp     al, 9
    je      .tok_done
    mov     [rdi], al
    inc     rsi
    inc     rdi
    jmp     .copy_tok
.tok_done:
    mov     byte [rdi], 0
    call    skip_spaces_cmd
    mov     [cmdline_rest], rsi
    lea     rcx, [cmd_token_buf]
    jmp     .go
.tok_end:
    mov     byte [rdi], 0
    mov     qword [cmdline_rest], 0
    lea     rcx, [cmd_token_buf]
    jmp     .go
.noarg:
    xor     rcx, rcx
    mov     qword [cmdline_rest], 0
.go:
    call    dispatch_argv
    mov     ecx, eax
    call    ExitProcess

skip_exe_token:
    cmp     byte [rsi], 34
    je      .quoted
    call    skip_token_cmd
    ret
.quoted:
    inc     rsi
.q:
    cmp     byte [rsi], 0
    je      .done
    cmp     byte [rsi], 34
    je      .past
    inc     rsi
    jmp     .q
.past:
    inc     rsi
.done:
    ret

skip_token_cmd:
    cmp     byte [rsi], 0
    je      .done
    cmp     byte [rsi], ' '
    je      .done
    cmp     byte [rsi], 9
    je      .done
    inc     rsi
    jmp     skip_token_cmd
.done:
    ret

skip_spaces_cmd:
    cmp     byte [rsi], ' '
    jne     .t
    inc     rsi
    jmp     skip_spaces_cmd
.t:
    cmp     byte [rsi], 9
    jne     .done
    inc     rsi
    jmp     skip_spaces_cmd
.done:
    ret

global cmd_install
cmd_install:
    xor     edx, edx
    mov     r8d, PATH_MAX
    lea     rcx, [self_path]
    call    GetModuleFileNameA
    lea     rcx, [home_var]
    lea     rdx, [home_buf]
    mov     r8d, PATH_MAX
    call    ExpandEnvironmentStringsA
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
    lea     rdx, [bin_suffix]
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
    ret
