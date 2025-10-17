#include "nvic.h"
#include "gpio.h"
#include "room_control.h"
#include "rcc.h"  // Para rcc_syscfg_clock_enable
#include "uart.h" // Para USART2

extern volatile uint8_t button_event;
extern volatile uint32_t system_ms_counter;

static void nvic_enable_irq(uint32_t IRQn)
{
    NVIC->ISER[IRQn / 32U] |= (1UL << (IRQn % 32U));
}

void nvic_set_priority(uint32_t IRQn, uint8_t priority)
{
    NVIC->IP[IRQn] = (priority & 0xFFU);
}

void nvic_exti_pc13_button_enable(void) // Esta función configura el botón conectado al pin PC13 para que genere una interrupción externa (EXTI) cuando se presiona.
{
    // reloj SYSCFG
    RCC->APB2ENR |= (1U << 0);

    SYSCFG->EXTICR[3] &= ~(0xFU << 4);
    SYSCFG->EXTICR[3] |= (0x2U << 4);

    EXTI->IMR1 |= (1U << 13);
    // Flanco descendente (botón activo-bajo)
    EXTI->FTSR1 |= (1U << 13);
    // Limpia pendiente inicial
    EXTI->PR1 = (1U << 13);

    // Habilita IRQ en NVIC
    NVIC->ISER[1] = (1U << (EXTI15_10_IRQn - 32));
}

void nvic_usart2_irq_enable(void) // Esta función habilita la interrupción del periférico UART2, para reaccionar automáticamente cuando llega un nuevo carácter por serial.
{
    // Habilita RXNEIE (interrupción cuando hay dato)
    USART2->CR1 |= (1U << 5);

    // Habilita IRQ de USART2 en NVIC
    NVIC->ISER[1] = (1U << (USART2_IRQn - 32));
}