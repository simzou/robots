%% Creating the 'solution' vector u

clear all; clc;

m = 30;    % number of 'readings' from sensor/dim of sensing basis
n = 100;  % dimension of unknown vector u
S = 7;    % sparsity of vector u

% Third argument is fractional sparsity times m times n
u_actual_sparse = sprand(n,1,S/n);  
u_actual = full(u_actual_sparse) * 100;

% Create A and b, which we will use to find u by split bregman
A = rand(m,n);
g = A*u_actual;


%% Split Bregman Implementation

% Set tolerance, number of iterations and parameter lambda
tol = 0.01;
N = 5;
lambda_1 = 1;
lambda_2 = 1;


%uguess = genSplitBregman(A, g, lambda_1, lambda_2, tol, N);
%[u_actual uguess]


% Initial guess for vector u
u_prev = zeros(n,1);
u_next = ones(n,1);   % FIXME ones?!

u_copy = u_next;

% Iterators
b = zeros(n,1);   % zeros?
d = zeros(n,1);   % zeros?


% define function to minimise u
u_min_fn = @(x) lambda_1 * norm(A*x - g)^2 + lambda_2 * norm(d - x - b)^2;

% define shrink function to minimise d
shrink = @(x,gamma) (x./(abs(x)) .* max(abs(x)-gamma, 0));


% Begin Algorithm
%options = optimset('MaxFunEvals', 10000000, 'MaxIter', 100000);
while norm(u_next - u_prev) > tol
    

    for i = 1:N
        
        u_prev = u_next;

        % Part 1 of algorithm
        u_next   = fminunc(u_min_fn, u_prev);
        
        %solmat = lambda_1 * transpose(A) * A + lambda_2 * eye(n,n);
        %solvec = -lambda_1*transpose(A)*g + lambda_2 * (d-b);
        %u_next = solmat\solvec;

        %S = lambda_1*(A'*A)+lambda_2*eye(n);
        %C = lambda_2*(d-b)-lambda_1*A'*g;
        %u_next = S\C;
        
        % Part 2 of algorithm
        d = shrink(u_next + b, 1/lambda_2);
       
    end
    
    % Modify b now
    b = b + u_next - d;
        
end








