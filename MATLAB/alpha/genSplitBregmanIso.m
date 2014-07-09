function u = genSplitBregmanIso(Phi1, Phi2, A, g, row, col, mu, lambda1, lambda2, tol, N )
% This function solves the problem
%     argmin_{u,d} |d|+|e|+H(u) such that d=Phi1(u), e=Phi2(u) 
% by converting it into the unconstrained problem
%     argmin_{u,d} |d|+|e|+H(u)+(lambda1/2)*norm(d-Phi1(u))^2+(lambda2/2)*norm(e-Phi2(u))^2
% and then running the Split-Bregman iteration to solve it.
%
% Inputs:
%    n = dimension of u.
%    Phi = R^n->R. Phi is a differentiable and |Phi()| is convex. 
%    H = Functional from R^n->R that is convex.
% Optional inputs:
%    solver = function with inputs uk, bk, dk that returns uk+1.
%    lambda = parameter for the unconstrained problem.
%    tol    = we iterate until the norm(u^k-u^{k-1})<tol.
%    N      = the number of times perform the inner loop.
%

n = row*col;

% Initialize our iterates.
u      = zeros(n, 2);
u(:,2) = ones(n, 1);
d      = zeros(n, 1);
b      = zeros(n, 1);
dx     = zeros(n, 1);
bx     = zeros(n, 1);
dy     = zeros(n, 1);
by     = zeros(n, 1);


num_params = 11;
% Set defaults for our parameters

if nargin < num_params
    N = 1;
end
if nargin < num_params - 1
    tol = 0.01;
end
if nargin < num_params - 2
    lambda2 = .1;
end
if nargin < num_params - 3
    lambda1 = .1;
end
if nargin < num_params - 4
    mu = 1;
end

AtA = A'*A;
DelX = - eye(n) + circshift(eye(n), 1);
DelY = - eye(n) + circshift(eye(n), col);

U = mu*AtA+lambda1*eye(n)+lambda2*(DelX'*DelX+DelY'*DelY);

%tic    
%% Begin the iterative process and continue until we are below
% a certain threshold.
while norm( u(:,2)-u(:,1) ) > tol
    for i = 1:N
        
        % Save our previous iteration's value for u.
        u(:,1) = u(:,2);
        
        %% Perform step 1 of the algorithm.
        rhs = make_right_hand_side(mu, lambda1, lambda2, A, b, d, bx, dx, by, dy, g, row, col);
        %u(:,2) = step1matrix_solver(mu, lambda1, lambda2, A, row, col, rhs);
        u(:,2) = U\rhs;
        
        %% Perform step 2 of the algorithm.
        d  = shrink( Phi1(u(:,2))+b, 1/lambda1 );
        
        [Dx Dy] = directional_gradient(u(:,2), row, col);
        [dx dy] = shrink2( Dx+bx, Dy+by, 1/lambda2 ); 
        
    end
    
    %% Step 3: Update b.
    b  = b  + ( u(:,2) - d );
    bx = bx + ( Dx - dx );
    by = by + ( Dy - dy );
end
%toc

u = u(:,2);

end


function d = shrink( x, gamma )
% Helper function carries out step 2 of the algorithm.

xsum = abs(x);
d = (x./xsum).*max( xsum-gamma, 0 );

end

function [dx dy] = shrink2(x, y, gamma)
% Helper function for the generalized shrinkage formula.

s = sqrt(x.*conj(x)+y.*conj(y));
ss = s-gamma;
ss = ss.*(ss>0);

s = s+(s<gamma);
ss = ss./s;

dx = ss.*x;
dy = ss.*y;

end
