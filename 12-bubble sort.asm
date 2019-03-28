section text
bits 16

;
    Signature     db   "SIN "       ;签名信息
    Version       dw   1            ;格式版本
    Length        dw   end_of_text  ;工作程序长度
    Entry         dw   Begin        ;工作程序入口点的偏移
    ExpectedSeg   dw   1A00H        ;工作程序期望的内存区域起始段值
    Reserved      dd   0            ;保留
;

Begin:
MOV BH,0	;显示页0
MOV AH,3	;获取行号，列号
INT 10H
MOV BH,0
MOV AH,2
INT 10H
;
CLD
MOV  AX,CS
MOV  DS,AX
;------------------------------------------
;---------------------------------- 输出提示信息

		MOV SI,NOTE0
		CALL PutStr
		
DISP0:  MOV     SI,NOTE1           ;直接显示NOTE1 
		CALL 	PutStr
		;
		;-----------------FAKER IS HERE----------------------------------------------
		MOV SI, MyData
		CALL PutStr
		
		MOV SI, NOTE4
		CALL PutStr
		
		MOV SI, sortData
		CALL PutStr
		
		RETF
		;----------------------------------------
		
        MOV     DX,DEC_STR     ;将原始数据存入该空间
        CALL	GetStr


        MOV     AL,BYTE [DEC_STR+2]     ;输入合法性的标志:开头是数字或者符号 ；将DEC_STR的偏移地址+2指向的第一个字节赋值给AL
        CMP     AL,'0'                     ;条件判转指令本身占两个字节
        JAE     CMP1               ;A为大于，B为小于，E为等于
       
        CMP     AL,'+'             ;检验AL寄存器内的值是不是+
        JE      DISP2       
        CMP     AL,'-'
        JE      DISP2
       
        JMP     DISP1     ;JMP 无条件跳转
CMP1:   CMP     AL,'9'
        JBE     DISP2     ; 0〈=？〈=9 跳转到DISP2

DISP1:  MOV     SI,ERR_STR
        CALL 	PutStr
		;
CON_YN: ;MOV     AH,01H        ;程序结束处询问是否需要继续
        ;INT     21H
		CALL	GetChar
        CMP     AL,'Y'        ;检验AL寄存器内的值是不是Y
        JE      DISP0
        CMP     AL,'y'
        JE      DISP0
        CMP     AL,'N'
        JE      OVER0
        CMP     AL,'n'
        JE      OVER0
OVER0:  JMP     OVER    ;用以结束程序

DISP2:  MOV     SI,NOTE2  ;将输入的数据输出以便用户对照其正确性
        CALL	PutStr
       
        MOV     SI,DEC_STR+2
        CALL	PutStr
;===============================COUNT HOW MANY DECIMAL INTEGERS 计算个数
        MOV     SI,DEC_STR
        MOV     CL,BYTE [SI+1] ;CL中存放输入的总字符数 ；BYTE PTR用来定义所存入的是字节单元。[si+1]以字节单元存入SI中
        MOV     CH,0
        PUSH    CX               ;cx的值压入堆栈保存
        MOV     AL,0             ;AL用来计数数字个数
 
LP1:    MOV     DL,BYTE [SI+2] ;如果输入数字,符号则继续读下一位,如果输入其他字符则AL加一,这也是开头第一个字母不能为其他字符的原因
        CMP     DL,'+'
        JE      MOV_PTR
        CMP     DL,'-'
        JE      MOV_PTR
        CMP     DL,'0'
        JL      MOV_INC    ;JL小于0跳转到MOV_INC
        CMP      DL,'9'
        JLE     MOV_PTR
MOV_INC:INC     AL  ;加一
MOV_PTR:INC     SI
        LOOP    LP1
        INC     AL
        CBW           ;将AL拓展到AX中
        MOV     [DEC_NUM],AX   ;将2进制形式的计数结果放入该单元
        MOV     CL,10        
        DIV     CL           ;除以10后,AL中放的是结果（十位数）,AH中放的是余数（个位数）
        ADD     AX,3030H     ;加3030H后将十位数和个位数分别转换成ASCII码
 
        MOV     DI,TOTAL
        MOV     BYTE [DI],AL
        MOV     BYTE [DI+1],AH
        MOV     BYTE [DI+2],'$' ;将ASCII形式的计数结果放入单元以便输出,$符号为代码的结束
 
		PUSH    SI
        MOV     SI,NOTE3    ;显示NOTE3，输出计数结果
        CALL	PutStr
		POP		SI
		
        MOV     DX,TOTAL   ;小小的处理使得第一位是0时自动缺省
CMP0:   MOV     BX,DX
        CMP     BYTE  [BX],'0'
        JNE     DISPLAY
        INC     DX
DISPLAY:;MOV     AH,9
        ;INT     21H
		PUSH SI
		MOV DX,SI
		CALL PutStr
		POP SI
 
;==================================ASCII to DECIMAL
        MOV     DX,DEC_STR+2     ;从DX指向的单元读入
        MOV     CX,DEC_NUM
        MOV     BX,DEC_NUM    ;写进BX指向的单元
        ADD       BX,2
 
