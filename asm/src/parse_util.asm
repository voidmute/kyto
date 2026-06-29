; Parser cursor over lexer token stream

%ifndef KYTO_PARSE_UTIL_ASM
%define KYTO_PARSE_UTIL_ASM

section .bss
global parse_pos
parse_pos:  resd 1

section .text

extern tok_count
extern tok_type
extern tok_val

%define PEEK_STR_MAX 512

; eax = token type at parse_pos (or TOK_EOF)
global peek_type
peek_type:
    mov     eax, [parse_pos]
    cmp     eax, [tok_count]
    jae     .eof
    mov     eax, [tok_type + rax * 4]
    ret
.eof:
    mov     eax, TOK_EOF
    ret

; rcx = token index, eax = type
peek_type_at:
    cmp     ecx, [tok_count]
    jae     .eof
    mov     eax, [tok_type + rcx * 4]
    ret
.eof:
    mov     eax, TOK_EOF
    ret

; Copy token string at parse_pos into rcx buffer
global peek_val
peek_val:
    push    rbx
    mov     eax, [parse_pos]
    cmp     eax, [tok_count]
    jae     .empty
    imul    eax, PEEK_STR_MAX
    lea     rsi, [tok_val + rax]
    mov     rdi, rcx
.copy:
    lodsb
    stosb
    test    al, al
    jnz     .copy
    pop     rbx
    ret
.empty:
    mov     byte [rcx], 0
    pop     rbx
    ret

; Copy token string at index ecx into rdx buffer
global peek_val_at
peek_val_at:
    push    rsi
    push    rdi
    cmp     ecx, [tok_count]
    jae     .empty
    mov     eax, ecx
    imul    eax, PEEK_STR_MAX
    lea     rsi, [tok_val + rax]
    mov     rdi, rdx
.copy:
    lodsb
    stosb
    test    al, al
    jnz     .copy
    pop     rdi
    pop     rsi
    ret
.empty:
    mov     byte [rdx], 0
    pop     rdi
    pop     rsi
    ret

global bump
bump:
    mov     eax, [parse_pos]
    cmp     eax, [tok_count]
    jae     .done
    inc     dword [parse_pos]
.done:
    ret

; ecx = expected type, rax=1 if matched
global expect_type
expect_type:
    call    peek_type
    cmp     eax, ecx
    jne     .fail
    call    bump
    mov     rax, 1
    ret
.fail:
    xor     rax, rax
    ret

global skip_type
skip_type:
    call    peek_type
    cmp     eax, ecx
    jne     .done
    call    bump
.done:
    ret

%endif
