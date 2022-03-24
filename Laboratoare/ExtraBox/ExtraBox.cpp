#include "ExtraBox.h"
#include "Box.h"

#include <vector>
#include <iostream>

#include <Core/Engine.h>

using namespace std;
float localTime = 0;

ExtraBox::ExtraBox()
{
}

ExtraBox::~ExtraBox()
{

}

void ExtraBox::Init()
{
	cullFace = GL_BACK;
	polygonMode = GL_FILL;

	// Create a shader program for drawing polygon faces with transparency
	{
		Shader* shader = new Shader("ShaderAlpha");
		shader->AddShader("Source/Laboratoare/ExtraBox/Shaders/Transparenta.VS.glsl", GL_VERTEX_SHADER);
		shader->AddShader("Source/Laboratoare/ExtraBox/Shaders/Transparenta.FS.glsl", GL_FRAGMENT_SHADER);
		shader->CreateAndLink();
		shaders[shader->GetName()] = shader;
	}

	// Create a mesh box using custom data
	{
		vector<VertexFormat> vertices
		{
			VertexFormat(glm::vec3(-1, -1,  1), glm::vec3(1.0, 0.0, 0.0)),
			VertexFormat(glm::vec3(1, -1,  1), glm::vec3(1.0, 0.0, 0.0)),
			VertexFormat(glm::vec3(-1, 1,  1), glm::vec3(1.0, 0.0, 0.0)),
			VertexFormat(glm::vec3(1, 1,  1), glm::vec3(1.0, 0.0, 0.0)),
			VertexFormat(glm::vec3(-1, -1,  -1), glm::vec3(1.0, 0.0, 0.0)),
			VertexFormat(glm::vec3(1, -1,  -1), glm::vec3(1.0, 0.0, 0.0)),
			VertexFormat(glm::vec3(-1, 1,  -1),glm::vec3(1.0, 0.0, 0.0)),
			VertexFormat(glm::vec3(1, 1,  -1), glm::vec3(1.0, 0.0, 0.0)),
		};

		vector<unsigned short> indices =
		{
			0, 1, 2,	// indices for first triangle
			1, 3, 2,	// indices for second triangle
			2, 3, 7,
			2, 7, 6,
			1, 7, 3,
			1, 5, 7,
			6, 7, 4,
			7, 5, 4,
			0, 4, 1,
			1, 4, 5,
			2, 6, 4,
			0, 2, 4
		};
	
		Mesh* mesh = new Mesh("Cube");
		mesh->LoadMesh(RESOURCE_PATH::MODELS + "Primitives", "box.obj");
		meshes[mesh->GetMeshID()] = mesh;

		meshes["BigBox"] = new Mesh("Big Box");
		meshes["BigBox"]->InitFromData(vertices, indices);

		bigBoxCentreX = bigBoxCentreY = bigBoxCentreZ = 0.0f;
		BigBoxRotation = 0.0f;

		GetSceneCamera()->transform->SetWorldPosition(glm::vec3(0, 2.8f, 15.0f));
		GetSceneCamera()->Update();

		Animations::initCubes();
	}
}

void ExtraBox::FrameStart()
{
	// clears the color buffer (using the previously set color) and depth buffer
	glClearColor(0, 0, 0, 1);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

	glm::ivec2 resolution = window->GetResolution();

	// sets the screen area where to draw
	glViewport(0, 0, resolution.x, resolution.y);

	// Animate the bix box
	BigBoxRotation += 0.1f;
	if (BigBoxRotation > 360)
		BigBoxRotation -= 360;

	DrawCoordinatSystem();
}

