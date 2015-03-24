// The Great Heterogenous Bitcoin Miner Project
// Written as part of their master's thesis by:
// 	Kristian Klomsten Skordal <kristian.skordal@wafflemail.net>
//	Torbjørn Langland <torbljan@stud.ntnu.no>
// Read the report on <https://github.com/skordal/tdt4102-master>

#include "sha256.h"

#ifdef SHA256_DISABLE_ACCELERATOR

static uint32_t initial[] =
{
		0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
		0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19
};

static uint32_t constants[] =
{
	0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
	0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
	0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
	0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
	0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
	0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
	0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
	0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
};

static uint32_t intermediate[8];

static inline uint32_t rotate_right(uint32_t x, int n)
{
	uint32_t retval = 0;

	retval = x >> n;
	retval |= x << (32 - n);

	return retval;
}

static uint32_t Ch(uint32_t x, uint32_t y, uint32_t z)
{
	return (x & y) ^ ((~x) & z);
}

static uint32_t Maj(uint32_t x, uint32_t y, uint32_t z)
{
	return (x & y) ^ (x & z) ^ (y & z);
}

static uint32_t s0(uint32_t x)
{
	return rotate_right(x, 2) ^ rotate_right(x, 13) ^ rotate_right(x, 22);
}

static uint32_t s1(uint32_t x)
{
	return rotate_right(x, 6) ^ rotate_right(x, 11) ^ rotate_right(x, 25);
}

static uint32_t o0(uint32_t x)
{
	return rotate_right(x, 7) ^ rotate_right(x, 18) ^ (x >> 3);
}

static uint32_t o1(uint32_t x)
{
	return rotate_right(x, 17) ^ rotate_right(x, 19) ^ (x >> 10);
}

static uint32_t schedule(uint32_t input, uint32_t * W, int i)
{
	if(i < 16)
		return input;
	else {
		return o1(W[i - 2]) + W[i - 7] + o0(W[i - 15]) + W[i - 16];
	}
}

static void compress(uint32_t * i, uint32_t W, uint32_t K)
{
	uint32_t a = i[0], b = i[1], c = i[2], d = i[3];
	uint32_t e = i[4], f = i[5], g = i[6], h = i[7];

	uint32_t t1 = h + s1(e) + Ch(e, f, g) + K + W;
	uint32_t t2 = s0(a) + Maj(a, b, c);

	h = g;
	g = f;
	f = e;
	e = d + t1;
	d = c;
	c = b;
	b = a;
	a = t1 + t2;

	i[0] = a;
	i[1] = b;
	i[2] = c;
	i[3] = d;
	i[4] = e;
	i[5] = f;
	i[6] = g;
	i[7] = h;
}

void sha256_reset(void)
{
	for(int i = 0; i < 8; ++i)
		intermediate[i] = initial[i];
}

void sha256_clear_irq(void)
{

}

void sha256_update(void)
{

}

void sha256_get_hash(uint8_t * hash)
{
	for(int i = 0; i < 8; ++i)
	{
		hash[i * 4 + 3] = intermediate[i] >> 0 & 0xff;
		hash[i * 4 + 2] = intermediate[i] >> 8 & 0xff;
		hash[i * 4 + 1] = intermediate[i] >> 16 & 0xff;
		hash[i * 4 + 0] = intermediate[i] >> 24 & 0xff;
	}
}

void sha256_set_data(uint32_t * data)
{
	uint32_t W[64];
	uint32_t temp[8];

	for(int i = 0; i < 8; ++i)
		temp[i] = intermediate[i];

	for(int i = 0; i < 64; ++i)
	{
		uint32_t v = i < 16 ? data[i] : 0;
		W[i] = schedule(v, W, i);
		compress(temp, W[i], constants[i]);
#ifdef SHA256_SOFTHASH_DEBUG
		shmac_printf("t = %d: %x  %x  %x  %x  %x  %x  %x  %x\n\r",
			i, temp[0], temp[1], temp[2], temp[3], temp[4],
			temp[5], temp[6], temp[7]);
#endif
	}

	for(int i = 0; i < 8; ++i)
		intermediate[i] += temp[i];
}

#else

static volatile uint32_t * module = SHA256_BASE;

void sha256_reset(void)
{
	// Toggle the reset bits in the control register to reset the module:
	module[SHA256_CTRL] = 1 << SHA256_CTRL_IRQCLR | 1 << SHA256_CTRL_ENABLE | 1 << SHA256_CTRL_RESET;
	module[SHA256_CTRL] = 1 << SHA256_CTRL_ENABLE;
}

void sha256_clear_irq(void)
{
	module[SHA256_CTRL] |= 1 << SHA256_CTRL_IRQCLR;
	module[SHA256_CTRL] &= ~(1 << SHA256_CTRL_IRQCLR);
}

void sha256_get_hash(uint8_t * hash)
{
	for(int i = 0; i < 8; ++i)
	{
		uint32_t value = module[SHA256_OUTPUT(i)];
		hash[i * 4 + 0] = (value >> 24) & 0xff;
		hash[i * 4 + 1] = (value >> 16) & 0xff;
		hash[i * 4 + 2] = (value >>  8) & 0xff;
		hash[i * 4 + 3] = (value >>  0) & 0xff;
	}
}

void sha256_set_data(uint32_t * data)
{
	for(int i = 0; i < 16; ++i)
		module[SHA256_INPUT(i)] = data[i];
}

void sha256_update(void)
{
	module[SHA256_CTRL] |= 1 << SHA256_CTRL_UPDATE;
	module[SHA256_CTRL] &= ~(1 << SHA256_CTRL_UPDATE);
}

#endif

void sha256_format_hash(const uint8_t * hash, char * output)
{
	static const char * hex_digits = "0123456789abcdef";
	for(int i = 0; i < 32; ++i)
	{
		uint8_t h = hash[i];

		output[i * 2 + 0] = hex_digits[(h >> 4) & 0xf];
		output[i * 2 + 1] = hex_digits[h & 0xf];
	}

	output[64] = 0;
}

