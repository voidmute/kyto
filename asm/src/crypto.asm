; ChaCha20-Poly1305 (RFC 8439) — compatible with kyto-core crypto.rs

%ifndef KYTO_CRYPTO_ASM
%define KYTO_CRYPTO_ASM

%ifndef KYTO_LINUX
extern GetEnvironmentVariableA
extern ExpandEnvironmentStringsA
%else
extern kyto_environ_ptr
extern home_buf
extern find_home
extern linux_env_get
%endif
extern read_file_to_buf
extern write_binary_file
extern trim_trailing
extern strcpy
extern strcat
extern file_buf
extern bytes_read
extern out_buf

%include "inc/const.inc"

section .data
    env_kyto_key    db "KYTO_KEY", 0
    env_userprofile db "%USERPROFILE%", 0
    key_rel_path    db "/.config/kyto/key", 0
    magic_kyto      db "KYTO"
    hex_digits      db "0123456789abcdef", 0

section .bss
global crypto_key
crypto_key:         resb 32
crypto_nonce:       resb 12
crypto_tag:         resb 16
crypto_poly_key:    resb 32
key_hex_buf:        resb 128
key_path_buf:       resb PATH_MAX
home_path_buf:      resb PATH_MAX
chacha_st:          resd 16
chacha_x:           resd 16
poly_r:             resd 5
poly_h:             resd 5
poly_s:             resd 4
poly_pad:           resd 4
poly_t:             resq 5
poly_blk:           resb 16
expected_tag:       resb 16

section .text

; --- hex decode: rcx=hex, rdx=out, r8=byte count — rax=1 ok ---
global hex_decode
hex_decode:
    push    rbx
    push    rsi
    push    rdi
    mov     rsi, rcx
    mov     rdi, rdx
    mov     ebx, r8d
    xor     r8d, r8d
.byte_loop:
    test    ebx, ebx
    jz      .ok
    mov     al, [rsi]
    inc     rsi
    test    al, al
    jz      .fail
    cmp     al, ' '
    je      .byte_loop
    cmp     al, 9
    je      .byte_loop
    cmp     al, 10
    je      .byte_loop
    cmp     al, 13
    je      .byte_loop
    push    rsi
    call    .hex_nibble
    pop     rsi
    jc      .fail
    test    r8d, r8d
    jz      .hi
    mov     ah, al
    shl     ah, 4
    or      ah, byte [rdi - 1]
    mov     [rdi - 1], ah
    xor     r8d, r8d
    dec     ebx
    jmp     .byte_loop
.hi:
    mov     [rdi], al
    inc     rdi
    mov     r8d, 1
    jmp     .byte_loop
.ok:
    test    r8d, r8d
    jnz     .fail
    mov     rax, 1
    jmp     .done
.fail:
    xor     rax, rax
.done:
    pop     rdi
    pop     rsi
    pop     rbx
    ret
.hex_nibble:
    cmp     al, '0'
    jb      .bad
    cmp     al, '9'
    jbe     .dig
    cmp     al, 'a'
    jb      .up
    cmp     al, 'f'
    jbe     .alo
.up:
    cmp     al, 'A'
    jb      .bad
    cmp     al, 'F'
    ja      .bad
    sub     al, 'A' - 10
    clc
    ret
.dig:
    sub     al, '0'
    clc
    ret
.alo:
    sub     al, 'a' - 10
    clc
    ret
.bad:
    stc
    ret

; --- RDRAND bytes: rcx=buf, edx=count ---
global fill_random
fill_random:
    push    rbx
    push    rsi
    mov     rsi, rcx
    mov     ebx, edx
.loop:
    test    ebx, ebx
    jz      .done
    rdrand  rax
    jc      .got
    rdtsc
.got:
    mov     [rsi], al
    inc     rsi
    dec     ebx
    shr     rax, 8
    test    ebx, ebx
    jz      .done
    mov     [rsi], al
    inc     rsi
    dec     ebx
    jmp     .loop
