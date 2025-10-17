#include "gpio.h"

// Define LD2_PIN with the correct pin number (e.g., 5 for PA5 on STM32 boards)
#define LD2_PIN 5

void gpio_init_pin(GPIO_TypeDef_t *GPIO, uint8_t pin, uint8_t mode, uint8_t type, uint8_t speed, uint8_t pupd)
{
    // Configurar modo
    GPIO->MODER &= ~(0x3U << (2 * pin));
    GPIO->MODER |= (mode << (2 * pin));

    // Configurar tipo
    GPIO->TYPER &= ~(1U << pin);
    GPIO->TYPER |= (type << pin);

    // Configurar velocidad
    GPIO->SPEEDR &= ~(0x3U << (2 * pin));
    GPIO->SPEEDR |= (speed << (2 * pin));

    // Configurar pull-up/pull-down
    GPIO->PUPDR &= ~(0x3U << (2 * pin));
    GPIO->PUPDR |= (pupd << (2 * pin));
}

void gpio_setup_pin(GPIO_TypeDef_t *GPIO, uint8_t pin, uint8_t mode, uint8_t af_num)
{
    // Modo AF en MODER
    GPIO->MODER &= ~(3U << (pin * 2));
    GPIO->MODER |= ((mode & 3U) << (pin * 2));

    // Configurar AF en AFRL o AFRH
    if (pin < 8)
    {
        GPIO->AFRL &= ~(0xFU << (pin * 4));
        GPIO->AFRL |= ((af_num & 0xFU) << (pin * 4));
    }

    else
    {
        uint8_t p = pin - 8;
        GPIO->AFRH &= ~(0xFU << (p * 4));
        GPIO->AFRH |= ((af_num & 0xFU) << (p * 4));
    }
}

void set_gpio(GPIO_TypeDef_t *GPIO, uint8_t pin)
{
    GPIO->ODR |= (1 << pin); // Encender LED
}

void clear_gpio(GPIO_TypeDef_t *GPIO, uint8_t pin)
{
    GPIO->ODR &= ~(1 << pin); // Apagar LED
}

uint8_t read_gpio(GPIO_TypeDef_t *GPIO, uint8_t pin)
{
    // Leer estado del botón PC13 (botón presionado = 0, no presionado = 1)
    if ((GPIO->IDR & (1 << pin)) == 0)
    {
        return 1; // Botón presionado
    }
    return 0; // Botón no presionado
}

/*Cambia el estado del LED LD2 (ON-OFF)*/
void gpio_toggle_ld2(void)
{
    GPIOA->ODR ^= (1 << 5);
}

void led_off(void)
{
    clear_gpio(GPIOA, 5);
}

void led_on(void)
{
    set_gpio(GPIOA, 5);
}