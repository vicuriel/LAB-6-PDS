/* ========================================
 *
 * Copyright YOUR COMPANY, THE YEAR
 * All Rights Reserved
 * UNPUBLISHED, LICENSED SOFTWARE.
 *
 * CONFIDENTIAL AND PROPRIETARY INFORMATION
 * WHICH IS THE PROPERTY OF your company.
 *
 * ========================================
*/
#include "project.h"
#include <stdio.h>

#define OFFSET 2.04
#define LONGITUD  512

/* Defines for DMA_1 */
#define DMA_1_BYTES_PER_BURST 2
#define DMA_1_REQUEST_PER_BURST 1
#define DMA_1_SRC_BASE (CYDEV_PERIPH_BASE)
#define DMA_1_DST_BASE (CYDEV_SRAM_BASE)

/* Add an explicit reference to the floating point printf library to allow
the usage of floating point conversion specifier */
#if defined (_GNUC_)
    asm (".global _printf_float");
#endif

int16 datos[LONGITUD];
float datos_float[LONGITUD];
float datos_filtrados[LONGITUD];

uint8 estado = 0u;

uint8 errorStatus = 0u;
uint k, j, i , n = 0;

//coeficientes del filtro alpha beta alpha,  las frecuencias de 0.2pi (1khz). Frecuencia de muestreo de 5khz
float x[] = { 1,   -0.61,    1};

//coeficientes del filtro fir pasa bajos en 0.4pi(1kHz cuando se muestrea a 5kHz)
float u[] = {-0.0061,   -0.0136,    0.0512,    0.2657,    0.4057,    0.2657,    0.0512,   -0.0136,   -0.0061};

//coeficientes del filtro iir pasa banda  de 0.2pi a 0.4pi (de 500hz hasta 1kHz si la frecuencia de muestreo es de 5kHz)
float num[] = {0.0003,    0.0000,   -0.0015,    0.0000,    0.0029,    0.0000,   -0.0029,    0.0000,    0.0015,    0.0000,   -0.0003};
float den[] = {1.0000,   -5.5397,   16.3975,  -32.2094,   46.1195,  -49.7632,   41.0058,  -25.4542,   11.5138,   -3.4549,    0.5558};


/* Variable declarations for DMA_1 */
uint8 DMA_1_Chan;
uint8 DMA_1_TD[1];

char aux[20];

CY_ISR(Adquisicion);
CY_ISR(RxIsr);


void my_Start(void);
void dmaConfig(void);

