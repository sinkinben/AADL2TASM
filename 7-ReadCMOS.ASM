    ;演示程序（工作程序）dp81.asm
    ;功能显示当前时间（采用虚拟机可加载格式）
        section   text
        bits   16
    ;可加载格式的头部
;
    Signature     db   "SIN "       ;签名信息
    Version       dw   1            ;格式版本
    Length        dw   end_of_text  ;工作程序长度
    Entry         dw   Begin        ;工作程序入口点的偏移
    ExpectedSeg   dw   0088H        ;工作程序期望的内存区域起始段值
    Reserved      dd   0            ;保留
;
    ;
    Begin:
        PUSH  CS
        POP   DS                    ;数据段与代码段相同
    NEXT:
        MOV   AL, 2                 ;分单元地址
        OUT   70H, AL               ;准备读取分单元
        IN    AL, 71H               ;读分值BCD码
        MOV   [minute], AL          ;保存之
        ;
        MOV   AL, 0                 ;秒单元地址
        OUT   70H, AL               ;准备读取秒单元
        IN    AL, 71H               ;读秒值BCD码
        MOV   [second], AL          ;保存之
        ;
		MOV	  AL, 4
		OUT   70H, AL
		IN    AL, 71H
		MOV   [hour], AL
		;
		
		MOV	  AL, 09H
		OUT   70H, AL
		IN    AL, 71H
		MOV   [year], AL
		;
		
		MOV	  AL, 08H
		OUT   70H, AL
		IN    AL, 71H
		MOV   [month], AL
		;
		MOV	  AL, 07H
		OUT   70H, AL
		IN    AL, 71H
		MOV   [day], AL
		;
		MOV AL, [year]
		CALL EchoBCD
		MOV AL,'/'
		CALL PutChar
		MOV AL,[month]
		CALL EchoBCD
		MOV AL,'/'
		CALL PutChar
		MOV AL,[day]
		CALL EchoBCD
		MOV AL,' ' 
		CALL PutChar
		
		
		MOV   AL,[hour]
		CALL  EchoBCD
		MOV   AL, ':'
		CALL  PutChar
        MOV   AL, [minute]
        CALL  EchoBCD               ;显示时钟的分值
        MOV   AL, ':'
        CALL  PutChar               ;显示间隔符
        MOV   AL, [second]
        CALL  EchoBCD               ;显示时钟的秒值
        MOV   AL, 0DH               ;形成回车换行效果
        CALL  PutChar
        MOV   AL, 0AH
        CALL  PutChar
        ;
        MOV   AH, 0                 ;等待并接受用户按键
        INT   16H
        CMP   AL, 0DH               ;如果按回车键，结束
        JNZ   NEXT                  ;否则，再次显示当前时间
        ;
        RETF                        ;结束（返回到加载器）
    ;
    EchoBCD:                        ;显示2位BCD码
        PUSH  AX
        SHR   AL, 4                 ;把高位BCD码转成ASCII码
        ADD   AL, '0'
        CALL  PutChar               ;显示之
        POP   AX
        AND   AL, 0FH               ;把低位BCD码转成ASCII码
        ADD   AL, '0'
        CALL  PutChar               ;显示之
        RET
   PutChar:                         ;TTY方式显示一个字符
        MOV   BH, 0
        MOV   AH, 14
        INT   10H
        RET
        ;
		;*********************   
		; 子程序：显示字符   
		; 入口参数：DS:DX=串首址   
		; 返回值：无   
		;*********************   
	PutStr:   
		push ax   
        mov ah,09h   
        int 21h   
        pop ax   
        ret  
    second   DB   0                 ;秒BCD码保存单元
    minute   DB   0                 ;分BCD码保存单元
	hour     DB   0
	year db 0
	month db 0
	day db 0
    end_of_text:                    ;结束位置
