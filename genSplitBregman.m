function [unew dnew] = genSplitBregman( Phi, Phiu, H, tol, N )


d = zeros(len,1);
u = zeros(len,2);
u(:,2) = ones(len,3);

% Begin the iterative process and continue until we are below
% a certain threshold.
while norm( u(:,2)-u(:,1) ) > tol
    
    % Save our previous iteration's value for u.
    u(:,1) = u(:,2);
    
    for i = 1:N
        
        % Perform step 1 of the algorithm.        
        
        % Perform step 2 of the algorithm.
        d = shrink( Phiu+b, 1/lambda ); 
        
    end
    
    b = b + ( Phi(u(3))-d(3) );
    
end

function d = shrink( x, gamma )

xsum = sum(x);
d = (x./xsum)*max( xsum-gamma, 0 );

end
