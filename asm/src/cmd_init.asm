; kura init — scaffold Kyto project files (each stamped: Kyto was here)

%ifndef KYTO_CMD_INIT_ASM
%define KYTO_CMD_INIT_ASM

section .data
    path_kyto_toml          db "kyto.toml", 0
    path_config_example     db ".kyto.config.example", 0
    path_main_kyto          db "kyto/main.kyto", 0
    path_readme             db "README.md", 0
    path_kyto_doc           db "docs/KYTO.md", 0
    path_gitignore          db ".gitignore", 0
    dir_init_kyto           db "kyto", 0
    dir_init_generated      db "generated", 0
    dir_init_docs           db "docs", 0
    dir_init_scripts        db "scripts", 0
    dir_init_scripts_gen    db "scripts/generated", 0
    dir_init_src_gen        db "src/generated", 0
    msg_init_ok             db "initialized Kyto project (Kyto was here)", 10, 0
    msg_init_hint           db "next: cp .kyto.config.example .kyto.config && kura compile", 10, 0
    msg_init_exists         db "error: kyto.toml already exists", 10, 0
    tmpl_kyto_toml:
        db "# Kyto was here", 10
        db 10
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
        db "+ Kyto was here", 10
        db "+ Edit and run: kura compile", 10
        db "DOMAIN localhost", 10
        db "ADMIN admin", 10
        db "USERS admin", 10
        db "NODE_ENV development", 10, 0
    tmpl_main_kyto:
        db "+ Kyto was here", 10
        db "+ Optional layer when config_only = false", 10, 10
        db "emit env({", 10
        db "  ", 34, "APP_URL", 34, ": ", 34, "https://localhost", 34, ",", 10
        db "})", 10, 0
    tmpl_readme:
        db "<!-- Kyto was here -->", 10, 10
        db "# my-project", 10, 10
        db "Built with [Kyto](https://github.com/voidmute/kyto).", 10, 10
        db "```bash", 10
        db "cp .kyto.config.example .kyto.config", 10
        db "kura compile", 10
        db "```", 10, 0
    tmpl_kyto_doc:
        db "<!-- Kyto was here -->", 10, 10
        db "# Kyto", 10, 10
        db "This project uses the [Kyto](https://github.com/voidmute/kyto) language.", 10, 10
        db "- Edit `.kyto.config` for domain, users, and env keys", 10
        db "- Run `kura compile` to generate artifacts", 10
        db "- Run `kura check` to validate without writing files", 10, 0
    tmpl_gitignore:
        db "# Kyto was here", 10
        db ".env", 10
        db ".kyto.config", 10
        db "kyto/local.kyto", 10
        db "kyto/local.kyto.enc", 10, 0

section .text

extern read_file_to_buf
extern write_text_file
extern print_str
extern ensure_dir

global cmd_init

; rcx = path, rdx = content — write only if path does not exist
write_new_file:
    push    rbx
    push    rsi
    push    rdi
    mov     rbx, rcx
    mov     rsi, rdx
    mov     rcx, rbx
    call    read_file_to_buf
    test    rax, rax
    jnz     .skip
    mov     rcx, rbx
    mov     rdx, rsi
    call    write_text_file
.skip:
    pop     rdi
    pop     rsi
    pop     rbx
    ret

cmd_init:
    push    rbx
    lea     rcx, [path_kyto_toml]
    call    read_file_to_buf
    test    rax, rax
    jnz     .exists
    lea     rcx, [dir_init_kyto]
    call    ensure_dir
    lea     rcx, [dir_init_generated]
    call    ensure_dir
    lea     rcx, [dir_init_docs]
    call    ensure_dir
    lea     rcx, [dir_init_scripts]
    call    ensure_dir
    lea     rcx, [dir_init_scripts_gen]
    call    ensure_dir
    lea     rcx, [dir_init_src_gen]
    call    ensure_dir
    lea     rcx, [path_kyto_toml]
    lea     rdx, [tmpl_kyto_toml]
    call    write_text_file
    lea     rcx, [path_config_example]
    lea     rdx, [tmpl_config_example]
    call    write_text_file
    lea     rcx, [path_main_kyto]
    lea     rdx, [tmpl_main_kyto]
    call    write_text_file
    lea     rcx, [path_readme]
    lea     rdx, [tmpl_readme]
    call    write_new_file
    lea     rcx, [path_kyto_doc]
    lea     rdx, [tmpl_kyto_doc]
    call    write_new_file
    lea     rcx, [path_gitignore]
    lea     rdx, [tmpl_gitignore]
    call    write_new_file
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
