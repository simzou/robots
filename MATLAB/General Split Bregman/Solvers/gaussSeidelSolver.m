function solver = gaussSeidelSolver( A, g, lambda1, lambda2 )

U = lambda1.*(A'*A)+lambda2.*eye(size(A,2));

x = lambda1.*A'*g;
c = @(b,d) x+lambda2.*(d-b);

solver = @(b,d,uguess) gaussSeidel( U, c(b,d), uguess );

end

function x = gaussSeidel( A, b, binit )

x = [ binit binit*2 ];

D = diag( diag( A ) );
L = tril( A, -1 );
U = triu( A, 1 );

while norm( x(:,2)-x(:,1) ) > 0.001
   
    x(:,2) = (D-L)\(U*x(:,1)+b);
    
end

x = x(:,2)

end