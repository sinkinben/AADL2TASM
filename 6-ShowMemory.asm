section text
bits 16
;
    Signature     db   "SIN "       ;签名信息
    Version       dw   1            ;格式版本
    Length        dw   end_of_text  ;工作程序长度
    Entry         dw   Begin        ;工作程序入口点的偏移
    ExpectedSeg   dw   0088H        ;工作程序期望的内存区域起始段值
    Reserved      dd   0            ;保留
;
BYTESNUM EQU 0X10   
ADDR EQU 0XFFFF
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
    MOV SI,tips2
	CALL PutStr
	
    CALL CODE645
    MOV SI,newline
	CALL PutStr
	MOV SI,tips3
	CALL PutStr
    CALL CODE645_DEC
    MOV SI,newline
	CALL PutStr
	
	RETF
;-----------------------------------------------------------------
;-----CODE6-45------;
CODE645:
    PUSH BX
    PUSH SI
    PUSH DX
    MOV BX,ADDR
    MOV ES,BX
    ;SHL BX,4
    XOR SI,SI  
    DEC SI
code645_loop:
    INC SI
    CMP SI,BYTESNUM
    JGE code645_ok
    MOV DL,[ES:SI]
    CALL ToHex
    MOV DL,' '
    PUSH AX
	MOV AL,DL
    CALL PutChar 
	POP AX
    JMP code645_loop
code645_ok: 
    POP DX
    POP SI
    POP BX
    RET  
;----end code 6-45 -----; 
CODE645_DEC:  
    PUSH BX
    PUSH DX
    PUSH SI 
    MOV BX,ADDR
    MOV ES,BX
    ;SHL BX,4
    XOR DX,DX
    XOR SI,SI
    DEC SI
    
CODE645_DEC_LOOP:
    INC SI
    CMP SI,BYTESNUM
    JGE CODE645_DEC_OK  
    MOV DL,[ES:SI]
    CALL TODEC
    MOV AL,' ' 
    CALL PutChar    
    JMP CODE645_DEC_LOOP
CODE645_DEC_OK:
    POP SI
    POP DX
    POP BX         
    RET
;-------------------------------------------------------;

hello DB "Hello world from 161630230-sinkinben",0DH,0AH,0
newline DB 0DH,0AH,0
tips1  DB "Addr 0xF0000 memory:",0DH,0AH,0
tips2  db "HEX:",0
tips3  db "DEC:",0
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
;-------------------;
;入口参数:DL
ToHex:
	PUSH AX
    PUSH DX
	
    SHR DL,4
    ADD DL,'0'
    CMP DL,'9'
    JLE tohex_label1
    ADD DL,7
tohex_label1:
	MOV AL,DL
    CALL PutChar
    POP DX    
    AND DL,0X0F
    ADD DL,'0'
    CMP DL,'9' 
    JLE tohex_label2
    ADD DL,7
tohex_label2:
	MOV AL,DL
    CALL PutChar 
tohex_ok:
	POP AX
    RET
;-------------------;  
;-------------------; 
;入口参数DX,字符串输出十进制数
TODEC:
    PUSH CX 
    PUSH AX 
    PUSH BX
    XOR CX,CX
    MOV AX,DX
    XOR DX,DX   ; num = [dx:ax]
    MOV BX,10D
TODEC_LOOP:
    TEST AX,AX
    JE TODEC_LABEL
    DIV BX
    ADD DX,'0'
    PUSH DX
    INC CX
    XOR DX,DX
    JMP TODEC_LOOP  
TODEC_ZERO:
    ;num is zero
    MOV DL,'0'
	PUSH AX
	MOV AL,DL
    CALL PutChar 
	POP AX
    JMP TODEC_OK 
TODEC_LABEL:     
    ;num is not zero 
    TEST CX,CX
    JE TODEC_ZERO
    POP DX
    PUSH AX
	MOV AL,DL
    CALL PutChar 
	POP AX
    LOOP TODEC_LABEL  
TODEC_OK:  
    POP BX
    POP AX
    POP CX
    RET
;-------------------;
;---------------------
times 510-($-$$) db 0
db 55h,0aah
end_of_text 