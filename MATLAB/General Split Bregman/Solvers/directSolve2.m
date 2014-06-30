function solver = directSolve2( A, Del, g, lambda1, lambda2, lambda3 )
% Solver for the problem 
%     argmin(|u|+|Del*u|+(lambda1/2)*||Au-g||^2+(lambda2/2)*||d-u-b||^2+(lambda3/2)*||e-Del*u-c||^2)
% that is performed algebraically.
%

U = lambda1.*(A'*A)+lambda2.*eye(size(A,2))+lambda3.*(Del'*Del);

x = lambda1.*A'*g;
f = @(b,d,c,e) x+lambda2.*(d-b)+lambda3.*(e-c);

solver = @(b, d, c, e, uguess) U\f(b,d,c,e);

end