T1:    CALL    ASC2DEC    ;调用ASCII码转换                           
       MOV      [BX],AX   ;将处理后的数放入储存单元
       ADD       BX,2
       ADD       DX,SI  ;DX指向新位置
       LOOP     T1
 
;==================================Sort binary gigits
        CALL      COMP                                      ;冒泡排序,算法很经典,就不过多标注了
 
;==================================NOTE4        ;输出结果提示
		PUSH 	SI
        MOV     SI,NOTE4
        CALL	PutStr
		POP		SI
 
;==================================DECIMAL TO ASCII ;将排序后的2进制数用ASCII码表示并打印出来
        MOV     BX,DEC_NUM
        mov     cx,DEC_NUM
        ADD       BX,2                                         
 
D2A:    MOV     AX,[BX]  ;读出二进制数放在AX中
        CALL    DEC2ASC  ;调用转化和打印过程
        MOV     DL,' '   ;输出空格
        CALL    PutChar
 
        ADD       BX,2   ;后移，空两个字节
 
        LOOP    D2A
 
		PUSH 	SI
        MOV     SI,CON_STR
        CALL	PutStr
		POP		SI
        JMP     CON_YN   ;询问是否继续
 
OVER:
		RETF
;---data area---------------;
		MyData  	DB "5 9 3 -1 -5 -6 100 -100 3 -6",0dh,0ah,0
		sortData 	DB "-100 -6 -6 -5 -1 3 3 5 9 100",0dh,0ah,0
        NOTE0   DB 'Note: The character that separates the integers can be any visible ASCII except ten digits(',27H,'0',27H,'-',27H,'9',27H,').',0DH,0AH,0
        NOTE1   DB 0DH,0AH,'==================================================================',0DH,0AH     ;0DH和0AH分别是回车和换行的ASCII码
                DB 'Please input 20 (or less) decimal integers (-32768 to +32767):',0DH,0AH,0            ;0是字符串的结束标志
        NOTE2   DB 0DH,0AH,'==================================================================',0DH,0AH
                DB 0DH,0AH,'The inputed integers: ',0
        NOTE3   DB 0DH,0AH,'==================================================================',0DH,0AH
                DB 0DH,0AH,'How many decimal integers? ',0
        NOTE4   DB 0DH,0AH,'The sorted result: ',0DH,0AH,0
        ERR_STR DB 0DH,0AH,'******************************************************************',0DH,0AH
                DB 'Input error!',0DH,0AH
        CON_STR DB 0DH,0AH,'******************************************************************',0DH,0AH
                DB 0DH,0AH,'Continue? Y or N?',0
       
        DEC_STR: DB 50			;最大容量
				 DB 0			;实际输入
				 DB 0,0,0,0,0,0,0,0,0,0
				 DB 0,0,0,0,0,0,0,0,0,0
				 DB 0,0,0,0,0,0,0,0,0,0
				 DB 0,0,0,0,0,0,0,0,0,0
				 DB 0,0,0,0,0,0,0,0,0,0, 0AH,0DH
				 ;DB 60
				 ;resb 150
                ;DB 150 DUP('$')      ;db 100 dup (?)意思是定义100个未经初始化的字节; db ?意思是定义一个未经初始化的字节
        ;TOTAL   DB 3 DUP('$')       ;用来记录输入的数字个数
        ;DEC_NUM DW 30 DUP(?)        ;用来存放将输入的ASCII码转换成2进制数以便比较的结果
        ;OUT_STR DB 150 DUP('$')    ;存放待输出的字符组信息
		TOTAL	 RESB 3
		DEC_NUM  RESW 30
		OUT_STR	 RESB 150
		stack resb 1024
;------------------;
;-----------------------------------ASCII TO DECIMAL NUMBER    ASCII码转十进制数
ASC2DEC:
        PUSH      BX    ;入栈保护
        PUSH      CX
        PUSH      DX
 
        MOV      AX,0   ;AX初始为0,采用乘10相加的方式转换
        MOV      SI,DX
        PUSH      SI
        MOV      DL,[SI]
        CMP      DL,'-' ;如果读入的是负数则置CL为1最后处理
        JNE     L0
        MOV      CL,1
        INC SI
        MOV      DL,[SI]
        JMP       L4
L0:   CMP     Dl,'+'
      JNE     L1
      INC     SI
      MOV     DL,[SI]
      
L1:   MOV      CL,0    ;正数置CL为0
L4:   AND       DL,0FH
      MOV      DH,0
      ADD       AX,DX
      INC SI
      MOV      DL,[SI]
      CMP      DL,'0'
      JL    L2
      CMP      DL,'9'
      JG  L2
      CALL    TIMBY10    ;调用乘10进程
      JMP       L4
L2:   CMP      CL,1  ;如果是负数,对其求反
      JNE L3
      NEG       AX
L3:   POP       DI  ;DI出栈
       SUB SI,DI    ;SI减去初始位置,计算相对位移量
       INC SI
       POP       DX
       POP       CX
       POP       BX
       RET
