; Extract token from rdx into rcx (lowercase, stop at whitespace)
strcpy_token_lower:
    push    rsi
    push    rdi
    mov     rdi, rcx
    mov     rsi, rdx
.loop:
    movzx   eax, byte [rsi]
    cmp     al, 0
    je      .end
    cmp     al, 10
    je      .end
    cmp     al, 13
    je      .end
    cmp     al, ' '
    je      .end
    cmp     al, 9
    je      .end
    cmp     al, '+'
    je      .end
    cmp     al, 'A'
    jb      .store
    cmp     al, 'Z'
    ja      .store
    add     al, 32
.store:
    mov     [rdi], al
    inc     rsi
    inc     rdi
    jmp     .loop
.end:
    mov     byte [rdi], 0
    pop     rdi
    pop     rsi
    ret

; rcx=line, rdx=key -> rax=1 if line starts with key then space/tab/end
str_eq_prefix:
    push    rsi
    push    rdi
    mov     rsi, rcx
    mov     rdi, rdx
.loop:
    mov     al, [rsi]
    mov     ah, [rdi]
    test    ah, ah
    jz      .need_sep
    cmp     al, ah
    jne     .no
    inc     rsi
    inc     rdi
    jmp     .loop
.need_sep:
    cmp     al, 0
    je      .yes
    cmp     al, ' '
    je      .yes
    cmp     al, 9
    je      .yes
.no:
    xor     rax, rax
    jmp     .done
.yes:
    mov     rax, 1
.done:
    pop     rdi
    pop     rsi
    ret

; rcx=line, rdx=key, r8=dest — copy first token after key (lowercase)
copy_value_after_key:
    push    rbx
    push    rsi
    push    rdi
    mov     rsi, rcx
    mov     rdi, rdx
    xor     ebx, ebx
.klen:
    cmp     byte [rdi + rbx], 0
    je      .got
    inc     ebx
    jmp     .klen
.got:
    add     rsi, rbx
.skip:
    cmp     byte [rsi], ' '
    je      .s1
    cmp     byte [rsi], 9
    je      .s1
    jmp     .copy
.s1:
    inc     rsi
    jmp     .skip
.copy:
    mov     rdx, rsi
    mov     rcx, r8
    call    strcpy_token_lower
    mov     rax, 1
    jmp     .out
.out:
    pop     rdi
    pop     rsi
    pop     rbx
    ret

; rcx=haystack — set domain_buf from first DOMAIN line (line-boundary scan)
find_domain_in_buffer:
    push    rbx
    push    r12
    mov     r12, rcx
    xor     ebx, ebx
.next_line:
    cmp     byte [r12 + rbx], 0
    je      .none
    lea     rdi, [line_work]
    xor     eax, eax
.read:
    movzx   ecx, byte [r12 + rbx]
    cmp     cl, 0
    je      .proc
    cmp     cl, 10
    je      .eol
    cmp     cl, 13
    je      .eol
    mov     [rdi + rax], cl
    inc     eax
    inc     ebx
    cmp     eax, LINE_MAX - 2
    jb      .read
    jmp     .skip_rest
.eol:
    mov     byte [rdi + rax], 0
    inc     ebx
    cmp     byte [r12 + rbx], 10
    jne     .proc
    inc     ebx
.proc:
    mov     byte [rdi + rax], 0
    lea     rcx, [line_work]
    call    strip_comment_trim
    cmp     byte [line_work], 0
    je      .next_line
    lea     rcx, [line_work]
    lea     rdx, [kw_domain]
    call    str_eq_prefix
    test    rax, rax
    jz      .next_line
    lea     rcx, [line_work]
    lea     rdx, [kw_domain]
    lea     r8, [domain_buf]
    call    copy_value_after_key
    mov     rax, 1
    jmp     .out
.skip_rest:
    movzx   ecx, byte [r12 + rbx]
    cmp     cl, 0
    je      .none
    cmp     cl, 10
    je      .sk1
    cmp     cl, 13
    je      .sk1
    inc     ebx
    jmp     .skip_rest
.sk1:
    inc     ebx
    jmp     .skip_rest
.none:
    xor     rax, rax
.out:
    pop     r12
    pop     rbx
    ret

config_parse_buffer:
    call    parse_env_lines
    call    parse_env_kv_lines
    cmp     byte [domain_buf], 0
    jne     .users
    lea     rcx, [file_buf]
    call    find_domain_in_buffer
.users:
    lea     rcx, [file_buf]
    lea     rdx, [kw_users]
    call    find_value_after_key
    test    rax, rax
    jz      .admin
    mov     rdx, rax
    lea     rcx, [val_work]
    call    strcpy_token_rest
    lea     rcx, [val_work]
    lea     rdx, [user_names]
    lea     r8, [user_count]
    call    parse_name_list
