function [unew dnew] = genSplitBregman( Phi, H, tol, N )

k=1;

while norm( u(k)-u(k-1) ) > tol
    for i = 1:N
        
        [~,u(k+1)] = min( H(u)+(lambda/2)*norm( d(k)-Phi(u)-b(k) )^2 );
        d(k+1) = shrink( Phi(u)+b(k), 1/lambda ); 
        
    end
    
    b(k+1) = b(k)+( Phi(u(k+1))-d(k+1) );
    k = k+1;
    
end

function d = shrink( x, gamma )

xsum = sum(x);
d = (x./xsum)*max( xsum-gamma, 0 );

end
