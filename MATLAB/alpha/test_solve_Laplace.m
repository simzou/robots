function [u, u_solve] = test_solve_Laplace
m = 4; 
n = 4;
U = magic(4);
u = reshape(U, m*n, 1);
lambda1 = 1;
lambda2 = 2;
[ux, uy] = directional_gradient(u, m, n);
[uxx, ~] = directional_gradient_transpose(ux, m, n);
[~, uyy] = directional_gradient_transpose(uy, m, n);
f = lambda1*u + lambda2*(uxx + uyy);
u_solve = solve_Laplace(f, lambda1, lambda2, m, n);