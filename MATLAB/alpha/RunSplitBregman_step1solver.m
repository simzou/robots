clc; clear all;

dim = 20;
num_paths = 200;

profile on;
tic;
paths = generate_paths(num_paths, [dim dim], 'bouncy');

filename = strcat('test', int2str(dim), '.png');
paths = generate_paths(num_paths, [dim dim], 'bouncy');
[A u ugrad g] = generate_Aug_from_image(filename, paths);
u = double(u);

m = dim;
n = dim;

Phi1 = @(u) u;
Phi2 = @(u) directional_gradient_x(u, m, n);
Phi3 = @(u) directional_gradient_y(u, m, n);

uguess = genSplitBregman_step1solver( n*n, Phi1, Phi2, Phi3, A, g, m, n);

error  = norm(u-uguess)
u      = reshape(u,dim,dim);
uguess = reshape(uguess,dim,dim);

hold on

subplot(1,2,1);
imshow(u);
title('Original Image')

subplot(1,2,2);
imshow(uguess);
title('Reconstructed Image')

[u uguess]
toc;
profile viewer;
hold off
