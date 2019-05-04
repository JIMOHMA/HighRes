/****************************************************************
 * The ppmFile.c provided was edited and my code was added to the file 
 * for this submission that I've just made. The ppmFile.c was renamed to 
 * jimohma_A4.c just to make my submission unique. 
 * Also, I received an extension from the pro for my submission till the end of 
 * today Friday, 29th 2019. This source file uses a header file ppmFile.h aswell. 
 * 
 * ppm.c
 *
 * Read and write PPM files.  Only works for "raw" format.
 *
 ****************************************************************/
// Name :: Muyideen Ayodele Jimoh 
// Student# :: 001327114
// macID :: jimohma
// Assignment4 
// Date :: 23/03/2019

#include <omp.h>
#include <stdlib.h>
#include <stdio.h>
#include <ctype.h>
#include "ppmFile.h"
#include <time.h>

/************************ private functions ***********************/
/* die gracelessly */
struct Image *originalImage; // object of initial image to be read from file
// ImageWrite(foxImage, "tempFile.ppm");
struct Image *newImage; // object for the new image to be outputted 
int brushRadius; // brush radius 

static void
die(char const *message)
{
  fprintf(stderr, "ppm: %s\n", message);
  exit(1);
}


/* check a dimension (width or height) from the image file for reasonability */
static void
checkDimension(int dim)
{
  if (dim < 1 || dim > 6000) 
	die("file contained unreasonable width or height");
}


/* read a header: verify format and get width and height */
static void
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

Image *ImageCreate(int width, int height)
{
  Image *image = (Image *) malloc(sizeof(Image));

  if (!image) die("cannot allocate memory for new image");

  image->width  = width;
  image->height = height;
  image->data   = (unsigned char *) malloc(width * height * 3);

  if (!image->data) die("cannot allocate memory for new image");

  return image;
}
  

Image *
ImageRead(char const *filename)
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


void ImageWrite(Image *image, char const *filename)
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


int
ImageWidth(Image *image)
{
  return image->width;
}


int
ImageHeight(Image *image)
{
  return image->height;
}


void   
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

void
ImageSetPixel(Image *image, int x, int y, int chan, unsigned char val)
{
  int offset = (y * image->width + x) * 3 + chan;

  image->data[offset] = val;
}


unsigned  char
ImageGetPixel(Image *image, int x, int y, int chan)
{
  int offset = (y * image->width + x) * 3 + chan;

  return image->data[offset];
}

// sets the minX value for a pixel
int setMinX(int x, int r){
	int minX;
	if(x - r < 0){ // this is the case whereby the minX value exceeds the boundary
		minX = 0;
	}
	else{
		minX = x - r;
	}
	return minX;
}
// sets the minY value for a pixel 
int setMinY(int y, int r){
	int minY;
	if(y - r < 0){ // this is the case whereby the minY value exceeds the boundary
		minY = 0;
	}
	else{
		minY = y - r;
	}
	return minY;
}
// sets the maxX value for a pixel 
int setMaxX(int x, int r, int width){
	int maxX;
	if(x + r > width){ // this is the case whereby the maxX value exceeds the boundary
		maxX = width;
	}
	else{
		maxX = x + r;
	}
	return maxX;
}
// sets the maxY value for a pixel 
int setMaxY(int y, int r, int height){
	int maxY;
	if(y + r > height){ // this is the case whereby the maxY value exceeds the boundary
		maxY = height;
	}
	else{
		maxY = y + r;
	}
	return maxY;
}

// gets the red channel for a pixel in an image 
int getRedPixel(int minX, int minY, int maxX, int maxY, Image *rawImage){
	int temp = 0;
	int i;
	int j;
	for (i = minX; i<maxX; i++){
		for (j = minY; j<maxY; j++){
			temp += ImageGetPixel(rawImage, i, j, 0);
		}
	}
	return temp; // temp is the calculated channel value being returned
}

// gets the green channel for a pixel in an image 
int getGreenPixel(int minX, int minY, int maxX, int maxY, Image *rawImage){
	int temp = 0;
	int i;
	int j;
	for (i = minX; i<maxX; i++){
		for (j = minY; j<maxY; j++){
			temp += ImageGetPixel(rawImage, i, j, 1);
		}
	}
	return temp;
}

// gets the blue channel for a pixel in an image 
int getBluePixel(int minX, int minY, int maxX, int maxY, Image *rawImage){

	int temp = 0;
	int i;
	int j;
	for (i = minX; i<maxX; i++){
		for (j = minY; j<maxY; j++){
			temp += ImageGetPixel(rawImage, i, j, 2);
		}
	}
	return temp;
}

// function for applying the filter function to the image
Image *processImage(int width, int height){ 
	
	int x;
	int y;
	#pragma omp parallel for collapse(2)
	for (x=0; x<width; x++){
		for (y=0; y<height; y++){

			// Variable holder for the colour channels
			int pr = 0;
			int pg = 0;
			int pb = 0;
			int minX, minY, maxX, maxY;
			int numPixels;
			// we need to set the max and min values for every pixel we try to process
			minX = setMinX(x, brushRadius);
			minY = setMinY(y, brushRadius);
			maxX = setMaxX(x, brushRadius, width);
			maxY = setMaxY(y, brushRadius, height);

			numPixels = (maxY - minY) * (maxX - minX);

			// these three functions compute the the unsigned car value for 
			// a channel for a given radius brush buy considering all the pixels 
			// withing the radius from the point (x,y)
			pr = getRedPixel(minX, minY, maxX, maxY, originalImage);
			pg = getGreenPixel(minX, minY, maxX, maxY, originalImage);
			pb = getBluePixel(minX, minY, maxX, maxY, originalImage);

			pr = pr/numPixels;
			pg = pg/numPixels;
			pb = pb/numPixels;
			// sets the values of the channels in the newImage being processed for 
			// filtering. 
			ImageSetPixel(newImage, x, y, 0, pr);
			ImageSetPixel(newImage, x, y, 1, pg);
			ImageSetPixel(newImage, x, y, 2, pb);
		}
	}
	return newImage;
}

int main(int argc, char* argv[]){
	if (argc != 4){
		printf("Incorrect number of command line argument ######!\n");
		exit(0);
	}

	brushRadius = atoi(argv[1]);
	char *inputFile = argv[2];  // input file containing our image 
	char *outputFile = argv[3]; // output file for which we'll be writing out processed image into 
	originalImage = ImageRead(inputFile);
	newImage = ImageRead(inputFile);

	size_t size = sizeof(newImage->width) + sizeof(newImage->height) + (newImage->width * newImage->height * sizeof(char)); // size of the memory we about to allocate for image on device
	size_t mySize = sizeof(*newImage);
	printf("\nSize of Structure : %d",size);
 	printf("\nSize of myStructure unChar: %d\n",mySize);

	// printf("Radius is %d and the input/output files are %s/%s.\n", brushRadius, inputFile, outputFile);

	int width = ImageWidth(originalImage);
	int height = ImageHeight(originalImage);

	printf("Image width is %d, and height is %d\n", width, height);
	printf("NewImage width is %d, and height is %d\n", ImageWidth(newImage), ImageHeight(newImage));

	printf("Begin time ...\n");
	time_t begin, end;
	time(&begin);
	processImage(width, height);
	ImageWrite(newImage, outputFile);
	time(&end);
	double time_spent = difftime(end, begin);
	printf("Time taken is %f seconds.\n", time_spent);

	return 0;
}