.done:
    pop     rsi
    pop     rbx
    ret

; --- load 32-byte key — rax=1 ok, key in crypto_key ---
global crypto_load_key
crypto_load_key:
    push    rbx
    push    rsi
    push    rdi
%ifndef KYTO_LINUX
    WIN_ALIGN_PROLOGUE
    lea     rcx, [env_kyto_key]
    lea     rdx, [key_hex_buf]
    mov     r8d, 128
    call    GetEnvironmentVariableA
    test    rax, rax
    jz      .from_file
    lea     rcx, [key_hex_buf]
    call    trim_trailing
    lea     rcx, [key_hex_buf]
    lea     rdx, [crypto_key]
    mov     r8d, 32
    call    hex_decode
    test    rax, rax
    jnz     .ok
    jmp     .fail
.from_file:
    lea     rcx, [env_userprofile]
    lea     rdx, [home_path_buf]
    mov     r8d, PATH_MAX
    call    ExpandEnvironmentStringsA
    test    rax, rax
    jz      .fail
    lea     rcx, [key_path_buf]
    lea     rdx, [home_path_buf]
    call    strcpy
%else
    lea     rcx, [env_kyto_key]
    lea     rdx, [key_hex_buf]
    call    linux_env_get
    test    rax, rax
    jz      .from_file
    lea     rcx, [key_hex_buf]
    call    trim_trailing
    lea     rcx, [key_hex_buf]
    lea     rdx, [crypto_key]
    mov     r8d, 32
    call    hex_decode
    test    rax, rax
    jnz     .ok
    jmp     .fail
.from_file:
    call    find_home
    test    rax, rax
    jz      .fail
    lea     rcx, [key_path_buf]
    lea     rdx, [home_buf]
    call    strcpy
%endif
    lea     rcx, [key_path_buf]
    lea     rdx, [key_rel_path]
    call    strcat
    lea     rcx, [key_path_buf]
    call    read_file_to_buf
    test    rax, rax
    jz      .fail
    lea     rcx, [file_buf]
    call    trim_trailing
    lea     rcx, [file_buf]
    lea     rdx, [crypto_key]
    mov     r8d, 32
    call    hex_decode
    test    rax, rax
    jz      .fail
.ok:
    mov     rax, 1
    jmp     .done
.fail:
    xor     rax, rax
.done:
%ifndef KYTO_LINUX
    WIN_ALIGN_EPILOGUE
%endif
    pop     rdi
    pop     rsi
    pop     rbx
    ret

; ChaCha20 init: key=crypto_key, nonce=rsi, counter=edi
chacha_init:
    mov     eax, 0x61707865
    mov     dword [chacha_st], eax
    mov     eax, 0x3320646e
    mov     dword [chacha_st + 4], eax
    mov     eax, 0x79622d32
    mov     dword [chacha_st + 8], eax
    mov     eax, 0x6b206574
    mov     dword [chacha_st + 12], eax
    xor     ecx, ecx
.key_copy:
    cmp     ecx, 8
    jae     .key_done
    mov     eax, [crypto_key + ecx * 4]
    mov     dword [chacha_st + 16 + ecx * 4], eax
    inc     ecx
    jmp     .key_copy
.key_done:
    mov     dword [chacha_st + 48], edi
    mov     eax, [rsi]
    mov     dword [chacha_st + 52], eax
    mov     eax, [rsi + 4]
    mov     dword [chacha_st + 56], eax
    mov     eax, [rsi + 8]
    mov     dword [chacha_st + 60], eax
.done:
    ret

