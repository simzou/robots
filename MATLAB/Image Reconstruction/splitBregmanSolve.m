function [uguess errplot energyplot iter] = splitBregmanSolve( A, g, u0, dim, param )
% This function solves the problem
%     argmin_{u} |d|+|e|+H(u) such that d=Phi1(u), e=Phi2(u) 
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

%% If no parameters are specified, use these defaults.
if ~isfield(param, 'alpha')
    param.alpha = 1;
end
if ~isfield(param, 'beta')
    param.beta = 1;
end
if ~isfield(param, 'mu')
    param.mu = 10;
end
if ~isfield(param, 'lambda1')
    param.lambda1 = .1;
end
if ~isfield(param, 'lambda2')
    param.lambda2 = 1;
end
if ~isfield(param, 'N')
    param.N = 1;
end
if ~isfield(param, 'tol')
    param.tol = 1/250;
end
if ~isfield(param, 'maxiter')
    param.maxiter = 100;
end

%% Initialize our iterates and other variables.
n = prod(dim);

errplot    = zeros(param.maxiter, 1);
energyplot = zeros(param.maxiter, 1);

u = [u0-ones(n,1) u0]; % Constructed so that we can get into the loop.
d      = zeros(n, 1);
b      = zeros(n, 1);
dx     = zeros(n, 1);
bx     = zeros(n, 1);
dy     = zeros(n, 1);
by     = zeros(n, 1);

iter = 0; % Number of iterations completed.

%% Begin the Split Bregman algorithm.
while norm(u(:,2)-u(:,1))/norm(u(:,1)) > param.tol && iter < param.maxiter
    for i = 1:N
        
        % Save our previous iteration's value for u.
        u(:,1) = u(:,2);
        
        %% Perform step 1 of the algorithm, solve for u^{k+1}.
        u(:,2) = solveStep1(A, g, d, b, dx, bx, dy, by, dim, param);
        
        % Uncomment these to see each iteration of the reconstruction.
        
        % imagesc(reshape(u(:,2), dim)); colormap gray;
        % pause;

        %% Perform step 2 of the algorithm, shrinkage.
        d  = shrink( Phi1(u(:,2))+b, alpha/param.lambda1 ); 
        dx = shrink( Phi2(u(:,2))+bx, beta/param.lambda2 ); 
        dy = shrink( Phi3(u(:,2))+by, beta/param.lambda2 ); 
    end
    
    %% Step 3: Update b.
    b  = b  + ( u(:,2) - d );
    bx = bx + ( Phi2(u(:,2)) - dx );
    by = by + ( Phi3(u(:,2)) - dy );
    
    %% Record our results so far.
    
    errplot(iter)    = norm( u(:,2)-u(:,1) )/norm(u(:,1));
    
    [Dx Dy] = directional_gradient(u(:,2), dim);
    energyplot(iter) = param.alpha*sum(u(:,2))+param.beta*sum(Dx)+...
        param.beta*sum(Dy)+(param.mu/2)*norm(A*u(:,2)-g)^2;
    
    iter = iter + 1;
    
end

errplot = errplot(1:iter);
energyplot = energyplot(1:iter);
uguess = u(:,2);

end

function u = Phi1(u)

end

function dx = Phi2(u)

dx = directional_gradient(u, m, n);

end

function dy = Phi3(u)

[~, dy] = directional_gradient(u, m, n);

end

function d = shrink( x, gamma )
% Helper function carries out step 2 of the algorithm.

xsum = abs(x)+eps;
d = (x./xsum).*max( xsum-gamma, 0 );

end


