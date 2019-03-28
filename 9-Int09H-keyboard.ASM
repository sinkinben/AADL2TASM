    ;演示程序（工作程序）dp84.asm
    ;演示键盘中断处理程序（采用虚拟机可加载格式）
    PORT_KEY_DAT   EQU   0x60
    PORT_KEY_STA   EQU   0x64
    ;
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
    Begin:
		MOV AX,CS
		MOV DS,AX	;DS=CS
		;
		MOV SI,tips1
		CALL PutStr
		
		MOV SI,tips2
		CALL PutStr
		
		;
		MOV SI,09H*4
		MOV AX,0	
		MOV ES,AX	;ES=0
		;
		MOV AX,[ES:SI]		;原中断偏移
		MOV [old09h], AX
		MOV AX,[ES:SI+2]	;原中断段值
		MOV [old09h+2], AX
		
		
        MOV   AX, 0                     ;准备设置中断向量
        MOV   DS, AX
        CLI
        MOV   WORD [9*4], int09h_handler
        MOV   [9*4+2], CS               ;启用新的键盘中断处理程序
        STI
        ;
    Next:                               ;演示程序的演示处理
        MOV   AH, 0                     ;调用键盘I/O程序
        INT   16H                       ;获取用户按键
        ;
        MOV   AH, 14                    ;显示取得的字符（按键）
        INT   10H
        ;
		;CMP   AL, ' '					
		;JZ    restore_09H_handler
		;
        CMP   AL, 0DH                   ;回车键吗？
        JNZ   Next                      ;否则继续
		

        ;
        MOV   AH, 14                    ;为了演示效果
        MOV   AL, 0AH                   ;显示一个换行
        INT   10H
        ;
        ;RETF                            ;结束（返回到加载器）
	restore_09H_handler:
		MOV AX,0
		MOV ES,AX
		MOV SI, 09H*4
		MOV EAX, [CS:old09h]
		MOV [ES:SI], EAX
		RETF
    ;-----------------------------------
    int09h_handler:                     ;新的9号键盘中断处理程序
        PUSHA                           ;保护通用寄存器
        ;
        MOV   AL, 0ADH
        OUT   PORT_KEY_STA, AL          ;禁止键盘发送数据到接口
        ;
        IN    AL, PORT_KEY_DAT          ;从键盘接口读取按键扫描码
        ;
        STI                             ;开中断
        CALL  Int09hfun                 ;完成相关功能
        ;
        CLI                             ;关中断
        MOV   AL, 0AEH
        OUT   PORT_KEY_STA, AL          ;允许键盘发送数据到接口
        ;
        MOV   AL, 20H                   ;通知中断控制器8259A
        OUT   20H, AL                   ;当前中断处理已经结束
        ;
        POPA                            ;恢复通用寄存器
        ;
        IRET                            ;中断返回
    ;-----------------------------------
    Int09hfun:                          ;演示9H号中断处理程序的具体功能
        CMP   AL, 1CH                   ;判断回车键的扫描码
        JNZ   .LAB1                     ;非回车键，转
        MOV   AH, AL                    ;回车键，保存扫描码
        MOV   AL, 0DH                   ;回车键ASCII码
        JMP   SHORT .LAB2
    .LAB1:                              ;仅识别处理QWERTYUIOP十个键
        CMP   AL, 10H                   ;判断字母Q键扫描码
        JB    .LAB3                     ;低于，则直接丢弃
        CMP   AL, 19H                   ;判断字母P键扫描码
        JA    .LAB3                     ;高于，则直接丢弃
        MOV   AH, AL                    ;保存扫描码
        ADD   AL, 20H                   ;按演示方案转成对应的ASCII码
    .LAB2:
        CALL  Enqueue                   ;保存到键盘缓冲区
    .LAB3:
        RET                             ;返回
    ;-----------------------------------
    Enqueue:                            ;把扫描码和ASCII码存入键盘缓冲区
        PUSH  DS                        ;保护DS
        MOV   BX, 40H
        MOV   DS, BX                    ;DS=0040H
        MOV   BX, [001CH]               ;取队列的尾指针
        MOV   SI, BX                    ;SI=队列尾指针
        ADD   SI, 2                     ;SI=下一个可能位置
        CMP   SI, 003EH                 ;越出缓冲区界吗？
        JB    .LAB1                     ;没有，转
        MOV   SI, 001EH                 ;是的，循环到缓冲区头部
    .LAB1:
        CMP   SI, [001AH]               ;与队列头指针比较
        JZ    .LAB2                     ;相等表示，队列已经满
        MOV   [BX], AX                  ;把扫描码和ASCII码填入队列
        MOV    [001CH], SI              ;保存队列尾指针
    .LAB2:
        POP   DS                        ;恢复DS
        RET                             ;返回
	;-----------------------------------------------
	old09h   DD   0                 ;用于保存原09H号中断向量
	tips1	DB "Here is the new INT 09H keyboard handler",0ah,0dh,0
	tips2	DB "Q=0 W=2 ... P=9",0ah,0dh,0
	;-----------------------------------------------
	;------------------------------------------------
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
    end_of_text:                        ;结束位置
