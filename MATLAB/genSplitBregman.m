function u = genSplitBregman(A, g, lambda1, lambda2, tol, N )
% This function solves the unconstrained problem
%     argmin_u |a|+lambda1/2*||Au-g||^2
% by utilizing the split-bregman algorithm.
%

% First, we initialize all of our variables.
cols   = size(A, 2);
u      = zeros(cols, 2);
u(:,2) = ones(cols, 1);
d      = zeros(cols, 1);
b      = zeros(cols, 1);

% Begin the iterative process and continue until we are below
% a certain threshold.
while norm( u(:,2)-u(:,1) ) > tol
    for i = 1:N
        
        % Save our previous iteration's value for u.
        u(:,1) = u(:,2);
        
        % Perform step 1 of the algorithm.
        %S = lambda1*(A'*A)+lambda2*eye(cols);
        %C = lambda2*(d-b)-lambda1*A'*g;
        %u(:,2) = S\C;
        u(:,2) = fminsearch( @(x)lambda1*norm(A*x-g)^2+lambda2*norm(d-x-b)^2, u(:,1) );
        
        % Perform step 2 of the algorithm.
        d = shrink( u(:,2)+b, 1/lambda2 ); 
        
    end
    
    % Update b.
    b = b + ( u(:,2) - d );
    
end

u = u(:,2);

end

function d = shrink( x, gamma )
% Helper function carries out step 2 of the algorithm.

xsum = abs(x);
d = (x./xsum).*max( xsum-gamma, 0 );

end
