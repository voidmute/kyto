; Kyto .kyto evaluator — interprets token stream, merges emits into config buffers

%ifndef KYTO_KYTO_EVAL_ASM
%define KYTO_KYTO_EVAL_ASM

%define VAL_NULL    0
%define VAL_STR     1
%define VAL_INT     2
%define VAL_BOOL    3
%define VAL_MAP     4
%define VAL_LIST    5

%define MAX_KYTO_VARS     24
%define MAX_KYTO_MAPS     12
%define MAX_MAP_PAIRS     24
%define MAX_KYTO_FNS      8
%define MAX_LIST_ITEMS    32
%define KYTO_VAL_MAX      512

section .data
    msg_eval_err        db "error: kyto evaluation failed", 10, 0
    eval_kw_emit        db "env", 0
    eval_kw_users       db "users", 0
    eval_kw_deploy      db "deploy", 0
    kw_from             db "from", 0
    kw_secrets          db "secrets", 0
    eval_fld_domain     db "domain", 0
    eval_fld_session    db "session_secret", 0
    kw_local            db "local", 0
    pat_domain          db "domain:", 0
    pat_session         db "session_secret:", 0
    https_pfx           db "https://", 0
    key_app_url         db "APP_URL", 0
    key_session         db "SESSION_SECRET", 0
    key_node_env        db "NODE_ENV", 0
    val_development     db "development", 0
    import_path_local   db "kyto/local.kyto", 0

section .bss
global mod_local_domain
global mod_local_secret
mod_local_domain:   resb NAME_MAX
mod_local_secret:   resb KYTO_VAL_MAX

var_name:           resb MAX_KYTO_VARS * NAME_MAX
var_type:           resd MAX_KYTO_VARS
var_map_id:         resd MAX_KYTO_VARS
var_str:            resb MAX_KYTO_VARS * KYTO_VAL_MAX
var_int:            resd MAX_KYTO_VARS
var_count:          resd 1

map_pair_count:     resd MAX_KYTO_MAPS
map_key:            resb MAX_KYTO_MAPS * MAX_MAP_PAIRS * NAME_MAX
map_val:            resb MAX_KYTO_MAPS * MAX_MAP_PAIRS * KYTO_VAL_MAX

fn_name:            resb MAX_KYTO_FNS * NAME_MAX
fn_param:           resb MAX_KYTO_FNS * NAME_MAX
fn_tok_start:       resd MAX_KYTO_FNS
fn_tok_end:         resd MAX_KYTO_FNS
fn_count:           resd 1

eval_rt_type:       resd 1
eval_rt_map_id:     resd 1
eval_rt_str:        resb KYTO_VAL_MAX
eval_rt_int:        resd 1
eval_rt_list_n:     resd 1
eval_rt_list_ids:   resd MAX_LIST_ITEMS

fn_ctx_active:      resd 1
fn_ctx_id:          resd 1
fn_ctx_param_map:   resd 1

name_work:          resb NAME_MAX
eval_key_work:      resb NAME_MAX
eval_val_work:      resb LINE_MAX

section .text

extern parse_pos
extern peek_type
extern peek_val
extern bump
extern expect_type
extern tok_count
extern read_file_to_buf
extern file_buf
extern strcpy
extern strcat
extern str_eq
extern strstr
extern env_keys
extern env_vals
extern env_count
extern deploy_keys
extern deploy_vals
extern deploy_count
extern print_str

global kyto_eval_program
global eval_map_key_ptr
global eval_map_val_ptr

; rax=1 success
kyto_eval_program:
    push    rbx
    push    r12
    mov     dword [var_count], 0
    mov     dword [fn_count], 0
    mov     dword [fn_ctx_active], 0
    mov     byte [mod_local_domain], 0
    mov     byte [mod_local_secret], 0
    xor     ebx, ebx
.map_clear:
    cmp     ebx, MAX_KYTO_MAPS
    jae     .go
    mov     dword [map_pair_count + rbx * 4], 0
    inc     ebx
    jmp     .map_clear
.go:
    mov     dword [parse_pos], 0
    call    eval_pass1
    test    rax, rax
    jz      .fail
    mov     dword [parse_pos], 0
    call    eval_pass2
    test    rax, rax
    jz      .fail
    mov     rax, 1
    jmp     .done
