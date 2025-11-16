;==========================
;       main.asm
;   Programa Principal
;==========================

.model small
.stack 100h

.data

.code

;Declaramos las llamadas a las funciones externas
extrn ShowMenu:proc
extrn InstallInt60:proc
extrn ClearScreen:proc


main proc

    ;Inicializamos DS
    mov ax, @data
    mov ds, ax

    ;Instalamos la interrupcion 
    call InstallInt60

    ;Llamamos a la funcion externa del menu
    call ShowMenu

    ;Terminamos el programa
    mov ax, 4c00h
    INT 21h

main endp
end main