int main(void)
{     
    my_Start();         /* Rutina para inicializar los componentes */
    dmaConfig(); 
    
    // Punteros a las rutinas de interrupción  
    #if(INTERRUPT_CODE_ENABLED == ENABLED)
    isr_1_StartEx(Adquisicion);    
    isr_rx_StartEx(RxIsr);
    #endif /* INTERRUPT_CODE_ENABLED == ENABLED */
    
    CyDelay(50);  
    CyGlobalIntEnable; /* Enable global interrupts. */
    isr_rx_Enable();
    isr_1_Disable();
    
    for(;;) 
    {
        switch(estado) {
            case '0': // es un cero
                // Estado vacío, el sistema espera una orden por UART
                break;
            
            case 'I': // habilitar digitalización
                ADC_SAR_1_Start();
                isr_1_Enable(); 
                estado = '0'; 
                break;
            
            case 'X':   // filtrar la señal
                Led_Write(~Led_Read());
                for(j = 0; j < LONGITUD; j++){
                   datos_float[j] = ADC_SAR_1_CountsTo_Volts(datos[j]);
                }
                    
                for(j = 0 ; j < 10 ; j++){ 
                    datos_filtrados[j] = 0;
                }
                    
                for(n = 10; n < sizeof(datos_float)/sizeof(datos_float[0]); n++){
                    datos_filtrados[n] = 0.004457316873616*datos_float[n] -0.013381728127024*datos_float[n-1] + 0.017394556777320*datos_float[n-2] -0.016878720527475*datos_float[n-3] + 0.013357931872552*datos_float[n-4]  - 0.000000000000000*datos_float[n-5]  - 0.013357931872552*datos_float[n-6] + 0.016878720527475*datos_float[n-7]  - 0.017394556777320*datos_float[n-8] + 0.013381728127024*datos_float[n-9] - 0.004457316873616*datos_float[n-10] + 5.360423467225571*datos_filtrados[n-1]  - 15.336049790434762*datos_filtrados[n-2] + 29.164280433882475*datos_filtrados[n-3] - 40.489547785908577*datos_filtrados[n-4] + 42.421766674640210*datos_filtrados[n-5] - 33.982415867011454*datos_filtrados[n-6] + 20.529110167169229*datos_filtrados[n-7] - 9.045237167851917*datos_filtrados[n-8] + 2.646064281233042*datos_filtrados[n-9] - 0.415307972988183*datos_filtrados[n-10];
                }
                    
                estado = '0'; 
                break;
            
            case 'P':   // enviar señal original al PSoC
                for(j = 0; j < sizeof(datos_float)/sizeof(datos_float[0]); j++){
                    Chart_1_Plot(datos_float[j]);
                }
                estado = '0'; 
                break;
            
            case 'F':   // enviar señal filtrada al PSoC
                for(j = 0; j < sizeof(datos_filtrados)/sizeof(datos_filtrados[0]); j++){
                    Chart_1_Plot(datos_filtrados[j]);
                }
                estado = '0'; 
                break;
        }
    }
} /* fin main */


void my_Start(){
    ADC_SAR_1_Start();
    Clock_1_Start();
    Opamp_1_Start();
    Opamp_2_Start();
    PGA_1_Start();
    UART_Start(); 
    ADC_SAR_1_Stop();
}

CY_ISR(Adquisicion){   
    ADC_SAR_1_Stop();
    estado = 'X'; 
    isr_1_ClearPending(); 
}

CY_ISR(RxIsr)
{
    uint8 rxStatus;         
    uint8 rxData;           
    
    do
    {
        rxStatus = UART_RXSTATUS_REG;

        if((rxStatus & (UART_RX_STS_BREAK | UART_RX_STS_PAR_ERROR |
                        UART_RX_STS_STOP_ERROR | UART_RX_STS_OVERRUN)) != 0u)
        {
            errorStatus |= rxStatus & ( UART_RX_STS_BREAK | UART_RX_STS_PAR_ERROR | 
                                        UART_RX_STS_STOP_ERROR | UART_RX_STS_OVERRUN);
        }
        
        if((rxStatus & UART_RX_STS_FIFO_NOTEMPTY) != 0u)
        {
            rxData = UART_RXDATA_REG;
            if (rxData == 'I'){
                estado = 'I';
            } else if (rxData == 'P'){
                estado = 'P';
            } else if (rxData == 'F'){
                estado = 'F';
            } else {
                estado = '0';   
            }
        }
    }while((rxStatus & UART_RX_STS_FIFO_NOTEMPTY) != 0u);
}

void dmaConfig(void){
    DMA_1_Chan = DMA_1_DmaInitialize(DMA_1_BYTES_PER_BURST, DMA_1_REQUEST_PER_BURST, 
    HI16(DMA_1_SRC_BASE), HI16(DMA_1_DST_BASE));
    DMA_1_TD[0] = CyDmaTdAllocate();
    CyDmaTdSetConfiguration(DMA_1_TD[0], 2*LONGITUD, DMA_1_TD[0], DMA_1__TD_TERMOUT_EN | CY_DMA_TD_INC_DST_ADR);
    CyDmaTdSetAddress(DMA_1_TD[0], LO16((uint32)ADC_SAR_1_SAR_WRK0_PTR), LO16((uint32)datos));
    CyDmaChSetInitialTd(DMA_1_Chan, DMA_1_TD[0]);
    CyDmaChEnable(DMA_1_Chan, 1);
}

/* [] END OF FILE */
