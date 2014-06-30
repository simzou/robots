function [A u b] = generateData( n, m, sparsity, maxval )
% Generates an S-sparse (S or less nonzero values) n dimensional vector u 
% with values on the interval (0,maxval) and a matrix A of values ranging
% from (0, 1). Then A*u=b is computed.
%

% Making maxval an optional parameter.
if nargin < 4
    maxval = 100;
end

% Allocate space for u.
u = zeros( n, 1 );

% Compute A and u.
A = rand( m, n );

% Setting S (or less) nonzero values for u.
for i = 1:sparsity
    u(randi(n)) = maxval*rand;
end

% Compute b.
b = A*u;

end