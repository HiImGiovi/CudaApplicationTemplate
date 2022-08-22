#include <iostream>

#include "GLFW\glfw3.h"
#include "glad/glad.h"

#include <cuda_runtime.h>
#include <device_launch_parameters.h>
#include <cuda_gl_interop.h>


const int N = 5;
const int TX = 32;

/// <summary>
/// Array addition parallelized in 1D.
/// </summary>
/// <param name="a">Input array 1.</param>ù
/// <param name="b">Input array 2.</param>
/// <param name="out">Result.</param>
/// <param name="n">Number of elements in the arrays.</param>
/// <returns></returns>
__global__ void kernel_1D_addition(const int* a, const int* b, int* out, const int n)
{
	int i = blockDim.x * blockIdx.x + threadIdx.x;
	if (i > n) return;
	out[i] = a[i] + b[i];
}
static void glfw_error_callback(int error, const char* description)
{
	fprintf(stderr, "Error: %s\n", description);
}
static void glfw_framebuffer_size_callback(GLFWwindow* window, int width, int height)
{
	glViewport(0, 0, width, height);
}
int main()
{
	// test case.
	int* a = new int[N] { 1, 1, 2, 1, 4};
	int* b = new int[N] { 1, 2, 3, 1, 1};
	int* out = new int[N] {0};
	int* d_a;
	int* d_b;
	int* d_out;
	GLFWwindow* window;
	if (!glfwInit())
		exit(EXIT_FAILURE);

	glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
	glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);

	glfwSetErrorCallback(glfw_error_callback);


	window = glfwCreateWindow(1280, 720, "Cuda Application", NULL, NULL);
	if (!window)
	{
		glfwTerminate();
		exit(EXIT_FAILURE);
	}
	
	glfwMakeContextCurrent(window);
	int status = gladLoadGLLoader((GLADloadproc)glfwGetProcAddress);
	if (!status)
	{
		glfwTerminate();
		exit(EXIT_FAILURE);
	}
	glfwSwapInterval(1);

	glfwSetFramebufferSizeCallback(window, glfw_framebuffer_size_callback);

	while (!glfwWindowShouldClose(window))
	{
		glClearColor(0, 0, 256, 256);

		glfwSwapBuffers(window);
		glfwPollEvents();
	}

	glfwDestroyWindow(window);
	glfwTerminate();

	// allocating memory on the GPU
	cudaMalloc(&d_a, N * sizeof(int));
	cudaMalloc(&d_b, N * sizeof(int));
	cudaMalloc(&d_out, N * sizeof(int));

	// copying the data from the CPU to the GPU
	cudaMemcpy(d_a, a, N * sizeof(int), cudaMemcpyHostToDevice);
	cudaMemcpy(d_b, b, N * sizeof(int), cudaMemcpyHostToDevice);

	// computing the grid size and block size of the kernel call 
	// NOTE: the launch parameters of the kernel has to be optimized based on the computation that has to be done
	//       There is not a proper way to calculate the best parameters, one way is simply by benchmarking.
	dim3 gridSize((N + TX - 1) / TX);
	dim3 blockSize(TX);

	// kernel call
	kernel_1D_addition << <gridSize, blockSize >> > (d_a, d_b, d_out, N);

	// waiting for all the CUDA calls to execute
	cudaDeviceSynchronize();


	// copying back the data from the GPU to the CPU
	cudaMemcpy(out, d_out, N * sizeof(int), cudaMemcpyDeviceToHost);

	// freeing the memory
	delete[] a, b, out;
	cudaFree(d_a);
	cudaFree(d_b);
	cudaFree(d_out);

}