; ==============================
; lib.asm
; Funciones externas
; ==============================

.model small
.stack 100h

CR              equ 0dh
LF              equ 0ah

.data

.data

; Titulo principal
msgTitle1 db '==============================', CR, LF, '$'
msgTitle2 db '         21 BLACKJACK        ', CR, LF, '$'
msgTitle3 db '==============================', CR, LF, CR, LF, '$'

; Menu principal
msgMenu db '   MENU PRINCIPAL', CR, LF
        db '   --------------', CR, LF, CR, LF
        db '   [1] Jugar una mano', CR, LF
        db '   [2] Ver reglas', CR, LF
        db '   [3] Salir', CR, LF, CR, LF, '$'

; Prompt de opcion
msgPrompt db 'Opcion: $'

; Mensajes generales
msgExit    db CR, LF, 'GRACIAS POR JUGAR - 21 BLACKJACK', CR, LF, 24h
msgInvalid db CR, LF, 'OPCION INVALIDA', CR, LF, 24h

; Mensajes de resultado (usados por INT 60h)
msgWin  db CR, LF, '********** GANASTE LA MANO **********', CR, LF, '$'
msgLose db CR, LF, '********** PERDISTE LA MANO **********', CR, LF, '$'
msgDraw db CR, LF, '**********  EMPATE **********', CR, LF, '$'

; Mensajes de reglas
msgRulesTitle db CR, LF, '=== Reglas del Blackjack ===', CR, LF, '$'
msgRules1     db '1. El jugador recibe dos cartas al inicio.', CR, LF, '$'
msgRules2     db '2. Las figuras valen 10 puntos.', CR, LF, '$'
msgRules3     db '3. El As vale 1 u 11 segun convenga.', CR, LF, '$'
msgRules4     db '4. El jugador gana automaticamente si obtiene 21 con sus dos primeras cartas.', CR, LF, '$'
msgRules5     db '5. El dealer pide cartas hasta tener 17 o mas.', CR, LF, '$'
msgRules6     db '6. Si ambos empatan en puntaje, es un PUSH.', CR, LF, '$'
msgRulesBack  db CR, LF, '(Presione una tecla para volver al menu...)', CR, LF, '$'

; Estadisticas
msgStatsTitle  db '   Estadisticas', CR, LF
               db '   ------------', CR, LF, '$'
msgStatsWins   db '   Ganadas : ', '$'
msgStatsLosses db '   Perdidas: ', '$'
msgStatsDraws  db '   Empates : ', '$'

; Contadores de estadisticas
winsCount   db 0
lossCount   db 0
drawCount   db 0


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

; Imprime CR LF
NewLine proc
    mov dl, CR
    mov ah, 02h
    int 21h
    mov dl, LF
    mov ah, 02h
    int 21h
    ret
NewLine endp
; Imprime un numero en AX (0..99) en decimal
PrintNumber8 proc
    push ax
    push bx
    push dx

    mov bx, 10
    xor dx, dx
    div bx          ; AX / 10 -> AL = decenas, DL = unidades

    mov bl, al      ; decenas
    mov bh, dl      ; unidades

    cmp bl, 0
    je PN8_only_units

    ; decenas
    mov dl, bl
    add dl, '0'
    mov ah, 02h
    int 21h

PN8_only_units:
    mov dl, bh
    add dl, '0'
    mov ah, 02h
    int 21h

    pop dx
    pop bx
    pop ax
    ret
PrintNumber8 endp

ShowStats proc
    push ax
    push dx

    ; Titulo
    mov dx, offset msgStatsTitle
    call PrintString

    ; Ganadas
    mov dx, offset msgStatsWins
    call PrintString
    mov al, winsCount
    xor ah, ah
    call PrintNumber8
    call NewLine

    ; Perdidas
    mov dx, offset msgStatsLosses
    call PrintString
    mov al, lossCount
    xor ah, ah
    call PrintNumber8
    call NewLine

    ; Empates
    mov dx, offset msgStatsDraws
    call PrintString
    mov al, drawCount
    xor ah, ah
    call PrintNumber8
    call NewLine

    pop dx
    pop ax
    ret
ShowStats endp



; ==============================
;       Show Menu
; Muestra el menu y actua segun la opcion
; ==============================
ShowMenu proc

menu_loop:

        call ClearScreen

        ; Titulo
        mov dx, offset msgTitle1
        call PrintString
        mov dx, offset msgTitle2
        call PrintString
        mov dx, offset msgTitle3
        call PrintString

        ; Menu principal
        mov dx, offset msgMenu
        call PrintString

        ; Estadisticas
        call ShowStats

        ; Prompt de opcion al final de todo
        mov dx, offset msgPrompt
        call PrintString

        ; Leer opcion
        call ReadKey

        cmp al, '1'
        je opcion_play

        cmp al, '2'
        je opcion_rules

        cmp al, '3'
        je opcion_exit

        mov dx, offset msgInvalid
        call PrintString
        jmp menu_loop


        opcion_play:
            call StartGame
            jmp menu_loop
        
        opcion_rules:
        call ClearScreen

        mov dx, offset msgRulesTitle
        call PrintString

        mov dx, offset msgRules1
        call PrintString

        mov dx, offset msgRules2
        call PrintString

        mov dx, offset msgRules3
        call PrintString

        mov dx, offset msgRules4
        call PrintString

        mov dx, offset msgRules5
        call PrintString

        mov dx, offset msgRules6
        call PrintString

        mov dx, offset msgRulesBack
        call PrintString

        call ReadKey
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
        inc winsCount
        mov dx, offset msgWin
        jmp MI60_print

    MI60_lose:
        inc lossCount
        mov dx, offset msgLose
        jmp MI60_print

    MI60_draw:
        inc drawCount
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

    mov cx, 9000       

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