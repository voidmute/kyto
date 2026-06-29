; Shared constants and BSS layout for Kyto kura ASM

%ifndef KYTO_INC_CONST
%define KYTO_INC_CONST

%define GENERIC_READ     0x80000000
%define GENERIC_WRITE    0x40000000
%define CREATE_ALWAYS    2
%define OPEN_EXISTING    3
%define FILE_ATTRIBUTE_NORMAL 0x80
%define INVALID_HANDLE_VALUE -1
%define STD_OUTPUT_HANDLE -11

%define MAX_FILE    65536
%define MAX_ENV     96
%define MAX_USERS   32
%define MAX_ADMINS  16
%define NAME_MAX    64
%define LINE_MAX    512
%define PATH_MAX    512

%macro ZSTR 1
    %1 db %1, 0
%endmacro

%endif
