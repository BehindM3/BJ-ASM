; ==============================
; lib.asm
; Funciones externas
; ==============================

.model small
.stack 100h

CR              equ 0dh
LF              equ 0ah

.data
    msgMenu db CR, LF, '=== MENU 21 BLACKJACK ===', CR, LF
            db '1) Jugar', CR, LF
            db '2) Salir', CR, LF
            db 'Opcion: $'

    msgExit     db CR, LF, 'GRACIAS POR JUGAR - 21 BLACKJACK', CR, LF, 24h
    msgInvalid  db CR, LF, 'OPCION INVALIDA', CR, LF, 24h

    msgWin      db CR, LF, '********** GANASTE LA MANO **********', CR, LF, '$'
    msgLose     db CR, LF, '********** PERDISTE LA MANO **********', CR, LF, '$'
    msgDraw     db CR, LF, '**********  EMPATE **********', CR, LF, '$'


.code 

public ShowMenu
public PrintString
public ReadKey
public InstallInt60 
public ClearScreen
public DelayShort


extrn StartGame:proc

; ==============================
;       Print String
; E :   DX = offset del string
; D :   AX
; ==============================

PrintString proc

    mov ah, 09h
    int 21h
    ret

PrintString endp

; ==============================
;       Read Key
; S :   AL = Tecla leida
; D :   AH 
; ==============================
ReadKey proc

    mov ah, 01h
    int 21h
    ret

ReadKey endp

; ==============================
;       Show Menu
; Muestra el menu y actua segun la opcion
; ==============================
ShowMenu proc

    menu_loop:

        call ClearScreen

        ;Mostramos el menu
        mov dx, offset msgMenu
        call PrintString

        ;Leemos la opcion
        call ReadKey

        cmp al, '1'
        je opcion_play

        cmp al, '2'
        je opcion_exit

        mov dx, offset msgInvalid
        call PrintString
        jmp menu_loop

        opcion_play:
            call StartGame
            jmp menu_loop
        
        opcion_exit:
            call ClearScreen
            mov dx, offset msgExit
            call PrintString
            ret

ShowMenu endp

; ==============================
;       Manejo del INT 60h
; AH = 0 -> GANASTE
; AH = 1 -> PERDISTE
; AH = 2 -> EMPATE
; ==============================
MyInt60Handler proc far

    push ax
    push bx
    push cx
    push dx
    push ds
    push es

    ;Guardamos el codigo que viene por AH
    mov bl, ah

    ; Colocamos DS apuntando al segmente de datos
    mov ax, seg msgWin
    mov ds, ax

    cmp bl, 0
    je MI60_win

    cmp bl, 1
    je MI60_lose

    cmp bl, 2
    je MI60_draw

    jmp MI60_end

    MI60_win:
        mov dx, offset msgWin
        jmp MI60_print

    MI60_lose:
        mov dx, offset msgLose
        jmp MI60_print
    
    MI60_draw:
        mov dx, offset msgDraw

    MI60_print:
        mov ah, 09h
        int 21h
    
    MI60_end:
        pop es
        pop ds
        pop dx
        pop cx
        pop bx
        pop ax
        iret

MyInt60Handler endp

; ==========================================================
;           InstallInt60: 
; Instala nuestro handler en el vector de interrupcion 60h
; ==========================================================
InstallInt60 proc

    push ds
    push dx
    
    ; DS debe contener el CS
    push cs
    pop ds

    mov dx, offset MyInt60Handler
    mov ax, 2560h
    int 21h

    pop dx
    pop ds
    
    ret

InstallInt60 endp

; =====================================
;               Clear Screen
; Borra toda la pantalla con INT 10h
; =====================================
ClearScreen proc

    push ax
    push bx
    push cx
    push dx

    ; Subimos la pagina agregando espacios
    mov ax, 0600h       ; AH = 06 (scroll up), AL = 00 (borra todo)
    mov bh, 07h 
    mov cx, 0000h       ; Esquina sup-izq
    mov dx, 184Fh       ; Esquina inf-der
    int 10h

    ; Colocamos el cursor en el 0,0
    mov ah, 02h
    mov bh, 0
    mov dh, 0
    mov dl, 0
    int 10h

    pop dx
    pop cx
    pop bx
    pop ax
    ret

ClearScreen endp

; =========================================
;           DelayShort
; Pequeña pausa para los turnos del dealer
; =========================================
DelayShort proc
    push ax
    push cx
    push dx

    mov cx, 9000       ; Valor del delay

    DS_outer:
        mov dx, 8000

    DS_inner:
        dec dx
        jnz DS_inner

        loop DS_outer

    pop dx
    pop cx
    pop ax
    ret
DelayShort endp

end