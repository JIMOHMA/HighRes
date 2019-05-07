/****************************************************************
 * To run assignment, run make first and then use "hw5 radius inputfile.ppm outfile.ppm" 
 *
 * Read and write PPM files.  Only works for "raw" format.
 * To get timing of program, run command "time Editor brushSize inputfile.ppm outputfile.ppm"
 * here brushSize is the level of blurness you want for the image being edited, 
 * inputfile.ppm is the image being edited and outfile.ppm is the edited image. 
 *
 ****************************************************************/
// Developer's Name :: Ayodele Jimoh 
// src: ImageEditor.cu
// Date :: 12/04/2019

#include <omp.h>
#include <stdlib.h>
#include <stdio.h>
#include <ctype.h>
#include <time.h>

 typedef struct Image
{
	  int width;
	  int height;
	  unsigned char *data;
} Image;

// Thread block size
#define BLOCK_SIZE 32

/************************ private functions ***********************/
struct Image *originalImage; // pointer object of initial image to be read from file
int someValue = 2;
int *brushRadius = &someValue; // brush radius.... VALUE IS CHANGED WHEN READ FROM IMPUT... This was done to avoid seg fault

/* die gracelessly */
static void
__host__ die(char const *message)
{
  fprintf(stderr, "ppm: %s\n", message);
  exit(1);
}


/* check a dimension (width or height) from the image file for reasonability */
__host__ static void
checkDimension(int dim)
{
  if (dim < 1 || dim > 6000) 
	die("file contained unreasonable width or height");
}


/* read a header: verify format and get width and height */
__host__ static void
readPPMHeader(FILE *fp, int *width, int *height)
{
  char ch;
  int  maxval;

  if (fscanf(fp, "P%c\n", &ch) != 1 || ch != '6') 
	die("file is not in ppm raw format; cannot read");

  /* skip comments */
  ch = getc(fp);
  while (ch == '#')
	{
	  do {
	ch = getc(fp);
	  } while (ch != '\n');	/* read to the end of the line */
	  ch = getc(fp);            
	}

  if (!isdigit(ch)) die("cannot read header information from ppm file");

  ungetc(ch, fp);		/* put that digit back */

  /* read the width, height, and maximum value for a pixel */
  fscanf(fp, "%d%d%d\n", width, height, &maxval);

  if (maxval != 255) die("image is not true-color (24 bit); read failed");
  
  checkDimension(*width);
  checkDimension(*height);
}

/************************ exported functions ****************************/

__host__ Image *ImageCreate(int width, int height)
{
  Image *image = (Image *) malloc(sizeof(Image));

  if (!image) die("cannot allocate memory for new image");

  image->width  = width;
  image->height = height;
  image->data   = (unsigned char *) malloc(width * height * 3);

  if (!image->data) die("cannot allocate memory for new image");

  return image;
}
  

__host__ Image *ImageRead(char const *filename)
{
  int width, height, num, size;

  Image *image = (Image *) malloc(sizeof(Image));
  FILE  *fp    = fopen(filename, "rb");

  if (!image) die("cannot allocate memory for new image");
  if (!fp)    die("cannot open file for reading");

  readPPMHeader(fp, &width, &height);

  size          = width * height * 3;
  image->data   = (unsigned  char*) malloc(size);
  image->width  = width;
  image->height = height;

  if (!image->data) die("cannot allocate memory for new image");

  num = fread((void *) image->data, 1, (size_t) size, fp);

  if (num != size) die("cannot read image data from file");

  fclose(fp);

  return image;
}


__host__ void ImageWrite(Image *image, char const *filename)
{
  int num;
  int size = image->width * image->height * 3;

  FILE *fp = fopen(filename, "wb");

  if (!fp) die("cannot open file for writing");

  fprintf(fp, "P6\n%d %d\n%d\n", image->width, image->height, 255);

  num = fwrite((void *) image->data, 1, (size_t) size, fp);

  if (num != size) die("cannot write image data to file");

  fclose(fp);
}  


__host__ int ImageWidth(Image *image)
{
  return image->width;
}


__host__ int ImageHeight(Image *image)
{
  return image->height;
}

// This function is not utilized anywhere in this code, so we put it on host
// since it has no application in any parallelization eoperation. Just for convenience. 
__host__ void   
ImageClear(Image *image, unsigned char red, unsigned char green, unsigned char blue)
{
  int i;
  int pix = image->width * image->height;

  unsigned char *data = image->data;

  for (i = 0; i < pix; i++)
	{
	  *data++ = red;
	  *data++ = green;
	  *data++ = blue;
	}
}