%macro CHACHA_QR 4
    mov     eax, dword [chacha_x + %2 * 4]
    add     dword [chacha_x + %1 * 4], eax
    mov     eax, dword [chacha_x + %1 * 4]
    xor     eax, dword [chacha_x + %4 * 4]
    rol     eax, 16
    mov     dword [chacha_x + %4 * 4], eax
    mov     eax, dword [chacha_x + %3 * 4]
    add     dword [chacha_x + %2 * 4], eax
    mov     eax, dword [chacha_x + %2 * 4]
    xor     eax, dword [chacha_x + %3 * 4]
    rol     eax, 12
    mov     dword [chacha_x + %3 * 4], eax
    mov     eax, dword [chacha_x + %2 * 4]
    add     dword [chacha_x + %1 * 4], eax
    mov     eax, dword [chacha_x + %1 * 4]
    xor     eax, dword [chacha_x + %4 * 4]
    rol     eax, 8
    mov     dword [chacha_x + %4 * 4], eax
    mov     eax, dword [chacha_x + %3 * 4]
    add     dword [chacha_x + %2 * 4], eax
    mov     eax, dword [chacha_x + %2 * 4]
    xor     eax, dword [chacha_x + %3 * 4]
    rol     eax, 7
    mov     dword [chacha_x + %3 * 4], eax
%endmacro

; one ChaCha20 block into chacha_x (adds original chacha_st)
chacha_block:
    push    rbx
    push    r10
    mov     ecx, 16
    xor     r10d, r10d
.copy_in:
    mov     eax, dword [chacha_st + r10 * 4]
    mov     dword [chacha_x + r10 * 4], eax
    inc     r10d
    dec     ecx
    jnz     .copy_in
    mov     ebx, 10
.round:
    CHACHA_QR 0, 4, 8, 12
    CHACHA_QR 1, 5, 9, 13
    CHACHA_QR 2, 6, 10, 14
    CHACHA_QR 3, 7, 11, 15
    CHACHA_QR 0, 5, 10, 15
    CHACHA_QR 1, 6, 11, 12
    CHACHA_QR 2, 7, 8, 13
    CHACHA_QR 3, 4, 9, 14
    dec     ebx
    jnz     .round
    xor     r10d, r10d
.add_out:
    cmp     r10d, 16
    jae     .done
    mov     eax, dword [chacha_x + r10 * 4]
    add     eax, dword [chacha_st + r10 * 4]
    mov     dword [chacha_x + r10 * 4], eax
    inc     r10d
    jmp     .add_out
.done:
    pop     r10
    pop     rbx
    ret

; derive poly1305 key (counter 0) into crypto_poly_key
chacha_poly_key:
    push    rbx
    push    r10
    mov     rsi, rcx
    xor     edi, edi
    call    chacha_init
    call    chacha_block
    xor     r10d, r10d
.copy:
    cmp     r10d, 8
    jae     .done
    mov     eax, dword [chacha_x + r10 * 4]
    mov     dword [crypto_poly_key + r10 * 4], eax
    inc     r10d
    jmp     .copy
.done:
    pop     r10
    pop     rbx
    ret

; rcx=nonce, rsi=src, rdi=dst, edx=len, r8d=counter start
chacha_crypt:
    push    r12
    push    r13
    push    r14
    push    r15
    push    rbx
    mov     r12, rcx
    mov     r13, rsi
    mov     r14, rdi
    mov     r15d, edx
    mov     ebx, r8d
.ct_loop:
    test    r15d, r15d
    jz      .done
    push    rbx
    mov     rsi, r12
    mov     edi, ebx
    call    chacha_init
    call    chacha_block
    pop     rbx
    xor     ecx, ecx
.xor_blk:
    cmp     ecx, 64
    jae     .next_ctr
    test    r15d, r15d
    jz      .done
    mov     al, [r13]
    mov     ah, byte [chacha_x + ecx]
    xor     al, ah
    mov     [r14], al
    inc     r13
    inc     r14
    inc     ecx
    dec     r15d
    jmp     .xor_blk
.next_ctr:
    inc     ebx
    jmp     .ct_loop
.done:
    pop     rbx
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    ret

; --- Poly1305 (donna-32 style, RFC 8439) ---

