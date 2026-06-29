; kura init — scaffold kyto.toml and .kyto.config.example

%ifndef KYTO_CMD_INIT_ASM
%define KYTO_CMD_INIT_ASM

section .data
    path_kyto_toml          db "kyto.toml", 0
    path_config_example     db ".kyto.config.example", 0
    msg_init_ok             db "initialized Kyto project", 10, 0
    msg_init_hint           db "next: cp .kyto.config.example .kyto.config && kura compile", 10, 0
    msg_init_exists         db "error: kyto.toml already exists", 10, 0
    tmpl_kyto_toml:
        db "[project]", 10
        db "name = ", 34, "my-project", 34, 10
        db "config_only = true", 10, 10
        db "[config]", 10
        db "file = ", 34, ".kyto.config", 34, 10, 10
        db "[emit.env]", 10
        db "file = ", 34, ".env", 34, 10
        db "example = ", 34, ".env.example", 34, 10, 10
        db "[emit.users]", 10
        db "sql = ", 34, "generated/seed.sql", 34, 10
        db "sql_table = ", 34, "users", 34, 10
        db "typescript = ", 34, "src/generated/users.ts", 34, 10
        db "json = ", 34, "generated/users.json", 34, 10, 10
        db "[emit.deploy]", 10
        db "script = ", 34, "scripts/generated/kyto-env.sh", 34, 10, 0
    tmpl_config_example:
        db "+ Edit and run: kura compile", 10
        db "DOMAIN localhost", 10
        db "ADMIN admin", 10
        db "USERS admin", 10
        db "NODE_ENV development", 10, 0

section .text

extern read_file_to_buf
extern write_text_file
extern print_str

global cmd_init

cmd_init:
    push    rbx
    lea     rcx, [path_kyto_toml]
    call    read_file_to_buf
    test    rax, rax
    jnz     .exists
    lea     rcx, [path_kyto_toml]
    lea     rdx, [tmpl_kyto_toml]
    call    write_text_file
    lea     rcx, [path_config_example]
    lea     rdx, [tmpl_config_example]
    call    write_text_file
    lea     rcx, [msg_init_ok]
    call    print_str
    lea     rcx, [msg_init_hint]
    call    print_str
    xor     eax, eax
    jmp     .done
.exists:
    lea     rcx, [msg_init_exists]
    call    print_str
    mov     eax, 1
.done:
    pop     rbx
    ret

%endif
