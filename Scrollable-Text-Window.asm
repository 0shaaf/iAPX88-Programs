[org 0x0100]
cpu 8086
jmp start

str   : db "Hello world yuhoo!!", 0
title : db "My Document" , 0

clrScr:
    push bp
    mov bp,sp
    push ax
    push cx
    push di 

    mov ax, 0xB800
    mov es, ax
    mov di, 0
    mov ah, 0x07
    mov al, 32
    mov cx, 2000
    cld
    rep stosw

    pop di
    pop cx
    pop ax
    pop bp
ret

strLen:
    push bp
    mov bp,sp
    push ax
    push di


    mov di, [bp+4] ; load the string starting address
    mov ah, 0
    xor cx, cx

    loopForLength:
        mov byte al , [di]
        cmp al,ah
        jz exitLengthCount
        inc di
        inc cx
        jmp loopForLength
    exitLengthCount:

    pop di
    pop ax
    pop bp
ret 2

printUntil:
    push bp
    mov bp,sp
    push ax
    push bx
    push cx
    push di
    push si

    mov si, [bp+10]
    ;call strLen ; CX has the string length now
    mov cx, [bp+4] ; load printable length
    ;call clrScr ; clear the screen

    mov ax, 0xB800
    mov es, ax
    
    mov ax, [bp+8]     ; load row
    mov bl, 160 
    mul bl             ; multiply by 160
    mov bx , [bp+6]    ; load column
    shl bx , 1         ; 2x to make proper offset
    add ax, bx         ; Add Column Offset
    mov di, ax
    

    cld
    mov ah,0x07
    innerPrintLoop:
        lodsb
        stosw
    loop innerPrintLoop
    
    pop si
    pop di
    pop cx
    pop bx
    pop ax
    pop bp

ret 8

drawBorder:
    push bp
    mov bp,sp
    push ax
    push bx
    push cx
    push si
    push di

    ;mov ah, 0x07
    mov ah, 00001110b
    mov al, 0xCD
    
    cld
    mov di , 496; [3*160 + 8*2]
    mov cx ,64;
    rep stosw

    mov di , 3376; [21*160 + 8*2]
    mov cx, 64
    rep stosw 

    mov al, 0xBA
    mov di, 496
    verticalMargins:
    cmp di, 3396
    jae quitVertical
    mov [es:di], ax
    add di, 128
    mov [es:di], ax
    sub di, 128
    add di, 160
    jmp verticalMargins
    quitVertical:

    mov al, 0xC9
    mov [es:496], ax
    mov al, 0xBB
    mov [es:624], ax
    mov al, 0xC8
    mov [es:3376], ax
    mov al, 0xBC
    mov [es:3504], ax

    ; Centering the title and printing using my own utility
    mov bx , title
    push bx
    call strLen
    mov bx, title
    push bx ; Pass title address
    mov bx, 1
    push bx  ; pass row
    cmp cx, 32
    jbe noChange
    mov cx, 32
    noChange:
    mov bx ,128
    sub bx, cx
    shr bx, 1
    add bx, 16
    shr bx, 1
    mov dx, cx
    shr dx,1
    shr dx,1
    sub bx, dx
    push bx ; pass column
    push cx ; pass title length
    call printUntil

    mov ah, 00001101b
    mov al, 0xCD
    mov di, bx  ; Raw Column Count
    shl di, 1   ; Turn into offset
    add di, 320 ; Adjust the Rows manually because BX only holds the column offset, not full Rows+Column offset
    rep stosw

    pop di
    pop si
    pop cx
    pop bx
    pop ax
    pop bp
ret

printBordered:
    push bp
    mov bp,sp
    push ax
    push bx
    push cx
    push di
    push si

    mov bx, 496; priniting baseline offset
    mov ax, 0xB800
    mov es,ax
    mov di, 0

    mov si, [str]
    call strLen
    cmp cx, 
    pop si
    pop di
    pop cx
    pop bx
    pop ax
    pop bp

ret 8
     
start:
    call clrScr
    mov [es:3396], ax
    mov ax, str
    push ax    ; address [bp+10]
    mov ax, 4  ; row [bp+8]
    push ax
    mov ax, 10 ; column [bp+6]
    push ax
    mov ax, 8  ; How many Characters to print [bp+4]
    push ax    ; 
    call printUntil

    call drawBorder

    mov ax ,0x4c00
    int 21h
