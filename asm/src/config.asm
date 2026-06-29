; .kyto.config parser (v2 rules)

%ifndef KYTO_CONFIG_ASM
%define KYTO_CONFIG_ASM

section .data
    kw_domain   db "DOMAIN", 0
    kw_users    db "USERS", 0
    kw_admin    db "ADMIN", 0
    kw_node_env db "NODE_ENV", 0
    repo_prefix db "REPO_", 0

global config_file
config_file db ".kyto.config", 0

section .bss
global domain_buf
global user_names
global admin_names
global user_count
global admin_count
global env_keys
global env_vals
global env_count
global deploy_keys
global deploy_vals
global deploy_count
global line_work

domain_buf:     resb NAME_MAX
user_names:     resb MAX_USERS * NAME_MAX
admin_names:    resb MAX_ADMINS * NAME_MAX
user_count:     resd 1
admin_count:    resd 1
env_keys:       resb MAX_ENV * NAME_MAX
env_vals:       resb MAX_ENV * LINE_MAX
env_count:      resd 1
deploy_keys:    resb MAX_ENV * NAME_MAX
deploy_vals:    resb MAX_ENV * LINE_MAX
deploy_count:   resd 1
line_work:      resb LINE_MAX
key_work:       resb NAME_MAX
val_work:       resb LINE_MAX

section .text

extern strip_comment_trim
extern split_key_value
extern unquote_value
extern str_eq
extern strcpy_lower
extern strcpy
extern parse_name_list
extern read_file_to_buf
extern file_buf
extern trim_trailing

global config_reset
global config_load
global config_parse_buffer
global is_admin_name

config_reset:
    mov     dword [user_count], 0
    mov     dword [admin_count], 0
    mov     dword [env_count], 0
    mov     dword [deploy_count], 0
    lea     rdi, [domain_buf]
    xor     eax, eax
    mov     rcx, NAME_MAX
    rep     stosb
    ret

config_load:
    call    config_reset
    lea     rcx, [config_file]
    call    read_file_to_buf
    test    rax, rax
    jz      .fail
    call    config_parse_buffer
    mov     rax, 1
    ret
.fail:
    xor     rax, rax
    ret

%include "config_parse_simple.asm"

add_env_entry:
    push    rbx
    cmp     byte [key_work], 0
    je      .out
    mov     eax, [env_count]
    cmp     eax, MAX_ENV
    jae     .out
    mov     ebx, eax
    mov     eax, ebx
    imul    eax, NAME_MAX
    lea     rdi, [env_keys + rax]
    lea     rsi, [key_work]
.copyk:
    mov     al, [rsi]
    mov     [rdi], al
    test    al, al
    jz      .copyk_done
    inc     rsi
    inc     rdi
    jmp     .copyk
.copyk_done:
    mov     eax, ebx
    imul    eax, LINE_MAX
    lea     rdi, [env_vals + rax]
    lea     rsi, [val_work]
.copyv:
    mov     al, [rsi]
    mov     [rdi], al
    test    al, al
    jz      .copyv_done
    inc     rsi
    inc     rdi
    jmp     .copyv
.copyv_done:
    inc     dword [env_count]
    lea     rcx, [key_work]
    call    key_is_repo
    test    rax, rax
    jz      .out
    call    add_deploy_from_repo
.out:
    pop     rbx
    ret

; rcx = key, rax=1 if starts with REPO_
key_is_repo:
    cmp     dword [rcx], 'REPO'
    jne     .no
    cmp     byte [rcx + 4], '_'
    je      .yes
.no:
    xor     rax, rax
    ret
.yes:
    mov     rax, 1
    ret

add_deploy_from_repo:
    push    rbx
    mov     eax, [deploy_count]
    cmp     eax, MAX_ENV
    jae     .out
    mov     ebx, eax
    ; key after REPO_ lowercased
    mov     eax, ebx
    imul    eax, NAME_MAX
    lea     rdi, [deploy_keys + rax]
    lea     rsi, [key_work + 5]
.copyk:
    movzx   eax, byte [rsi]
    cmp     al, 'A'
    jb      .w
    cmp     al, 'Z'
    ja      .w
    add     al, 32
.w:
    mov     [rdi], al
    test    al, al
    jz      .copyv
    inc     rsi
    inc     rdi
    jmp     .copyk
.copyv:
    mov     eax, ebx
    imul    eax, LINE_MAX
    lea     rdi, [deploy_vals + rax]
    lea     rsi, [val_work]
.copyv2:
    mov     al, [rsi]
    mov     [rdi], al
    test    al, al
    jz      .copyv_done
    inc     rsi
    inc     rdi
    jmp     .copyv2
.copyv_done:
    inc     dword [deploy_count]
.out:
    pop     rbx
    ret

; rcx = name, rax=1 if admin
is_admin_name:
    push    rbx
    push    rsi
    push    rdi
    mov     rdi, rcx
    xor     ebx, ebx
.loop:
    mov     eax, ebx
    cmp     eax, [admin_count]
    jae     .no
    imul    eax, NAME_MAX
    lea     rsi, [admin_names + rax]
    mov     rcx, rdi
    mov     rdx, rsi
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

%endif
