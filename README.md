# 🂡 Blackjack 8086 — Juego en Assembly x86

### Trabajo Práctico Final — Sistemas de Procesamiento de Datos (SPD)  
**Grupo:** 5  
**Lenguaje:** Assembly x86  
**Arquitectura:** Intel 8086 
**Ejecución:** DOS / DOSBox

---

## Descripción del Proyecto

Implementación completa del juego **Blackjack (21)** en Assembly x86 utilizando:

- Rutinas modulares en archivos separados (`main.asm`, `game.asm`, `lib.asm`)
- Una interrupción propia **INT 60h**
- Shuffle real tipo *Fisher–Yates*
- Representación visual de cartas con ASCII extendido
- Cálculo correcto de puntajes incluyendo As (1/11)
- Limpieza de pantalla y delays para mejor experiencia visual

---

## Estructura del Proyecto

```
blackjack-8086/
│
├── src/
│   ├── main.asm
│   ├── lib.asm
│   ├── game.asm
│
├── build.bat
├── .gitignore
└── README.md
```

---

## Requisitos

- **TASM 3.0**
- **TLINK**
- **DOS o DOSBox**
- Windows / Linux / MacOS con DOSBox

---

## Compilación

Ejecutar en DOSBox:

```
build
```

Esto genera:

```
blackjack.exe
```

---

## Ejecución

```
blackjack.exe
```

---

## Funcionamiento del Juego

- Mazo barajado con Fisher–Yates  
- Turno del jugador:  
  - **H** → Pedir carta  
  - **S** → Plantarse  
- Dealer roba hasta tener 17+
- Limpieza de pantalla entre acciones
- Impresión de cartas estilo:

```
[A ♥]
[10 ♦]
[J ♣]
```

---

## Interrupción Personalizada — INT 60h

Se utiliza para mostrar:

- Victoria del jugador  
- Victoria del dealer  
- Empate  

Valores:  
- **AH = 0** → Jugador gana  
- **AH = 1** → Dealer gana  
- **AH = 2** → Empate  

---

## Sistema de Puntaje

- 2–10 → Valor natural  
- J, Q, K → 10  
- A → 11 o 1 (ajustable si el jugador se pasa de 21)  

---

## Limpieza y Delay

- `ClearScreen` → Limpia la pantalla con INT 10h  
- `DelayShort` → Pausa mediante doble loop  
