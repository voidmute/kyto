; Kyto .kyto lexer — tokenizes source in file_buf

%ifndef KYTO_LEXER_ASM
%define KYTO_LEXER_ASM

%define TOK_EOF         0
%define TOK_EMIT        1
%define TOK_LET         2
%define TOK_IDENT       3
%define TOK_STRING      4
%define TOK_INT         5
%define TOK_LPAREN      6
%define TOK_RPAREN      7
%define TOK_LBRACE      8
%define TOK_RBRACE      9
%define TOK_COMMA       10
%define TOK_COLON       11
%define TOK_ARROW       12
%define TOK_EQ          13
%define TOK_PLUS        14
%define TOK_IMPORT      15
%define TOK_FN          16
%define TOK_IF          17
%define TOK_ELSE        18
%define TOK_RETURN      19
%define TOK_TRUE        20
%define TOK_FALSE       21
%define TOK_STRUCT      22
%define TOK_ENUM        23
%define TOK_LBRACKET    24
%define TOK_RBRACKET    25
%define TOK_DOT         26
%define TOK_LT          27
%define TOK_GT          28
%define TOK_NULLCOALESCE 29

%define MAX_TOKENS      512
%define MAX_IDENT       NAME_MAX
%define LEX_STR_MAX     LINE_MAX

section .data
    kw_emit     db "emit", 0
    kw_let      db "let", 0
    kw_import   db "import", 0
    kw_fn       db "fn", 0
    kw_if       db "if", 0
    kw_else     db "else", 0
    kw_return   db "return", 0
    kw_true     db "true", 0
    kw_false    db "false", 0
    kw_struct   db "struct", 0
    kw_enum     db "enum", 0

section .bss
global lex_pos
global lex_line
global tok_count
global tok_type
global tok_val

lex_pos:    resq 1
lex_line:   resd 1
tok_count:  resd 1
tok_type:   resd MAX_TOKENS
tok_val:    resb MAX_TOKENS * LEX_STR_MAX

section .text

extern file_buf
extern strstr

; Reset and tokenize file_buf (NUL-terminated). rax=1 on success.
global lex_tokenize
lex_tokenize:
    push    rbx
    mov     qword [lex_pos], 0
    mov     dword [lex_line], 1
    mov     dword [tok_count], 0
.loop:
    call    lex_next
    cmp     rax, -1
    je      .fail
    cmp     rax, TOK_EOF
    je      .ok
    jmp     .loop
.ok:
    mov     rax, 1
    jmp     .done
.fail:
    xor     rax, rax
.done:
    pop     rbx
    ret

; rax = token type, or -1 on error
lex_next:
    push    rbx
    push    rdi
    call    lex_skip_ws
    mov     rsi, [lex_pos]
    movzx   eax, byte [file_buf + rsi]
    test    al, al
    jz      .eof
    cmp     al, '('
    je      .lp
    cmp     al, '['
    je      .lbracket
    cmp     al, ']'
    je      .rbracket
    cmp     al, '.'
    je      .dot
    cmp     al, '<'
    je      .lt
    cmp     al, '>'
    je      .gt
    cmp     al, '?'
    je      .question
    cmp     al, ')'
    je      .rp
    cmp     al, '{'
    je      .lb
    cmp     al, '}'
    je      .rb
    cmp     al, ','
    je      .comma
    cmp     al, ':'
    je      .colon
    cmp     al, '+'
    je      .plus
    cmp     al, '='
    je      .eq
    cmp     al, 34
    je      .str
    cmp     al, '0'
    jb      .id
    cmp     al, '9'
    ja      .id
    jmp     .int
.lp:
    mov     eax, TOK_LPAREN
    inc     qword [lex_pos]
    jmp     .store
.lbracket:
    mov     eax, TOK_LBRACKET
    inc     qword [lex_pos]
    jmp     .store
.rbracket:
    mov     eax, TOK_RBRACKET
    inc     qword [lex_pos]
    jmp     .store
.dot:
    mov     eax, TOK_DOT
    inc     qword [lex_pos]
    jmp     .store
.lt:
    mov     eax, TOK_LT
    inc     qword [lex_pos]
    jmp     .store
.gt:
    mov     eax, TOK_GT
    inc     qword [lex_pos]
    jmp     .store
.question:
    mov     rsi, [lex_pos]
    cmp     byte [file_buf + rsi + 1], '?'
    jne     .qfail
    mov     eax, TOK_NULLCOALESCE
    add     qword [lex_pos], 2
    jmp     .store