; RFC 8439 / poly1305-donna-32 r clamp from crypto_poly_key[0..15]
poly1305_init_state:
    push    rbx
    push    r11
    push    r10
    xor     eax, eax
    mov     [poly_h], eax
    mov     [poly_h + 4], eax
    mov     [poly_h + 8], eax
    mov     [poly_h + 12], eax
    mov     [poly_h + 16], eax
    lea     r11, [crypto_poly_key]
    mov     eax, dword [r11 + 16]
    mov     dword [poly_pad], eax
    mov     eax, dword [r11 + 20]
    mov     dword [poly_pad + 4], eax
    mov     eax, dword [r11 + 24]
    mov     dword [poly_pad + 8], eax
    mov     eax, dword [r11 + 28]
    mov     dword [poly_pad + 12], eax
    mov     eax, dword [r11]
    mov     ebx, dword [r11 + 3]
    mov     ecx, dword [r11 + 6]
    mov     edx, dword [r11 + 9]
    mov     r8d, dword [r11 + 12]
    mov     r9d, eax
    and     r9d, 0x3ffffff
    mov     dword [poly_r], r9d
    mov     r9d, eax
    shr     r9d, 26
    mov     r10d, ebx
    shl     r10d, 6
    or      r9d, r10d
    and     r9d, 0x3ffff03
    mov     dword [poly_r + 4], r9d
    mov     r9d, ebx
    shr     r9d, 20
    mov     r10d, ecx
    shl     r10d, 12
    or      r9d, r10d
    and     r9d, 0x3ffc0ff
    mov     dword [poly_r + 8], r9d
    mov     r9d, ecx
    shr     r9d, 14
    mov     r10d, edx
    shl     r10d, 18
    or      r9d, r10d
    and     r9d, 0x3f03fff
    mov     dword [poly_r + 12], r9d
    mov     r9d, edx
    shr     r9d, 8
    mov     r10d, r8d
    shl     r10d, 24
    or      r9d, r10d
    and     r9d, 0x00fffff
    mov     dword [poly_r + 16], r9d
    mov     eax, [poly_r + 4]
    imul    eax, 5
    mov     [poly_s], eax
    mov     eax, [poly_r + 8]
    imul    eax, 5
    mov     [poly_s + 4], eax
    mov     eax, [poly_r + 12]
    imul    eax, 5
    mov     [poly_s + 8], eax
    mov     eax, [poly_r + 16]
    imul    eax, 5
    mov     [poly_s + 12], eax
    pop     r10
    pop     r11
    pop     rbx
    ret