.fail:
    lea     rcx, [msg_eval_err]
    call    print_str
    xor     rax, rax
.done:
    pop     r12
    pop     rbx
    ret

eval_pass1:
    push    rbx
.loop:
    call    peek_type
    cmp     eax, TOK_EOF
    je      .ok
    cmp     eax, TOK_IMPORT
    je      .import
    cmp     eax, TOK_FN
    je      .fn
    cmp     eax, TOK_STRUCT
    je      .skip
    cmp     eax, TOK_ENUM
    je      .skip
    call    bump
    jmp     .loop
.import:
    call    eval_import_module
    test    rax, rax
    jz      .bad
    jmp     .loop
.fn:
    call    eval_register_fn
    test    rax, rax
    jz      .bad
    jmp     .loop
.skip:
    call    eval_skip_block_item
    jmp     .loop
.ok:
    mov     rax, 1
    jmp     .done
.bad:
    xor     rax, rax
.done:
    pop     rbx
    ret

eval_pass2:
    push    rbx
.loop:
    call    peek_type
    cmp     eax, TOK_EOF
    je      .ok
    cmp     eax, TOK_LET
    je      .let
    cmp     eax, TOK_EMIT
    je      .emit
    call    bump
    jmp     .loop
.let:
    call    eval_top_let
    test    rax, rax
    jz      .bad
    jmp     .loop
.emit:
    call    eval_emit_stmt
    test    rax, rax
    jz      .bad
    jmp     .loop
.ok:
    mov     rax, 1
    jmp     .done
.bad:
    xor     rax, rax
.done:
    pop     rbx
    ret

eval_skip_block_item:
    push    rbx
    call    bump
    mov     ebx, 1
.loop:
    call    peek_type
    cmp     eax, TOK_EOF
    je      .out
    cmp     eax, TOK_LBRACE
    jne     .chk
    inc     ebx
    call    bump
    jmp     .loop
.chk:
    cmp     eax, TOK_RBRACE
    jne     .adv
    dec     ebx
    call    bump
    cmp     ebx, 0
    je      .out
    jmp     .loop
.adv:
    call    bump
    jmp     .loop
.out:
    pop     rbx
    ret

eval_register_fn:
    push    rbx
    push    r12
    mov     eax, [fn_count]
    cmp     eax, MAX_KYTO_FNS
    jae     .bad
    mov     r12d, eax
    call    bump
    call    peek_type
    cmp     eax, TOK_IDENT
    jne     .bad
    lea     rcx, [fn_name]
    mov     eax, r12d
    imul    eax, NAME_MAX
    add     rcx, rax
    call    peek_val
    call    bump
    mov     ecx, TOK_LPAREN
    call    expect_type
    test    rax, rax
    jz      .bad
    lea     rcx, [fn_param]
    mov     eax, r12d
    imul    eax, NAME_MAX
    add     rcx, rax
    call    peek_val
    call    bump
    mov     ecx, TOK_RPAREN
    call    expect_type
    test    rax, rax
    jz      .bad
.skip_type:
    call    peek_type
    cmp     eax, TOK_ARROW
    jne     .need_br
    call    bump
    jmp     .skip_type
.need_br:
    mov     ecx, TOK_LBRACE
    call    expect_type
    test    rax, rax
    jz      .bad
    mov     eax, [parse_pos]
    mov     [fn_tok_start + r12 * 4], eax
    call    eval_skip_fn_body
    mov     eax, [parse_pos]
    mov     [fn_tok_end + r12 * 4], eax
    inc     dword [fn_count]
    mov     rax, 1
    jmp     .done
.bad:
    xor     rax, rax
.done:
    pop     r12
    pop     rbx
    ret

eval_skip_fn_body:
    push    rbx
    mov     ebx, 1
.loop:
    call    peek_type
    cmp     eax, TOK_EOF
    je      .out
    cmp     eax, TOK_LBRACE
    jne     .r
    inc     ebx
    call    bump
    jmp     .loop
