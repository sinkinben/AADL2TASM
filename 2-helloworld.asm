section text
bits 16
;������20
;
    Signature     db   "SIN "       ;ǩ����Ϣ
    Version       dw   1            ;��ʽ�汾
    Length        dw   end_of_text  ;�������򳤶�
    Entry         dw   Begin        ;����������ڵ��ƫ��
    ExpectedSeg   dw   0088H        ;���������������ڴ�������ʼ��ֵ
    Reserved      dd   0            ;����
;

Begin:
CLD
MOV  AX,CS
MOV  DS,AX

MOV BH, 0	;��ʾҳ
MOV AH, 3	;��õ�ǰ����(DH,DL) (CH,CL)
INT 10H		
MOV BL, [Color]
MOV DI, [Count]
JMP Loop1Over
;-----------------------------------------------------------------
Loop1:
	MOV SI, hello
	INC DH		;��һ����ʾ
	XOR DL, DL
	MOV CX, 1
Loop2:
	MOV AL, [SI]
	TEST AL, AL
	JE  Loop2Over
	MOV BH, 0
	MOV AH, 9		;��ʾAL�ַ���BHҳ�ţ�BL���ԣ�CX�ַ��ظ�����
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