#include "Box.h"
#include <numeric>
#include <vector>
#include <algorithm>
#include <random>
#include <set>
#include "CheckCollision.cuh"

#define M_PI 3.141592f

float velF = 0.1f;
float gravF = 0.005f;
float velyF = 0.1f;
std::map<int,box> boxes;
int noOfCubes = 500;
int id = 0;
float g = 9.8f;
float D = 5.5f;

// random float between 0 and 1
float randomFloat() {
	return float(rand()) / float((RAND_MAX));
}

void Animations::generateCube(float x, float y, float z) {
	float xVel = sin(randomFloat() * 2 * M_PI);
	float zVel = cos(randomFloat() * 2 * M_PI);
	boxes[id] = box{id, randomFloat() * 9 + 1, x, y, z, xVel, zVel, 0, 0, 
		glm::vec3(randomFloat(), randomFloat(), randomFloat()) };
	id++;
}

void Animations::initCubes() {
	srand((unsigned int)time(NULL));
	float x, y, z;
	for (int i = 0; i < noOfCubes; i++) {
		while (true) {
			bool collision = false;
			// generate random coordinates for cube
			x = float(rand()) / float((RAND_MAX)) * 22 - 11;
			y = float(rand()) / float((RAND_MAX)) * 22 - 11;
			z = float(rand()) / float((RAND_MAX)) * 22 - 11;
			// check to be in the extra box all the time
			if (abs(sqrt(x * x + z * z)) > 10) continue;

			// check collision at generation of cube
			for (int i = 0; i < noOfCubes; i++) {
				// we have collision between two boxes
				if (abs(x - boxes[i].x) < 1 && abs(y - boxes[i].y) < 1 && abs(z - boxes[i].z) < 1)
				{
					collision = true;
					break;
				}
			}
			if (!collision) break;
		}
		generateCube(x, y, z);
	}
}


void checkCollisionBigBox(box b) {

	float yPos = b.y + 1 - (12);
	float yNeg = b.y - (-12);
	float zPos = b.z + 1 - (12);
	float zNeg = b.z - (-12);
	float xPos = b.x + 1 - (12);
	float xNeg = b.x - (-12);

	// collision with extraBox bottom
	if ((yNeg < 0.5) && b.moving) {
		boxes[b.id].moving = false;
	}

	// collision with extraBox top
	if (yPos > 0.5) {
		boxes[b.id].timeFalling = 0;
		boxes[b.id].yVel = 0;
	}

	// collision with extraBox sides
	if (zPos > 0.5 || zNeg < 0.5 || xPos > 0.5 || xNeg < 0.5) {
		boxes[b.id].zVel = -boxes[b.id].zVel;
		boxes[b.id].xVel = -boxes[b.id].xVel;
	}
}


void Animations::moveCubes(float deltaTimeSeconds) {

	for (int i = 0; i < noOfCubes; i++) {
		if (!boxes[i].moving) continue;
		boxes[i].timeFalling += deltaTimeSeconds;
	}
	
	CUDA::checkCollision();

	for (int i = 0; i < noOfCubes; i++) {
		checkCollisionBigBox(boxes[i]);
		if (!boxes[i].moving) continue;

		float A = ((g - (float)(D / boxes[i].m)) / 2.0f)
			* (float)(2.0f * boxes[i].timeFalling + 1.0f) * gravF;
		float bump = boxes[i].yVel * velyF;

		boxes[i].y -= A - bump;

		if (boxes[i].yVel > 0) {
			boxes[i].yVel -= 0.1;
			if (A > bump) {
				boxes[i].timeFalling = 0;
				boxes[i].yVel = 0;
			}
		}

		boxes[i].x += boxes[i].xVel * velF;
		boxes[i].z += boxes[i].zVel * velF;
	}
}