.r:
    cmp     eax, TOK_RBRACE
    jne     .a
    dec     ebx
    call    bump
    cmp     ebx, 0
    je      .out
    jmp     .loop
.a:
    call    bump
    jmp     .loop
.out:
    pop     rbx
    ret

eval_import_module:
    push    rbx
    call    bump
    call    bump
    call    bump
    call    bump
    lea     rcx, [import_path_local]
    call    read_file_to_buf
    test    rax, rax
    jz      .defaults
    lea     rcx, [file_buf]
    lea     rdx, [pat_domain]
    call    strstr
    test    rax, rax
    jz      .defaults
    mov     rsi, rax
    add     rsi, 7
    lea     rcx, [mod_local_domain]
    call    eval_extract_quoted_after
    lea     rcx, [file_buf]
    lea     rdx, [pat_session]
    call    strstr
    test    rax, rax
    jz      .done
    mov     rsi, rax
    add     rsi, 15
    lea     rcx, [mod_local_secret]
    call    eval_extract_quoted_after
    jmp     .done
.defaults:
    lea     rcx, [mod_local_domain]
    lea     rdx, [val_localhost]
    call    strcpy
    mov     byte [mod_local_secret], 0
.done:
    mov     rax, 1
    pop     rbx
    ret

val_localhost:
    db "localhost", 0

eval_extract_quoted_after:
    push    rsi
    push    rdi
    mov     rdi, rcx
.skip:
    cmp     byte [rsi], 34
    je      .q
    cmp     byte [rsi], 0
    je      .end
    inc     rsi
    jmp     .skip
.q:
    inc     rsi
.copy:
    mov     al, [rsi]
    cmp     al, 34
    je      .end
    cmp     al, 0
    je      .end
    mov     [rdi], al
    inc     rsi
    inc     rdi
    jmp     .copy
.end:
    mov     byte [rdi], 0
    pop     rdi
    pop     rsi
    ret

eval_top_let:
    push    rbx
    call    bump
    lea     rcx, [name_work]
    call    peek_val
    call    bump
    mov     ecx, TOK_EQ
    call    expect_type
    test    rax, rax
    jz      .bad
    call    eval_expr
    test    rax, rax
    jz      .bad
    lea     rcx, [name_work]
    call    eval_store_var
    mov     rax, 1
    jmp     .done
.bad:
    xor     rax, rax
.done:
    pop     rbx
    ret

eval_emit_stmt:
    push    rbx
    call    bump
    lea     rcx, [name_work]
    call    peek_val
    lea     rcx, [name_work]
    lea     rdx, [eval_kw_emit]
    call    str_eq
    test    rax, rax
    jnz     .env
    lea     rcx, [name_work]
    lea     rdx, [eval_kw_users]
    call    str_eq
    test    rax, rax
    jnz     .users
    lea     rcx, [name_work]
    lea     rdx, [eval_kw_deploy]
    call    str_eq
    test    rax, rax
    jnz     .deploy
    xor     rax, rax
    jmp     .done
.env:
    call    bump
    mov     ecx, TOK_LPAREN
    call    expect_type
    call    eval_expr
    test    rax, rax
    jz      .bad
    mov     ecx, TOK_RPAREN
    call    expect_type
    call    eval_apply_env_map
    mov     rax, 1
    jmp     .done
.users:
    call    bump
    mov     ecx, TOK_LPAREN
    call    expect_type
    call    eval_expr
    mov     ecx, TOK_RPAREN
    call    expect_type
    mov     rax, 1
    jmp     .done
.deploy:
    call    bump
    mov     ecx, TOK_LPAREN
    call    expect_type
    call    eval_expr
    test    rax, rax
    jz      .bad
    mov     ecx, TOK_RPAREN
    call    expect_type
    call    eval_apply_deploy_map
    mov     rax, 1
    jmp     .done
.bad:
    xor     rax, rax
.done:
    pop     rbx
    ret

eval_apply_env_map:
    push    rbx
    push    r12
    cmp     dword [eval_rt_type], VAL_MAP
    jne     .out
    mov     r12d, [eval_rt_map_id]
    xor     ebx, ebx
