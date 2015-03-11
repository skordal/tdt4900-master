// The Great Heterogenous Bitcoin Miner Project
// Written as part of their master's thesis by:
// 	Kristian Klomsten Skordal <kristian.skordal@wafflemail.net>
//	Torbjørn Langland <torbljan@stud.ntnu.no>
// Read the report on <https://github.com/skordal/tdt4102-master>

#include "mm.h"
#include "irq.h"
#include "shmac.h"
#include "timer.h"

struct timer_info
{
	timer_callback_func callback;
	int irq;
	void * user_data;
	volatile uint32_t * memory;
};

static struct timer_info ** timer_infos;

static void timer_irq_handler(int irq)
{
	switch(irq)
	{
		case TIMER0_IRQ:
			timer_infos[shmac_get_tile_cpu_id()][0].callback(timer_infos[shmac_get_tile_cpu_id()][0].user_data);
			timer_infos[shmac_get_tile_cpu_id()][0].memory[TIMER_CLR] = 1;
			break;
		case TIMER1_IRQ:
			timer_infos[shmac_get_tile_cpu_id()][1].callback(timer_infos[shmac_get_tile_cpu_id()][1].user_data);
			timer_infos[shmac_get_tile_cpu_id()][1].memory[TIMER_CLR] = 1;
			break;
		case TIMER2_IRQ:
			timer_infos[shmac_get_tile_cpu_id()][2].callback(timer_infos[shmac_get_tile_cpu_id()][2].user_data);
			timer_infos[shmac_get_tile_cpu_id()][2].memory[TIMER_CLR] = 1;
			break;
	}
}

void timer_initialize(void)
{
	timer_infos = mm_allocate(sizeof(struct timer_info *) * shmac_get_cpu_count());
	for(int i = 0; i < shmac_get_cpu_count(); ++i)
	{
		timer_infos[i] = mm_allocate(sizeof(struct timer_info) * 3);
		for(int j = 0; j < 3; ++j)
		{
			switch(j)
			{
				case 0:
					timer_infos[i][j].irq = TIMER0_IRQ;
					timer_infos[i][j].memory = TIMER0_BASE;
					break;
				case 1:
					timer_infos[i][j].irq = TIMER1_IRQ;
					timer_infos[i][j].memory = TIMER1_BASE;
					break;
				case 2:
					timer_infos[i][j].irq = TIMER2_IRQ;
					timer_infos[i][j].memory = TIMER2_BASE;
					break;
			}
		}
	}
}

void timer_start(unsigned int timer, uint32_t count, enum timer_scale_factor scale,
	bool repeating, timer_callback_func callback, void * data)
{
	if(timer > 2)
	{
		shmac_printf("CPU%d: WARNING: trying to use timer %d, which does not exist!\n\r", shmac_get_tile_cpu_id(),
			timer);
		return;
	}

	timer_infos[shmac_get_tile_cpu_id()][timer].user_data = data;
	timer_infos[shmac_get_tile_cpu_id()][timer].callback = callback;
	timer_infos[shmac_get_tile_cpu_id()][timer].memory[TIMER_LOAD] = count;
	uint32_t ctrl_value = 1 << TIMER_CTRL_ENABLE
		| (repeating ? 1 : 0) << TIMER_CTRL_PERIODIC
		| scale << TIMER_CTRL_SCALE;
	timer_infos[shmac_get_tile_cpu_id()][timer].memory[TIMER_CTRL] = ctrl_value;

	irq_set_handler(timer_infos[shmac_get_tile_cpu_id()][timer].irq, timer_irq_handler);
	shmac_printf("CPU%d: timer %d started!\n\r", shmac_get_tile_cpu_id(), timer);
}