__device__ void ImageSetPixel(unsigned char *d_dataOut, int x, int y, int chan, unsigned char val, int width)
{
  int offset = (y * width + x) * 3 + chan;

  d_dataOut[offset] = val;
}

__device__ unsigned  char ImageGetPixel(unsigned char *d_dataIn, int x, int y, int chan, int width)
{
  int offset = (y * width + x) * 3 + chan;

  return d_dataIn[offset];
}

// sets the minX value for a pixel
__device__ int setMinX(int x, int *d_brushRadius){
	int minX;
	if(x - *d_brushRadius < 0){ // this is the case whereby the minX value exceeds the boundary
		minX = 0;
	}
	else{
		minX = x - *d_brushRadius;
	}
	return minX;
}
// sets the minY value for a pixel 
__device__ int setMinY(int y, int *d_brushRadius){

	int minY;
	if(y - *d_brushRadius < 0){ // this is the case whereby the minY value exceeds the boundary
		minY = 0;
	}
	else{
		minY = y - *d_brushRadius;
	}
	return minY;
}
// sets the maxX value for a pixel 
__device__ int setMaxX(int x, int *d_brushRadius, int width){
	int maxX;
	if(x + *d_brushRadius > width){ // this is the case whereby the maxX value exceeds the boundary
		maxX = width;
	}
	else{
		maxX = x + *d_brushRadius;
	}
	return maxX;
}
// sets the maxY value for a pixel 
__device__ int setMaxY(int y, int *d_brushRadius, int height){
	int maxY;
	if(y + *d_brushRadius > height){ // this is the case whereby the maxY value exceeds the boundary
		maxY = height;
	}
	else{
		maxY = y + *d_brushRadius;
	}
	return maxY;
}


// gets the red channel for a pixel in an image 
// this is a gpu fucntion because the function is 
// being usig by a kernel on the GPU side
__device__ int getRedPixel(int minX, int minY, int maxX, int maxY, unsigned char *d_dataIn, int width){
	int temp = 0;
	int i;
	int j;
	for (i = minX; i<maxX; i++){
		for (j = minY; j<maxY; j++){
			temp += ImageGetPixel(d_dataIn, i, j, 0, width);
		}
	}
	return temp; // temp is the calculated channel value being returned
}

// gets the green channel for a pixel in an image 
// this is a gpu fucntion because the function is 
// being usig by a kernel on the GPU side
__device__ int getGreenPixel(int minX, int minY, int maxX, int maxY, unsigned char *d_dataIn, int width){
	int temp = 0;
	int i;
	int j;
	for (i = minX; i<maxX; i++){
		for (j = minY; j<maxY; j++){
			temp += ImageGetPixel(d_dataIn, i, j, 1, width);
		}
	}
	return temp;
}

// gets the blue channel for a pixel in an image 
// this is a gpu fucntion because the function is 
// being usig by a kernel on the GPU side
__device__ int getBluePixel(int minX, int minY, int maxX, int maxY, unsigned char *d_dataIn, int width){

	int temp = 0;
	int i;
	int j;
	for (i = minX; i<maxX; i++){
		for (j = minY; j<maxY; j++){
			temp += ImageGetPixel(d_dataIn, i, j, 2, width);
		}
	}
	return temp;
}

// function for applying the filter function to the image
// Function to be parallelized which is callable from the host CPU. 
// remember to change d_inputImage d_dataIn, and d_outputImage to d_dataOut within this function
// Remember d_dataOut holds the data for the filtered image
__global__ void processImage(unsigned char *d_dataIn, unsigned char *d_dataOut, int width, int height, int *d_brushRadius){ 
	
	// Need to define the blockIdx and threadIdx
	int x = threadIdx.x + blockIdx.x * blockDim.x;
	int y = threadIdx.y + blockIdx.y * blockDim.y;

	//printf("x and y are %d, %d\n", x, y);
	// Variable holder for the colour channels
	int pr = 0;
	int pg = 0;
	int pb = 0;
	int minX, minY, maxX, maxY;
	int numPixels;

	// printf("1) Value of brush is %d\n", *d_brushRadius);

	// we need to set the max and min values for every pixel we try to process
	// device function to set the min and max values of the boundary
	minX = setMinX(x, d_brushRadius);
	minY = setMinY(y, d_brushRadius);
	maxX = setMaxX(x, d_brushRadius, width);
	maxY = setMaxY(y, d_brushRadius, height);

	numPixels = (maxY - minY) * (maxX - minX);

	// these three functions compute the the unsigned car value for 
	// a channel for a given radius brush buy considering all the pixels 
	// withing the radius from the point (x,y)
	pr = getRedPixel(minX, minY, maxX, maxY, d_dataIn, width); // d_inputImage should be replaced with d_dataIn
	pg = getGreenPixel(minX, minY, maxX, maxY, d_dataIn, width);
	pb = getBluePixel(minX, minY, maxX, maxY, d_dataIn, width);

	pr = pr/numPixels;
	pg = pg/numPixels;
	pb = pb/numPixels;
	// sets the values of the channels in the newImage being processed for 
	// filtering. 
	ImageSetPixel(d_dataOut, x, y, 0, pr, width); // d_outputImage should be replaced with d_dataOut
	ImageSetPixel(d_dataOut, x, y, 1, pg, width);
	ImageSetPixel(d_dataOut, x, y, 2, pb, width);

}