.qfail:
    mov     rax, -1
    jmp     .err
.rp:
    mov     eax, TOK_RPAREN
    inc     qword [lex_pos]
    jmp     .store
.lb:
    mov     eax, TOK_LBRACE
    inc     qword [lex_pos]
    jmp     .store
.rb:
    mov     eax, TOK_RBRACE
    inc     qword [lex_pos]
    jmp     .store
.comma:
    mov     eax, TOK_COMMA
    inc     qword [lex_pos]
    jmp     .store
.colon:
    mov     rsi, [lex_pos]
    mov     al, [file_buf + rsi + 1]
    cmp     al, '>'
    jne     .colon_only
    mov     eax, TOK_ARROW
    add     qword [lex_pos], 2
    jmp     .store
.colon_only:
    mov     eax, TOK_COLON
    inc     qword [lex_pos]
    jmp     .store
.plus:
    mov     eax, TOK_PLUS
    inc     qword [lex_pos]
    jmp     .store
.eq:
    mov     eax, TOK_EQ
    inc     qword [lex_pos]
    jmp     .store
.str:
    call    lex_read_string
    test    rax, rax
    js      .err
    mov     eax, TOK_STRING
    jmp     .store
.int:
    call    lex_read_int
    test    rax, rax
    js      .err
    mov     eax, TOK_INT
    jmp     .store
.id:
    call    lex_read_ident
    test    rax, rax
    js      .err
    mov     eax, TOK_IDENT
    jmp     .kwcheck
.kwcheck:
    mov     ebx, [tok_count]
    mov     eax, ebx
    imul    eax, LEX_STR_MAX
    lea     rdi, [tok_val + rax]
    lea     rcx, [rdi]
    lea     rdx, [kw_emit]
    call    str_eq_kw
    test    rax, rax
    jnz     .emit
    lea     rcx, [rdi]
    lea     rdx, [kw_let]
    call    str_eq_kw
    test    rax, rax
    jnz     .let
    lea     rcx, [rdi]
    lea     rdx, [kw_import]
    call    str_eq_kw
    test    rax, rax
    jnz     .import
    lea     rcx, [rdi]
    lea     rdx, [kw_fn]
    call    str_eq_kw
    test    rax, rax
    jnz     .fn
    lea     rcx, [rdi]
    lea     rdx, [kw_if]
    call    str_eq_kw
    test    rax, rax
    jnz     .if
    lea     rcx, [rdi]
    lea     rdx, [kw_return]
    call    str_eq_kw
    test    rax, rax
    jnz     .ret
    lea     rcx, [rdi]
    lea     rdx, [kw_true]
    call    str_eq_kw
    test    rax, rax
    jnz     .true
    lea     rcx, [rdi]
    lea     rdx, [kw_false]
    call    str_eq_kw
    test    rax, rax
    jnz     .false
    lea     rcx, [rdi]
    lea     rdx, [kw_struct]
    call    str_eq_kw
    test    rax, rax
    jnz     .struct
    lea     rcx, [rdi]
    lea     rdx, [kw_enum]
    call    str_eq_kw
    test    rax, rax
    jnz     .enum
    mov     eax, TOK_IDENT
    jmp     .store
.emit:
    mov     eax, TOK_EMIT
    jmp     .store
.let:
    mov     eax, TOK_LET
    jmp     .store
.import:
    mov     eax, TOK_IMPORT
    jmp     .store
.fn:
    mov     eax, TOK_FN
    jmp     .store
.if:
    mov     eax, TOK_IF
    jmp     .store
.ret:
    mov     eax, TOK_RETURN
    jmp     .store
.true:
    mov     eax, TOK_TRUE
    jmp     .store
.false:
    mov     eax, TOK_FALSE
    jmp     .store
.struct:
    mov     eax, TOK_STRUCT
    jmp     .store
.enum:
    mov     eax, TOK_ENUM
    jmp     .store
.eof:
    mov     eax, TOK_EOF
.store:
    mov     ebx, [tok_count]
    cmp     ebx, MAX_TOKENS - 1
    jae     .err
    mov     [tok_type + rbx * 4], eax
    inc     dword [tok_count]
    pop     rdi
    pop     rbx
    ret
.err:
    mov     rax, -1
    pop     rdi
    pop     rbx
    ret

