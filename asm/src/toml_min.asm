; Minimal kyto.toml path scraper

%ifndef KYTO_TOML_MIN_ASM
%define KYTO_TOML_MIN_ASM

section .data
    toml_file       db "kyto.toml", 0
    pat_env_file    db "emit.env]", 10, "file = ", 34, 0
    pat_env_ex      db "example = ", 34, 0
    pat_sql         db "sql = ", 34, 0
    pat_ts          db "typescript = ", 34, 0
    pat_json        db "json = ", 34, 0
    pat_deploy      db "script = ", 34, 0
    pat_sql_table   db "sql_table = ", 34, 0
    pat_config_only db "config_only = true", 0
    pat_entry       db "entry = ", 34, 0
    def_env_file    db ".env", 0
    def_env_ex      db ".env.example", 0
    def_sql         db "generated/seed.sql", 0
    def_ts          db "src/generated/users.ts", 0
    def_json        db "generated/users.json", 0
    def_deploy      db "scripts/generated/kyto-env.sh", 0
    def_sql_table   db "users", 0
    def_entry       db "kyto/main.kyto", 0

section .bss
global path_env_file
global path_env_example
global path_users_sql
global path_users_ts
global path_users_json
global path_deploy_script
global path_sql_table

path_env_file:      resb PATH_MAX
path_env_example:   resb PATH_MAX
path_users_sql:     resb PATH_MAX
path_users_ts:      resb PATH_MAX
path_users_json:    resb PATH_MAX
path_deploy_script: resb PATH_MAX
path_sql_table:     resb NAME_MAX
global config_only_flag
global path_entry
config_only_flag:   resd 1
path_entry:         resb PATH_MAX

section .text

extern read_file_to_buf
extern file_buf
extern strstr
extern strcpy

global toml_load_paths

toml_load_paths:
    push    rbx
    mov     dword [config_only_flag], 0
    lea     rcx, [path_env_file]
    lea     rdx, [def_env_file]
    call    strcpy
    lea     rcx, [path_env_example]
    lea     rdx, [def_env_ex]
    call    strcpy
    lea     rcx, [path_users_sql]
    lea     rdx, [def_sql]
    call    strcpy
    lea     rcx, [path_users_ts]
    lea     rdx, [def_ts]
    call    strcpy
    lea     rcx, [path_users_json]
    lea     rdx, [def_json]
    call    strcpy
    lea     rcx, [path_deploy_script]
    lea     rdx, [def_deploy]
    call    strcpy
    lea     rcx, [path_sql_table]
    lea     rdx, [def_sql_table]
    call    strcpy
    lea     rcx, [path_entry]
    lea     rdx, [def_entry]
    call    strcpy
    lea     rcx, [toml_file]
    call    read_file_to_buf
    test    rax, rax
    jz      .done
    lea     rcx, [file_buf]
    lea     rdx, [pat_env_file]
    lea     r8, [path_env_file]
    call    extract_quoted
    lea     rcx, [file_buf]
    lea     rdx, [pat_env_ex]
    lea     r8, [path_env_example]
    call    extract_quoted
    lea     rcx, [file_buf]
    lea     rdx, [pat_sql]
    lea     r8, [path_users_sql]
    call    extract_quoted
    lea     rcx, [file_buf]
    lea     rdx, [pat_ts]
    lea     r8, [path_users_ts]
    call    extract_quoted
    lea     rcx, [file_buf]
    lea     rdx, [pat_json]
    lea     r8, [path_users_json]
    call    extract_quoted
    lea     rcx, [file_buf]
    lea     rdx, [pat_deploy]
    lea     r8, [path_deploy_script]
    call    extract_quoted
    lea     rcx, [file_buf]
    lea     rdx, [pat_sql_table]
    lea     r8, [path_sql_table]
    call    extract_quoted
    lea     rcx, [file_buf]
    lea     rdx, [pat_entry]
    lea     r8, [path_entry]
    call    extract_quoted
    lea     rcx, [file_buf]
    lea     rdx, [pat_config_only]
    call    strstr
    test    rax, rax
    jz      .done
    mov     dword [config_only_flag], 1
.done:
    pop     rbx
    ret

; rcx=buf, rdx=pattern, r8=dest
extract_quoted:
    push    rsi
    push    rdi
    push    rbx
    mov     rdi, rdx
    xor     ebx, ebx
.plen:
    cmp     byte [rdi + rbx], 0
    je      .gotlen
    inc     ebx
    jmp     .plen
.gotlen:
    mov     rcx, rcx
    mov     rdx, rdi
    call    strstr
    test    rax, rax
    jz      .out
    mov     rsi, rax
    add     rsi, rbx
    cmp     byte [rsi], 34
    jne     .out
    inc     rsi
    mov     rdi, r8
    mov     r10, r8
.copy:
    mov     al, [rsi]
    cmp     al, 34
    je      .end
    cmp     al, 0
    je      .end
    mov     rcx, rdi
    sub     rcx, r10
    cmp     rcx, PATH_MAX - 2
    jae     .end
    mov     [rdi], al
    inc     rsi
    inc     rdi
    jmp     .copy
.end:
    mov     byte [rdi], 0
.out:
    pop     rbx
    pop     rdi
    pop     rsi
    ret

%endif
