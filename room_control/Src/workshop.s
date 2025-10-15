// --- Ejemplo de Botón y LED en STM32L476RG ---

    .syntax unified @usar la sintaxis Unified (compatible con ARM y Thumb)
    .thumb @Indica que el código siguiente es modo Thumb (instrucciones de 16/32 bits)
    .section .text @Sitúa las próximas instrucciones en la sección de código ejecutable

// --- Seccion de datos para la variable del contador ---
    .section .data
    .align 4
delay_counter: .word 0 // Variable de 32 bits para nuestro contador de retardo

    .section .text
    .global main
    .global init_led
    .global init_button
    .global init_systick
    .global SysTick_Handler

// --- Definiciones para LED LD2 (PA5) ---
    .equ RCC_BASE,      0x40021000      @ Base de RCC
    .equ RCC_AHB2ENR,   RCC_BASE + 0x4C @ Registro para habilitar relojes de GPIO
    .equ GPIOA_BASE,    0x48000000      @ Base de GPIOA
    .equ GPIOA_MODER,   GPIOA_BASE + 0x00 @ Registro de modo de GPIOA
    .equ GPIOA_ODR,     GPIOA_BASE + 0x14 @ Registro de datos de salida de GPIOA
    .equ LD2_PIN,       5               @ Pin del LED LD2 es PA5

// --- Definiciones para Botón B1 (PC13) ---
    .equ GPIOC_BASE,    0x48000800      @ Base de GPIOC
    .equ GPIOC_MODER,   GPIOC_BASE + 0x00 @ Registro de modo de GPIOC
    .equ GPIOC_PUPDR,   GPIOC_BASE + 0x0C @ Registro de Pull-up/Pull-down
    .equ GPIOC_IDR,     GPIOC_BASE + 0x10 @ Registro de datos de entrada de GPIOC
    .equ BUTTON_PIN,    13              @ Pin del Botón B1 es PC13

// --- Definiciones para SysTick ---
    .equ SYST_CSR,      0xE000E010      @ Control y estado
    .equ SYST_RVR,      0xE000E014      @ Valor de recarga
    .equ HSI_FREQ,      4000000         @ Reloj interno por defecto (4 MHz)

// --- Programa principal ---
main:
    bl init_led
    bl init_button
    bl init_systick
loop:
    // Leer el estado del botón
    movw  r0, #:lower16:GPIOC_IDR
    movt  r0, #:upper16:GPIOC_IDR
    ldr   r1, [r0]                      @ r1 = valor del registro de entrada de GPIOC
    tst   r1, #(1 << BUTTON_PIN)        @ Comprueba si el bit 13 es 0 (botón presionado)

    // Si el bit es 0 (resultado de TST es 0), la bandera Z se activa.
    // BEQ (Branch if Equal) salta si la bandera Z está activa.
    beq   button_pressed
    b     loop                          @ Si no está presionado, sigue revisando

button_pressed:
    // Primero, verificamos si ya hay un conteo en marcha para no reiniciarlo
    ldr   r0, =delay_counter            @ Carga la dirección de nuestra variable
    ldr   r1, [r0]                      @ Carga el valor actual del contador
    cmp   r1, #0                        @ Si el contador es > 0, no hagas nada
    bne   loop

    // Si el contador es 0, enciende el LED y carga el contador
    // Enciende el LED LD2
    movw  r0, #:lower16:GPIOA_ODR
    movt  r0, #:upper16:GPIOA_ODR
    ldr   r1, [r0]
    orr   r1, r1, #(1 << LD2_PIN)       @ Pone el bit 5 a 1
    str   r1, [r0]

    // Carga 3000 en nuestro contador para 3 segundos (3000 ms)
    ldr   r0, =delay_counter            @ Carga la dirección de nuestra variable
    movs  r1, #0
    movw  r1, #3000                     @ Carga el valor 3000 en r1
    str   r1, [r0]                      @ Guarda 3000 en la memoria
    b     loop                          @ Vuelve al bucle principal

// --- Inicialización de GPIOA PA5 para el LED LD2 ---
init_led:
    movw  r0, #:lower16:RCC_AHB2ENR
    movt  r0, #:upper16:RCC_AHB2ENR
    ldr   r1, [r0]
    orr   r1, r1, #(1 << 0)             @ Habilita reloj GPIOA (bit 0)
    str   r1, [r0]

    movw  r0, #:lower16:GPIOA_MODER
    movt  r0, #:upper16:GPIOA_MODER
    ldr   r1, [r0]
    bic   r1, r1, #(0b11 << (LD2_PIN * 2))
    orr   r1, r1, #(0b01 << (LD2_PIN * 2)) @ PA5 como salida
    str   r1, [r0]
    bx    lr

// --- Inicialización de GPIOC PC13 para el Botón B1 ---
init_button:
    // Habilitar reloj para GPIOC
    movw  r0, #:lower16:RCC_AHB2ENR
    movt  r0, #:upper16:RCC_AHB2ENR
    ldr   r1, [r0]
    orr   r1, r1, #(1 << 2)             @ Habilita reloj GPIOC (bit 2)
    str   r1, [r0]

    // Configurar PC13 como entrada
    movw  r0, #:lower16:GPIOC_MODER
    movt  r0, #:upper16:GPIOC_MODER
    ldr   r1, [r0]
    bic   r1, r1, #(0b11 << (BUTTON_PIN * 2)) @ Pone en 00 los bits de PC13 (entrada)
    str   r1, [r0]

    // Habilitar resistencia de pull-up para PC13
    movw  r0, #:lower16:GPIOC_PUPDR
    movt  r0, #:upper16:GPIOC_PUPDR
    ldr   r1, [r0]
    bic   r1, r1, #(0b11 << (BUTTON_PIN * 2))
    orr   r1, r1, #(0b01 << (BUTTON_PIN * 2)) @ Pone en 01 los bits (Pull-up)
    str   r1, [r0]
    bx    lr

// --- Inicialización de Systick para interrupción de 1 ms ---
init_systick:
    movw  r0, #:lower16:SYST_RVR
    movt  r0, #:upper16:SYST_RVR
    // Para 1 ms: (4,000,000 / 1000) - 1 = 3999
    movw  r1, #3999
    str   r1, [r0]

    movw  r0, #:lower16:SYST_CSR
    movt  r0, #:upper16:SYST_CSR
    movs  r1, #(1 << 0)|(1 << 1)|(1 << 2) @ ENABLE=1, TICKINT=1, CLKSOURCE=1
    str   r1, [r0]
    bx    lr

// --- Manejador de la interrupción SysTick ---
.thumb_func
SysTick_Handler:
    // Carga la dirección y el valor de nuestro contador
    ldr   r0, =delay_counter
    ldr   r1, [r0]

    // Si el contador es 0, no hagas nada
    cmp   r1, #0
    beq   systick_exit

    // Si es > 0, decrémentalo
    subs  r1, r1, #1
    str   r1, [r0] // Guarda el nuevo valor

    // Si el contador acaba de llegar a 0, apaga el LED
    cmp   r1, #0
    bne   systick_exit

    // Apagar el LED LD2
    movw  r2, #:lower16:GPIOA_ODR
    movt  r2, #:upper16:GPIOA_ODR
    ldr   r3, [r2]
    bic   r3, r3, #(1 << LD2_PIN)       @ Pone el bit 5 a 0
    str   r3, [r2]

systick_exit:
    bx    lr

