[org 0x0100]
cpu 8086
jmp start

str   : db "Hi, There is a rare, quiet dignity in stripping a system down until nothing remains between your intent and the cold pulse of copper. Modern life runs on layers of polite illusion—glossy interfaces and forgiving compilers that quietly pardon our shortcuts and patch our oversights. But past midnight, beneath the harsh hum of a terminal, the abstractions dissolve. A processor never bargains with sentiment; it demands that every register account for its contents, every jump respect its boundary, and every cycle justify its brief existence. Working at the bedrock of logic means accepting that clarity cannot be faked. It asks you to trade the comfort of easy answers for the fierce thrill of knowing precisely how raw electricity turns into thought. When the screen finally blinks awake—not by accident, but through the patient, stubborn alignment of every single byte—the stillness feels earned. You haven't merely written code; you have coaxed order.", 0
title : db "My Document" , 0
search : db "a", 0
statusBar : db "Total Matches Found :          | Viewport Status : ACTIVE", 0

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

tokenLen:
    push bp
    mov bp,sp
    push ax
    push di


    mov di, [bp+4] ; load the string starting address
    mov ah, 32
    xor cx, cx

    loopForToken:
        mov byte al , [di]
        cmp al,ah
        jz exitTokenLoop
        inc di
        inc cx
        jmp loopForToken
    exitTokenLoop:

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
    push dx
    push di
    push si

    mov ax, 0xB800
    mov es,ax
    mov di, 660 ; starts writing from here
    mov bx, 0   ; counts from 0 to 60

    mov si, str
    push si
    call strLen
    cmp cx, 1037 ; max printable length
    jbe skipClamp
    mov cx, 1037
    skipClamp:
    
    mov ah, 0x07

    loopPrintText:
    push cx             ; save cx
    push si             ; param for tokenLen
    call tokenLen       ; get token length in cx

    ; Test if this word will go out of bounds and wrap around
    mov dx, bx
    add dx, cx
    cmp dx, 61
    jbe printNormal 
    ; Word doesnt fit
    mov dx, 61
    sub dx, bx          ; DX = remaining columns to reach column 61
    shl dx, 1           ; convert column to actual bytes
    add dx, 38          ; Add outer border gap to start of next line
    add di, dx         ;DI  now lands at Column 10 of the next row
    mov bx, 0            ;Reset column counter

    printNormal:
    lodsb               ; load character
    stosw               ;[ES:DI] = character + attribute
    inc bx              ; increment column count

    ; if a single word is > 61 check
    cmp bx, 61
    jb skipHardWrap
    add di, 38
    mov bx, 0
    skipHardWrap:
    pop cx              ; revive cx to continue looping
    cmp di,3376         ; hard check on di
    ja endPrint
    loop loopPrintText
    endPrint:

    pop si
    pop di
    pop dx
    pop cx
    pop bx
    pop ax
    pop bp

ret
     
scroll_window_up:
    push bp
    mov bp,sp
    push ax
    push bx
    push cx
    push di
    push si
    push ds

    mov ax, 0xB800
    mov es,ax
    mov ds,ax
    mov ax, [bp+12]; load top
    mov bl, 160;
    mul bl
    mov di, ax
    mov ax, [bp+8] ; load left
    shl ax, 1
    add di,ax
    add di, 160 ; move to next line
    add di, 4  ; inner margins
   
    mov ax, [bp+10] ; load bottom
    mul bl
    sub ax, 4
    mov cx, ax

    mov ax, [bp+4] ; load N
    mov bl, 160
    mul bl
    mov si, di
    add si, ax
    mov bl, 0   ; counts from 0 to 60


    mov ah, 0x07
    loopScroll:
    cmp si, cx
    jae quitLoopScroll
    movsw
    inc bl
    cmp bl, 61
    jnz skipScrRowShift
    add di, 38 ; 2 inner right cols + 8 outer right cols + 8 outer left on down row + 2 inner left on down row
    add si, 38
    mov bl, 0
    skipScrRowShift:
    jmp loopScroll
    quitLoopScroll:

    mov bl, 0
    cleanUpLoop:
    cmp di, cx
    jae quitCleanUp
    cmp bl,61
    jnz skipCleanUpRowShift
    mov bl, 0
    add di, 38
    cmp di, cx
    jae quitCleanUp
    skipCleanUpRowShift:
    mov word [es:di], 0x0720
    add di, 2
    inc bl
    jmp cleanUpLoop
    quitCleanUp:

    pop ds
    pop si
    pop di
    pop cx
    pop bx
    pop ax
    pop bp

