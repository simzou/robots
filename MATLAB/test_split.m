grid_size = 20;
num_paths = 500;
grid_dim = [grid_size grid_size];
[A u ugrad g] = generate_Aug_from_image(strcat('test',int2str(grid_size),'.png'), generate_paths(num_paths, grid_dim, []));

Phi = @(x) x;
H = @(x) A*x;
solver = directSolve1(A, g, 1, 1);
lambda = .1;
tol = 0.1;
N = 1;
uguess = genSplitBregman(grid_size^2, Phi, H, solver, lambda, tol, N )
