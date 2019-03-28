    ;演示程序（工作程序）dp86.asm
    ;演示软件中断处理程序（采用虚拟机可加载格式）
        section   text
        bits   16
;
    Signature     db   "SIN "       ;签名信息
    Version       dw   1            ;格式版本
    Length        dw   end_of_text  ;工作程序长度
    Entry         dw   Begin        ;工作程序入口点的偏移
    ExpectedSeg   dw   1A00H        ;工作程序期望的内存区域起始段值
    Reserved      dd   0            ;保留
;
    ;-------------------------------
    newhandler:                     ;扩展显示I/O程序入口
        STI                         ;开中断//@2
        PUSHA                       ;保护通用寄存器//@3
        PUSH  DS                    ;保护涉及的段寄存器//@4
        PUSH  ES
        ;
        CALL  putchar               ;实现功能
        ;
        POP   ES                    ;恢复段寄存器
        POP   DS
        POPA                        ;恢复通用寄存器
        IRET                        ;中断返回
    ;------------------------------
    putchar:
    ;功能：当前光标位置处显示带属性的字符，随后光标后移一个位置
    ;入口：AL=字符ASCII码；BL=属性
    ;说明：不支持退格符、响铃符等控制符
        PUSH  AX
        MOV   AX, 0B800H            ;设置显示存储区段值
        MOV   DS, AX
        MOV   ES, AX
        POP   AX
        ;        
        CALL  get_lcursor           ;取得光标逻辑位置
        ;
        CMP   AL, 0DH               ;回车符？
        JNZ   .LAB1
        MOV   DL, 0                 ;是，列号DL=0
        JMP   .LAB3
    .LAB1:
        CMP   AL, 0AH               ;换行符？
        JZ    .LAB2
        ;                           ;至此，普通字符
        MOV   AH, BL                ;AH=属性
        MOV   BX, 0                 ;计算光标位置对应存储单元偏移
        MOV   BL, DH
        IMUL  BX, 80
        ADD   BL, DL
        ADC   BH, 0
        SHL   BX, 1                 ;BX=(行号*80+列号)*2
        ;
        MOV   [BX], AX              ;写到显示存储区对应单元
        ;
        INC   DL                    ;增加列号
        CMP   DL, 80                ;超过最后一列？
        JB    .LAB3                 ;否
        MOV   DL, 0                 ;是，列号=0
    .LAB2:
        INC   DH                    ;增加行号
        CMP   DH, 25                ;超过最后一行？
        JB    .LAB3                 ;否
        DEC   DH                    ;是，行号减1（保持在最后一行）
        ;
        CLD                         ;实现屏幕向上滚一行
        MOV   SI, 80*2              ;第1行起始偏移
        MOV   ES, AX
        MOV   DI, 0                 ;第0行起始偏移
        MOV   CX, 80*24             ;复制24行内容
        REP   MOVSW                 ;实现屏幕向上滚一行
        ;
        MOV   CX, 80                ;清除屏幕最后一行
        MOV   DI, 80*24*2           ;最后一行起始偏移
        MOV   AX, 0x0720            ;黑底白字
        REP   STOSW                 ;形成空白行
    .LAB3:
        CALL  set_lcursor           ;设置逻辑光标
        CALL  set_pcursor           ;设置物理光标
        RET
    ;------------------------------
    get_lcursor:                    ;取得逻辑光标位置（DH=行号，DL=列号）
        PUSH  DS
        PUSH  0040H                 ;BIOS数据区的段值是0040H
        POP   DS                    ;DS=0040H
        MOV   DL, [0050H]           ;取得列号
        MOV   DH, [0051H]           ;取得行号
        POP   DS
        RET
    ;------------------------------
    set_lcursor:                    ;设置逻辑光标（DH=行号，DL=列号）
        PUSH  DS
        PUSH  0040H                 ;BIOS数据区的段值是0040H
        POP   DS                    ;DS=0040H
        MOV   [0050H], DL           ;设置列号
        MOV   [0051H], DH           ;设置行号
        POP   DS
        RET
    ;------------------------------
    set_pcursor:                    ;设置物理光标（DH=行号，DL=列号）
        MOV   AL, 80                ;计算光标寄存器值
        MUL   DH                    ;AX=(行号*80+列号)
        ADD   AL, DL
        ADC   AH, 0
        MOV   CX, AX                ;保存到CX
        ;
        MOV   DX, 3D4H              ;索引端口地址
        MOV   AL, 14                ;14号是光标寄存器高位
        OUT   DX, AL
        MOV   DX, 3D5H              ;数据端口地址
        MOV   AL, CH
        OUT   DX, AL                ;设置光标寄存器高8位
        ;
        MOV   DX, 3D4H              ;索引端口地址
        MOV   AL, 15
        OUT   DX, AL
        MOV   DX, 3D5H              ;数据端口地址
        MOV   AL, CL
        OUT   DX, AL                ;设置光标寄存器低8位
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
		MOV   [old90h], AX		;旧段值
		MOV   AX, [ES:SI+2]
		MOV   [old90h+2], AX	;旧偏移
		
        MOV   AL, 0
        MOV   AH, 5
        INT   10H                       ;指定第0显示页
        ;
        XOR   AX, AX                    ;准备设置中断向量
        MOV   DS, AX
        CLI
        MOV   WORD [90H*4], newhandler  ;设置90H中断向量之偏移
        MOV   [90H*4+2], CS             ;设置90H中断向量之段值
        STI
        ;
        PUSH  CS
        POP   DS
        CLD
        MOV   BL, 17H                   ;兰底白字
		;MOV    bl,27H	;绿底	
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
;入口参数SI
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
    end_of_text:                    ;结束位置
