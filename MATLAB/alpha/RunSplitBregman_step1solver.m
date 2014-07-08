clc; clear all;
dim = 50;
num_paths = 150;
paths = generate_paths(num_paths, [dim dim], 'bouncy');
filename = strcat('test', int2str(dim), '.png');
[A u ugrad g] = generate_Aug_from_image(filename, paths);
u = double(u);
%size(u)
m = dim;
n = dim;

% Del = -eye(n*n)+diag(ones(n*n-1,1),1);

Phi1 = @(u) u;
Phi2 = @(u) directional_gradient_x(u, m, n);
Phi3 = @(u) directional_gradient_y(u, m, n);

uguess = genSplitBregman_step1solver( n*n, Phi1, Phi2, Phi3, A, g, dim, dim);

[u uguess]