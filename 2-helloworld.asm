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

MOV BH, 0	;显示页
MOV AH, 3	;获得当前坐标(DH,DL) (CH,CL)
INT 10H		
MOV BL, [Color]
MOV DI, [Count]
JMP Loop1Over
;-----------------------------------------------------------------
Loop1:
	MOV SI, hello
	INC DH		;下一行显示
	XOR DL, DL
	MOV CX, 1
Loop2:
	MOV AL, [SI]
	TEST AL, AL
	JE  Loop2Over
	MOV BH, 0
	MOV AH, 9		;显示AL字符，BH页号，BL属性，CX字符重复次数
	INT 10H
	INC DL
	INC SI
	JMP Loop2
Loop2Over:
	INC BL
	DEC DI
	TEST DI,DI
	JE  Loop1Over
	JMP Loop1
Loop1Over:
	MOV SI, hello
	CALL PutStr
	MOV SI, hello
	CALL PutStr
	MOV SI, hello
	CALL PutStr
	RETF
;-----------------------------------------------------------------

;-------------------------------------------------------;
hello DB "Hello world from 161630230-sinkinben",0DH,0AH,0
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
CurRow db 5
CurCol db 8
Color  db 0x07
Count  db 5
;------------------;
times 510-($-$$) db 0
db 55h,0aah
end_of_text 