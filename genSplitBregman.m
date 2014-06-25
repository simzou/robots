function u = genSplitBregman(A, b, lambda, tol, N )

len    = length(b);
u      = zeros(len, 2);
u(:,2) = ones(len, 1);
d      = zeros(len, 1);
c      = zeros(len, 1);

% Begin the iterative process and continue until we are below
% a certain threshold.
while norm( u(:,2)-u(:,1) ) > tol
    
    % Save our previous iteration's value for u.
    u(:,1) = u(:,2);
    
    for i = 1:N
        
        % Perform step 1 of the algorithm.        
        u(:,2) = fminunc( @(u)norm(A*u-b)^2+norm(d-u-c)^2, u(:,1) );
        
        % Perform step 2 of the algorithm.
        d = shrink( u(:,2)+c, 1/lambda ); 
        
    end
    
    % Update c.
    c = c + ( -d(3) );
    
end

end

function d = shrink( x, gamma )
% Helper function carries out step 2 of the algorithm.

xsum = sum(x);
d = (x./xsum)*max( xsum-gamma, 0 );

end
