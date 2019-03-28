
    Signature  equ   0              ;signature offset
    Length     equ   6              ;length offset
    Entry      equ   8              ;entry offset
    ZONELOW    equ   1000H          ;
    ZONEHIGH   equ   9000H          ;max segment value
    ZONETEMP   equ   07E0H          ;first sector buffer
	ProgramListOrder equ 1D			;my programs list sector
    
    section   text              
    bits  16                    
    org   7C00H                 
        ;
    Begin:
        MOV   AX, 0
        CLI
        MOV   SS, AX                
        MOV   SP, 7C00H
        STI
        ;
    Lab1:                           
        CLD
        PUSH  CS
        POP   DS                    ;DS=CS
        MOV   AX, ZONETEMP          
        MOV   WORD [DAP+6], AX      ;DAP��ֵ
        MOV   ES, AX                ;���浽ES
        
        MOV   DX, tips1
        CALL  PutStr                
        CALL  GetInstruction        ;get a user instruction
		LEA   EAX, [EAX+EAX*4]
		SHL   EAX, 1
        OR    EAX, EAX              
        JZ    Begin
        ;---------------------------
	RunProgram:
        MOV   [DAP+8], EAX       	
        CALL  ReadSec               
        JC    Lab7                  
        ;---------------------------
        CMP   DWORD [ES:Signature], "SIN "
        JNZ   Lab6                  ;invalid signature
        ;---------------------------
        MOV   CX, [ES:Length]       
        CMP   CX, 0                 
        JZ    Lab6                  
        ADD   CX, 511               
        SHR   CX, 9                 ;calcultor the length of the program
        ;---------------------------
        MOV   AX, [ES:Entry+2]      
        CMP   AX, ZONELOW           
        JB    Lab2                  
        CMP   AX, ZONEHIGH
        JB    Lab3
    Lab2:
        MOV   AX, ZONELOW           
    Lab3:
        MOV   WORD [DAP+6], AX   
        ;-----------������Ų----------------
        MOV   ES, AX                
        XOR   DI, DI                
        PUSH  DS
        PUSH  ZONETEMP              
        POP   DS                    
        XOR   SI, SI
        PUSH  CX                    
        MOV   CX, 128
        REP   MOVSD                 
        POP   CX
        POP   DS
        ;--------��ȡ��������-------------
        DEC   CX                    
        JZ    Lab5                  ; program has only one sector
    Lab4:
        ADD   WORD [DAP+6], 20H  
        INC   DWORD [DAP+8]      	;get next sector
        CALL  ReadSec               ;read a sector
        JC    Lab7                  
        LOOP  Lab4                  
        ;---------------------------
    Lab5:
        MOV   [ES:Entry+2], ES      ;set program working entry
        CALL  FAR  [ES:Entry]       ;jmp to run program
        JMP   Lab1                  
        ;---------------------------
    Lab6:
        MOV   DX, tips2             ;invalid sector
        CALL  PutStr                ;
        JMP   Lab1                  
    Lab7:
        MOV   DX, tips3 
        CALL  PutStr    
        JMP   Lab1
    Over:
        MOV   DX, tips4             
        CALL  PutStr                ;Exit
    Halt:
        HLT
        JMP   SHORT  Halt           
    ;===============================
    ReadSec:                        ;��1��ָ����������ָ���ڴ�����
        PUSH  DX
        PUSH  SI
        MOV	  SI, DAP            	;ָ��DAP��������LBA�ͻ�������ַ��
        MOV	  DL, 80H               ;C��
        MOV	  AH, 42H               ;��չ��ʽ��
        INT   13H                   ;����
        POP   SI
        POP   DX
        RET
    ;-------------------------------
    GetSecAdr:                      ;�����û��������빤����������������LBA
        MOV   DX, buffer            ;DXָ�򻺳�����
        CALL  GetStr                ;�����û�����һ�����ִ����س���β��
        MOV   AL, 0DH               ;�γɻس�����Ч��
        CALL  PutChar
        MOV   AL, 0AH
        CALL  PutChar        
        MOV   SI, buffer+1          ;DXָ�򻺳����е����ִ�
        CALL  DSTOB                 ;�����ִ�ת�ɶ�Ӧ�Ķ�����ֵ�����ٷ����㣩
        RET
    ;-------------------------------
	GetInstruction:
		MOV   DX, buffer
		CALL  GetStr
		MOV   AL, 0DH
        CALL  PutChar
        MOV   AL, 0AH
        CALL  PutChar
		MOV   SI, buffer+1
		CMP   DWORD [SI], "list"
		JE    ShowList
		CMP   DWORD [SI], "clsr"
		JE    ClearScreen
		;else 
		CALL  DSTOB
		RET
	ShowList:
		MOV   EAX, ProgramListOrder
		RET
	ClearScreen:
		MOV AL,3
		MOV AH,0
		INT 10H
		JMP Begin
	;---------------------------------
    DSTOB:                          ;�����ִ�ת���ɶ�Ӧ�Ķ�����ֵ
        XOR   EAX, EAX
        XOR   EDX, EDX
    .next:
        LODSB                       ;ȡһ�����ַ�
        CMP   AL, 0DH
        JZ    .ok
        AND   AL, 0FH
        IMUL  EDX, 10
        ADD   EDX, EAX
        JMP   SHORT .next
    .ok:
        MOV   EAX, EDX              ;EAX���ض�����ֵ
        RET
    ;-------------------------------
    %define  Space      20H         ;�ո��
    %define  Enter      0DH         ;�س���
    %define  Backspace  08H         ;�˸�
    %define  Bell       07H         ;����
    ;GetStr
    ;��ڲ�����DS:DX=�������׵�ַ
    ;��������һ���ֽ������ַ�������
    ;���ص��ַ����Իس�����0DH����β
    GetStr:
        PUSH  SI
        MOV   SI, DX
        MOV   CL, [SI]              
        CMP   CL, 1                 
        JB    .Lab6
        ;
        INC   SI                    
        XOR   CH, CH                
    .Lab1:
        CALL  GetChar               
        OR    AL, AL                
        JZ    SHORT  .Lab1
        CMP   AL, Enter             
        JZ    SHORT  .Lab5          
        CMP   AL,  Backspace        
        JZ    SHORT  .Lab4          
        CMP   AL, Space             
        JB    SHORT  .Lab1
        ;
      
        ;
        CMP   CL, 1                
        JA    SHORT  .Lab3          
    .Lab2:
        MOV   AL, Bell
        CALL  PutChar               
        JMP   SHORT  .Lab1          
        ;
    .Lab3:
        CALL  PutChar               
        MOV   [SI], AL              
        INC   SI                    
        INC   CH                    
        DEC   CL                    
        JMP   SHORT  .Lab1          
        ;
    .Lab4:                          
        CMP   CH, 0                 
        JBE   .Lab2                 
        CALL  PutChar               
        MOV   AL, Space
        CALL  PutChar               
        MOV   AL, Backspace
        CALL  PutChar               
        DEC   SI                    
        DEC   CH                    
        INC   CL                    
        JMP   SHORT  .Lab1          
        ;
    .Lab5:
        MOV    [SI], AL             
    .Lab6:
        POP   SI
        RET
    ;-------------------------------
    PutChar:                        ;��ʾһ���ַ�
        MOV   BH, 0
        MOV   AH, 14
        INT   10H
        RET
    ;
    GetChar:                        ;��������һ���ַ�
        MOV   AH, 0
        INT   16H
        RET
    ;-------------------------------
    PutStr:                         ;��ʾ�ַ�������0��β��
        MOV   BH, 0
        MOV   SI, DX
    .Lab1:
        LODSB
        OR    AL, AL
        JZ    .Lab2
        MOV   AH, 14
        INT   10H
        JMP   .Lab1
    .Lab2:
        RET
    ;-------------------------------
    DAP:                            ;���̵�ַ��
        DB    10H                   ;DAP�ߴ�
        DB    0                     ;����
        DW    1                     ;������
        DW    0                     ;������ƫ��
        DW    ZONETEMP              ;��������ֵ
        DD    0                     ;��ʼ������LBA�ĵ�4�ֽ�
        DD    0                     ;��ʼ������LBA�ĸ�4�ֽ�
    ;-------------------------------
    buffer:                         ;������
        db    9                     ;���������ַ�������
        db    "123456789"           ;����ַ���
    ;-------------------------------
    tips1     db    "Input a instruction:", 0
    tips2     db    "Invalid instruction", 0DH, 0AH, 0
    tips3     db    "DiskReadingFatal", 0DH, 0AH, 0
    tips4     db    "Exit", 0
    ;-------------------------------
    times   510 - ($ - $$) db   0   ;���0��ֱ��510�ֽ�
    db    55h, 0aah             ;���2�ֽڣ�����512�ֽ�
