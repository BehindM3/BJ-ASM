; ==============================
; game.asm
; Logica base del BJ
; ==============================

.model small
.stack 100h

CR              equ 0dh
LF              equ 0ah
MAX_CARDS       equ 12


.data

    msgStart    db CR, LF, 'Iniciando partida...', CR, LF, '$'
    msgPause    db CR, LF, '(Presione una tecla para volver al menu...)', CR, LF, '$'

    msgPlayer   db 'Jugador: ', '$'
    msgDealer   db CR, LF, 'Dealer: ', CR, LF, '$'

    msgPlayerSc     db CR, LF, 'Puntaje jugador: ', '$'
    msgDealerSc     db CR, LF, 'Puntaje dealer : ', '$'
    msgDealerUp     db CR, LF, 'Dealer: ', '$'
    msgDealerHidden db ' [ ? ] (+ Cartas ocultas)', CR, LF, '$'

    msgTurnPlayer db CR, LF, '--- Turno del jugador ---', CR, LF, '$'
    msgTurnDealer db CR, LF, '--- Turno del dealer  ---', CR, LF, '$'

    msgAskAction  db CR, LF, 'H) Pedir carta [HIT]  S) Plantarse [STAND] ', CR, LF, '$'
    msgInvalidAct db CR, LF, 'Opcion inválida. Intente de nuevo.', CR, LF, '$'

    msgPlayerBust db CR, LF, 'Te pasaste de 21. Perdiste.', CR, LF, '$'
    msgDealerBust db CR, LF, 'El dealer se paso de 21. Ganaste!', CR, LF, '$'

    msgPlayerWins db CR, LF, 'Ganaste la mano!', CR, LF, '$'
    msgDealerWins db CR, LF, 'El dealer gana la mano.', CR, LF, '$'
    msgPush       db CR, LF, 'Empate [PUSH].', CR, LF, '$'

    ; Mazo y manos
    deck            db 52 dup(?)
    playerHand      db MAX_CARDS dup(0FFh)
    dealerHand      db MAX_CARDS dup(0FFh)
    playerCount     db 0
    dealerCount     db 0
    deckPos         db 0

    ; Score
    playerScore     dw 0
    dealerScore     dw 0

.code

    ;Reutilizamos las funciones declaradas en lib.asm
    extrn PrintString:proc
    extrn ReadKey:proc
    extrn ClearScreen:proc
    extrn DelayShort:proc


    ;hacemos visible y accesible StartGame al resto del programa
    public StartGame

    StartGame proc
        call ClearScreen

        ;Mensaje de inicio
        mov dx, offset msgStart
        call PrintString

        ;Inicializamos estado de juego
        call InitDeck
        call ShuffleDeck
        call ResetHand

        ;Reparto de cartas
        call dealCardToPlayer
        call dealCardToPlayer
        call dealCardToDealer
        call dealCardToDealer

        ; ===== TURNO DEL JUGADOR =====

        ;Mostrar mano del jugador
        mov dx, offset msgTurnPlayer
        call PrintString

        call PlayerTurn

        ; Si el player se pasa de 21
        mov ax, playerScore
        cmp ax, 21
        jg SG_end

        ; ===== TURNO DEL DEALER =====

        ;Mostrar mano del dealer
        mov dx, offset msgTurnDealer
        call PrintString

        call DealerTurn

        ; Si el dealer se pasa de 21
        mov ax, dealerScore
        cmp ax, 21
        jg SG_end

        ; ===== DECIDIMOS GANADOR =====

        call DecideWinner

        SG_end:
        
            ;Pausa final
            mov dx, offset msgPause
            call PrintString
            call ReadKey

            ret

    StartGame endp

    ; ==============================
    ;           Init Deck
    ; Llena 'deck' con valores del 0-51
    ; ==============================
    InitDeck proc

        mov si, offset deck
        mov cx, 52
        mov al, 0

        ID_loop:
            
            mov [si], al
            inc al
            inc si
            loop ID_loop

            mov byte ptr deckPos, 0
        ret

    InitDeck endp

    ; ==============================
    ;           Reset Hand
    ; Limpia la mano y los contadores
    ; ==============================
    ResetHand proc
        ; Jugador
        mov si, offset playerHand
        mov cx, MAX_CARDS
        mov al, 0FFh

        RH_Player:
            mov [si], al
            inc si
            loop RH_Player

            mov byte ptr playerCount, 0

        
        ;Dealer
        mov si, offset dealerHand
        mov cx, MAX_CARDS
        mov al, 0FFh

        RH_Dealer:
            mov [si], al
            inc si
            loop RH_Dealer

            mov byte ptr dealerCount, 0

        ret
    ResetHand endp

    ; ===============================================================
    ;           Deal Card To Player
    ; Toma la carta deck[deckPos] y la agrega a player[playerCount]
    ; ===============================================================
    DealCardToPlayer proc

        ;Primero chequeamos que el deckPos no sea mayor o igual a 52
        mov al, byte ptr deckPos
        cmp al, 52
        jae DCP_end

        ;Obtener una carta del mazo
        mov si, offset deck
        mov bl, byte ptr deckPos
        xor bh, bh
        add si, bx
        mov dl, [si]

        ;Guardamos la carta en la mano del jugador
        mov si, offset playerHand
        mov bl, byte ptr playerCount
        xor bh, bh
        add si, bx
        mov [si], dl


        inc byte ptr playerCount
        inc byte ptr deckPos

        DCP_end:
            ret

    DealCardToPlayer endp

    ; ===============================================================
    ;           Deal Card To Dealer
    ; Toma la carta deck[deckPos] y la agrega a dealer[dealerCount]
    ; ===============================================================
    DealCardToDealer proc
        ;Primero chequeamos que el deckPos no sea mayor o igual a 52
        mov al, byte ptr deckPos
        cmp al, 52
        jae DCD_end

        ;Obtener una carta del mazo
        mov si, offset deck
        mov bl, byte ptr deckPos
        xor bh, bh
        add si, bx
        mov dl, [si]

        ;Guardamos la carta en la mano del jugador
        mov si, offset dealerHand
        mov bl, byte ptr dealerCount
        xor bh, bh
        add si, bx
        mov [si], dl


        inc byte ptr dealerCount
        inc byte ptr deckPos

        DCD_end:
            ret

    DealCardToDealer endp

    ; =========================================
    ; GetRank:  rank = carta % 13
    ; E:        AL = carta (0, 1, 2, ..., 51)
    ; S:        AL = rank  (0, 1, 2, ..., 12)
    ; =========================================
    GetRank proc
        push bx

        mov ah, 0 
        mov bl, 13
        div bl
        mov al, ah
        
        pop bx
        ret

    GetRank endp

    ; =========================================
    ; GetSuit:  suit = carta / 13
    ; E:        AL = carta (0, 1, 2, ..., 51)
    ; S:        AL = suit  (0, 1, 2, 3)
    ; =========================================
    GetSuit proc

        push bx

        mov ah, 0
        mov bl, 13
        div bl
        
        pop bx

        ret

    GetSuit endp

    ; =========================================
    ;               Print Suit
    ; E:        AL = suit  (0, 1, 2, 3)
    ; =========================================
    PrintSuit proc

        cmp al, 0
        je suit_hearts
        
        cmp al, 1
        je suit_diamonds
        
        cmp al, 2
        je suit_clubs
        
        mov dl, 6           ; ♠
        je ps_print

        suit_hearts:
            mov dl, 3       ; ♥
            jmp ps_print

        suit_diamonds:
            mov dl, 4       ; ♦
            jmp ps_print

        suit_clubs:
            mov dl, 5       ; ♣

        ps_print:
            mov ah, 02h
            int 21h
            ret

    PrintSuit endp

    ; =========================================
    ;               Print Rank
    ; E:        AL = rank  (0=A, ..., 12=K)
    ; =========================================
    PrintRank proc

        ;Caso A
        cmp al, 0
        je pr_A

        ;Caso 10
        cmp al, 9
        je pr_10

        ; Casos J, Q, K
        cmp al, 10
        je pr_J
        cmp al, 11
        je pr_Q
        cmp al, 12
        je pr_K

        ;Resto de cartas por su valor
        mov bl, al
        add bl, '1'
        mov dl, bl
        jmp pr_print

        pr_A:
            mov dl, 'A'
            jmp pr_print

        pr_10:
            mov dl, '1'
            mov ah, 02h
            int 21h
            mov dl, '0'
            jmp pr_print
        
        pr_J:
            mov dl, 'J'
            jmp pr_print
        
        pr_Q:
            mov dl, 'Q'
            jmp pr_print

        pr_K:
            mov dl, 'K'
        
        pr_print:
            mov ah, 02h
            int 21h
            ret

    PrintRank endp

    CRLF proc 

    mov dl, 13 
    mov ah, 02h 
    int 21h 
    mov dl, 10 
    mov ah, 02h 
    int 21h 
    ret 
    
    CRLF endp
    ; ===============================================================
    ; PrintCard (Estilo 5x9 simétrica)
    ; AL = card (0..51)
    ; ===============================================================
    PrintCard proc
        push ax
        push bx
        push cx
        push dx

        ; Guardar carta original
        mov bl, al     ; BL = card

        ; Obtener rank
        push ax
        mov al, bl
        call GetRank   ; AL = rank
        mov bh, al     ; BH = rank
        pop ax

        ; Obtener suit
        push ax
        mov al, bl
        call GetSuit   ; AL = suit
        mov bl, al     ; BL = suit
        pop ax

    ; ---------------------------------------------------------------
    ; Línea 1: ╔═══════╗
    ; ---------------------------------------------------------------
        call CRLF
        mov dl, 201        ; ╔
        mov ah, 02h
        int 21h

        mov cx, 7
    pc_top_loop:
        mov dl, 205        ; ═
        int 21h
        loop pc_top_loop

        mov dl, 187        ; ╗
        int 21h
        call CRLF

    ; ---------------------------------------------------------------
    ; Línea 2: ║A      ║
    ; ---------------------------------------------------------------
        mov dl, 186        ; ║
        int 21h

        ; rank izquierda
        mov al, bh
        cmp al, 9          ;rank 9 = card 10
        je print_10_izq
        call PrintRank
        jmp siga

        ; excepción 10 izquierda
    print_10_izq:
        call PrintRank
        mov cx, 5           ; espacios (5)
    loop_10:
        mov dl, ' '
        mov ah, 02h
        int 21h
        loop loop_10
        jmp end_l2

    siga:
        ; espacios (6)
        mov cx, 6
    pc_l2_sp:
        mov dl, ' '
        int 21h
        loop pc_l2_sp

    end_l2:
        mov dl, 186        ; ║
        int 21h
        call CRLF

    ; ---------------------------------------------------------------
    ; Línea 3: ║   ♠   ║
    ; ---------------------------------------------------------------
        mov dl, 186        ; ║
        int 21h

        ; 3 espacios
        mov cx, 3
    pc_l3_sp1:
        mov dl, ' '
        int 21h
        loop pc_l3_sp1

        ; suit centrado
        mov al, bl
        call PrintSuit

        ; 3 espacios
        mov cx, 3
    pc_l3_sp2:
        mov dl, ' '
        int 21h
        loop pc_l3_sp2

        mov dl, 186       ; ║
        int 21h
        call CRLF

    ; ---------------------------------------------------------------
    ; Línea 4: ║      A║
    ; ---------------------------------------------------------------
        mov dl, 186      ; ║
        int 21h
        
        ;excepcion 10 derecha
        mov al, bh
        cmp al, 9          ;rank 9 = card 10
        je print_10_der
        jmp siga2

        print_10_der:
        mov cx, 5           ; espacios (5)
    loop_10_der:
        mov dl, ' '
        mov ah, 02h
        int 21h
        loop loop_10_der
        jmp rnk_der

        siga2:
        ; 6 espacios
        mov cx, 6
    pc_l4_sp:
        mov dl, ' '
        int 21h
        loop pc_l4_sp

        ; rank derecha
        rnk_der:
        mov al, bh
        call PrintRank

        end_l4:
        mov dl, 186
        int 21h
        call CRLF

    ; ---------------------------------------------------------------
    ; Línea 5: ╚═══════╝
    ; ---------------------------------------------------------------
        mov dl, 200        ; ╚
        int 21h

        mov cx, 7
    pc_bot_loop:
        mov dl, 205        ; ═
        int 21h
        loop pc_bot_loop

        mov dl, 188        ; ╝
        int 21h
;        call CRLF

    ; restore
        pop dx
        pop cx
        pop bx
        pop ax
        ret
    PrintCard endp


    ; =========================================
    ;               Show Hand
    ; E:        SI = puntero a mano
    ;           CX = cantidad de cartas
    ; =========================================
    ShowHand proc

        cmp cx, 0
        jz sh_end

        sh_loop:
            mov al, [si]
            call PrintCard

            ; Espacio entre cartas 
;            mov dl, ' '
 ;           mov ah, 02h
  ;          int 21h

            inc si
            loop sh_loop

        sh_end:

 ;           mov dl, CR
  ;          mov ah, 02h
   ;         int 21h
    ;        mov dl, LF
     ;       mov ah, 02h
      ;      int 21h

        ret

    ShowHand endp

    ; =========================================
    ;               Score Hand
    ; E:        SI = puntero a mano
    ;           CX = cantidad de cartas
    ; S:        AX = puntaje blackjack
    ; =========================================
    ScoreHand proc

        push bx
        push dx
        push di

        xor dx, dx      ; Suma total
        xor bl, bl      ; Cantidad de A's como 11

        SC_loop:
            cmp cx, 0
            jz SC_after_loop
        
            ; Tomamos la carta actual
            mov al, [si]
            inc si

            ; Obtenemos Rank
            push ax
            call GetRank
            mov ah, 0
            mov di, ax
            pop ax
            ; BL tiene 0, ... , 12

            ; Comparamos casos especiales
            cmp di, 0
            je SC_is_ace

            cmp di, 9 
            je SC_is_ten
            
            cmp di, 10 
            jae SC_is_ten

            ; Resto de cartas
            mov ax, di
            inc ax
            add dx, ax
            jmp SC_next

        SC_is_ten:
            add dx, 10
            jmp SC_next

        SC_is_ace:
            add dx, 11
            inc bl
            jmp SC_next
        
        SC_next:
            dec cx
            jmp SC_loop
        
        ; Ajustamos A's (De A = 11 -> A = 1)
        SC_after_loop:
            SC_adjust:
                cmp dx, 21
                jle SC_done
                cmp bl, 0
                je SC_done

                sub dx, 10
                dec bl
                jmp SC_adjust

        SC_done:
            mov ax, dx

            pop di
            pop dx
            pop bx

            ret

    ScoreHand endp

    ; ===============================================
    ;               Print Number
    ; E:        AX = Numero del 0-99
    ; S:        Imprime en decimal (1 o 2 digitos)
    ; ===============================================
    PrintNumber proc

        push ax
        push bx
        push dx

        mov bx, 10
        xor dx, dx
        div bx          ; AX = Cociente, DX = resto

        mov bl, al
        mov bh, dl

        cmp bl, 0
        je PN_only_units

        ;Imprimimos decenas
        mov dl, bl
        add dl, '0'
        mov ah, 02h
        int 21h

        PN_only_units:
            mov dl, bh
            add dl, '0'
            mov ah, 02h
            int 21h

        pop dx
        pop bx
        pop ax
        ret
    PrintNumber endp

    ; ===============================================
    ;               Player Turn
    ; Usa: Player Hand / Player Count / Player Score 
    ; ===============================================
    PlayerTurn proc
        PT_loop:
            ; Recalculamos el puntaje del player
            mov si, offset playerHand
            mov al, byte ptr playerCount
            mov ah, 0
            mov cx, ax
            call ScoreHand
            mov playerScore, ax

            ; Limpiamos la pantalla y mostramos estado 
            call ClearScreen

            mov dx , offset msgTurnPlayer
            call PrintString

            ; Mostramos mano del jugador
            mov dx, offset msgPlayer
            call PrintString
            ; Salto de linea
 ;           mov dl, CR
  ;          mov ah, 02h
   ;         int 21h
    ;        mov dl, LF
     ;       mov ah, 02h
      ;      int 21h

            mov si, offset playerHand
            mov al, byte ptr playerCount
            mov ah, 0
            mov cx, ax
            call ShowHand

            ; Mostramos puntaje del jugador
            mov dx, offset msgPlayerSc
            call PrintString
            mov ax, playerScore
            call PrintNumber


            ; Salto de linea
 ;           mov dl, CR
  ;          mov ah, 02h
   ;         int 21h
    ;        mov dl, LF
     ;       mov ah, 02h
      ;      int 21h

            ; Mostramos solo la UpCard del dealer
            call ShowDealerUpcard

            ; Evaluamos si se paso de 21
            mov ax, playerScore
            cmp ax, 21 
            jl PT_not_bust
            cmp ax, 21
            je PT_stand

            mov dx, offset msgPlayerBust
            call PrintString

            mov ah, 1
            int 60h

            ret 

        PT_not_bust:
            ; Preguntamos que accion toma
            mov dx, offset msgAskAction
            call PrintString

            call ReadKey

            ; Aceptamos Mayusc y Minusc
            cmp al, 'h'
            je PT_hit
    
            cmp al, 'H'
            je PT_hit
            
            cmp al, 's'
            je PT_stand
    
            cmp al, 'S'
            je PT_stand

            ; Opciones invalidas
            mov dx, offset msgInvalidAct
            call PrintString
            jmp PT_loop

        PT_hit:
            call DealCardToPlayer
            jmp PT_loop

        PT_stand:
            ret

    PlayerTurn endp

    ; =============================================
    ;           Dealer Turn
    ; Dealer pide cartas mientras puntaje < 17
    ; Usa dealerHand / dealerCount / dealerScore
    ; =============================================
    DealerTurn proc
        DT_start:
                ; Recalcular puntaje del dealer
                mov si, offset dealerHand
                mov al, byte ptr dealerCount
                mov ah, 0
                mov cx, ax
                call ScoreHand
                mov dealerScore, ax

                ; Limpiamos la pantalla y mostramos las manos completas
                call ClearScreen

                mov dx, offset msgTurnDealer
                call PrintString

                ; Mostramos ultima mano del palyer
                mov dx, offset msgPlayer
                call PrintString

                mov si, offset playerHand
                mov al, byte ptr playerCount
                mov ah, 0
                mov cx, ax
                call ShowHand
                
                ; Mostrar puntaje del player
                mov dx, OFFSET msgPlayerSc
                call PrintString
                mov ax, playerScore
                call PrintNumber

                ; Salto de linea
                mov dl, CR
                mov ah, 02h
                int 21h
                mov dl, LF
                mov ah, 02h
                int 21h

                ; Mostrar mano del dealer
                mov dx, offset msgDealer
                call PrintString

                mov si, offset dealerHand
                mov al, byte ptr dealerCount
                mov ah, 0
                mov cx, ax
                call ShowHand

                ; Mostrar puntaje dealer
                mov dx, offset msgDealerSc
                call PrintString
                mov ax, dealerScore
                call PrintNumber

                ; Salto de linea
                mov dl, CR
                mov ah, 02h
                int 21h
                mov dl, LF
                mov ah, 02h
                int 21h

                ; Evaluamos si se paso de 21
                mov ax, dealerScore
                cmp ax, 21
                jle DT_check_17

                mov dx, offset msgDealerBust
                call PrintString

                mov ah, 0
                int 60h

                ret

        DT_check_17:
                ; Si es menor 17, debe pedir carta
                cmp ax, 17
                jl DT_hit

                ; Si mayor o igual a 17, se planta
                call DelayShort
                ret

        DT_hit:
                call DelayShort
                call DealCardToDealer
                jmp DT_start

    DealerTurn endp

    ; =================================
    ;           Decide Winner
    ; Usa Player Score y Dealer Score
    ; =================================
    DecideWinner proc
    
        mov ax, playerScore
        mov bx, dealerScore

        cmp ax, bx
        jg DW_player_wins
        jl DW_dealer_wins

        mov ah, 2
        int 60h
        ret

        DW_player_wins:
            mov ah, 0
            int 60h
            ret
        
        DW_dealer_wins:
            mov ah, 1
            int 60h
            ret
    
    DecideWinner endp

    ; =================================================================
    ;                       Shuffle Deck
    ; Mezcla el mazo 'deck' en forma aleatoria
    ; Usamos el clock de la BIOS (INT 1Ah) como fuente del 'random'
    ; =================================================================
    ShuffleDeck proc

        push ax
        push bx
        push dx
        push si
        push di

        mov si, 51      ; i = 51

        SD_outer:

            ; Generamos j en [0, ... , i]
            ; Tomamos dx como valor pseudo-aleatorio
            mov ah, 0
            int 1ah
            mov ax, dx 

            mov bx, si
            inc bx
            xor dx, dx
            div bx          ; AX/BX -> AX = Cociente, DX = Resto

            ; Calculamos el &deck[i] y &deck[j]
            mov di, offset deck
            add di, si

            mov bx, offset deck
            add bx, dx

            ; Swapeamos o intercambiamos los valores de las cartas en deck[i] con deck[j]
            mov al, [di]
            mov ah, [bx]
            mov [di], ah
            mov [bx], al

            dec si
            jns SD_outer    ; Mientras SI >= 0

        pop di
        pop si
        pop dx
        pop bx
        pop ax

        ret

    ShuffleDeck endp

    ; =========================================
    ;        ShowDealerUpcard
    ; Muestra solo la primera carta del dealer
    ; y un texto indicando que hay cartas ocultas
    ; =========================================
    ShowDealerUpcard proc
        push ax
        push bx
        push cx
        push dx
        push si

        mov dx, OFFSET msgDealerUp
        call PrintString

        ; Si el dealer no tiene cartas salta al final 
        mov al, byte ptr dealerCount
        cmp al, 0
        jz SDU_end

        ; Primera carta de la mano del dealer
        mov si, OFFSET dealerHand
        mov al, [si]
        call PrintCard

        ; Texto de cartas ocultas
        mov dx, OFFSET msgDealerHidden
        call PrintString

    SDU_end:
        pop si
        pop dx
        pop cx
        pop bx
        pop ax
        ret
    ShowDealerUpcard endp


end