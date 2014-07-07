tic
dim = 800;
u = reshape(rand(dim), dim^2, 1);
mu = 1;
lambda1 = 10;
lambda2 = 10;
A = rand(100, dim^2);
m = dim;
n = dim;
rhs = step1matrix(mu, lambda1, lambda2, A, u, m, n);
disp('rhs:')
size(rhs)
usolved = step1matrix_solver(mu, lambda1, lambda2, A, m, n, rhs);
[u usolved];
toc