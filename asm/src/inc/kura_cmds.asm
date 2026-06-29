; Shared kura command dispatch and compile (Windows + Linux)

%ifndef KYTO_KURA_CMDS_ASM
%define KYTO_KURA_CMDS_ASM

section .data
    msg_version     db "kura 0.5.0-asm", 10, 0
    msg_usage       db "usage: kura compile | check | init | install | encrypt | decrypt | --version", 10, 0
    msg_err_config  db "error: .kyto.config not found", 10, 0
    kw_compile      db "compile", 0
    kw_check        db "check", 0
    kw_init         db "init", 0
    kw_install      db "install", 0
    kw_encrypt      db "encrypt", 0
    kw_decrypt      db "decrypt", 0
    kw_version      db "--version", 0
    dir_generated   db "generated", 0
    dir_scripts     db "scripts", 0
    dir_src         db "src", 0
    dir_scripts_gen db "scripts/generated", 0
    dir_src_gen     db "src/generated", 0

section .text

extern kyto_compile_project
extern compile_dry_run
extern print_str
extern str_eq
extern trim_trailing
extern cmd_init
extern cmd_encrypt
extern cmd_decrypt
extern ensure_dir
extern emit_env_files
extern emit_users_files
extern emit_deploy_file

global dispatch_argv
global msg_err_config

; rcx = command string (argv[1] or parsed token)
dispatch_argv:
    push    rbx
    mov     rbx, rcx
    test    rbx, rbx
    jz      .usage
    mov     rcx, rbx
    call    trim_trailing
    mov     rcx, rbx
    lea     rdx, [kw_version]
    call    str_eq
    test    rax, rax
    jnz     .version
    mov     rcx, rbx
    lea     rdx, [kw_compile]
    call    str_eq
    test    rax, rax
    jnz     .compile
    mov     rcx, rbx
    lea     rdx, [kw_check]
    call    str_eq
    test    rax, rax
    jnz     .check
    mov     rcx, rbx
    lea     rdx, [kw_init]
    call    str_eq
    test    rax, rax
    jnz     .init
    mov     rcx, rbx
    lea     rdx, [kw_install]
    call    str_eq
    test    rax, rax
    jnz     .install
    mov     rcx, rbx
    lea     rdx, [kw_encrypt]
    call    str_eq
    test    rax, rax
    jnz     .encrypt
    mov     rcx, rbx
    lea     rdx, [kw_decrypt]
    call    str_eq
    test    rax, rax
    jnz     .decrypt
.usage:
    lea     rcx, [msg_usage]
    call    print_str
    mov     eax, 1
    jmp     .done
.version:
    lea     rcx, [msg_version]
    call    print_str
    xor     eax, eax
    jmp     .done
.compile:
    mov     dword [compile_dry_run], 0
    call    kyto_compile_project
    jmp     .done
.check:
    mov     dword [compile_dry_run], 1
    call    kyto_compile_project
    jmp     .done
.init:
    call    cmd_init
    jmp     .done
.install:
    call    cmd_install
    jmp     .done
.encrypt:
    call    cmd_encrypt
    jmp     .done
.decrypt:
    call    cmd_decrypt
.done:
    pop     rbx
    ret

%endif
