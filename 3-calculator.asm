section text
bits 16
;扇区号20
;
    Signature     db   "SIN "       ;签名信息
    Version       dw   1            ;格式版本
    Length        dw   end_of_text  ;工作程序长度
    Entry         dw   Begin        ;工作程序入口点的偏移
    ExpectedSeg   dw   0088H        ;工作程序期望的内存区域起始段值
    Reserved      dd   0            ;保留
;
Begin:
	CLD
	MOV  AX,CS
	MOV  DS,AX		;DS=CS
	MOV  ES,AX		;ES=CS
	MOV SI, A
	CALL PutStr
	;输入
	MOV  DX, buffer
	CALL GetStr
	MOV   AL, 0DH               ;形成回车换行效果
    CALL  PutChar
    MOV   AL, 0AH
    CALL  PutChar
	
	;转换
	MOV  SI, buffer+1
	CALL DSTOB
	PUSH EAX
	
	
	MOV SI,B
	CALL PutStr
	;输入
	MOV  DX, buffer
	CALL GetStr
	MOV   AL, 0DH               ;形成回车换行效果
    CALL  PutChar
    MOV   AL, 0AH
    CALL  PutChar
	
	;转换
	MOV  SI, buffer+1
	CALL DSTOB
	POP EBX
	ADD EAX,EBX
	
	PUSH EAX
	MOV SI,SUM
	CALL PutStr
	
	POP EAX
	CALL BIN2DEC
	MOV   AL, 0DH               ;形成回车换行效果
    CALL  PutChar
    MOV   AL, 0AH
    CALL  PutChar
	RETF
	
	
	
	
	

;----------------------------
;SI指向字符串
PutStr:
	LODSB
	OR AL,AL
	JZ PutStr_OK
	MOV AH,14
	INT 10H
	JMP SHORT PutStr
PutStr_OK:
	RET
;-------------------------------
BIN2DEC:
	PUSH EDX
	PUSH EBX
	PUSH ECX
	XOR EDX,EDX
	XOR ECX,ECX
	MOV EBX,10
	CMP EAX,0
	JNE BIN2DEC_LOOP
	MOV AL,'0'
	CALL PutChar
	RET
BIN2DEC_LOOP:
	CMP EAX,0
	JE  BIN2DEC_OK
	DIV EBX
	ADD EDX,'0'
	PUSH EDX
	INC ECX
	XOR EDX,EDX
	JMP BIN2DEC_LOOP
BIN2DEC_OK:
	POP EDX
	MOV AL, DL
	CALL PutChar
	LOOP BIN2DEC_OK
	POP ECX
	POP EBX
	POP EDX
	RET
;-------------------------------
    DSTOB:                          ;将数字串转换成对应的二进制值
        XOR   EAX, EAX
        XOR   EDX, EDX
    .next:
        LODSB                       ;取一个数字符
        CMP   AL, 0DH
        JZ    .ok
        AND   AL, 0FH
        IMUL  EDX, 10
        ADD   EDX, EAX
        JMP   SHORT .next
    .ok:
        MOV   EAX, EDX              ;EAX返回二进制值
        RET
;-------------------------------
    %define  Space      20H         ;空格符
    %define  Enter      0DH         ;回车符
    %define  Backspace  08H         ;退格
    %define  Bell       07H         ;响铃
    ;子程序名：GetStr
    ;功    能：接受一个字符串
    ;入口参数：DS:DX=缓冲区首地址
    ;说    明：（1）缓冲区第一个字节是其字符串容量
    ;          （2）返回的字符串以回车符（0DH）结尾
    GetStr:
        PUSH  SI
        MOV   SI, DX
        MOV   CL, [SI]              ;取得缓冲区的字符串容量
        CMP   CL, 1                 ;如小于1，直接返回
        JB    .Lab6
        ;
        INC   SI                    ;指向字符串的首地址
        XOR   CH, CH                ;CH作为字符串中的字符计数器，清零
    .Lab1:
        CALL  GetChar               ;读取一个字符
        OR    AL, AL                ;如为功能键，直接丢弃//@1
        JZ    SHORT  .Lab1
        CMP   AL, Enter             ;如为回车键，表示输入字符串结束
        JZ    SHORT  .Lab5          ;转输入结束
        CMP   AL,  Backspace        ;如为退格键
        JZ    SHORT  .Lab4          ;转退格处理
        CMP   AL, Space             ;如为其他不可显示字符，丢弃//@2
        JB    SHORT  .Lab1
        ;
        cmp   al, '0'
        jb    short  .Lab1          ;小于数字符，丢弃
        cmp   al, '9'
        ja    short  .Lab1          ;大于数字符，丢弃
        ;
        CMP   CL, 1                 ;字符串中的空间是否有余？
        JA    SHORT  .Lab3          ;是，转存入字符串处理
    .Lab2:
        MOV   AL, Bell
        CALL  PutChar               ;响铃提醒
        JMP   SHORT  .Lab1          ;继续接受字符
        ;
    .Lab3:
        CALL  PutChar               ;显示字符
        MOV   [SI], AL              ;保存到字符串
        INC   SI                    ;调整字符串中的存放位置
        INC   CH                    ;调整字符串中的字符计数
        DEC   CL                    ;调整字符串中的空间计数
        JMP   SHORT  .Lab1          ;继续接受字符
        ;
    .Lab4:                          ;退格处理
        CMP   CH, 0                 ;字符串中是否有字符？
        JBE   .Lab2                 ;没有，响铃提醒
        CALL  PutChar               ;光标回退
        MOV   AL, Space
        CALL  PutChar               ;用空格擦除字符
        MOV   AL, Backspace
        CALL  PutChar               ;再次光标回退
        DEC   SI                    ;调整字符串中的存放位置
        DEC   CH                    ;调整字符串中的字符计数
        INC   CL                    ;调整字符串中的空间计数
        JMP   SHORT  .Lab1          ;继续接受字符
        ;
    .Lab5:
        MOV    [SI], AL             ;保存最后的回车符
    .Lab6:
        POP   SI
        RET
;-------------------------------

PutChar:                        ;显示一个字符
    MOV   BH, 0
    MOV   AH, 14
    INT   10H
    RET
    ;
GetChar:                        ;键盘输入一个字符
    MOV   AH, 0
    INT   16H
    RET
;-------------------------------
buffer:                         ;缓冲区
    db    9                     ;缓冲区的字符串容量
    db    "000000000"           ;存放字符串
A   DB "A=",0
B   DB "B=",0
SUM DB "SUM=",0
;-------------------------------
times 510-($-$$) db 0
db 55h,0aah
end_of_text 
