# 🂡 Blackjack 8086 — Juego en Assembly x86

### Trabajo Práctico Final — Sistemas de Procesamiento de Datos (SPD)  
**Grupo:** 5
**Arquitectura:** Intel 8086 (Real Mode)  
**Lenguaje:** Assembly x86 (TASM)  
**Entorno:** DOS / DOSBox

---

# Descripción General

Este proyecto implementa **Blackjack (21)** completamente en **Assembly x86 (8086)**.  
Incluye toda la lógica del juego y varias características avanzadas:

- Mazo de 52 cartas con **Shuffle Fisher–Yates real**
- Representación de cartas en **ASCII 5×9**
- Sistema de puntaje con As (1 u 11)
- Menú interactivo
- Delay visual en el turno del dealer
- Limpieza de pantalla
- Estadísticas durante la sesión
- Instrucciones del juego
- Interrupción personalizada **INT 60h**
- Arquitectura modular con 3 archivos ASM

Cumple ampliamente los requisitos del TP final.

---

# Estructura del Proyecto

```
blackjack-8086/
│
├── src/
│   ├── main.asm      ; Punto de entrada principal
│   ├── lib.asm       ; Funciones: impresión, lectura, interrupción, pantalla
│   └── game.asm      ; Lógica del Blackjack (cartas, puntajes, turnos)
│   
│
├── build.bat         ; Script para compilar blackjack.exe
└── README.md
```

---

# Funcionalidades del Juego

## Cartas ASCII 5×9

Las cartas se muestran así:

```
┌─────────┐
│ A       │
│         │
│    ♥    │
│         │
│       A │
└─────────┘
```

Incluye números, J, Q, K y As.  
Pueden aparecer ♥ ♦ ♣ ♠ según corresponda.

---

# Mezcla con Fisher–Yates

Antes de cada partida, el mazo se mezcla correctamente usando el algoritmo:

```
for i = 51 down to 1:
    j = random(0..i)
    swap(deck[i], deck[j])
```

---

# Puntaje del Blackjack

- 2–10 → valor normal  
- J, Q, K → 10  
- As → 11 o 1 según convenga  
- Si el puntaje pasa 21 y hay As, se convierten a 1 automáticamente  

Ejemplo real:

```
A 7 5 8 → 21
```

---

# Turno del Jugador

- Pedir carta (H)
- Plantarse (S)
- Cartas mostradas en grande
- Upcard del dealer visible

---

# Turno del Dealer

- Roba hasta llegar a 17 o más
- Muestra cada carta con un delay visual
- Limpia pantalla entre acciones para una experiencia agradable

---

# Delay Visual

Implementado por un doble loop en ASM para lograr animación simulada.

---

# Estadísticas

Durante la sesión completa se contabilizan:

- Victorias
- Derrotas
- Empates

Mostradas en el menú de juego.

---

# Interrupción Personalizada — INT 60h

El handler implementado permite:

- Mostrar mensaje de victoria
- Mostrar mensaje de derrota
- Mostrar mensaje de empate

Ejemplo de uso:

```asm
mov ah, 0   ; Ganó el jugador
int 60h
```

### Instalación en `main.asm`
```asm
call InstallInt60
```

### Handler en `lib.asm`
Se encarga de imprimir el mensaje correspondiente.

---

# Limpieza de Pantalla (ClearScreen)

Basada en:

```
INT 10h — Scroll Up Window
```

Borra completamente el área visible sin parpadeos.

---

# Compilación del Juego

Ejecutar:

```
build.bat
```

Genera:

```
blackjack.exe
```

---

# Ejecución del Juego

En DOSBox:

```
blackjack
```