poly1305_mul:
    push    rbx
    push    rsi
    push    rdi
    mov     eax, [poly_h]
    mov     r8d, [poly_r]
    mul     r8
    mov     [poly_t], rax
    mov     eax, [poly_h + 4]
    mov     r8d, [poly_s + 12]
    mul     r8
    add     [poly_t], rax
    mov     eax, [poly_h + 8]
    mov     r8d, [poly_s + 8]
    mul     r8
    add     [poly_t], rax
    mov     eax, [poly_h + 12]
    mov     r8d, [poly_s + 4]
    mul     r8
    add     [poly_t], rax
    mov     eax, [poly_h + 16]
    mov     r8d, [poly_s]
    mul     r8
    add     [poly_t], rax
    mov     eax, [poly_h]
    mov     r8d, [poly_r + 4]
    mul     r8
    add     [poly_t + 8], rax
    mov     eax, [poly_h + 4]
    mov     r8d, [poly_r]
    mul     r8
    add     [poly_t + 8], rax
    mov     eax, [poly_h + 8]
    mov     r8d, [poly_s + 12]
    mul     r8
    add     [poly_t + 8], rax
    mov     eax, [poly_h + 12]
    mov     r8d, [poly_s + 8]
    mul     r8
    add     [poly_t + 8], rax
    mov     eax, [poly_h + 16]
    mov     r8d, [poly_s + 4]
    mul     r8
    add     [poly_t + 8], rax
    mov     eax, [poly_h]
    mov     r8d, [poly_r + 8]
    mul     r8
    add     [poly_t + 16], rax
    mov     eax, [poly_h + 4]
    mov     r8d, [poly_r + 4]
    mul     r8
    add     [poly_t + 16], rax
    mov     eax, [poly_h + 8]
    mov     r8d, [poly_r]
    mul     r8
    add     [poly_t + 16], rax
    mov     eax, [poly_h + 12]
    mov     r8d, [poly_s + 12]
    mul     r8
    add     [poly_t + 16], rax
    mov     eax, [poly_h + 16]
    mov     r8d, [poly_s + 8]
    mul     r8
    add     [poly_t + 16], rax
    mov     eax, [poly_h]
    mov     r8d, [poly_r + 12]
    mul     r8
    add     [poly_t + 24], rax
    mov     eax, [poly_h + 4]
    mov     r8d, [poly_r + 8]
    mul     r8
    add     [poly_t + 24], rax
    mov     eax, [poly_h + 8]
    mov     r8d, [poly_r + 4]
    mul     r8
    add     [poly_t + 24], rax
    mov     eax, [poly_h + 12]
    mov     r8d, [poly_r]
    mul     r8
    add     [poly_t + 24], rax
    mov     eax, [poly_h + 16]
    mov     r8d, [poly_s + 12]
    mul     r8
    add     [poly_t + 24], rax
    mov     eax, [poly_h]
    mov     r8d, [poly_r + 16]
    mul     r8
    add     [poly_t + 32], rax
    mov     eax, [poly_h + 4]
    mov     r8d, [poly_r + 12]
    mul     r8
    add     [poly_t + 32], rax
    mov     eax, [poly_h + 8]
    mov     r8d, [poly_r + 8]
    mul     r8
    add     [poly_t + 32], rax
    mov     eax, [poly_h + 12]
    mov     r8d, [poly_r + 4]
    mul     r8
    add     [poly_t + 32], rax
    mov     eax, [poly_h + 16]
    mov     r8d, [poly_r]
    mul     r8
    add     [poly_t + 32], rax
    mov     rax, [poly_t]
    mov     rcx, rax
    shr     rcx, 26
    and     eax, 0x3ffffff
    mov     [poly_h], eax
    mov     rax, [poly_t + 8]
    add     rax, rcx
    mov     rcx, rax
    shr     rcx, 26
    and     eax, 0x3ffffff
    mov     [poly_h + 4], eax
    mov     rax, [poly_t + 16]
    add     rax, rcx
    mov     rcx, rax
    shr     rcx, 26
    and     eax, 0x3ffffff
    mov     [poly_h + 8], eax
    mov     rax, [poly_t + 24]
    add     rax, rcx
    mov     rcx, rax
    shr     rcx, 26
    and     eax, 0x3ffffff
    mov     [poly_h + 12], eax
    mov     rax, [poly_t + 32]
    add     rax, rcx
    mov     rcx, rax
    shr     rcx, 26
    and     eax, 0x3ffffff
    mov     [poly_h + 16], eax
    mov     eax, ecx
    imul    eax, 5
    add     [poly_h], eax
    adc     dword [poly_h + 4], 0
    adc     dword [poly_h + 8], 0
    adc     dword [poly_h + 12], 0
    adc     dword [poly_h + 16], 0
    pop     rdi
    pop     rsi
    pop     rbx
    ret

