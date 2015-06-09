ldr     r0, =0x10000000 //DMA Source address
ldr 	r1, =0xFFFE4000 //LREG0
str		r0, [r1]		//Store Src adr to LREG0
ldr		r0,	=0x18000000 //DMA Destination address
str		r0, [r1, #4]	//Store Dest adr to SREG0
ldr		r0, =0x00F80001 //DMA Request Register Details (count = 16 (start included), byte addressing on, DMA on)
str		r0, [r1, #8] 
b		.