.admin:
    lea     rcx, [file_buf]
    lea     rdx, [kw_admin]
    call    find_value_after_key
    test    rax, rax
    jz      .done
    mov     rdx, rax
    lea     rcx, [val_work]
    call    strcpy_token_rest
    lea     rcx, [val_work]
    lea     rdx, [admin_names]
    lea     r8, [admin_count]
    call    parse_name_list
.done:
    ret

; rcx=haystack, rdx=key -> rax=value start or 0 (line-boundary match, scan all lines)
find_value_after_key:
    push    rbx
    push    rsi
    push    rdi
    push    r12
    push    r13
    push    r14
    mov     r12, rcx
    mov     r13, rdx
    xor     ebx, ebx
.next_line:
    cmp     byte [r12 + rbx], 0
    je      .none
    lea     rdi, [line_work]
    xor     eax, eax
.read:
    movzx   ecx, byte [r12 + rbx]
    cmp     cl, 0
    je      .proc
    cmp     cl, 10
    je      .eol
    cmp     cl, 13
    je      .eol
    mov     [rdi + rax], cl
    inc     eax
    inc     ebx
    cmp     eax, LINE_MAX - 2
    jb      .read
    jmp     .skip_rest
.eol:
    mov     byte [rdi + rax], 0
    inc     ebx
    cmp     byte [r12 + rbx], 10
    jne     .proc
    inc     ebx
.proc:
    mov     byte [rdi + rax], 0
    lea     rcx, [line_work]
    call    strip_comment_trim
    cmp     byte [line_work], 0
    je      .next_line
    lea     rcx, [line_work]
    mov     rdx, r13
    call    str_eq_prefix
    test    rax, rax
    jz      .next_line
    lea     rsi, [line_work]
    mov     rdi, r13
    xor     r14d, r14d
.klen:
    cmp     byte [rdi + r14], 0
    je      .got
    inc     r14d
    jmp     .klen
.got:
    lea     rax, [rsi + r14]
.skip:
    cmp     byte [rax], ' '
    je      .s1
    cmp     byte [rax], 9
    je      .s1
    jmp     .found
.s1:
    inc     rax
    jmp     .skip
.skip_rest:
    movzx   ecx, byte [r12 + rbx]
    cmp     cl, 0
    je      .none
    cmp     cl, 10
    je      .sk1
    cmp     cl, 13
    je      .sk1
    inc     ebx
    jmp     .skip_rest
.sk1:
    inc     ebx
    jmp     .skip_rest
.found:
    jmp     .out
.none:
    xor     rax, rax
.out:
    pop     r14
    pop     r13
    pop     r12
    pop     rdi
    pop     rsi
    pop     rbx
    ret

; copy rest of line for name lists
strcpy_token_rest:
    push    rsi
    push    rdi
    mov     rdi, rcx
    mov     rsi, rdx
.loop:
    movzx   eax, byte [rsi]
    cmp     al, 0
    je      .end
    cmp     al, 10
    je      .end
    cmp     al, 13
    je      .end
    cmp     al, '+'
    je      .end
    mov     [rdi], al
    inc     rsi
    inc     rdi
    jmp     .loop
.end:
    mov     byte [rdi], 0
    pop     rdi
    pop     rsi
    ret

; line_work -> key_work / val_work, rax=1 ok
parse_config_kv_line:
    push    rsi
    push    rdi
    push    rbx
    lea     rsi, [line_work]
    lea     rdi, [key_work]
    xor     ebx, ebx
.lead:
    cmp     byte [rsi], 0
    je      .fail
    cmp     byte [rsi], ' '
    je      .l1
    cmp     byte [rsi], 9
    je      .l1
    jmp     .key
.l1:
    inc     rsi
    jmp     .lead
.key:
    cmp     byte [rsi], 0
    je      .fail
    cmp     byte [rsi], ' '
    je      .key_done
    cmp     byte [rsi], 9
    je      .key_done
    mov     al, [rsi]
    mov     [rdi], al
    inc     rdi
    inc     rsi
    inc     ebx
    cmp     ebx, NAME_MAX - 1
    jb      .key
.key_done:
    mov     byte [rdi], 0
    test    ebx, ebx
    jz      .fail
.vskip:
    cmp     byte [rsi], 0
    je      .fail
    cmp     byte [rsi], ' '
    je      .v1
    cmp     byte [rsi], 9
    je      .v1
    jmp     .val
.v1:
    inc     rsi
    jmp     .vskip
.val:
    lea     rdi, [val_work]
    xor     ebx, ebx
.vcopy:
    mov     al, [rsi]
    cmp     al, 0
    je      .vend
    mov     [rdi], al
    inc     rsi
    inc     rdi
    inc     ebx
    cmp     ebx, LINE_MAX - 1
    jb      .vcopy