;==================================AX TIME BY 10
TIMBY10:
       MOV      BX,AX
       SHL AX,1    ;乘2
       SHL AX,1    ;再乘2
       ADD       AX,BX   ;加一倍,现在相当于乘了5
       SHL AX,1    ;乘2,总共是乘了10
       RET
;------------------;
;==================================SORT DECIMAL NUMBERS 十进制数排序
 
COMP:
       PUSH      AX
       PUSH      BX
       PUSH      CX
       PUSH      DI
 
       ;MOV     AX,DATA
       ;MOV     DS,AX
       MOV     DI,DEC_NUM
 
       MOV     CX,WORD [DI]  ;计数
       DEC     CX
 
C1:    MOV     DX,CX
       MOV      BH,0
C2:    ADD       DI,2
       MOV      AX,[DI]
       CMP      AX,[DI+2]
       JLE  CONT1
       XCHG    AX,[DI+2]
       MOV      [DI],AX
       MOV      BH,1
CONT1:  LOOP     C2
       CMP      BH,0
       JE   STOP
 
        MOV     CX,DX
 
       MOV     DI,DEC_NUM
       LOOP     C1
 
STOP:  MOV     BX,DEC_NUM
       MOV      AX,[BX+8]
       POP       DI
       POP       CX
       POP       BX
       POP       AX
       RET
;-------------------------------------------------
;==================================DECIMAL NUMBER TO ASCII转换成ASCII码
DEC2ASC:
        PUSH     BX   ;保护
        PUSH     CX
 
        MOV      DI,OUT_STR   ;将处理后的放入DI
        MOV    DX,DI
 
        CMP     AX,0              
        JNE     NON_0
 
ZERO:   MOV     BYTE  [DI],'0' ;如果是0
        MOV     BYTE  [DI+1],'$'
        JMP     OUT_ASC
 
NON_0:  TEST    AX,8000H ;不是0
        JZ      PTIVE    ;判断符号,是正号跳转
NTIVE:  NEG     AX        ;取反
        MOV     BYTE  [DI],'-'  ;置负号
        JMP     CON
 
PTIVE:  MOV     BYTE  [DI],'+'  ;置正号
 
CON:    INC     DI
 
        MOV     DX,0
        MOV     CX,10000   ;万位
        IDIV    CX         ;带符号数除法
        ADD     AL,30H     ;加30H变成ASCII
        MOV      BYTE  [DI],AL
 
       MOV      AX,DX
       MOV      DX,0
       MOV      CX,1000   ;千位
        IDIV    CX   
       ADD       AL,30H   ;加30H变成ASCII
        MOV     BYTE  [DI+1],AL   ;写入
 
       MOV      AX,DX                 
       MOV      CL,100   ;百位
        IDIV    CL
       ADD       AL,30H
        MOV     BYTE  [DI+2],AL
 
       MOV      AL,AH
       MOV      AH,0
       MOV      CL,10 ;十位
        IDIV    CL
       ADD       AL,30H
        MOV     BYTE  [DI+3],AL
     
       ADD       AH,30H
        MOV     BYTE  [DI+4],AH  ;个位
       
OUT_SIG:MOV     DI,OUT_STR
        MOV     DL,BYTE  [DI]
        CALL	PutChar
 
        INC     DI
        MOV     DX,DI
 
B2:     CMP     BYTE  [DI],'0'
        JNE     OUT_ASC
        INC     DI
        INC     DX
        JMP     B2
 
OUT_ASC:
		;MOV     AH,09H                  ;打印
        ;INT   21H
		PUSH SI
		MOV SI,DX
		CALL PutStr
		POP SI
		
        POP  CX
        POP  BX
        RET
;==================================
;------------------;
;入口参数SI
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
        ADD SI,2                    ;指向字符串的首地址
        XOR   CH, CH                ;CH作为字符串中的字符计数器，清零
    .Lab1:
        CALL  GetChar               ;读取一个字符
        ;OR    AL, AL                ;如为功能键，直接丢弃//@1
        ;JZ    SHORT  .Lab1
        CMP   AL, Enter             ;如为回车键，表示输入字符串结束
        JZ    SHORT  .Lab5          ;转输入结束
        CMP   AL,  Backspace        ;如为退格键
        JZ    SHORT  .Lab4          ;转退格处理
        ;CMP   AL, Space             ;如为其他不可显示字符，丢弃//@2
        ;JB    SHORT  .Lab1
        ;
		cmp   al, ' '
		je    .myLab
		cmp   al, '-'
		je	  .myLab
        cmp   al, '0'
        jb    short  .Lab1          ;小于数字符，丢弃
        cmp   al, '9'
        ja    short  .Lab1          ;大于数字符，丢弃
        ;
	.myLab:
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
		INC   BYTE [DEC_STR+1]
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
		DEC   BYTE [DEC_STR+1]
        JMP   SHORT  .Lab1          ;继续接受字符
        ;
    .Lab5:
        MOV    [SI], AL             ;保存最后的回车符
    .Lab6:
        POP   SI
        RET
;-------------------------------
;-------------------------------
;------------------------------------------
;times 510-($-$$) db 0
db 55h,0aah
end_of_text 