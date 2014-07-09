clc; clear all;

dim = 50;
num_paths = 200;
mu = 1;
lambda1 = .1;
lambda2 = .1;
tol = 0.01;
N = 1;

profile on;
tic;

paths = generate_paths(num_paths, [dim dim], 'bouncy');
weights = compute_paths(paths,[dim dim]);

file = strcat('test', int2str(dim), '.png');

u = rgb2gray(imread(file));
[m n] = size(u);

paths = generate_paths(num_paths, [m n], 'bouncy');
[A u ugrad g] = generate_Aug_from_image(u, paths);

Phi1 = @(u) u;
Phi2 = @(u) directional_gradient_x(u, m, n);
Phi3 = @(u) directional_gradient_y(u, m, n);

uguess = genSplitBregman_step1solver( Phi1, Phi2, Phi3, A, g, m, n)

error  = norm(u-uguess);
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

% [u uguess]
toc;
hold off
profile viewer;
