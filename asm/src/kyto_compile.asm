; Kyto compile orchestrator — config-only vs full .kyto entry

%ifndef KYTO_COMPILE_ASM
%define KYTO_COMPILE_ASM

section .data
    msg_ok              db "ok", 10, 0
    msg_compiled_full   db "compiled (asm)", 10, 0
    msg_err_entry       db "error: .kyto entry not found", 10, 0
    msg_err_lex         db "error: failed to tokenize .kyto source", 10, 0
    msg_err_eval        db "error: kyto program evaluation failed", 10, 0
    def_kyto_entry     db "kyto/main.kyto", 0

section .bss
global compile_dry_run
compile_dry_run:    resd 1

section .text

extern config_reset
extern config_file
extern config_parse_buffer
extern read_file_to_buf
extern ensure_dir
extern emit_env_files
extern emit_users_files
extern emit_deploy_file
extern toml_load_paths
extern config_only_flag
extern path_entry
extern kyto_eval_program
extern lex_tokenize
extern print_str

global kyto_compile_project

; compile_dry_run=1 for check (no writes). rax=0 ok, 1 error.
kyto_compile_project:
    push    rbx
    call    config_reset
    call    toml_load_paths
    cmp     dword [config_only_flag], 0
    je      .full
    jmp     .load_config
.full:
    lea     rcx, [path_entry]
    cmp     byte [rcx], 0
    jne     .read_entry
    lea     rcx, [def_kyto_entry]
.read_entry:
    call    read_file_to_buf
    test    rax, rax
    jz      .no_entry
    call    lex_tokenize
    test    rax, rax
    jz      .lex_fail
    call    kyto_eval_program
    test    rax, rax
    jz      .eval_fail
.load_config:
    lea     rcx, [config_file]
    call    read_file_to_buf
    test    rax, rax
    jz      .no_config
    call    config_parse_buffer
    cmp     dword [compile_dry_run], 0
    jne     .dry
    lea     rcx, [dir_generated]
    call    ensure_dir
    lea     rcx, [dir_scripts]
    call    ensure_dir
    lea     rcx, [dir_scripts_gen]
    call    ensure_dir
    lea     rcx, [dir_src]
    call    ensure_dir
    lea     rcx, [dir_src_gen]
    call    ensure_dir
    call    emit_env_files
    call    emit_users_files
    call    emit_deploy_file
.dry:
    cmp     dword [compile_dry_run], 0
    jne     .print_ok
    lea     rcx, [msg_compiled_full]
    call    print_str
    xor     eax, eax
    jmp     .done
.print_ok:
    lea     rcx, [msg_ok]
    call    print_str
    xor     eax, eax
    jmp     .done
.no_config:
    lea     rcx, [msg_err_config]
    call    print_str
    mov     eax, 1
    jmp     .done
.no_entry:
    lea     rcx, [msg_err_entry]
    call    print_str
    mov     eax, 1
    jmp     .done
.lex_fail:
    lea     rcx, [msg_err_lex]
    call    print_str
    mov     eax, 1
    jmp     .done
.eval_fail:
    lea     rcx, [msg_err_eval]
    call    print_str
    mov     eax, 1
.done:
    pop     rbx
    ret

extern msg_err_config

%endif