; rsi=block ptr, ecx=hibit (0 or 1)
poly1305_block:
    push    rbx
    push    rdi
    mov     eax, [rsi]
    mov     ebx, [rsi + 4]
    mov     edx, [rsi + 8]
    mov     edi, [rsi + 12]
    mov     r8d, eax
    and     r8d, 0x3ffffff
    add     [poly_h], r8d
    mov     r8d, eax
    shr     r8d, 26
    mov     r9d, ebx
    shl     r9d, 6
    or      r8d, r9d
    and     r8d, 0x3ffffff
    add     [poly_h + 4], r8d
    mov     r8d, ebx
    shr     r8d, 20
    mov     r9d, edx
    shl     r9d, 12
    or      r8d, r9d
    and     r8d, 0x3ffffff
    add     [poly_h + 8], r8d
    mov     r8d, edx
    shr     r8d, 14
    mov     r9d, edi
    shl     r9d, 18
    or      r8d, r9d
    and     r8d, 0x3ffffff
    add     [poly_h + 12], r8d
    mov     r8d, edi
    shr     r8d, 8
    and     r8d, 0x3ffffff
    add     [poly_h + 16], r8d
    test    ecx, ecx
    jz      .no_hibit
    add     dword [poly_h + 16], 0x1000000
.no_hibit:
    call    poly1305_mul
    pop     rdi
    pop     rbx
    ret

; finalize poly1305 — tag in crypto_tag (donna-32 emit)
poly1305_finish:
    push    rbx
    mov     eax, [poly_h]
    add     eax, [poly_pad]
    mov     ebx, eax
    shr     eax, 32
    mov     ecx, [poly_h + 4]
    add     ecx, [poly_pad + 4]
    add     ecx, eax
    mov     edx, ecx
    shr     ecx, 32
    mov     eax, [poly_h + 8]
    add     eax, [poly_pad + 8]
    add     eax, ecx
    mov     r8d, eax
    shr     eax, 32
    mov     ecx, [poly_h + 12]
    add     ecx, [poly_pad + 12]
    add     ecx, eax
    mov     r9d, ecx
    shr     ecx, 32
    mov     eax, [poly_h + 16]
    add     eax, ecx
    and     ebx, 0xffffffff
    and     edx, 0xffffffff
    and     r8d, 0xffffffff
    and     r9d, 0xffffffff
    mov     ecx, eax
    and     ecx, 3
    mov     eax, ecx
    shr     ecx, 2
    imul    ecx, 5
    add     eax, ecx
    mov     ecx, eax
    shr     eax, 2
    dec     eax
    mov     r10d, 0x3fffffb
    mov     r11d, ebx
    sub     r11d, r10d
    and     r11d, eax
    not     eax
    and     ebx, eax
    or      ebx, r11d
    mov     r10d, 0x3ffffff
    mov     r11d, edx
    sub     r11d, r10d
    and     r11d, ecx
    not     ecx
    and     edx, ecx
    or      edx, r11d
    mov     r10d, 0x3ffffff
    mov     r11d, r8d
    sub     r11d, r10d
    mov     ecx, eax
    and     r11d, ecx
    not     eax
    and     r8d, eax
    or      r8d, r11d
    mov     r10d, 0x3ffffff
    mov     r11d, r9d
    sub     r11d, r10d
    mov     ecx, eax
    and     r11d, ecx
    and     r9d, eax
    or      r9d, r11d
    mov     [crypto_tag], ebx
    mov     [crypto_tag + 4], edx
    mov     [crypto_tag + 8], r8d
    mov     [crypto_tag + 12], r9d
    pop     rbx
    ret

; rcx=ct, edx=ct_len — tag in crypto_tag
poly1305_aead_mac:
    push    rbx
    push    rsi
    push    rdi
    push    r12
    cld
    mov     rsi, rcx
    mov     r12d, edx
    call    poly1305_init_state
    mov     ebx, r12d
.mac16:
    cmp     ebx, 16
    jb      .tail
    mov     ecx, 1
    call    poly1305_block
    sub     ebx, 16
    add     rsi, 16
    test    ebx, ebx
    jnz     .mac16
.tail:
    test    ebx, ebx
    jnz     .partial
