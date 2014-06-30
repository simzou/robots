function solver = gaussSeidelSolver( A, g, lambda1, lambda2 )
% Create a solver for Ax=g that uses the Gauss-Seidel method.
%

U = lambda1.*(A'*A)+lambda2.*eye(size(A,2));

x = lambda1.*A'*g;
c = @(b,d) x+lambda2.*(d-b);

solver = @(b,d,uguess) gaussSeidel( U, c(b,d), uguess );

end

function x = gaussSeidel( A, b, xinit )
% Solves Ax=b. Only works if A is diagonally dominant or if it 
% is symmetric and positive definite.
%

iterations = 0;
x = [ xinit xinit*2 ];

L = tril( A );
U = triu( A, 1 );

T = -L\U;
C = L\b;

% Now perform our iteration.
while norm( x(:,2)-x(:,1) ) > 0.0001 && iterations < 200
    x(:,1) = x(:,2);
    x(:,2) = T*x(:,1)+C;
    
    iterations = iterations+1;
end

% Return our answer.
x = x(:,2);

end