int main(int argc, char* argv[]){
	if (argc != 4){
		printf("Incorrect number of command line argument ######!\n");
		exit(0);
	}

	// printf("The value of brushSize is: %d\n", brushRadius);
	// printf("The value of brushSize after assignment is: %d\n", radius);
	// printf("The value of brushSize after assignment is: %d\n", *brushRadius);
	
	int radius = atoi(argv[1]); // our brush radius
	*brushRadius = radius;
	char *inputFile = argv[2];  // input fileName containing our image 
	char *outputFile = argv[3]; // output fileName for which we'll be writing out processed image into 
	originalImage = ImageRead(inputFile);
	int width = ImageWidth(originalImage);
	int height = ImageHeight(originalImage);

	struct Image *h_inputImage = ImageRead(inputFile); // pointer object for the new image to be outputted on host machine

	// structure that will eventually hold the output/edited 
	// image on the host machine. 
	// Create am empty image inside h_outputImage
	struct Image *h_outputImage = ImageCreate(width, height);
	// unsigned char *h_dataOut = NULL; //h_outputImage->data; // we've copied the empty data in h_outputImage to h_dataOut

	printf("Image width is %d, and height is %d\n", width, height);
	printf("NewImage width is %d, and height is %d\n", ImageWidth(h_inputImage), h_inputImage->height);

	// pointers for holding out input image data and output image data
	unsigned char *d_dataIn = NULL;
	unsigned char *d_dataOut = NULL;
	int *d_brushRadius = NULL; // pointer for radius brush

	// size of the memory we about to allocate for image on device
	size_t sizeData = h_inputImage->width * h_inputImage->height * 3;
	size_t brushSize = sizeof(int);

	// Allocate memory on the device for the d_inputImage and d_outputImage
	cudaMalloc(&d_dataIn, sizeData);
	cudaMalloc(&d_dataOut, sizeData);
	cudaMalloc(&d_brushRadius, brushSize);

	// Copy data host image memory into device GPU image memory
	cudaMemcpy(d_dataIn, h_inputImage->data, sizeData, cudaMemcpyHostToDevice);
	cudaMemcpy(d_brushRadius, brushRadius, brushSize, cudaMemcpyHostToDevice);
	// printf("Begin time ...\n");
	// time_t begin, end;
	// time(&begin);

	// Launch Kernel for parallelization
	// This is the kernel function that we want to parallelize for 
	// faster rendering of filter to image. 
	// Note: Add image as an argument which is a pointer so any update 
	// we do is gonna be done to this outputImage for the device machine i.e d_outputImage
	// TO DO: find out how to allocate the blocks and threads for the kernel
	dim3 dimBlock(32,32); // 32 threads in each block of threads
	dim3 dimGrid(width/dimBlock.x, height/dimBlock.y); 
	processImage<<<dimGrid, dimBlock>>>(d_dataIn, d_dataOut, width, height, d_brushRadius);
	// End of launching kernel
	cudaDeviceSynchronize();

	// Let's copy out final image data back onto the CPU
	cudaMemcpy(h_outputImage->data, d_dataOut, sizeData, cudaMemcpyDeviceToHost);

	// write final/edited image data into output file
	ImageWrite(h_outputImage, outputFile); // writes the final edited image into the outputFile. 
	// time(&end); // end timer for Image Processing. 
	// double time_spent = difftime(end, begin); // time taken to process image.
	// printf("Time taken is %f seconds.\n", time_spent);

	// Free the allocated memory on the GPU 
	cudaFree(d_dataIn);
	cudaFree(d_dataOut);
	cudaFree(d_brushRadius);

	return 0;
}