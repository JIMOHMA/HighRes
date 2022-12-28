# HighRes

_**ORIGINAL IMAGE**_
![fox](https://user-images.githubusercontent.com/36754815/108548953-85d8e600-72ba-11eb-9466-b5894fae78dd.jpg)

**_EDITED IMAGE_**
![EDITED](https://user-images.githubusercontent.com/36754815/108549040-a4d77800-72ba-11eb-9ef1-9e0ccd7f2d7b.jpg)

**_HOW TO RUN CODE ON A LINUX SERVER OR COMMAND LINE GIVEN YOU HAVE ENOUGH GPU RESOURCES_**
![How To Run](https://user-images.githubusercontent.com/36754815/209846438-37c1c86d-3e9b-43b7-9451-ab531924d2bd.png)

**_SUMMARY OF RUN TIME WITH INCREASING RADIUS BRUSHES_**

![gpu vs opemmp vs cpu](https://user-images.githubusercontent.com/36754815/108547399-6b9e0880-72b8-11eb-92d5-922593e53530.PNG)

1. Sequential Execution Plot

![sequential](https://user-images.githubusercontent.com/36754815/108547576-a7d16900-72b8-11eb-96a4-3f0d8b8fbbfc.PNG)

2. GPU (Using CUDA) vs OpenMP

![GPU](https://user-images.githubusercontent.com/36754815/108547715-db13f800-72b8-11eb-8827-1e36c6019068.PNG)

**_ANALYSIS OF RESULT_**

`The longest time taken for the execution of assignment 5 was about 9 seconds for a radius brush of 40 with GPU programming. This is a significant decrease in time compared to the sequential execution which took almost 26 minutes for the same radius brush of 40. It is noticeable here that the GPU parallelization technique offers a great improvement to running programs that might require lots of memory and CPU time. One thing to note however was the execution time at a radius brush of 0; the execution time for the sequential program was a tiny bit faster than that of the GPU program, however, this is due to the fact that lots of blocks and threads (non-useful due to brush size of 0) were created for the GPU execution whereas the sequential execution just ran the skeleton program. But we see a better improvement when the brush size increases slightly to 10. The GPU execution time was a lot faster than the sequential execution and likewise for a radial brush of 20. The openMP execution is still better with its timing relative to the sequential execution but the GPU execution showed the fastest speed among all three different techniques. In conclusion, GPU execution > OpenMP execution > sequential execution in terms of the time they take to run programs that require lots of CPU time.