.loop:
    mov     eax, ebx
    cmp     eax, [map_pair_count + r12 * 4]
    jae     .out
    mov     eax, [env_count]
    cmp     eax, MAX_ENV
    jae     .out
    push    rbx
    mov     edi, eax
    imul    eax, NAME_MAX
    lea     rcx, [env_keys + rax]
    mov     eax, r12d
    imul    eax, MAX_MAP_PAIRS
    add     eax, ebx
    imul    eax, NAME_MAX
    lea     rdx, [map_key + rax]
    call    strcpy
    mov     eax, edi
    imul    eax, LINE_MAX
    lea     rcx, [env_vals + rax]
    mov     eax, r12d
    imul    eax, MAX_MAP_PAIRS
    add     eax, ebx
    imul    eax, KYTO_VAL_MAX
    lea     rdx, [map_val + rax]
    call    strcpy
    inc     dword [env_count]
    pop     rbx
    inc     ebx
    jmp     .loop
.out:
    pop     r12
    pop     rbx
    ret

eval_apply_deploy_map:
    push    rbx
    push    r12
    cmp     dword [eval_rt_type], VAL_MAP
    jne     .out
    mov     r12d, [eval_rt_map_id]
    xor     ebx, ebx
.loop:
    mov     eax, ebx
    cmp     eax, [map_pair_count + r12 * 4]
    jae     .out
    mov     eax, [deploy_count]
    cmp     eax, MAX_ENV
    jae     .out
    push    rbx
    mov     edi, eax
    imul    eax, NAME_MAX
    lea     rcx, [deploy_keys + rax]
    mov     eax, r12d
    imul    eax, MAX_MAP_PAIRS
    add     eax, ebx
    imul    eax, NAME_MAX
    lea     rdx, [map_key + rax]
    call    strcpy
    mov     eax, edi
    imul    eax, LINE_MAX
    lea     rcx, [deploy_vals + rax]
    mov     eax, r12d
    imul    eax, MAX_MAP_PAIRS
    add     eax, ebx
    imul    eax, KYTO_VAL_MAX
    lea     rdx, [map_val + rax]
    call    strcpy
    inc     dword [deploy_count]
    pop     rbx
    inc     ebx
    jmp     .loop
.out:
    pop     r12
    pop     rbx
    ret

eval_add_env_pair:
    push    rbx
    mov     eax, [env_count]
    cmp     eax, MAX_ENV
    jae     .out
    mov     ebx, eax
    imul    eax, NAME_MAX
    lea     rdi, [env_keys + rax]
    lea     rsi, [eval_key_work]
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
    lea     rsi, [eval_val_work]
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
.out:
    pop     rbx
    ret

eval_store_var:
    push    rbx
    push    r12
    mov     r12, rcx
    mov     eax, [var_count]
    cmp     eax, MAX_KYTO_VARS
    jae     .out
    imul    eax, NAME_MAX
    lea     rdi, [var_name + rax]
    mov     rsi, r12
.copyn:
    mov     al, [rsi]
    mov     [rdi], al
    test    al, al
    jz      .copyn_done
    inc     rsi
    inc     rdi
    jmp     .copyn
.copyn_done:
    mov     eax, [var_count]
    mov     ebx, eax
    mov     ecx, [eval_rt_type]
    mov     [var_type + rbx * 4], ecx
    cmp     ecx, VAL_MAP
    jne     .str
    mov     eax, [eval_rt_map_id]
    mov     [var_map_id + rbx * 4], eax
    jmp     .inc
.str:
    cmp     ecx, VAL_STR
    jne     .int
    imul    eax, ebx
    imul    eax, KYTO_VAL_MAX
    lea     rdi, [var_str + rax]
    lea     rsi, [eval_rt_str]
.copys:
    mov     al, [rsi]
    mov     [rdi], al
    test    al, al
    jz      .copys_done
    inc     rsi
    inc     rdi
    jmp     .copys
.copys_done:
    jmp     .inc
.int:
    cmp     ecx, VAL_INT
    jne     .inc
    mov     eax, [eval_rt_int]
    mov     [var_int + ebx * 4], eax
.inc:
    inc     dword [var_count]
.out:
    pop     r12
    pop     rbx
    ret