.pad16:
    lea     rdi, [poly_blk]
    mov     byte [rdi], 1
    mov     byte [rdi + 1], 0
    mov     byte [rdi + 2], 0
    mov     byte [rdi + 3], 0
    mov     byte [rdi + 4], 0
    mov     byte [rdi + 5], 0
    mov     byte [rdi + 6], 0
    mov     byte [rdi + 7], 0
    mov     byte [rdi + 8], 0
    mov     byte [rdi + 9], 0
    mov     byte [rdi + 10], 0
    mov     byte [rdi + 11], 0
    mov     byte [rdi + 12], 0
    mov     byte [rdi + 13], 0
    mov     byte [rdi + 14], 0
    mov     byte [rdi + 15], 0
    mov     rsi, rdi
    mov     ecx, 1
    call    poly1305_block
    jmp     .lens
.partial:
    test    ebx, ebx
    jz      .pad16
    lea     rdi, [poly_blk]
    xor     ecx, ecx
.pad_copy:
    cmp     ecx, ebx
    jae     .pad_fill
    mov     al, [rsi + rcx]
    mov     [rdi + rcx], al
    inc     ecx
    jmp     .pad_copy
.pad_fill:
    mov     byte [rdi + rcx], 1
    inc     ecx
    cmp     ecx, 16
    jae     .pad_done
    mov     byte [rdi + rcx], 0
    inc     ecx
    jmp     .pad_fill
.pad_done:
    mov     rsi, rdi
    mov     ecx, 1
    call    poly1305_block
.lens:
    xor     eax, eax
    mov     [poly_blk], eax
    mov     [poly_blk + 4], eax
    mov     [poly_blk + 8], eax
    mov     [poly_blk + 12], eax
    mov     eax, r12d
    mov     [poly_blk + 8], eax
    lea     rsi, [poly_blk]
    mov     ecx, 1
    call    poly1305_block
    call    poly1305_finish
    pop     r12
    pop     rdi
    pop     rsi
    pop     rbx
    ret

; AEAD encrypt: rsi=plain, edi=len, rcx=nonce, rdx=ct out — tag in crypto_tag
aead_encrypt:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r10
    mov     r12, rsi
    mov     r13d, edi
    mov     r14, rcx
    mov     r10, rdx
    mov     rcx, r14
    call    chacha_poly_key
    mov     rcx, r14
    mov     rsi, r12
    mov     rdi, r10
    mov     edx, r13d
    mov     r8d, 1
    call    chacha_crypt
    mov     rcx, r10
    mov     edx, r13d
    call    poly1305_aead_mac
    pop     r10
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; AEAD decrypt: rsi=ct, edi=len, rcx=nonce, rdx=plain out, r8=expected tag — rax=0 ok
aead_decrypt:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    push    r8
    mov     r12, rsi
    mov     r13d, edi
    mov     r14, rcx
    mov     r15, rdx
    mov     rcx, r14
    call    chacha_poly_key
    mov     rcx, r12
    mov     edx, r13d
    call    poly1305_aead_mac
    pop     r8
    lea     rsi, [crypto_tag]
    mov     rdi, r8
    mov     ebx, 16
.tag_cmp:
    test    ebx, ebx
    jz      .tag_ok
    mov     al, [rsi]
    cmp     al, [rdi]
    jne     .bad
    inc     rsi
    inc     rdi
    dec     ebx
    jmp     .tag_cmp
.tag_ok:
    mov     rcx, r14
    mov     rsi, r12
    mov     rdi, r15
    mov     edx, r13d
    mov     r8d, 1
    call    chacha_crypt
    xor     rax, rax
    jmp     .done
.bad:
    mov     rax, 1
