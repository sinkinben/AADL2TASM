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
	MOV  DS,AX
	MOV BH,0	;显示页0
	MOV AH,3	;获取行号，列号
	INT 10H
	MOV BH,0
	MOV AH,2
	INT 10H

	MOV SI,tips1
	CALL PutStr
	CALL GetChar
	PUSH AX
	CALL PutChar
	POP AX
	CALL CODE643
	MOV SI,newline
	CALL PutStr 
	MOV SI,tips2
	CALL PutStr   
	MOV SI,decOfChar
	CALL PutStr
	MOV SI,newline
	CALL PutStr 
	RETF
;-----------------------------------------------------------------

;-------------------------------------------------------;
decOfChar DB 0,0,0,0DH,0AH,0
hello DB "Hello world from 161630230-sinkinben",0DH,0AH,0
newline DB 0DH,0AH,0
tips1 DB "Enter a char:",0
tips2 DB "The dec is:",0
;-------------------------------------------------------;
PutStr:
LODSB
OR AL,AL
JZ PutStr_OK
MOV AH,14
INT 10H
JMP SHORT PutStr
PutStr_OK:
RET
;------------------;
GetChar:                        ;键盘输入一个字符,AL=ascii
    MOV   AH, 0
    INT   16H
    RET
;---------------------
PutChar:                        ;显示一个字符AL
    MOV   BH, 0
    MOV   AH, 14
    INT   10H
    RET
;-----------------------
;入口参数=AL
CODE643:
	PUSH AX
	PUSH BX
	PUSH CX
	PUSH DX
	MOV CX,10 
	XOR BX,BX
	XOR AH,AH
code643_loop: 
    TEST AL,AL
    JE code643_loop2
	XOR DX,DX 
	DIV CX
	ADD DX,'0'
	PUSH DX 
	INC BX
	JMP code643_loop
 
code643_loop2:
    TEST BX,BX
    JE code643_ok
    POP DX
    MOV [decOfChar],DL
    DEC BX
    TEST BX,BX
    JE code643_ok
    POP DX
    MOV [decOfChar+1],DL
    DEC BX
    TEST BX,BX
    JE code643_ok
    POP DX
    MOV [decOfChar+2],DL     
code643_ok:   
    POP DX
    POP CX
    POP BX
    POP AX
	RET 
;-----end code 6-43 ---------;

;---------------------
times 510-($-$$) db 0
db 55h,0aah
end_of_text 