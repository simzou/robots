clc; clear all;
profile on;
tic;
dim = 10;
num_paths = 20;
paths = generate_paths(num_paths, [dim dim], 'bouncy');
weights = compute_paths(paths,[dim dim]);
%A = rand(num_paths, dim*dim);

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
colormap gray;
subplot(1,3,1);
imagesc(u);
title('Original Image')

subplot(1,3,2);
imagesc(uguess);
title('Reconstructed Image')

subplot(1,3,3);
imagesc(weights);
title('Paths')

[u uguess]
toc;
hold off
profile viewer;