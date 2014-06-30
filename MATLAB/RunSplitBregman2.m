clc; clear all;
n = 100;
m = 100;
sparsity = 10;
lambda1 = 1;
lambda2 = 1;
lambda3 = 1;

[A u b] = generateData( n, m, sparsity );
H = @(x) (lambda1/2)*norm(A*x-b)^2;
Del = -eye(n)+diag(ones(n-1,1),1);

Phi1 = @(x) x;
Phi2 = @(x) Del*x;

%solver = gaussSeidelSolver( A, b, lambda1, lambda2 );
solver = directSolve2( A, Del, b, lambda1, lambda2, lambda3 );

uguess = genSplitBregman2( n, Phi1, Phi2, H, solver );

[u uguess]