str_eq_kw:
    push    rsi
    push    rdi
    mov     rsi, rcx
    mov     rdi, rdx
.loop:
    mov     al, [rsi]
    mov     ah, [rdi]
    cmp     al, ah
    jne     .no
    test    al, al
    jz      .yes
    inc     rsi
    inc     rdi
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

lex_skip_ws:
    push    rbx
.loop:
    mov     rsi, [lex_pos]
    movzx   eax, byte [file_buf + rsi]
    test    al, al
    jz      .done
    cmp     al, ' '
    je      .skip
    cmp     al, 9
    je      .skip
    cmp     al, 10
    je      .nl
    cmp     al, 13
    je      .nl
    cmp     al, '+'
    jne     .done
    call    lex_skip_comment
    jmp     .loop
.skip:
    inc     qword [lex_pos]
    jmp     .loop
.nl:
    inc     dword [lex_line]
    inc     qword [lex_pos]
    cmp     byte [file_buf + rsi + 1], 10
    jne     .loop
    inc     qword [lex_pos]
    jmp     .loop
.done:
    pop     rbx
    ret

lex_skip_comment:
    mov     rsi, [lex_pos]
.c:
    movzx   eax, byte [file_buf + rsi]
    cmp     al, 0
    je      .out
    cmp     al, 10
    je      .out
    cmp     al, 13
    je      .out
    inc     rsi
    jmp     .c
.out:
    mov     [lex_pos], rsi
    ret

lex_read_ident:
    push    rbx
    mov     ebx, [tok_count]
    mov     eax, ebx
    imul    eax, LEX_STR_MAX
    lea     rdi, [tok_val + rax]
    xor     ebx, ebx
.loop:
    mov     rsi, [lex_pos]
    movzx   eax, byte [file_buf + rsi]
    cmp     al, 'a'
    jb      .check
    cmp     al, 'z'
    jbe     .store
.check:
    cmp     al, 'A'
    jb      .end
    cmp     al, 'Z'
    ja      .end
.store:
    cmp     ebx, LEX_STR_MAX - 2
    jae     .end
    mov     [rdi + rbx], al
    inc     ebx
    inc     qword [lex_pos]
    jmp     .loop
.end:
    mov     byte [rdi + rbx], 0
    test    ebx, ebx
    jz      .fail
    mov     rax, 1
    jmp     .done
.fail:
    mov     rax, -1
.done:
    pop     rbx
    ret

lex_read_string:
    push    rbx
    inc     qword [lex_pos]
    mov     ebx, [tok_count]
    mov     eax, ebx
    imul    eax, LEX_STR_MAX
    lea     rdi, [tok_val + rax]
    xor     ebx, ebx
.loop:
    mov     rsi, [lex_pos]
    movzx   eax, byte [file_buf + rsi]
    cmp     al, 0
    je      .fail
    cmp     al, 10
    je      .fail
    cmp     al, 34
    je      .end
    cmp     ebx, LEX_STR_MAX - 2
    jae     .fail
    mov     [rdi + rbx], al
    inc     ebx
    inc     qword [lex_pos]
    jmp     .loop
.end:
    mov     byte [rdi + rbx], 0
    inc     qword [lex_pos]
    mov     rax, 1
    jmp     .done
.fail:
    mov     rax, -1
.done:
    pop     rbx
    ret

lex_read_int:
    push    rbx
    mov     ebx, [tok_count]
    mov     eax, ebx
    imul    eax, LEX_STR_MAX
    lea     rdi, [tok_val + rax]
    xor     ebx, ebx
    xor     r8d, r8d
.loop:
    mov     rsi, [lex_pos]
    movzx   eax, byte [file_buf + rsi]
    cmp     al, '0'
    jb      .end
    cmp     al, '9'
    ja      .end
    sub     al, '0'
    movzx   eax, al
    imul    r8d, 10
    add     r8d, eax
    cmp     ebx, LEX_STR_MAX - 2
    jae     .end
    mov     rsi, [lex_pos]
    mov     al, [file_buf + rsi]
    mov     [rdi + rbx], al
    inc     ebx
    inc     qword [lex_pos]
    jmp     .loop
.end:
    mov     byte [rdi + rbx], 0
    test    ebx, ebx
    jz      .fail
    mov     rax, 1
    jmp     .done
.fail:
    mov     rax, -1
.done:
    pop     rbx
    ret

%endif