.vend:
    mov     byte [rdi], 0
    mov     rax, 1
    jmp     .done
.fail:
    xor     rax, rax
.done:
    pop     rbx
    pop     rdi
    pop     rsi
    ret

parse_env_lines:
    push    rbx
    push    r12
    push    r13
    lea     r12, [file_buf]
    xor     ebx, ebx
.loop:
    cmp     byte [r12 + rbx], 0
    je      .done
    lea     rdi, [line_work]
    xor     r13d, r13d
.read:
    movzx   eax, byte [r12 + rbx]
    cmp     al, 0
    je      .proc
    cmp     al, 10
    je      .eol
    cmp     al, 13
    je      .eol
    mov     [rdi + r13], al
    inc     r13d
    inc     ebx
    cmp     r13d, LINE_MAX - 2
    jb      .read
    jmp     .skip
.eol:
    mov     byte [rdi + r13], 0
    inc     ebx
    cmp     byte [r12 + rbx], 10
    jne     .proc
    inc     ebx
.proc:
    mov     byte [rdi + r13], 0
    lea     rcx, [line_work]
    call    strip_comment_trim
    cmp     byte [line_work], 0
    je      .loop
    cmp     byte [line_work], '+'
    je      .loop
    lea     rcx, [line_work]
    lea     rdx, [kw_users]
    call    strstr
    test    rax, rax
    jz      .not_users
    lea     rcx, [line_work]
    cmp     rax, rcx
    jne     .not_users
    jmp     .loop
.not_users:
    lea     rcx, [line_work]
    lea     rdx, [kw_admin]
    call    strstr
    test    rax, rax
    jz      .not_admin
    lea     rcx, [line_work]
    cmp     rax, rcx
    jne     .not_admin
    jmp     .loop
.not_admin:
    lea     rcx, [line_work]
    lea     rdx, [kw_domain]
    call    str_eq_prefix
    test    rax, rax
    jnz     .domain_line
    jmp     .loop
.domain_line:
    lea     rcx, [line_work]
    lea     rdx, [kw_domain]
    lea     r8, [domain_buf]
    call    copy_value_after_key
    jmp     .loop
.skip:
    movzx   eax, byte [r12 + rbx]
    cmp     al, 0
    je      .done
    cmp     al, 10
    je      .sk1
    cmp     al, 13
    je      .sk1
    inc     ebx
    jmp     .skip
.sk1:
    inc     ebx
    jmp     .skip
.done:
    pop     r13
    pop     r12
    pop     rbx
    ret

; Collect KEY VALUE lines into env_keys (skip DOMAIN/USERS/ADMIN/+ comments)
parse_env_kv_lines:
    push    rbx
    push    r12
    push    r13
    lea     r12, [file_buf]
    xor     ebx, ebx
.kv_loop:
    cmp     byte [r12 + rbx], 0
    je      .kv_done
    lea     rdi, [line_work]
    xor     r13d, r13d
.kv_read:
    movzx   eax, byte [r12 + rbx]
    cmp     al, 0
    je      .kv_proc
    cmp     al, 10
    je      .kv_eol
    cmp     al, 13
    je      .kv_eol
    mov     [rdi + r13], al
    inc     r13d
    inc     ebx
    cmp     r13d, LINE_MAX - 2
    jb      .kv_read
    jmp     .kv_skip
.kv_eol:
    mov     byte [rdi + r13], 0
    inc     ebx
    cmp     byte [r12 + rbx], 10
    jne     .kv_proc
    inc     ebx
.kv_proc:
    mov     byte [rdi + r13], 0
    lea     rcx, [line_work]
    call    strip_comment_trim
    cmp     byte [line_work], 0
    je      .kv_loop
    cmp     byte [line_work], '+'
    je      .kv_loop
    call    parse_config_kv_line
    test    rax, rax
    jz      .kv_loop
    lea     rcx, [key_work]
    lea     rdx, [kw_users]
    call    str_eq
    test    rax, rax
    jnz     .kv_loop
    lea     rcx, [key_work]
    lea     rdx, [kw_admin]
    call    str_eq
    test    rax, rax
    jnz     .kv_loop
    lea     rcx, [key_work]
    lea     rdx, [kw_domain]
    call    str_eq
    test    rax, rax
    jnz     .kv_loop
    lea     rcx, [val_work]
    call    unquote_value
    call    add_env_entry
    jmp     .kv_loop
.kv_skip:
    movzx   eax, byte [r12 + rbx]
    cmp     al, 0
    je      .kv_done
    cmp     al, 10
    je      .kv_sk1
    cmp     al, 13
    je      .kv_sk1
    inc     ebx
    jmp     .kv_skip
.kv_sk1:
    inc     ebx
    jmp     .kv_skip
.kv_done:
    pop     r13
    pop     r12
    pop     rbx
    ret