void ExtraBox::Update(float deltaTimeSeconds)
{
	glLineWidth(3);
	glPointSize(5);
	glPolygonMode(GL_FRONT_AND_BACK, polygonMode);

	localTime += deltaTimeSeconds;

	Animations::moveCubes(deltaTimeSeconds);
	for (int i = 0; i < noOfCubes; i++) {
		box b = boxes[i];
		// Cubes
		{
			glm::mat4 modelMatrix = glm::mat4(1);
			modelMatrix = glm::scale(modelMatrix, glm::vec3(0.5f, 0.5f, 0.5f));
			modelMatrix = glm::translate(modelMatrix, glm::vec3(b.x, b.y, b.z));
			// render an object using colors from vertex
			RenderSimpleMesh(meshes["Cube"], shaders["Color"], modelMatrix, b.color, 0.2f);
		}
	}

	// Big Box
	{
		glm::mat4 modelMatrix = glm::mat4(1);

		//modelMatrix = glm::rotate(modelMatrix, RADIANS(BigBoxRotation), glm::vec3(0, 1, 0));
		modelMatrix = glm::scale(modelMatrix, glm::vec3(6.0f, 6.0f, 6.0f));
		modelMatrix = glm::translate(modelMatrix, glm::vec3(bigBoxCentreX, bigBoxCentreY, bigBoxCentreZ));

		// ALPHA, BLEND
		glEnable(GL_BLEND);
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
		//glEnable(GL_CULL_FACE);
		//glCullFace(GL_BACK);
		RenderSimpleMesh(meshes["BigBox"], shaders["ShaderAlpha"], modelMatrix, glm::vec3(0.5, 0.6, 0.5), 0.3f);
		glDisable(GL_BLEND);
		//glDisable(GL_CULL_FACE);
	}
}

void ExtraBox::FrameEnd()
{
	
}

void ExtraBox::OnInputUpdate(float deltaTime, int mods)
{

}

void ExtraBox::RenderSimpleMesh(Mesh* mesh, Shader* shader, const glm::mat4& modelMatrix, const glm::vec3& color, const float obj_alpha)
{
	if (!mesh || !shader || !shader->GetProgramID())
		return;

	// render an object using the specified shader and the specified position
	glUseProgram(shader->program);

	// Set shader uniforms 
	int object_color = glGetUniformLocation(shader->program, "color");
	glUniform3f(object_color, color.r, color.g, color.b);

	int object_alpha = glGetUniformLocation(shader->program, "alpha");
	glUniform1f(object_alpha, obj_alpha);

	// Bind model matrix
	GLint loc_model_matrix = glGetUniformLocation(shader->program, "Model");
	glUniformMatrix4fv(loc_model_matrix, 1, GL_FALSE, glm::value_ptr(modelMatrix));

	// Bind view matrix
	glm::mat4 viewMatrix = GetSceneCamera()->GetViewMatrix();
	int loc_view_matrix = glGetUniformLocation(shader->program, "View");
	glUniformMatrix4fv(loc_view_matrix, 1, GL_FALSE, glm::value_ptr(viewMatrix));

	// Bind projection matrix
	glm::mat4 projectionMatrix = GetSceneCamera()->GetProjectionMatrix();
	int loc_projection_matrix = glGetUniformLocation(shader->program, "Projection");
	glUniformMatrix4fv(loc_projection_matrix, 1, GL_FALSE, glm::value_ptr(projectionMatrix));

	// Draw the object
	glBindVertexArray(mesh->GetBuffers()->VAO);
	glDrawElements(mesh->GetDrawMode(), static_cast<int>(mesh->indices.size()), GL_UNSIGNED_SHORT, 0);
}

void ExtraBox::OnKeyPress(int key, int mods)
{
	// TODO: switch between GL_FRONT and GL_BACK culling - DONE
	// Save the state in "cullFace" variable and apply it in the Update() method not here

	if (key == GLFW_KEY_SPACE)
	{
		switch (polygonMode)
		{
			case GL_POINT:
				polygonMode = GL_FILL;
				break;
			case GL_LINE:
				polygonMode = GL_POINT;
				break;
			default:
				polygonMode = GL_LINE;
				break;
			}
	}
}

void ExtraBox::OnKeyRelease(int key, int mods)
{
	// add key release event
}

void ExtraBox::OnMouseMove(int mouseX, int mouseY, int deltaX, int deltaY)
{
	// add mouse move event
}

void ExtraBox::OnMouseBtnPress(int mouseX, int mouseY, int button, int mods)
{
	// add mouse button press event
}

void ExtraBox::OnMouseBtnRelease(int mouseX, int mouseY, int button, int mods)
{
	// add mouse button release event
}

void ExtraBox::OnMouseScroll(int mouseX, int mouseY, int offsetX, int offsetY)
{
}

void ExtraBox::OnWindowResize(int width, int height)
{
}
