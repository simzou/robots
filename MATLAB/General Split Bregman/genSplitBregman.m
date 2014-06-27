function u = genSplitBregman(n, Phi, H, solver, lambda, tol, N )
% This function solves the problem
%     argmin_{u,d} |d|+H(u) such that d=Phi(u) 
% by converting it into the unconstrained problem
%     argmin_{u,d} |d|+H(u)+(lambda/2)*norm(d-Phi(u))^2
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

% Initialize our iterates.
u      = zeros(n, 2);
u(:,2) = ones(n, 1);
d      = zeros(n, 1);
b      = zeros(n, 1);

% Set defaults for our parameters
if ~exist('lambda','var')
  lambda = 1;
end
if ~exist('tol','var')
  tol = 0.001;
end
if ~exist('N','var')
  N = 1;
end
if ~exist('solver','var')
    % By default, we solve the first step numerically using fminsearch.
    options = optimset('Display','off');

    func = @(u, b, d) H(u)+(lambda/2)*norm(d-Phi(u)-b)^2;
    solver = @(b, d, uguess) fminsearch(@(u) func(u,b,d), uguess, options);  
end

%tic    
%% Begin the iterative process and continue until we are below
% a certain threshold.
while norm( u(:,2)-u(:,1) ) > tol
    for i = 1:N
        
        % Save our previous iteration's value for u.
        u(:,1) = u(:,2);
        
        %% Perform step 1 of the algorithm.
        u(:,2) = solver( b, d, u(:,1) );
                
        %% Perform step 2 of the algorithm.
        d = shrink( Phi(u(:,2))+b, 1/lambda ); 
        
    end
    
    %% Step 3: Update b.
    b = b + ( u(:,2) - d );
    
end
%toc

u = u(:,2);

end


function d = shrink( x, gamma )
% Helper function carries out step 2 of the algorithm.

xsum = abs(x);
d = (x./xsum).*max( xsum-gamma, 0 );

end
