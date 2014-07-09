clc; clear all;
profile on;
tic;
dim = 25;
num_paths = 100;
paths = generate_paths(num_paths, [dim dim], 'bouncy');
%for i = 1:dim
%    paths(i,:) = [0 i-.5 dim i-.5];
%    paths(i+dim,:) = [i-.5 0 i-.5 dim];
%end

filename = strcat('test', int2str(dim), '.png');
%paths = generate_paths(num_paths, [dim dim], 'bouncy');
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
imagesc(u);
title('Original Image')

subplot(1,2,2);
imagesc(uguess);
title('Reconstructed Image')

colormap gray

[u uguess]
toc;
profile viewer;
hold off
