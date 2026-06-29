; Windows file I/O helpers

%ifndef KYTO_WIN_IO_ASM
%define KYTO_WIN_IO_ASM

extern CreateFileA
extern ReadFile
extern WriteFile
extern CloseHandle
extern GetStdHandle
extern CreateDirectoryA
extern CopyFileA

%include "inc/io_buf.asm"

%macro WIN_ALIGN_PROLOGUE 0
    push    rbp
    mov     rbp, rsp
    and     rsp, -16
    sub     rsp, 64
%endmacro

%macro WIN_ALIGN_EPILOGUE 0
    mov     rsp, rbp
    pop     rbp
%endmacro

section .text

; rcx = path, reads into file_buf, rax=1 ok
global read_file_to_buf
read_file_to_buf:
    push    rbx
    push    rsi
    WIN_ALIGN_PROLOGUE
    mov     rbx, rcx
    mov     rcx, rbx
    mov     edx, GENERIC_READ
    xor     r8d, r8d
    xor     r9d, r9d
    mov     dword [rsp+32], OPEN_EXISTING
    mov     dword [rsp+40], FILE_ATTRIBUTE_NORMAL
    mov     qword [rsp+48], 0
    call    CreateFileA
    cmp     rax, -1
    je      .fail
    mov     rsi, rax
    mov     rcx, rsi
    lea     rdx, [file_buf]
    mov     r8d, MAX_FILE - 1
    lea     r9, [bytes_read]
    mov     qword [rsp+32], 0
    call    ReadFile
    test    rax, rax
    jz      .close_fail
    mov     rcx, rsi
    call    CloseHandle
    mov     ecx, dword [bytes_read]
    cmp     ecx, MAX_FILE - 1
    jae     .fail
    mov     byte [file_buf + rcx], 0
    mov     rax, 1
    jmp     .out
.close_fail:
    mov     rcx, rsi
    call    CloseHandle
.fail:
    xor     rax, rax
.out:
    WIN_ALIGN_EPILOGUE
    pop     rsi
    pop     rbx
    ret

; rcx = path, rdx = content
global write_text_file
write_text_file:
    push    rbx
    push    rsi
    push    rdi
    WIN_ALIGN_PROLOGUE
    mov     rsi, rdx
    mov     rbx, rcx
    mov     rcx, rbx
    mov     edx, GENERIC_WRITE
    xor     r8d, r8d
    xor     r9d, r9d
    mov     dword [rsp+32], CREATE_ALWAYS
    mov     dword [rsp+40], FILE_ATTRIBUTE_NORMAL
    mov     qword [rsp+48], 0
    call    CreateFileA
    cmp     rax, -1
    je      .out
    mov     rbx, rax
    mov     rcx, rsi
    call    str_len
    mov     r8, rax
    mov     rcx, rbx
    mov     rdx, rsi
    lea     r9, [bytes_read]
    mov     qword [rsp+32], 0
    call    WriteFile
    mov     rcx, rbx
    call    CloseHandle
.out:
    WIN_ALIGN_EPILOGUE
    pop     rdi
    pop     rsi
    pop     rbx
    ret

; rcx = string
global print_str
print_str:
    push    rbx
    push    rsi
    WIN_ALIGN_PROLOGUE
    mov     rsi, rcx
    mov     ecx, STD_OUTPUT_HANDLE
    call    GetStdHandle
    mov     rbx, rax
    mov     rcx, rsi
    call    str_len
    mov     r8, rax
    mov     rcx, rbx
    mov     rdx, rsi
    lea     r9, [bytes_read]
    mov     qword [rsp+32], 0
    call    WriteFile
    WIN_ALIGN_EPILOGUE
    pop     rsi
    pop     rbx
    ret

; rcx = path
global ensure_dir
ensure_dir:
    push    rbx
    WIN_ALIGN_PROLOGUE
    mov     rbx, rcx
    mov     rcx, rbx
    xor     edx, edx
    call    CreateDirectoryA
    WIN_ALIGN_EPILOGUE
    pop     rbx
    ret

; rcx = path, rdx = buffer, r8 = byte count — rax=1 ok
global write_binary_file
write_binary_file:
    push    rbx
    push    rsi
    push    rdi
    WIN_ALIGN_PROLOGUE
    mov     rdi, r8
    mov     rsi, rdx
    mov     rbx, rcx
    mov     rcx, rbx
    mov     edx, GENERIC_WRITE
    xor     r8d, r8d
    xor     r9d, r9d
    mov     dword [rsp+32], CREATE_ALWAYS
    mov     dword [rsp+40], FILE_ATTRIBUTE_NORMAL
    mov     qword [rsp+48], 0
    call    CreateFileA
    cmp     rax, -1
    je      .fail
    mov     rbx, rax
    mov     rcx, rbx
    mov     rdx, rsi
    mov     r8, rdi
    lea     r9, [bytes_read]
    mov     qword [rsp+32], 0
    call    WriteFile
    test    rax, rax
    jz      .close_fail
    mov     rcx, rbx
    call    CloseHandle
    mov     rax, 1
    jmp     .out
.close_fail:
    mov     rcx, rbx
    call    CloseHandle
.fail:
    xor     rax, rax
.out:
    WIN_ALIGN_EPILOGUE
    pop     rdi
    pop     rsi
    pop     rbx
    ret

; rcx = src, rdx = dst
global copy_file_path
copy_file_path:
    push    rbx
    WIN_ALIGN_PROLOGUE
    mov     rbx, rdx
    mov     rcx, rcx
    mov     rdx, rbx
    xor     r8d, r8d
    call    CopyFileA
    WIN_ALIGN_EPILOGUE
    pop     rbx
    ret

%endif