.done:
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; rcx=input path, rdx=output path — rax=0 ok
global crypto_encrypt_file
crypto_encrypt_file:
    push    rbx
    push    rsi
    push    rdi
    push    r12
    push    r13
    sub     rsp, 8
    mov     r12, rcx
    mov     r13, rdx
    call    crypto_load_key
    test    rax, rax
    jz      .err_key
    mov     rcx, r12
    call    read_file_to_buf
    test    rax, rax
    jz      .err_read
    mov     eax, dword [bytes_read]
    mov     dword [rsp], eax
    lea     rcx, [crypto_nonce]
    mov     edx, 12
    call    fill_random
    mov     rsi, file_buf
    lea     rdx, [out_buf + 16]
    lea     rcx, [crypto_nonce]
    mov     edi, dword [rsp]
    call    aead_encrypt
    mov     rdi, out_buf
    mov     eax, 4
    lea     rsi, [magic_kyto]
.copy_magic:
    mov     bl, [rsi]
    mov     [rdi], bl
    inc     rsi
    inc     rdi
    dec     eax
    jnz     .copy_magic
    mov     ecx, 12
    lea     rsi, [crypto_nonce]
.copy_nonce:
    mov     bl, [rsi]
    mov     [rdi], bl
    inc     rsi
    inc     rdi
    loop    .copy_nonce
    lea     rsi, [out_buf + 16]
    mov     ecx, dword [rsp]
.copy_ct:
    mov     bl, [rsi]
    mov     [rdi], bl
    inc     rsi
    inc     rdi
    loop    .copy_ct
    mov     ecx, 16
    lea     rsi, [crypto_tag]
.copy_tag:
    mov     bl, [rsi]
    mov     [rdi], bl
    inc     rsi
    inc     rdi
    loop    .copy_tag
    mov     eax, dword [rsp]
    add     eax, 32
    mov     r8d, eax
    mov     rcx, r13
    lea     rdx, [out_buf]
    call    write_binary_file
    test    rax, rax
    jz      .err_io
    xor     rax, rax
    jmp     .done
.err_key:
    mov     rax, 2
    jmp     .done
.err_read:
    mov     rax, 1
    jmp     .done
.err_io:
    mov     rax, 4
.done:
    add     rsp, 8
    pop     r13
    pop     r12
    pop     rdi
    pop     rsi
    pop     rbx
    ret

; rcx=input path, rdx=output path — rax=0 ok
global crypto_decrypt_file
crypto_decrypt_file:
    push    rbx
    push    rsi
    push    rdi
    push    r12
    push    r13
    sub     rsp, 8
    mov     r12, rcx
    mov     r13, rdx
    call    crypto_load_key
    test    rax, rax
    jz      .err_key
    mov     rcx, r12
    call    read_file_to_buf
    test    rax, rax
    jz      .err_io
    mov     eax, dword [bytes_read]
    cmp     eax, 32
    jb      .err_crypto
    lea     rsi, [file_buf]
    lea     rdi, [magic_kyto]
    mov     ebx, 4
.magic_cmp:
    test    ebx, ebx
    jz      .magic_ok
    mov     al, [rsi]
    cmp     al, [rdi]
    jne     .err_crypto
    inc     rsi
    inc     rdi
    dec     ebx
    jmp     .magic_cmp
.magic_ok:
    lea     rcx, [file_buf + 4]
    mov     eax, dword [bytes_read]
    sub     eax, 32
    jb      .err_crypto
    mov     ebx, eax
    lea     rsi, [file_buf + 16]
    lea     rdx, [out_buf]
    lea     r8, [file_buf + 16]
    add     r8, rbx
    mov     edi, ebx
    call    aead_decrypt
    test    rax, rax
    jnz     .err_crypto
    mov     rcx, r13
    lea     rdx, [out_buf]
    mov     r8, rbx
    call    write_binary_file
    test    rax, rax
    jz      .err_io
    xor     rax, rax
    jmp     .done
.err_key:
    mov     rax, 2
    jmp     .done
.err_read:
    mov     rax, 1
    jmp     .done
.err_crypto:
    mov     rax, 3
    jmp     .done
.err_io:
    mov     rax, 4
.done:
    add     rsp, 8
    pop     r13
    pop     r12
    pop     rdi
    pop     rsi
    pop     rbx
    ret

%endif