ret 10

matchStrings:
    push bp
    mov bp,sp
    push ax
    push cx
    push si
    push di
    
    mov ax,0xB800
    mov es, ax
    mov di,[bp+4]  ; load position from where to start checking
    mov si, [bp+6] ; load starting address of search string
    push si
    call strLen

    mov ah, 0x07
    mov bx, 1      ; Return Value, 1 By Default
    matchLoop:
    lodsb ; load char of string 
    scasw ; compares it with current memory column
    jz equal
    mov cx, 1 ; Break Loop If not equal
    mov bx, 0 ; Set the return Value to 0
    equal:
    loop matchLoop

    cmp bx,0
    jz skipHighlight
    mov ax,[bp+8]   ; load attribute byte into AX
    mov si, [bp+6]  ; starting position of search
    mov di, [bp+4]  ; starting position of display memory read 
    push si
    call strLen
    itrHighlight:
        mov al, [es:di] ; move the character from display memory, attribute already loaded in ah
        stosw           ; store the char with the new attribute
    loop itrHighlight   ; iterate until String length

    skipHighlight:
    pop di
    pop si
    pop cx
    pop ax
    pop bp
ret 6

find_and_highlight:
    push bp
    mov bp,sp
    sub sp, 2 ; Local Variable for Number of Matches
    push ax
    push bx
    push cx
    push di
    push si

    mov cx, [bp+4] ; load attribute
    mov si, [bp+6] ; load starting address 
    mov ax, 0xB800
    mov es, ax
    mov di, 660    ; starting of the text

    mov word [bp-2], 0
    traverseMemory:
    push cx
    push si
    push di
    call matchStrings
    cmp bx, 0
    jz notFound
    inc word [bp-2]
    notFound:
    add di, 2
    cmp di, 3376
    jb traverseMemory

    mov di, statusBar
    push di ; push address
    call strLen
    
    ; Pushing params for print until
    mov di, statusBar
    push di ; push address
    mov di, 23
    push di ; push row
    mov di, 10
    push di ; push column
    push cx
    call printUntil

    mov di, 3750 ; where column is to be printed
    printCounter:
    mov ax, [bp-2]
    mov bl, 10
    div bl
    cmp al, 0
    jz quitPrint
    mov bh, 00000110b
    mov bl, ah
    add bl, 48
    mov [es:di], bx
    sub di, 2
    xor ah, ah
    mov [bp-2], ax
    jmp printCounter
    quitPrint:
    mov bh, 00000110b
    mov bl, ah
    add bl, 48
    mov [es:di], bx

    pop si
    pop di
    pop cx
    pop bx
    pop ax
    add sp, 2
    pop bp

ret 4

start:
    call clrScr
    call drawBorder
    call printBordered

    mov ax, 3 ; top                         [bp+12]
    push ax 
    mov ax,21 ; bott                        [bp+10]
    push ax
    mov ax,8 ; left                         [bp+8]
    push ax
    mov ax, 72; right                       [bp+6]
    push ax
    mov ax, 5 ; n number of lines to scroll [bp+4]
    push ax
    call scroll_window_up

    mov ax, search
    push ax         ; pass the string 
    mov ax, 0xCE00
    push ax         ; pass the attribute
    call find_and_highlight

    mov ax, 0x4c00
    int 21h