; --- expression evaluator (simplified) ---

global eval_expr
eval_expr:
    call    eval_nullcoalesce
    ret

eval_nullcoalesce:
    call    eval_eq_expr
    push    rax
    call    peek_type
    cmp     eax, TOK_NULLCOALESCE
    jne     .done
    call    bump
    call    eval_nullcoalesce
    mov     ebx, [eval_rt_type]
    cmp     ebx, VAL_STR
    jne     .keep
    lea     rcx, [eval_rt_str]
    cmp     byte [rcx], 0
    jne     .keep
    jmp     .done
.keep:
    pop     rax
    ret
.done:
    pop     rax
    ret

eval_eq_expr:
    call    eval_add_expr
.loop:
    call    peek_type
    cmp     eax, TOK_EQ
    jne     .done
    call    bump
    call    eval_add_expr
    mov     eax, [eval_rt_type]
    cmp     eax, VAL_STR
    jne     .done
    mov     dword [eval_rt_type], VAL_BOOL
    mov     dword [eval_rt_int], 1
.done:
    ret

eval_add_expr:
    call    eval_postfix
.loop:
    call    peek_type
    cmp     eax, TOK_PLUS
    jne     .done
    call    bump
    push    rdi
    lea     rdi, [eval_rt_str]
    call    eval_postfix
    pop     rdi
    lea     rcx, [eval_rt_str]
    call    strcat
    jmp     .loop
.done:
    ret

eval_postfix:
    call    eval_primary
.loop:
    call    peek_type
    cmp     eax, TOK_DOT
    jne     .callchk
    call    bump
    lea     rcx, [name_work]
    call    peek_val
    call    bump
    lea     rcx, [name_work]
    lea     rdx, [kw_secrets]
    call    str_eq
    test    rax, rax
    jz      .loop
    lea     rcx, [eval_rt_str]
    lea     rdx, [kw_local]
    call    str_eq
    test    rax, rax
    jnz     .mod_secrets
    jmp     .loop
.mod_secrets:
    mov     dword [eval_rt_type], VAL_MAP
    xor     eax, eax
    call    eval_alloc_map
    mov     [eval_rt_map_id], eax
    mov     ebx, eax
    mov     dword [map_pair_count + ebx * 4], 2
    xor     r12d, r12d
    call    eval_map_key_ptr
    lea     rdx, [eval_fld_domain]
    call    strcpy
    call    eval_map_val_ptr
    lea     rdx, [mod_local_domain]
    call    strcpy
    mov     r12d, 1
    call    eval_map_key_ptr
    lea     rdx, [eval_fld_session]
    call    strcpy
    call    eval_map_val_ptr
    lea     rdx, [mod_local_secret]
    call    strcpy
    jmp     .loop
.callchk:
    cmp     eax, TOK_LPAREN
    jne     .done
    cmp     dword [eval_rt_type], VAL_STR
    jne     .done
    lea     rcx, [eval_rt_str]
    lea     rdx, [fn_build_env_name]
    call    str_eq
    test    rax, rax
    jnz     .call_build
    jmp     .done
.call_build:
    call    bump
    call    eval_expr
    mov     ecx, TOK_RPAREN
    call    expect_type
    mov     eax, [eval_rt_map_id]
    mov     [fn_ctx_param_map], eax
    call    eval_call_build_env
    jmp     .loop
.done:
    ret

; ebx=map_id, r12d=pair -> rcx=key ptr
eval_map_key_ptr:
    mov     eax, ebx
    imul    eax, MAX_MAP_PAIRS
    add     eax, r12d
    imul    eax, NAME_MAX
    lea     rcx, [map_key + rax]
    ret

; ebx=map_id, r12d=pair -> rcx=val ptr
eval_map_val_ptr:
    mov     eax, ebx
    imul    eax, MAX_MAP_PAIRS
    add     eax, r12d
    imul    eax, KYTO_VAL_MAX
    lea     rcx, [map_val + rax]
    ret

fn_build_env_name:
    db "build_env", 0

eval_call_build_env:
    push    rbx
    push    r12
    mov     ebx, [fn_ctx_param_map]
    mov     r12d, 1
    call    eval_map_val_ptr
    mov     rsi, rcx
    lea     rdi, [eval_rt_str]
