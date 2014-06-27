function solver = defaultSolver( H, Phi, lambda )

options = optimset('Display','off');

solver = @(b, d, uguess) fminsearch( @(u) H(u)+(lambda/2)*...
    norm(d-Phi(u)-b)^2, uguess, options );

end