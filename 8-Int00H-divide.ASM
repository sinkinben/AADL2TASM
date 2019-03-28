    ;演示程序（工作程序）dp85.asm
    ;演示除法出错中断处理程序（采用虚拟机可加载格式）
        section   text
        bits   16
    ;可加载工作程序头部特征信息
;
    Signature     db   "SIN "       ;签名信息
    Version       dw   1            ;格式版本
    Length        dw   end_of_text  ;工作程序长度
    Entry         dw   Begin        ;工作程序入口点的偏移
    ExpectedSeg   dw   0088H        ;工作程序期望的内存区域起始段值
    Reserved      dd   0            ;保留
;
    ;-------------------------------
    Begin:                              ;演示程序的初始化
        MOV   AX, 0                     ;准备设置中断向量
        MOV   DS, AX
        CLI                             ;关中断
        MOV   WORD [0*4], int00h_handler;设置0号中断向量之偏移
        MOV   [0*4+2], CS               ;设置0号中断向量之段值
        STI                             ;开中断
        ;
        ;MOV   BH, 0
        ;MOV   AH, 14
        ;MOV   AL, '#'
        ;INT   10H                       ;为了示意，显示井号
        ;
        ;MOV   AX, 600                   ;演示除出错
        ;MOV   BL, 2
        ;DIV   BL                        ;除法操作溢出！//@1
		;-----------------------------------------------------
		CLD
		MOV  AX,CS
		MOV  DS,AX		;DS=CS
		MOV  ES,AX		;ES=CS
		;print A=
		MOV SI, A
		CALL MyPutStr
		
		;input A str
		mov dx, buffer
		call GetStr
		MOV   AL, 0DH               ;形成回车换行效果
		CALL  PutChar
		MOV   AL, 0AH
		CALL  PutChar
		
		;转换A
		MOV  SI, buffer+1
		CALL DSTOB
		PUSH EAX
		
		;print B=
		mov si, B
		call MyPutStr
		
		;input B str
		MOV  DX, buffer
		CALL GetStr
		MOV   AL, 0DH               ;形成回车换行效果
		CALL  PutChar
		MOV   AL, 0AH
		CALL  PutChar
		
		;转换
		MOV  SI, buffer+1
		CALL DSTOB
		
		mov ebx,eax
		pop eax
		xor edx,edx		;eax div ebx = eax ... edx
		div ebx
		
		mov bl, [is_iret]
		test bl,bl
		jnz LABV
		
		;保存商和余数
		push eax
		push edx
		
		mov si, result
		call MyPutStr
		pop edx
		pop eax
		
		;print dec of eax
		call BIN2DEC
		
		push edx
		mov si, points
		call MyPutStr
		pop edx
		;print dec of edx
		mov eax,edx
		call BIN2DEC
		
		MOV   AL, 0DH               ;形成回车换行效果
		CALL  PutChar
		MOV   AL, 0AH
		CALL  PutChar
		;-----------------------------------------------------
    LABV:
        ;
        MOV   AH, 14
        MOV   AL, 0DH                   ;形成回车
        INT   10H
        MOV   AL, 0AH                   ;形成换行
        INT   10H
        ;
        RETF                            ;结束（返回到加载器）
    ;-----------------------------------
    ;00H号中断处理程序（除出错中断处理程序）
    int00h_handler:                      
        STI                             ;开中断//@2
        PUSHA                           ;保护通用寄存器//@3
        PUSH  DS                        ;保护DS//@4
        MOV   BP, SP
        ;
        PUSH  CS
        POP   DS                        ;使DS=CS
        MOV   DX, mess                  ;指向提示信息
        CALL  PutStr                    ;显示提示信息
        ;
        ADD   WORD [BP+18], 2           ;调整返回地址! //@5
        ;
		inc byte [is_iret]
        POP   DS                        ;恢复DS
        POPA                            ;恢复通用寄存器
        ;
        IRET                            ;中断返回
        ;
	;----------------data buffer-----------------------------
	is_iret db 0
	points db "...",0
    mess   db   "#Divide Overflow!!!!", 0    ;提示信息
	buffer:                         ;缓冲区
    db    9                     ;缓冲区的字符串容量
    db    "000000000",0           ;存放字符串
	A   DB "A=",0
	B   DB "B=",0
	result DB "A/B=",0
	;---------------------------------------------
    ;
    PutStr:                             ;显示字符串（以0结尾）
		;保护
		PUSH CS
		PUSH DS
		;
		PUSH  CS
        POP   DS                        ;使DS=CS
        MOV   BH, 0
        MOV   SI, DX                    ;DX=字符串起始地址偏移
    .LAB1:
        LODSB
        OR    AL, AL
        JZ    .LAB2
        MOV   AH, 14
        INT   10H
        JMP   .LAB1
    .LAB2:
		POP DS
		POP CS
        RET
	;-----------------------------------------------
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
;----------------------------
;SI指向字符串
MyPutStr:
	LODSB
	OR AL,AL
	JZ MyPutStr_OK
	MOV AH,14
	INT 10H
	JMP SHORT MyPutStr
MyPutStr_OK:
	RET
;-------------------------------
    end_of_text:                        ;结束位置
