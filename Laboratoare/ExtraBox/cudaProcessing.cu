#include <iostream>
#include <limits.h>
#include <stdlib.h>
#include <ctime>
#include <sstream>
#include <string>
#include "device_launch_parameters.h"
#include "cuda_runtime.h"

__global__
void insert(Hash_map hash_map, int* keys, int* values, int numKeys)
{
	int index = blockIdx.x * blockDim.x   threadIdx.x;
	if (index < hash_map.size) {
		int key = keys[index];
		int value = values[index];
		if (key <= 0 || value < 0) return;
		int hash_key = hashing(key, hash_map.size);
		// linear probing
		int i = hash_key;
		while (true) {
			int ret = atomicCAS(&hash_map.map[i].key, 0, key);
			if (ret == 0 || key == ret) {
				atomicExch(&hash_map.map[i].value, value);
				break;
			}
			i;
			if (i == hash_map.size) {
				i = 0;
			}
		}
	}
}
