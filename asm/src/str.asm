; String and memory helpers

%ifndef KYTO_STR_ASM
%define KYTO_STR_ASM

section .text

; rcx = dst, rdx = src
global strcpy
strcpy:
    push    rsi
    push    rdi
    mov     rdi, rcx
    mov     rsi, rdx
.copy:
    mov     al, [rsi]
    mov     [rdi], al
    test    al, al
    jz      .done
    inc     rsi
    inc     rdi
    jmp     .copy
.done:
    mov     rax, rcx
    pop     rdi
    pop     rsi
    ret

; rcx = dst, rdx = src - append
global strcat
strcat:
    push    rsi
    push    rdi
    mov     rdi, rcx
    mov     rsi, rdx
.find:
    cmp     byte [rdi], 0
    je      .copy
    inc     rdi
    jmp     .find
.copy:
    mov     al, [rsi]
    mov     [rdi], al
    test    al, al
    jz      .done
    inc     rsi
    inc     rdi
    jmp     .copy
.done:
    dec     rdi
    mov     rax, rcx
    pop     rdi
    pop     rsi
    ret

; rcx, rdx - return rax=1 if equal
global str_eq
str_eq:
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

; rcx = haystack, rdx = needle - rax ptr or 0
global strstr
strstr:
    push    rbx
    push    rsi
    push    rdi
    mov     rsi, rcx
    mov     rdi, rdx
    test    byte [rdi], 0
    jz      .found_at_rsi
.outer:
    mov     rbx, rsi
    mov     rcx, rdi
.inner:
    mov     al, [rbx]
    mov     ah, [rcx]
    test    ah, ah
    jz      .found_at_rsi
    cmp     al, ah
    jne     .next
    inc     rbx
    inc     rcx
    jmp     .inner
.next:
    cmp     byte [rsi], 0
    je      .notfound
    inc     rsi
    jmp     .outer
.found_at_rsi:
    mov     rax, rsi
    jmp     .done
.notfound:
    xor     rax, rax
.done:
    pop     rdi
    pop     rsi
    pop     rbx
    ret

; rcx = s
global str_len
str_len:
    xor     rax, rax
    test    rcx, rcx
    jz      .done
    mov     rdi, rcx
.loop:
    cmp     byte [rdi + rax], 0
    je      .done
    inc     rax
    jmp     .loop
.done:
    ret

; rcx = dst, rdx = src - lowercase copy
global strcpy_lower
strcpy_lower:
    push    rsi
    push    rdi
    mov     rdi, rcx
    mov     rsi, rdx
.loop:
    movzx   eax, byte [rsi]
    cmp     al, 'A'
    jb      .store
    cmp     al, 'Z'
    ja      .store
    add     al, 32
.store:
    mov     [rdi], al
    test    al, al
    jz      .done
    cmp     al, ' '
    je      .cut
    cmp     al, 9
    je      .cut
    inc     rsi
    inc     rdi
    jmp     .loop
.cut:
    mov     byte [rdi], 0
.done:
    mov     rax, rcx
    pop     rdi
    pop     rsi
    ret

; rcx = line, rdx = key out, r8 = val out
global split_key_value
split_key_value:
    push    rbx
    push    rsi
    push    rdi
    mov     rsi, rcx
    mov     rdi, rdx
    ; skip leading space
.skip:
    cmp     byte [rsi], ' '
    je      .skip1
    cmp     byte [rsi], 9
    je      .skip1
    jmp     .key
.skip1:
    inc     rsi
    jmp     .skip
.key:
    cmp     byte [rsi], 0
    je      .empty
    cmp     byte [rsi], ' '
    je      .key_done
    cmp     byte [rsi], 9
    je      .key_done
    movzx   eax, byte [rsi]
    cmp     al, 'a'
    jb      .kw
    cmp     al, 'z'
    ja      .kw
    sub     al, 32
.kw:
    mov     [rdi], al
    inc     rdi
    inc     rsi
    jmp     .key
.key_done:
    mov     byte [rdi], 0
