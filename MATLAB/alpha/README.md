## Sparse Image Reconstruction using Split-Bregman Iteration

### Purpose

Our objective is to recover an unknown grayscale image `u` from a collection of sums of the 
pixel values of the images taken across linear paths across the image's surface.


We wish to solve the minimization problem 
````
min_{u} a|u|+b|grad_x(u)|+b|grad_y(u)| st Au=g,
````
which we relax to the unconstrained problem
````
min_{u} a|u|+b|grad_x(u)|+b|grad_y(u)|+(mu/2)||Au-g||^2.
````


### The files

#### The Algorithm

- directional_gradient.m 
- directional_gradient_transpose.m
- generate_Aug_from_image.m
- generate_paths.m
- path_weights.m
- solve_Laplace.m
- step1matrix.m
- step1matrix_solver.m

#### Testing Files

- test10.png
- test20.PNG
- test50.PNG
- test_generate_paths.m
- test_path_weights.m
- test_solve_Laplace.m
- test_step1matrix_solver.m

### How to use