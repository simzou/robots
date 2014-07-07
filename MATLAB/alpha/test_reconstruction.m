% testing reconstruction
dim = 50;
num_paths = 150;
paths = generate_paths(num_paths, [dim dim], 'bouncy');
filename = strcat('test', int2str(dim), '.png');
[A u ugrad g] = generate_Aug_from_image(filename, paths);
u = double(u);
size(u)
pause;
mu = 10;
lambda1 = 10;
lambda2 = 10;
m = dim;
n = dim;
g = step1matrix(mu, lambda1, lambda2, A, u, m, n);
uguess = step1matrix_solver(mu, lambda1, lambda2, A, m, n, g);
colormap gray;
imagesc(reshape(uguess, dim, dim));