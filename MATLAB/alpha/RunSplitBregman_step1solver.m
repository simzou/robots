clc; clear all;

dim = 50;
<<<<<<< HEAD
num_paths = 200;

alpha = 1;
beta = 1;
=======
num_paths = 100;
>>>>>>> a81609115cea918178a6fb5b8426e7ac4bc7ad21
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

[uguess errplot energyplot] = genSplitBregman_step1solver( Phi1, Phi2, Phi3, A, g, m, n, alpha, beta, mu, lambda1, lambda2, tol, N);

u      = reshape(u,dim,dim);
uguess = reshape(uguess,dim,dim);

hold on
colormap gray;
subplot(2,3,1);
imagesc(u);
title('Original Image')

subplot(2,3,2);
imagesc(uguess);
title('Reconstructed Image')

subplot(2,3,3);
imagesc(weights);
title('Paths')

subplot(2,3,4);
plot(errplot);
title('Error')

subplot(2,3,5);
plot(energyplot);
title('Energy')

% [u uguess]
toc;
hold off
profile viewer;
