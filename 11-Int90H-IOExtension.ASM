    ;��ʾ���򣨹�������dp86.asm
    ;��ʾ�����жϴ������򣨲���������ɼ��ظ�ʽ��
        section   text
        bits   16
;
    Signature     db   "SIN "       ;ǩ����Ϣ
    Version       dw   1            ;��ʽ�汾
    Length        dw   end_of_text  ;�������򳤶�
    Entry         dw   Begin        ;����������ڵ��ƫ��
    ExpectedSeg   dw   1A00H        ;���������������ڴ�������ʼ��ֵ
    Reserved      dd   0            ;����
;
    ;-------------------------------
    newhandler:                     ;��չ��ʾI/O�������
        STI                         ;���ж�//@2
        PUSHA                       ;����ͨ�üĴ���//@3
        PUSH  DS                    ;�����漰�ĶμĴ���//@4
        PUSH  ES
        ;
        CALL  putchar               ;ʵ�ֹ���
        ;
        POP   ES                    ;�ָ��μĴ���
        POP   DS
        POPA                        ;�ָ�ͨ�üĴ���
        IRET                        ;�жϷ���
    ;------------------------------
    putchar:
    ;���ܣ���ǰ���λ�ô���ʾ�����Ե��ַ�����������һ��λ��
    ;��ڣ�AL=�ַ�ASCII�룻BL=����
    ;˵������֧���˸����������ȿ��Ʒ�
        PUSH  AX
        MOV   AX, 0B800H            ;������ʾ�洢����ֵ
        MOV   DS, AX
        MOV   ES, AX
        POP   AX
        ;        
        CALL  get_lcursor           ;ȡ�ù���߼�λ��
        ;
        CMP   AL, 0DH               ;�س�����
        JNZ   .LAB1
        MOV   DL, 0                 ;�ǣ��к�DL=0
        JMP   .LAB3
    .LAB1:
        CMP   AL, 0AH               ;���з���
        JZ    .LAB2
        ;                           ;���ˣ���ͨ�ַ�
        MOV   AH, BL                ;AH=����
        MOV   BX, 0                 ;������λ�ö�Ӧ�洢��Ԫƫ��
        MOV   BL, DH
        IMUL  BX, 80
        ADD   BL, DL
        ADC   BH, 0
        SHL   BX, 1                 ;BX=(�к�*80+�к�)*2
        ;
        MOV   [BX], AX              ;д����ʾ�洢����Ӧ��Ԫ
        ;
        INC   DL                    ;�����к�
        CMP   DL, 80                ;�������һ�У�
        JB    .LAB3                 ;��
        MOV   DL, 0                 ;�ǣ��к�=0
    .LAB2:
        INC   DH                    ;�����к�
        CMP   DH, 25                ;�������һ�У�
        JB    .LAB3                 ;��
        DEC   DH                    ;�ǣ��кż�1�����������һ�У�
        ;
        CLD                         ;ʵ����Ļ���Ϲ�һ��
        MOV   SI, 80*2              ;��1����ʼƫ��
        MOV   ES, AX
        MOV   DI, 0                 ;��0����ʼƫ��
        MOV   CX, 80*24             ;����24������
        REP   MOVSW                 ;ʵ����Ļ���Ϲ�һ��
        ;
        MOV   CX, 80                ;�����Ļ���һ��
        MOV   DI, 80*24*2           ;���һ����ʼƫ��
        MOV   AX, 0x0720            ;�ڵװ���
        REP   STOSW                 ;�γɿհ���
    .LAB3:
        CALL  set_lcursor           ;�����߼����
        CALL  set_pcursor           ;�����������
        RET
    ;------------------------------
    get_lcursor:                    ;ȡ���߼����λ�ã�DH=�кţ�DL=�кţ�
        PUSH  DS
        PUSH  0040H                 ;BIOS�������Ķ�ֵ��0040H
        POP   DS                    ;DS=0040H
        MOV   DL, [0050H]           ;ȡ���к�
        MOV   DH, [0051H]           ;ȡ���к�
        POP   DS
        RET
    ;------------------------------
    set_lcursor:                    ;�����߼���꣨DH=�кţ�DL=�кţ�
        PUSH  DS
        PUSH  0040H                 ;BIOS�������Ķ�ֵ��0040H
        POP   DS                    ;DS=0040H
        MOV   [0050H], DL           ;�����к�
        MOV   [0051H], DH           ;�����к�
        POP   DS
        RET
    ;------------------------------
    set_pcursor:                    ;����������꣨DH=�кţ�DL=�кţ�
        MOV   AL, 80                ;������Ĵ���ֵ
        MUL   DH                    ;AX=(�к�*80+�к�)
        ADD   AL, DL
        ADC   AH, 0
        MOV   CX, AX                ;���浽CX
        ;
        MOV   DX, 3D4H              ;�����˿ڵ�ַ
        MOV   AL, 14                ;14���ǹ��Ĵ�����λ
        OUT   DX, AL
        MOV   DX, 3D5H              ;���ݶ˿ڵ�ַ
        MOV   AL, CH
        OUT   DX, AL                ;���ù��Ĵ�����8λ
        ;
        MOV   DX, 3D4H              ;�����˿ڵ�ַ
        MOV   AL, 15
        OUT   DX, AL
        MOV   DX, 3D5H              ;���ݶ˿ڵ�ַ
        MOV   AL, CL
        OUT   DX, AL                ;���ù��Ĵ�����8λ
        RET
    ;===============================
    Begin:
		MOV   AX, CS
		MOV   DS, AX	;DS=CS
		MOV	  SI, 90H*4
		MOV   AX, 0 
		MOV   ES, AX	;ES=0
		;
		MOV   AX, [ES:SI]
		MOV   [old90h], AX		;�ɶ�ֵ
		MOV   AX, [ES:SI+2]
		MOV   [old90h+2], AX	;��ƫ��
		
        MOV   AL, 0
        MOV   AH, 5
        INT   10H                       ;ָ����0��ʾҳ
        ;
        XOR   AX, AX                    ;׼�������ж�����
        MOV   DS, AX
        CLI
        MOV   WORD [90H*4], newhandler  ;����90H�ж�����֮ƫ��
        MOV   [90H*4+2], CS             ;����90H�ж�����֮��ֵ
        STI
        ;
        PUSH  CS
        POP   DS
        CLD
        MOV   BL, 17H                   ;���װ���
		;MOV    bl,27H	;�̵�	
		;mov bl,07h
		;
		MOV  SI,line
		CALL ExIOPutStr
		inc  bl

		MOV  SI,list
		CALL ExIOPutStr
		inc  bl
		
		MOV  SI,list1
		CALL ExIOPutStr
		inc  bl
		
		MOV  SI,list2
		CALL ExIOPutStr
		inc  bl
		
		MOV  SI,list3
		CALL ExIOPutStr
		inc  bl
		
		MOV  SI,list4
		CALL ExIOPutStr
		inc  bl

		MOV SI,list5
		CALL ExIOPutStr
		inc  bl

		MOV SI,list6
		CALL ExIOPutStr
		inc  bl
		
		MOV SI,list7
		CALL ExIOPutStr
		mov bl,17h
		
		MOV SI,list8
		CALL ExIOPutStr
		inc  bl
		
		MOV SI,list9
		CALL ExIOPutStr
		inc  bl
		
		MOV SI,list10
		CALL ExIOPutStr
		inc  bl
		
		MOV SI,list11
		CALL ExIOPutStr
		inc  bl
		
		MOV SI,list12
		CALL ExIOPutStr
		INC BL
		
		MOV SI,list13
		CALL ExIOPutStr
		inc bl
		
		MOV  SI,line
		CALL ExIOPutStr
		;
	restore_90H_handler:
		MOV AX, 0 
		MOV ES, AX
		MOV SI, 90H*4
		MOV EAX, [CS:old90h]
		MOV [ES:SI], EAX
        RETF
    ;
