; Linux x86-64 file I/O (syscalls)

%ifndef KYTO_LINUX_IO_ASM
%define KYTO_LINUX_IO_ASM

%include "inc/io_buf.asm"

extern kyto_environ_ptr

%define SYS_read    0
%define SYS_write   1
%define SYS_open    2
%define SYS_close   3
%define SYS_mkdir   83

%define O_RDONLY    0
%define O_WRONLY    1
%define O_CREAT     64
%define O_TRUNC     512

section .text

; rcx = path, reads into file_buf, rax=1 ok
global read_file_to_buf
read_file_to_buf:
    push    rbx
    push    r12
    mov     r12, rcx
    mov     rax, SYS_open
    mov     rdi, r12
    mov     rsi, O_RDONLY
    xor     edx, edx
    syscall
    cmp     rax, 0
    jl      .fail
    mov     rbx, rax
    mov     rax, SYS_read
    mov     rdi, rbx
    lea     rsi, [file_buf]
    mov     rdx, MAX_FILE - 1
    syscall
    test    rax, rax
    js      .close_fail
    mov     [bytes_read], rax
    mov     rcx, rax
    cmp     rcx, MAX_FILE - 1
    jae     .close_fail
    mov     byte [file_buf + rcx], 0
    mov     rax, SYS_close
    mov     rdi, rbx
    syscall
    mov     rax, 1
    pop     r12
    pop     rbx
    ret
.close_fail:
    mov     rax, SYS_close
    mov     rdi, rbx
    syscall
.fail:
    xor     rax, rax
    pop     r12
    pop     rbx
    ret

; rcx = path, rdx = content
global write_text_file
write_text_file:
    push    rbx
    push    r12
    push    r13
    mov     r13, rdx
    mov     r12, rcx
    mov     rax, SYS_open
    mov     rdi, r12
    mov     rsi, O_WRONLY | O_CREAT | O_TRUNC
    mov     edx, 420
    syscall
    cmp     rax, 0
    jl      .out
    mov     rbx, rax
    mov     rcx, r13
    call    str_len
    mov     rax, SYS_write
    mov     rdi, rbx
    mov     rsi, r13
    mov     rdx, rax
    syscall
    mov     rax, SYS_close
    mov     rdi, rbx
    syscall
.out:
    pop     r13
    pop     r12
    pop     rbx
    ret

; rcx = string
global print_str
print_str:
    push    rbx
    mov     rbx, rcx
    call    str_len
    mov     rax, SYS_write
    mov     rdi, 1
    mov     rsi, rbx
    mov     rdx, rax
    syscall
    pop     rbx
    ret

; rcx = path (one level; ignores EEXIST)
global ensure_dir
ensure_dir:
    push    rbx
    mov     rbx, rcx
    mov     rax, SYS_mkdir
    mov     rdi, rbx
    mov     rsi, 493
    syscall
    pop     rbx
    ret

; rcx = src path, rdx = dst path
global copy_file_path
copy_file_path:
    push    rbx
    push    r12
    push    r13
    mov     r12, rcx
    mov     r13, rdx
    mov     rcx, r12
    call    read_file_to_buf
    test    rax, rax
    jz      .fail
    mov     rcx, qword [bytes_read]
    mov     rax, SYS_open
    mov     rdi, r13
    mov     rsi, O_WRONLY | O_CREAT | O_TRUNC
    mov     edx, 493
    syscall
    cmp     rax, 0
    jl      .fail
    mov     rbx, rax
    mov     rax, SYS_write
    mov     rdi, rbx
    lea     rsi, [file_buf]
    mov     rdx, qword [bytes_read]
    syscall
    mov     rax, SYS_close
    mov     rdi, rbx
    syscall
    mov     rax, 1
    jmp     .done
.fail:
    xor     rax, rax
.done:
    pop     r13
    pop     r12
    pop     rbx
    ret

; rcx = path, rdx = buffer, r8 = byte count — rax=1 ok
global write_binary_file
write_binary_file:
    push    rbx
    push    r12
    push    r13
    push    r14
    mov     r12, rcx
    mov     r13, rdx
    mov     r14, r8
    mov     rax, SYS_open
    mov     rdi, r12
    mov     rsi, O_WRONLY | O_CREAT | O_TRUNC
    mov     edx, 420
    syscall
    cmp     rax, 0
    jl      .fail
    mov     rbx, rax
    mov     rax, SYS_write
    mov     rdi, rbx
    mov     rsi, r13
    mov     rdx, r14
    syscall
    mov     rax, SYS_close
    mov     rdi, rbx
    syscall
    mov     rax, 1
    jmp     .done
.fail:
    xor     rax, rax
.done:
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

; rcx = env name, rdx = out buffer — rax=1 if set
global linux_env_get
linux_env_get:
    push    rbx
    push    rsi
    push    rdi
    push    r12
    mov     r12, rcx
    mov     rdi, rdx
    mov     rbx, [kyto_environ_ptr]
    test    rbx, rbx
    jz      .none
.loop:
    mov     rsi, [rbx]
    test    rsi, rsi
    jz      .none
    mov     rcx, r12
    mov     rdx, rsi
.match:
    mov     al, [rcx]
    test    al, al
    jz      .check_eq
    cmp     al, [rdx]
    jne     .next
    inc     rcx
    inc     rdx
    jmp     .match
.check_eq:
    cmp     byte [rdx], '='
    jne     .next
    inc     rdx
.copy:
    mov     al, [rdx]
    mov     [rdi], al
    test    al, al
    jz      .found
    inc     rdx
    inc     rdi
    jmp     .copy
.found:
    mov     rax, 1
    jmp     .done
.next:
    add     rbx, 8
    jmp     .loop
.none:
    xor     rax, rax
.done:
    pop     r12
    pop     rdi
    pop     rsi
    pop     rbx
    ret

%endif
