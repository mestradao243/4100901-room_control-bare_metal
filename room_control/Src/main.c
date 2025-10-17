#include "gpio.h"    // llama a las funciones de perifericos y la logica del control de sala
#include "systick.h" // la logica del control de sala
#include "rcc.h"
#include "uart.h"
#include "nvic.h"
#include "tim.h"
#include "room_control.h"

volatile uint8_t button_event = 0;
volatile char uart_event_char = 0;

// Contador de milisegundos del sistema
volatile uint32_t system_ms_counter = 0;

// Inicializar periféricos del programa
static void peripherals_init(void)
{
    // Inicialización del sistema
    rcc_init();

    // Configuración de GPIOs
    init_gpio(GPIOA, 5, 0x01, 0x00, 0x01, 0x00, 0x00);
    init_gpio(GPIOC, 13, 0x00, 0x00, 0x01, 0x01, 0x00);

    init_systick();
    init_gpio_uart();
    init_uart();
    nvic_exti_pc13_button_enable();
    nvic_usart2_irq_enable();
    tim3_ch1_pwm_set_frequency(100000);
}

int main(void)
{
    peripherals_init();
    room_control_app_init();
    uart_send_string("Sistema Inicializado!\r\n"); // esto lo hace dos veces

    // Bucle principal
    while (1)
    {
        if (button_event)
        {
            button_event = 0;
            room_control_on_button_press();
        }
        if (uart_event_char)
        {
            char c = uart_event_char;
            uart_event_char = 0;
            room_control_on_uart_receive(c);
        }
        // Llamar a la función de actualización periódica
        room_control_update();
    }
}

// Manejadores de interrupciones
void EXTI15_10_IRQHandler(void)
{
    // Limpiar flag de interrupción
    if (EXTI->PR1 & (1 << 13))
    {
        EXTI->PR1 |= (1 << 13); // Clear pending
        button_event = 1;
    }
}

void USART2_IRQHandler(void)
{
    // Verificar si es recepción
    if (USART2->ISR & (1 << 5))
    { // RXNE
        uart_event_char = (char)(USART2->RDR & 0xFF);
    }
}