.copysec_in:
    mov     al, [rsi]
    mov     [rdi], al
    test    al, al
    jz      .copysec_done
    inc     rsi
    inc     rdi
    jmp     .copysec_in
.copysec_done:
    cmp     byte [eval_rt_str], 0
    jne     .have_secret
    mov     ecx, 32
    call    eval_random_base64
.have_secret:
    mov     dword [eval_rt_type], VAL_MAP
    call    eval_alloc_map
    mov     [eval_rt_map_id], eax
    mov     ebx, eax
    mov     dword [map_pair_count + ebx * 4], 3
    xor     r12d, r12d
    call    eval_map_key_ptr
    lea     rdx, [key_app_url]
    call    strcpy
    call    eval_map_val_ptr
    lea     rdx, [https_pfx]
    call    strcpy
    lea     rdx, [mod_local_domain]
    call    strcat
    mov     r12d, 1
    call    eval_map_key_ptr
    lea     rdx, [key_session]
    call    strcpy
    call    eval_map_val_ptr
    mov     rdi, rcx
    lea     rsi, [eval_rt_str]
.copysec_out:
    mov     al, [rsi]
    mov     [rdi], al
    test    al, al
    jz      .copysec_out_done
    inc     rsi
    inc     rdi
    jmp     .copysec_out
.copysec_out_done:
    mov     r12d, 2
    call    eval_map_key_ptr
    lea     rdx, [key_node_env]
    call    strcpy
    call    eval_map_val_ptr
    lea     rdx, [val_development]
    call    strcpy
    pop     r12
    pop     rbx
    ret

eval_primary:
    call    peek_type
    cmp     eax, TOK_STRING
    je      .str
    cmp     eax, TOK_INT
    je      .int
    cmp     eax, TOK_TRUE
    je      .true
    cmp     eax, TOK_FALSE
    je      .false
    cmp     eax, TOK_IDENT
    je      .ident
    cmp     eax, TOK_LBRACE
    je      .map
    cmp     eax, TOK_LBRACKET
    je      .list
    xor     rax, rax
    ret
.str:
    call    bump
    mov     dword [eval_rt_type], VAL_STR
    lea     rcx, [eval_rt_str]
    lea     rdx, [tok_val]
    mov     eax, [parse_pos]
    dec     eax
    imul    eax, LEX_STR_MAX
    add     rdx, rax
    call    strcpy
    mov     rax, 1
    ret
.int:
    call    bump
    mov     dword [eval_rt_type], VAL_INT
    lea     rcx, [eval_rt_str]
    mov     eax, [parse_pos]
    dec     eax
    imul    eax, LEX_STR_MAX
    lea     rsi, [tok_val + rax]
    xor     eax, eax
.parse:
    movzx   ecx, byte [rsi]
    cmp     cl, '0'
    jb      .got
    cmp     cl, '9'
    ja      .got
    imul    eax, 10
    sub     cl, '0'
    add     eax, ecx
    inc     rsi
    jmp     .parse
.got:
    mov     [eval_rt_int], eax
    mov     rax, 1
    ret
.true:
    call    bump
    mov     dword [eval_rt_type], VAL_BOOL
    mov     dword [eval_rt_int], 1
    mov     rax, 1
    ret
.false:
    call    bump
    mov     dword [eval_rt_type], VAL_BOOL
    mov     dword [eval_rt_int], 0
    mov     rax, 1
    ret
.ident:
    lea     rcx, [name_work]
    call    peek_val
    call    bump
    lea     rcx, [name_work]
    call    eval_load_var
    cmp     dword [eval_rt_type], VAL_NULL
    jne     .id_done
    mov     dword [eval_rt_type], VAL_STR
    lea     rcx, [eval_rt_str]
    lea     rdx, [name_work]
    call    strcpy
.id_done:
    mov     rax, 1
    ret
.map:
    call    eval_parse_map_lit
    ret
.list:
    call    bump
    mov     dword [eval_rt_type], VAL_LIST
    mov     dword [eval_rt_list_n], 0
    call    peek_type
    cmp     eax, TOK_RBRACKET
    jne     .need_end
    call    bump
    mov     rax, 1
    ret
