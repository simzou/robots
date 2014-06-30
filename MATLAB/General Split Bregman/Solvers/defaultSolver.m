function solver = defaultSolver( H, Phi, lambda )
% Given convex functions H and Phi, and parameter lambda, we create a
% function that uses fminsearch to minimize
%     H(u)+(lambda/2)*||d-Phi(u)-b||^2
% for u given b, d, and an initial guess for u.
%

options = optimset('Display','off');

solver = @(b, d, uguess) fminsearch( @(u) H(u)+(lambda/2)*...
    norm(d-Phi(u)-b)^2, uguess, options );

end