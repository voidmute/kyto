; Emit .env and .env.example

%ifndef KYTO_EMIT_ENV_ASM
%define KYTO_EMIT_ENV_ASM

section .data
    https_prefix    db "https://", 0
    app_url_key     db "APP_URL", 0
    session_key     db "SESSION_SECRET", 0
    session_default db "changeme-replace-in-production", 0
    crlf            db 13, 10, 0
    eq_sign         db "=", 0
    node_env_key    db "NODE_ENV", 0
    node_env_default db "development", 0
    redact_val      db "changeme", 0
    redact_needles  db "SECRET", 0, "TOKEN", 0, "PASSWORD", 0, "KEY", 0, 0

section .text

extern out_buf
extern strcat
extern strstr
extern write_text_file
extern domain_buf
extern env_keys
extern env_vals
extern env_count
extern path_env_file
extern path_env_example
extern str_len
extern str_eq

global emit_env_files

; rcx = key name — rax=1 if env_keys contains key
env_has_key:
    push    rbx
    push    rsi
    push    rdi
    mov     rdi, rcx
    xor     ebx, ebx
.loop:
    mov     eax, ebx
    cmp     eax, [env_count]
    jae     .no
    imul    eax, NAME_MAX
    lea     rsi, [env_keys + rax]
    mov     rcx, rsi
    mov     rdx, rdi
    call    str_eq
    test    rax, rax
    jnz     .yes
    inc     ebx
    jmp     .loop
.yes:
    mov     rax, 1
    jmp     .done
.no:
    xor     rax, rax
.done:
    pop     rdi
    pop     rsi
    pop     rbx
    ret

clear_out_buf:
    push    rdi
    cld
    lea     rdi, [out_buf]
    xor     eax, eax
    mov     rcx, 8192
    rep     stosb
    pop     rdi
    ret

emit_env_files:
    push    rbx
    push    r12
    call    clear_out_buf
    lea     rcx, [app_url_key]
    call    env_has_key
    test    rax, rax
    jnz     .env_lines
    cmp     byte [domain_buf], 0
    je      .env_lines
    lea     rcx, [out_buf]
    lea     rdx, [app_url_key]
    call    strcat
    lea     rcx, [out_buf]
    lea     rdx, [eq_sign]
    call    strcat
    lea     rcx, [out_buf]
    lea     rdx, [https_prefix]
    call    strcat
    lea     rcx, [out_buf]
    lea     rdx, [domain_buf]
    call    strcat
    lea     rcx, [out_buf]
    lea     rdx, [crlf]
    call    strcat
.env_lines:
    xor     ebx, ebx
.el:
    mov     eax, ebx
    cmp     eax, [env_count]
    jae     .secret
    mov     eax, ebx
    imul    eax, NAME_MAX
    lea     rsi, [env_keys + rax]
    cmp     byte [rsi], 0
    je      .el_next
    mov     eax, ebx
    imul    eax, LINE_MAX
    lea     r12, [env_vals + rax]
    lea     rcx, [out_buf]
    mov     rdx, rsi
    call    strcat
    lea     rcx, [out_buf]
    lea     rdx, [eq_sign]
    call    strcat
    lea     rcx, [out_buf]
    mov     rdx, r12
    call    strcat
    lea     rcx, [out_buf]
    lea     rdx, [crlf]
    call    strcat
    inc     ebx
    jmp     .el
.el_next:
    inc     ebx
    jmp     .el
.secret:
    lea     rcx, [node_env_key]
    call    env_has_key
    test    rax, rax
    jnz     .session_chk
    lea     rcx, [out_buf]
    lea     rdx, [node_env_key]
    call    strcat
    lea     rcx, [out_buf]
    lea     rdx, [eq_sign]
    call    strcat
    lea     rcx, [out_buf]
    lea     rdx, [node_env_default]
    call    strcat
    lea     rcx, [out_buf]
    lea     rdx, [crlf]
    call    strcat
.session_chk:
    lea     rcx, [session_key]
    call    env_has_key
    test    rax, rax
    jnz     .write
    lea     rcx, [out_buf]
    lea     rdx, [session_key]
    call    strcat
    lea     rcx, [out_buf]
    lea     rdx, [eq_sign]
    call    strcat
    lea     rcx, [out_buf]
    lea     rdx, [session_default]
    call    strcat
    lea     rcx, [out_buf]
    lea     rdx, [crlf]
    call    strcat
.write:
    lea     rcx, [path_env_file]
    lea     rdx, [out_buf]
    call    write_text_file
    call    build_example
    lea     rcx, [path_env_example]
    lea     rdx, [out_buf]
    call    write_text_file
    pop     r12
    pop     rbx
    ret

build_example:
    push    rbx
    push    r12
    call    clear_out_buf
    cmp     byte [domain_buf], 0
    je      .lines
    lea     rcx, [out_buf]
    lea     rdx, [app_url_key]
    call    strcat
    lea     rcx, [out_buf]
    lea     rdx, [eq_sign]
    call    strcat
    lea     rcx, [out_buf]
    lea     rdx, [https_prefix]
    call    strcat
    lea     rcx, [out_buf]
    lea     rdx, [domain_buf]
    call    strcat
    lea     rcx, [out_buf]
    lea     rdx, [crlf]
    call    strcat
.lines:
    xor     ebx, ebx
.el:
    mov     eax, ebx
    cmp     eax, [env_count]
    jae     .secret
    mov     eax, ebx
    imul    eax, NAME_MAX
    lea     rsi, [env_keys + rax]
    cmp     byte [rsi], 0
    je      .el_next
    mov     eax, ebx
    imul    eax, LINE_MAX
    lea     r12, [env_vals + rax]
    lea     rcx, [out_buf]
    mov     rdx, rsi
    call    strcat
    lea     rcx, [out_buf]
    lea     rdx, [eq_sign]
    call    strcat
    lea     rcx, [out_buf]
    mov     rdx, rsi
    call    should_redact
    test    rax, rax
    jnz     .red
    lea     rcx, [out_buf]
    mov     rdx, r12
    jmp     .append
.red:
    lea     rcx, [out_buf]
    lea     rdx, [redact_val]
.append:
    call    strcat
    lea     rcx, [out_buf]
    lea     rdx, [crlf]
    call    strcat
    inc     ebx
    jmp     .el
.el_next:
    inc     ebx
    jmp     .el
.secret:
    lea     rcx, [session_key]
    call    env_has_key
    test    rax, rax
    jnz     .done
    lea     rcx, [out_buf]
    lea     rdx, [session_key]
    call    strcat
    lea     rcx, [out_buf]
    lea     rdx, [eq_sign]
    call    strcat
    lea     rcx, [out_buf]
    lea     rdx, [redact_val]
    call    strcat
    lea     rcx, [out_buf]
    lea     rdx, [crlf]
    call    strcat
.done:
    pop     r12
    pop     rbx
    ret

should_redact:
    push    rsi
    push    rdi
    mov     rdi, rcx
    lea     rsi, [redact_needles]
.loop:
    cmp     byte [rsi], 0
    je      .no
    mov     rcx, rdi
    mov     rdx, rsi
    call    strstr
    test    rax, rax
    jnz     .yes
    mov     rcx, rsi
    call    str_len
    add     rsi, rax
    inc     rsi
    jmp     .loop
.yes:
    mov     rax, 1
    jmp     .done
.no:
    xor     rax, rax
.done:
    pop     rdi
    pop     rsi
    ret

%endif