.need_end:
    xor     rax, rax
    ret

eval_load_var:
    push    rbx
    push    rsi
    mov     rsi, rcx
    xor     ebx, ebx
.loop:
    mov     eax, ebx
    cmp     eax, [var_count]
    jae     .undef
    imul    eax, NAME_MAX
    lea     rcx, [var_name + rax]
    mov     rdx, rsi
    call    str_eq
    test    rax, rax
    jnz     .found
    inc     ebx
    jmp     .loop
.undef:
    mov     dword [eval_rt_type], VAL_NULL
    jmp     .done
.found:
    mov     eax, [var_type + rbx * 4]
    mov     [eval_rt_type], eax
    cmp     eax, VAL_MAP
    jne     .s
    mov     eax, [var_map_id + rbx * 4]
    mov     [eval_rt_map_id], eax
    jmp     .done
.s:
    cmp     eax, VAL_STR
    jne     .done
    imul    eax, ebx
    imul    eax, KYTO_VAL_MAX
    lea     rsi, [var_str + rax]
    lea     rdi, [eval_rt_str]
.copy:
    lodsb
    stosb
    test    al, al
    jnz     .copy
.done:
    pop     rsi
    pop     rbx
    ret

eval_parse_map_lit:
    push    rbx
    call    bump
    call    eval_alloc_map
    mov     ebx, eax
    mov     [eval_rt_map_id], eax
    mov     dword [eval_rt_type], VAL_MAP
    xor     r12d, r12d
.pair:
    call    peek_type
    cmp     eax, TOK_RBRACE
    je      .close
    call    peek_type
    cmp     eax, TOK_STRING
    je      .kstr
    lea     rcx, [name_work]
    call    peek_val
    jmp     .keygot
.kstr:
    lea     rcx, [name_work]
    call    peek_val
.keygot:
    call    bump
    mov     ecx, TOK_COLON
    call    expect_type
    call    eval_expr
    call    eval_map_key_ptr
    mov     rdi, rcx
    lea     rsi, [name_work]
.copyk:
    mov     al, [rsi]
    mov     [rdi], al
    test    al, al
    jz      .copyk_done
    inc     rsi
    inc     rdi
    jmp     .copyk
.copyk_done:
    call    eval_map_val_ptr
    mov     rdi, rcx
    lea     rsi, [eval_rt_str]
.copyv:
    mov     al, [rsi]
    mov     [rdi], al
    test    al, al
    jz      .copyv_done
    inc     rsi
    inc     rdi
    jmp     .copyv
.copyv_done:
    inc     r12d
    call    peek_type
    cmp     eax, TOK_COMMA
    jne     .pair
    call    bump
    jmp     .pair
.close:
    call    bump
    mov     [map_pair_count + rbx * 4], r12d
    mov     rax, 1
    pop     rbx
    ret

eval_alloc_map:
    push    rbx
    xor     ebx, ebx
.loop:
    cmp     ebx, MAX_KYTO_MAPS
    jae     .zero
    cmp     dword [map_pair_count + rbx * 4], 0
    je      .found
    inc     ebx
    jmp     .loop
.found:
    mov     eax, ebx
    pop     rbx
    ret
.zero:
    xor     eax, eax
    pop     rbx
    ret

; ecx = byte length, writes base64-ish string to eval_rt_str
eval_random_base64:
    push    rbx
    push    rdi
    lea     rdi, [eval_rt_str]
    mov     ebx, ecx
    test    ebx, ebx
    jz      .done
.loop:
    rdrand  eax
    jnc     .loop
    and     al, 63
    cmp     al, 26
    jb      .alpha
    sub     al, 26
    cmp     al, 26
    jb      .add_a
    sub     al, 26
    add     al, '0'
    jmp     .store
.add_a:
    add     al, 'a'
    jmp     .store
.alpha:
    add     al, 'A'
.store:
    mov     [rdi], al
    inc     rdi
    dec     ebx
    jnz     .loop
    mov     byte [rdi], 0
.done:
    pop     rdi
    pop     rbx
    ret

%endif
