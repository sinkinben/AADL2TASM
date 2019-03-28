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
MOV  SI,line
CALL PutStr

MOV  SI,list
CALL PutStr
MOV  SI,list1
CALL PutStr
MOV  SI,list2
CALL PutStr
MOV  SI,list3
CALL PutStr
MOV  SI,list4
CALL PutStr

MOV SI,list5
CALL PutStr

MOV SI,list6
CALL PutStr

MOV SI,list7
CALL PutStr

MOV SI,list8
CALL PutStr

MOV SI,list9
CALL PutStr

MOV SI,list10
CALL PutStr

MOV SI,list11
CALL PutStr

MOV SI,list12
CALL PutStr

MOV SI,list13
CALL PutStr

MOV  SI,line
CALL PutStr
RETF
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
;times 510-($-$$) db 0
db 55h,0aah
end_of_text 