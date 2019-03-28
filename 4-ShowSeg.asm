    ;演示程序（工作程序）dp78.asm
        section   text
        bits   16
    ;工作程序特征信息
    Signature     db   "SIN "       ;签名信息
    Version       dw   1            ;格式版本
    Length        dw   end_of_text  ;工作程序长度
    Entry         dw   Begin        ;工作程序入口点的偏移
    ExpectedSeg   dw   1200H        ;工作程序期望的内存区域起始段值
    Reserved      dd   0            ;保留
    ;-------------------------------
    ;数据部分之一
    info   db    "Program Working Segment Address:", 0      ;提示信息
    ;-------------------------------
    ;代码部分
    Begin:                          ;工作程序入口
        MOV   AX, CS
        MOV   DS, AX                ;源数据段与代码段一致
        CLD                         ;清方向标志
        MOV   DX, info
        CALL  PutStr                ;显示提示信息
        ;
        MOV   DX, CS                ;准备显示工作内存区域的段值
        MOV   CX, 4                 ;4位十六进制数
        MOV   SI, buffer            ;字符串缓冲区首地址
    Next:
        ROL   DX, 4                 ;循环左移4位
        MOV   AL, DL                ;
        CALL  TOASCII               ;转换成对应ASCII码
        MOV   [SI],AL               ;依次填到缓冲区
        INC   SI
        LOOP  Next                  ;下一位
        ;
        MOV   DX, buffer            ;取得显示字符串首地址
        CALL  PutStr                ;显示之
        ;
        RETF                        ;返回到加载程序!!//@1
    ;-------------------------------
    PutStr:                         ;显示字符串（以0结尾）
        MOV   BH, 0
        MOV   SI, DX                ;DX=字符串起始地址偏移
    .LAB1:
        LODSB
        OR    AL, AL
        JZ    .LAB2
        MOV   AH, 14
        INT   10H
        JMP   .LAB1
    .LAB2:
        RET
    ;
    TOASCII:                        ;转对应十六进制数的ASCII码
        AND   AL, 0FH               ;AL低4位 = 十六进制数
        ADD   AL, '0'
        CMP   AL, '9'
        SETBE BL
        DEC   BL
        AND   BL, 7
        ADD   AL, BL
        RET
    ;-------------------------------
    ;数据部分之二
           times  1024  db  90H     ;为了演示，刻意插入了1024字节
    ;
    buffer db    "00000H"           ;用于存放工作内存区域的地址
           db    0DH, 0AH, 0
    end_of_text:                    ;代码结束处（代码字节长度）
