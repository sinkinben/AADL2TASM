
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
        MOV   WORD [DAP+6], AX      ;DAP段值
        MOV   ES, AX                ;保存到ES
        
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
        ;-----------自身腾挪----------------
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
        ;--------读取扇区数据-------------
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
    ReadSec:                        ;读1个指定的扇区到指定内存区域
        PUSH  DX
        PUSH  SI
        MOV	  SI, DAP            	;指向DAP（含扇区LBA和缓冲区地址）
        MOV	  DL, 80H               ;C盘
        MOV	  AH, 42H               ;扩展方式读
        INT   13H                   ;读！
        POP   SI
        POP   DX
        RET
    ;-------------------------------
    GetSecAdr:                      ;接受用户键盘输入工作程序所在扇区的LBA
        MOV   DX, buffer            ;DX指向缓冲区首
        CALL  GetStr                ;接受用户输入一个数字串（回车结尾）
        MOV   AL, 0DH               ;形成回车换行效果
        CALL  PutChar
        MOV   AL, 0AH
        CALL  PutChar        
        MOV   SI, buffer+1          ;DX指向缓冲区中的数字串
        CALL  DSTOB                 ;将数字串转成对应的二进制值（至少返回零）
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
    ;GetStr
    ;入口参数：DS:DX=缓冲区首地址
    ;缓冲区第一个字节是其字符串容量
    ;返回的字符串以回车符（0DH）结尾
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
    PutStr:                         ;显示字符串（以0结尾）
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
    DAP:                            ;磁盘地址包
        DB    10H                   ;DAP尺寸
        DB    0                     ;保留
        DW    1                     ;扇区数
        DW    0                     ;缓冲区偏移
        DW    ZONETEMP              ;缓冲区段值
        DD    0                     ;起始扇区号LBA的低4字节
        DD    0                     ;起始扇区号LBA的高4字节
    ;-------------------------------
    buffer:                         ;缓冲区
        db    9                     ;缓冲区的字符串容量
        db    "123456789"           ;存放字符串
    ;-------------------------------
    tips1     db    "Input a instruction:", 0
    tips2     db    "Invalid instruction", 0DH, 0AH, 0
    tips3     db    "DiskReadingFatal", 0DH, 0AH, 0
    tips4     db    "Exit", 0
    ;-------------------------------
    times   510 - ($ - $$) db   0   ;填充0，直到510字节
    db    55h, 0aah             ;最后2字节，共计512字节