.val_skip:
    cmp     byte [rsi], ' '
    je      .vs1
    cmp     byte [rsi], 9
    je      .vs1
    jmp     .val
.vs1:
    inc     rsi
    jmp     .val_skip
.val:
    mov     rdi, r8
.copy:
    mov     al, [rsi]
    mov     [rdi], al
    test    al, al
    jz      .ok
    inc     rsi
    inc     rdi
    jmp     .copy
.ok:
    mov     rax, 1
    jmp     .done
.empty:
    xor     rax, rax
.done:
    pop     rdi
    pop     rsi
    pop     rbx
    ret

; rcx = value in/out buffer - strip quotes
global unquote_value
unquote_value:
    push    rsi
    push    rdi
    mov     rsi, rcx
    mov     rdi, rcx
    mov     al, [rsi]
    cmp     al, 34
    je      .quoted
    cmp     al, 39
    je      .quoted
    jmp     .done
.quoted:
    inc     rsi
.copy:
    mov     al, [rsi]
    cmp     al, 34
    je      .end
    cmp     al, 39
    je      .end
    cmp     al, 0
    je      .end
    mov     [rdi], al
    inc     rsi
    inc     rdi
    jmp     .copy
.end:
    mov     byte [rdi], 0
.done:
    pop     rdi
    pop     rsi
    ret

; rcx = line - strip + comment and trim into rcx buffer
global strip_comment_trim
strip_comment_trim:
    push    rsi
    push    rdi
    mov     rsi, rcx
    mov     rdi, rcx
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
    lodsb
    cmp     al, '+'
    je      .end
    cmp     al, 0
    je      .end
    cmp     al, 10
    je      .end
    cmp     al, 13
    je      .end
    stosb
    jmp     .copy
.end:
    mov     byte [rdi], 0
    ; trim trailing space
    dec     rdi
    cmp     rdi, rcx
    jb      .done
.trim:
    cmp     byte [rdi], ' '
    je      .t1
    cmp     byte [rdi], 9
    je      .t1
    jmp     .done
.t1:
    mov     byte [rdi], 0
    dec     rdi
    cmp     rdi, rcx
    jae     .trim
.done:
    pop     rdi
    pop     rsi
    ret

; rcx = list "a b c", rdx = names array, r8 = count ptr
global parse_name_list
parse_name_list:
    push    rbx
    push    rsi
    push    rdi
    mov     rsi, rcx
    mov     rdi, rdx
    xor     ebx, ebx
.loop:
    cmp     byte [rsi], 0
    je      .done
    cmp     byte [rsi], ' '
    je      .skip
    cmp     byte [rsi], 9
    je      .skip
    ; copy one name lowercased
    mov     eax, ebx
    imul    eax, NAME_MAX
    add     rax, rdi
    push    rsi
    mov     rcx, rax
    mov     rdx, rsi
    call    strcpy_lower
    pop     rsi
    inc     ebx
    cmp     ebx, MAX_USERS
    jae     .done
.name_skip:
    cmp     byte [rsi], 0
    je      .done
    cmp     byte [rsi], ' '
    je      .next
    cmp     byte [rsi], 9
    je      .next
    inc     rsi
    jmp     .name_skip
.next:
    jmp     .loop
.skip:
    inc     rsi
    jmp     .loop
.done:
    mov     rax, r8
    mov     [rax], ebx
    pop     rdi
    pop     rsi
    pop     rbx
    ret

; rcx = s — trim trailing space, tab, cr, lf
global trim_trailing
trim_trailing:
    push    rsi
    mov     rsi, rcx
    call    str_len
    test    rax, rax
    jz      .done
    lea     rdi, [rcx + rax - 1]
.loop:
    cmp     rdi, rcx
    jb      .done
    mov     al, [rdi]
    cmp     al, ' '
    je      .cut
    cmp     al, 9
    je      .cut
    cmp     al, 10
    je      .cut
    cmp     al, 13
    je      .cut
    jmp     .done
.cut:
    mov     byte [rdi], 0
    dec     rdi
    jmp     .loop
.done:
    pop     rsi
    ret

%endif
