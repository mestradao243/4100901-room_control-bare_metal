# Manual de Usuario: Sistema de Control de Sala  
**Universidad Nacional de Colombia – Sede Manizales**  
**Curso:** Estructuras Computacionales (4100901)  

---

## 1. Introducción  

El **Sistema de Control de Sala** implementa un controlador de iluminación utilizando el microcontrolador **STM32L476RG** en modo *bare-metal*.  
El sistema simula el control de una habitación mediante varios **LEDs** que representan diferentes bombillas: una principal, una controlada por PWM (modulación por ancho de pulso) y un LED de *heartbeat* que indica el funcionamiento del sistema.  

Su objetivo es demostrar el uso de periféricos básicos del microcontrolador como **GPIO**, **TIM**, **SysTick**, **NVIC** y **UART**, aplicados al control de hardware en tiempo real sin usar librerías de alto nivel (HAL o LL).  

---

## 2. Hardware Utilizado  

| Componente | Descripción |
|-------------|-------------|
| **Placa** | STM32L476RG Nucleo-64 |
| **LED Heartbeat (LD2)** | LED en placa conectado a **PA5**, parpadea periódicamente para indicar que el sistema está activo |
| **Bombilla Principal** | LED conectado a **PB3**, controlado mediante el botón de usuario |
| **Bombilla PWM** | LED conectado al canal **TIM3_CH1 (PA6)**, controlado por modulación PWM |
| **Botón de Usuario (B1)** | Conectado a **PC13**, genera una interrupción externa (EXTI13) |
| **UART2** | Comunicación serie a 115200 bps sobre pines **PA2 (TX)** y **PA3 (RX)** |

---

## 3. Funcionalidades  

### 3.1 Heartbeat LED  
El LED de *heartbeat* (PA5) parpadea de forma periódica para indicar que el sistema está en funcionamiento.  
Se controla mediante el temporizador **SysTick**, que genera una interrupción cada 1 ms y permite actualizar el estado del LED según un contador interno.

---

### 3.2 Control de Bombilla por Botón  
El botón de usuario (**PC13**) activa una interrupción externa (EXTI13).  
Cuando el usuario presiona el botón:  
- El LED principal (**PB3**) se enciende.  
- Permanece encendido por **3 segundos** (`LED_TIMEOUT_MS = 3000`).  
- Después de ese tiempo, se apaga automáticamente.  
- Por UART se envía un mensaje notificando la acción (por ejemplo: `"LED encendido por botón\r\n"`).  

---

### 3.3 Comunicación UART  
El sistema implementa comunicación serial mediante **USART2** a **115200 bps**.  
Permite enviar y recibir comandos desde un monitor serial (por ejemplo, *PuTTY* o *TeraTerm*).  

**Funciones UART:**
- Eco de los caracteres recibidos.  
- Ejecución de comandos específicos para controlar el PWM.  
- Mensajes de estado enviados por el sistema (inicio, cambios de estado, etc.).  

Ejemplo de conexión:

---

### 3.4 Control PWM de Bombilla  
La bombilla secundaria está controlada mediante **PWM (Pulse Width Modulation)** generado por el **TIM3**, canal **CH1 (PA6)**.  
- Frecuencia de PWM: **1 kHz** (`PWM_FREQUENCY = 1000 Hz`).  
- Duty cycle inicial: **50 %** (`PWM_INITIAL_DUTY = 50`).  
- El valor del *duty cycle* puede modificarse mediante comandos UART o funciones internas.  

El PWM permite variar el brillo del LED, simulando una bombilla con control de intensidad.

---

## 4. Arquitectura del Sistema  

### 4.1 Módulos  

| Módulo | Descripción |
|--------|--------------|
| **gpio.h / gpio.c** | Configuración y control de pines GPIO. |
| **rcc.h / rcc.c** | Configura los relojes de los periféricos (GPIO, TIM, SYSCFG). |
| **tim.h / tim.c** | Configuración del temporizador TIM3 para generar señal PWM. |
| **systick.h / systick.c** | Implementa temporización basada en interrupciones cada 1 ms. |
| **nvic.h / nvic.c** | Maneja interrupciones externas (EXTI13, USART2). |
| **uart.h / uart.c** | Comunicación serial para interacción con el usuario. |
| **room_control.h / room_control.c** | Lógica de control de la sala (eventos de botón, UART, y actualización de estados). |
| **main.c** | Punto de entrada: inicializa periféricos y ejecuta el ciclo principal del sistema. |

---

### 4.2 Flujo de Ejecución  

1. **Inicialización:**  
   - Se configuran relojes, GPIOs, SysTick, UART, NVIC y PWM.  
   - Se imprime el mensaje `"Sistema Inicializado!"` por UART.  

2. **Bucle Principal:**  
   - Supervisa eventos de **botón** y **UART** mediante variables compartidas (`button_event`, `uart_event_char`).  
   - Llama a `room_control_update()` para manejar timeouts y actualización de estados.  

3. **Interrupciones:**  
   - `EXTI15_10_IRQHandler`: se ejecuta al presionar el botón.  
   - `USART2_IRQHandler`: se ejecuta al recibir datos por UART.  

---

## 5. Uso del Sistema  

### 🔌 Conexión  
1. Conecta la placa **STM32L476RG** al PC mediante cable USB.  
2. Abre un terminal serie con los parámetros:
   - **Baud rate:** 115200  
   - **Data bits:** 8  
   - **Stop bits:** 1  
   - **Parity:** None  
3. (Opcional) Conecta LEDs externos a los pines **PB3** y **PA6** si deseas visualizarlos fuera de la placa.  

---

### ⚙️ Inicio del Sistema  
Al energizar la placa:  


---

### 🧠 Interacción  

**Por Botón (PC13):**
- Presionar el botón enciende el LED principal por 3 s.  
- El evento se reporta por UART.

**Por UART:**
- Se pueden enviar caracteres para interactuar con el sistema.  
- El microcontrolador realiza eco de los caracteres recibidos.  
- Comandos específicos (por implementar) pueden modificar el *duty cycle* del PWM.  


- El LED de *heartbeat* (PA5) comienza a parpadear.  

## 6. Diagramas  

### 6.1 Diagrama de Estados 
 ┌────────────┐        Botón presionado        ┌───────────────┐
 │   IDLE     │ ───────────────────────────▶  │ LED Encendido │
 └────────────┘                               └───────────────┘
       ▲                                              │
       │    Timeout (3 s)                             │ UART comando PWM
       │                                              ▼
       │                                        ┌──────────────┐
       └──────────────────────────────────────  │ PWM Activo   │
                                                └──────────────┘

### 6.2 Diagrama de Componentes  
           ┌────────────────────────────┐
           │       room_control.c       │
           │  (Lógica principal)        │
           └────────────┬───────────────┘
                        │
        ┌───────────────┼──────────────────────┐
        │                │                     │
┌──────────────┐  ┌──────────────┐     ┌────────────────┐
│ gpio.c/.h    │  │ tim.c/.h     │     │ uart.c/.h      │
│ Control GPIO │  │ PWM (TIM3)   │     │ Comunicación    │
└──────────────┘  └──────────────┘     └────────────────┘
        │                │                     │
        │                │                     │
        └──────────────┬───────────────────────┘
                       │
                ┌─────────────┐
                │ main.c      │
                │ Inicializa  │
                │ periféricos │
                └─────────────┘

