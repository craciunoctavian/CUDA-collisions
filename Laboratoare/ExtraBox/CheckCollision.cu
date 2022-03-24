#include "device_launch_parameters.h"
#include "cuda_runtime.h"
#include "CheckCollision.cuh"
#include "Box.h"

#define cudaCheckError() { \
	cudaError_t e=cudaGetLastError(); \
	if(e!=cudaSuccess) { \
		printf("Cuda failure, %s",cudaGetErrorString(e)); \
		exit(0); \
	 }\
}

__global__ 
void kernel_check(int noOfCubes, float* d_x, float* d_y, float* d_z, float* d_yVel)
{
	int idxX = blockIdx.x * blockDim.x + threadIdx.x;
	int idxY = blockIdx.y * blockDim.y + threadIdx.y;
	if (idxX > noOfCubes || idxY > noOfCubes) {
		return;
	}
	float c_x = d_x[idxX];
	float c_y = d_y[idxX];
	float c_z = d_z[idxX];

	float b_x = d_x[idxY];
	float b_y = d_y[idxY];
	float b_z = d_z[idxY];

	if (idxX == idxY) return;
	// AABB collision
	if ((c_x - 0.5 <= b_x + 0.5 && c_x + 0.5 >= b_x - 0.5) &&
		(c_y - 0.5 <= b_y + 0.5 && c_y + 0.5 >= b_y - 0.5) &&
		(c_z - 0.5 <= b_z + 0.5 && c_z + 0.5 >= b_z - 0.5)) {
		if (c_y > b_y) {
			d_yVel[idxX] = 2.0f;
		}
	}
}

bool CUDA::checkCollision() {

	float *h_x; 
	float *h_y; 
	float *h_z; 
	float *h_yVel;

	h_x = (float*)malloc(noOfCubes * sizeof(float));
	h_y = (float*)malloc(noOfCubes * sizeof(float));
	h_z = (float*)malloc(noOfCubes * sizeof(float));
	h_yVel = (float*)malloc(noOfCubes * sizeof(float));

	for (int i = 0; i < noOfCubes; i++) {
		h_x[i] = boxes[i].x;
		h_y[i] = boxes[i].y;
		h_z[i] = boxes[i].z;
		h_yVel[i] = boxes[i].yVel;
	}

	float *d_x;
	float *d_y;
	float *d_z;
	float *d_yVel;

	cudaMalloc((void**)&d_x, noOfCubes * sizeof(float));
	cudaCheckError();
	cudaMalloc((void**)&d_y, noOfCubes * sizeof(float));
	cudaCheckError();
	cudaMalloc((void**)&d_z, noOfCubes * sizeof(float));
	cudaCheckError();
	cudaMalloc((void**)&d_yVel, noOfCubes * sizeof(float));
	cudaCheckError();

	cudaMemcpy(d_x, h_x, noOfCubes * sizeof(float), cudaMemcpyHostToDevice);
	cudaMemcpy(d_y, h_y, noOfCubes * sizeof(float), cudaMemcpyHostToDevice);
	cudaMemcpy(d_z, h_z, noOfCubes * sizeof(float), cudaMemcpyHostToDevice);
	cudaMemcpy(d_yVel, h_yVel, noOfCubes * sizeof(float), cudaMemcpyHostToDevice);

	dim3 blocksPerGrid((noOfCubes + 15) / 16, (noOfCubes + 15) / 16, 1);
	dim3 threadsPerBlock(16, 16, 1);
	kernel_check<<<blocksPerGrid, threadsPerBlock >>>(noOfCubes, d_x, d_y, d_z, d_yVel);

	// Wait for GPU to finish before accessing on host
	cudaDeviceSynchronize();

	cudaMemcpy(h_yVel, d_yVel, noOfCubes * sizeof(float), cudaMemcpyDeviceToHost);

	for (int i = 0; i < noOfCubes; i++) {
		boxes[i].yVel = h_yVel[i];
	}

	cudaFree(d_x);
	cudaFree(d_y);
	cudaFree(d_z);
	cudaFree(d_yVel);
	free(h_x);
	free(h_y);
	free(h_z);
	free(h_yVel);

	return true;
}
