function solver = directSolve1( A, g, lambda1, lambda2 )

U = lambda1.*(A'*A)+lambda2.*eye(size(A,2));
c = @(b,d) lambda1.*A'*g+lambda2.*(d-b);

solver = @(b, d, uguess) U\c(b,d);

end