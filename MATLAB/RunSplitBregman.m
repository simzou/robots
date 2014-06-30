clc; clear all;
n = 100;
m = 100;
sparsity = 10;
lambda1 = 1;
lambda2 = 1;

[A u b] = generateData( n, m, sparsity );
H = @(x) (lambda1/2)*norm(A*x-b)^2;
Phi = @(x) x;

%uguess = zeros(n, 100, 100);

% for i=1:100
%     for j=1:100
%         solver = directSolve1( A, b, i, j );
%         uguess( :, i, j ) = genSplitBregman( n, Phi, H, solver, j );
%     end
% end

solver = gaussSeidelSolver( A, b, lambda1, lambda2 );
%solver = directSolve1( A, b, lambda1, lambda2 );

uguess = genSplitBregman( n, Phi, H, solver );

[u uguess]