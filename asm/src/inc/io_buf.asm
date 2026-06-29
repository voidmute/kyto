; Shared I/O buffers for win/linux kura

%ifndef KYTO_IO_BUF_ASM
%define KYTO_IO_BUF_ASM

section .bss
global file_buf
global bytes_read
global out_buf

file_buf:   resb MAX_FILE
out_buf:    resb MAX_FILE
bytes_read: resq 1

%endif
