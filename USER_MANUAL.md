
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
- Se envía por UART el mensaje:  
