# Photo_Editor

Program was developed in C programming language, with the use of 
CUDA programming interface. This CUDA API allow for the use of 
multi-threading programming on GPU resources. 

Command for running program from command line prompt:
	i) cd to the desktop where directory ("Photo_Editor") is cloned to
	ii) type "ImageEditor radius inputfile.ppm outfile.ppm"
		where 
			radius --> how big you want your radius brush to be for 
						applying the filter to your photo image
						example.
			inputfile.ppm --> is the name of the origial file you 
								want to edit. NOTE: image must be 
								in ppm format
								
			outputfile.ppm --> this is based on user's preference. if they have 
								a preferred name they can change it to that which 
								they prefer, however this argument could be left unchanged.
								Also NOTE: edited image will also be in 
								ppm format. 
								
	iii) To view your edited image, you can open your image any imaging 
		software. Example would be PhotoShop. 
		
		
Sample satatemnt for running application: 
		ImageEditor 40 fox.ppm EDITED.ppm
		The name of the output file for above command is "EDITED.ppm"
	
Sample satatemnt for running application: 
		ImageEditor 40 fox.ppm outputfile.ppm
		The name of the output file for above command is "outputfile.ppm"
		
Sample satatemnt for running application: 
		hw5 40 fox.ppm Result.ppm
		The name of the output file for above command is "Result.ppm"
								
