; kura encrypt / decrypt — ChaCha20-Poly1305 via crypto.asm

%ifndef KYTO_CMD_CRYPTO_ASM
%define KYTO_CMD_CRYPTO_ASM

section .data
    msg_crypto_usage    db "usage: kura encrypt <input> -o <output>", 10, \
                           "       kura decrypt <input> -o <output>", 10, 0
    msg_crypto_key      db "error: missing KYTO_KEY or ~/.config/kyto/key", 10, 0
    msg_crypto_args     db "error: expected <input> -o <output>", 10, 0
    msg_crypto_fail     db "error: encrypt/decrypt failed", 10, 0
    msg_crypto_read     db "error: cannot read input file", 10, 0
    msg_crypto_write    db "error: cannot write output file", 10, 0
    kw_dash_o           db "-o", 0

section .bss
    crypto_in_path:     resb PATH_MAX
    crypto_out_path:    resb PATH_MAX

section .text

extern cmdline_rest
extern crypto_load_key
extern crypto_encrypt_file
extern crypto_decrypt_file
extern print_str

global cmd_encrypt
global cmd_decrypt

; rax=1 ok — input in crypto_in_path, output in crypto_out_path
parse_crypto_paths:
    push    rbx
    push    rsi
    push    rdi
    mov     rsi, [cmdline_rest]
    test    rsi, rsi
    jz      .fail
    cmp     byte [rsi], 0
    je      .fail
.skip_lead:
    cmp     byte [rsi], ' '
    jne     .sl_done
    inc     rsi
    jmp     .skip_lead
.sl_done:
    cmp     byte [rsi], 9
    jne     .copy_in
    inc     rsi
    jmp     .skip_lead
.copy_in:
    lea     rdi, [crypto_in_path]
.copy_in_loop:
    cmp     byte [rsi], 0
    je      .fail
    cmp     byte [rsi], ' '
    je      .in_done
    cmp     byte [rsi], 9
    je      .in_done
    mov     al, [rsi]
    mov     [rdi], al
    inc     rsi
    inc     rdi
    jmp     .copy_in_loop
.in_done:
    mov     byte [rdi], 0
.skip_mid:
    cmp     byte [rsi], ' '
    jne     .sm_done
    inc     rsi
    jmp     .skip_mid
.sm_done:
    cmp     byte [rsi], 9
    jne     .check_o
    inc     rsi
    jmp     .skip_mid
.check_o:
    cmp     byte [rsi], '-'
    jne     .fail
    cmp     byte [rsi + 1], 'o'
    jne     .fail
    add     rsi, 2
.skip_out:
    cmp     byte [rsi], ' '
    jne     .so_done
    inc     rsi
    jmp     .skip_out
.so_done:
    cmp     byte [rsi], 9
    jne     .copy_out
    inc     rsi
    jmp     .skip_out
.copy_out:
    lea     rdi, [crypto_out_path]
.copy_out_loop:
    cmp     byte [rsi], 0
    je      .out_done
    cmp     byte [rsi], ' '
    je      .out_done
    cmp     byte [rsi], 9
    je      .out_done
    mov     al, [rsi]
    mov     [rdi], al
    inc     rsi
    inc     rdi
    jmp     .copy_out_loop
.out_done:
    mov     byte [rdi], 0
    mov     rax, 1
    jmp     .done
.fail:
    xor     rax, rax
.done:
    pop     rdi
    pop     rsi
    pop     rbx
    ret

cmd_encrypt:
    call    parse_crypto_paths
    test    rax, rax
    jz      crypto_bad_args
    call    crypto_load_key
    test    rax, rax
    jz      crypto_bad_key
    lea     rcx, [crypto_in_path]
    lea     rdx, [crypto_out_path]
    call    crypto_encrypt_file
    cmp     rax, 1
    je      crypto_read_fail
    cmp     rax, 4
    je      crypto_write_fail
    test    rax, rax
    jnz     crypto_fail
    xor     eax, eax
    ret

cmd_decrypt:
    call    parse_crypto_paths
    test    rax, rax
    jz      crypto_bad_args
    call    crypto_load_key
    test    rax, rax
    jz      crypto_bad_key
    lea     rcx, [crypto_in_path]
    lea     rdx, [crypto_out_path]
    call    crypto_decrypt_file
    cmp     rax, 1
    je      crypto_read_fail
    cmp     rax, 4
    je      crypto_write_fail
    test    rax, rax
    jnz     crypto_fail
    xor     eax, eax
    ret

crypto_bad_args:
    lea     rcx, [msg_crypto_args]
    call    print_str
    lea     rcx, [msg_crypto_usage]
    call    print_str
    mov     eax, 1
    ret
crypto_bad_key:
    lea     rcx, [msg_crypto_key]
    call    print_str
    mov     eax, 1
    ret
crypto_read_fail:
    lea     rcx, [msg_crypto_read]
    call    print_str
    mov     eax, 1
    ret
crypto_write_fail:
    lea     rcx, [msg_crypto_write]
    call    print_str
    mov     eax, 1
    ret
crypto_fail:
    lea     rcx, [msg_crypto_fail]
    call    print_str
    mov     eax, 1
    ret

%endif