;------------------;
line    DB "----------------------------------",0DH,0AH,0
list    DB "161630230 SinKinBen's Program List",0DH,0AH,0
list1   DB "1. Show Program List",0DH,0AH,0
list2   DB "2. Hello World",0DH,0AH,0
list3   DB "3. Add Calculator",0DH,0AH,0
list4   DB "4. Show Program Working Segment",0DH,0AH,0
list5   DB "5. Show DEC of a character",0DH,0AH,0
list6   DB "6. Show address=0XF000 memory",0DH,0AH,0
list7   DB "7. ReadCMOS - an I/O program",0dh,0ah,0
list8	DB "8. INT00H-Divide Calculator",0dh,0ah,0
list9	DB "9. INT09H-Keyboard Handler",0dh,0ah,0
list10	DB "10.INT1CH-System Real Clock",0dh,0ah,0
list11  DB "11.INT90H-TTY Print with I/O Extension",0dh,0ah,0
list12  DB "12.Bubble Sort",0dh,0ah,0
list13  DB "13.Pacman Eat Dots Game",0dh,0ah,0
old90h	DD 0
;------------------;
;------------------;
;��ڲ���SI
ExIOPutStr:
LODSB
OR AL,AL
JZ ExIOPutStr_OK
;
;MOV AH,14
;INT 10H
;
INT 90H
JMP SHORT ExIOPutStr
ExIOPutStr_OK:
RET
;------------------;
    end_of_text:                    ;����λ��