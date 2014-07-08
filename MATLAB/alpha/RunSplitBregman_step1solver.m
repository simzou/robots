clc; clear all;
profile on;
tic;
dim = 10;
num_paths = 20;

file = strcat('test', int2str(dim), '.png');

u = rgb2gray(imread(file));
[m n] = size(u);

paths = generate_paths(num_paths, [m n], 'bouncy');
[A u ugrad g] = generate_Aug_from_image(u, paths);

Phi1 = @(u) u;
Phi2 = @(u) directional_gradient_x(u, m, n);
Phi3 = @(u) directional_gradient_y(u, m, n);

uguess = genSplitBregman_step1solver( Phi1, Phi2, Phi3, A, g, m, n);

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

%[u uguess]
toc;
profile viewer;
hold off
