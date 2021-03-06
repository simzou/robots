clc; clear all; close all;

dim = 50;
num_paths = 200;

alpha = 1;
beta = 1;
mu = .01;
lambda1 = .1;
lambda2 = 1;
tol = 1/256;
N = 1;

profile on;
tic;
%for i = 1:dim
%    paths(i,:) = [0 i-.5 dim i-.5];
%    paths(i+dim,:) = [i-.5 0 i-.5 dim];
%end

file = strcat('test', int2str(dim), '.png');

uorig = rgb2gray(imread(file));
[m n] = size(uorig);
unoise = imnoise(uorig, 'gaussian');
paths = generate_paths(num_paths, [m n], 'randombounce');
weights = compute_paths(paths,[m n]);
[A u ugrad g] = generate_Aug_from_image(unoise, paths);

Phi1 = @(u) u;
Phi2 = @(u) directional_gradient_x(u, m, n);
Phi3 = @(u) directional_gradient_y(u, m, n);

[uguess errplot energyplot iterplot] = ...
                genSplitBregman_step1solver( Phi1, Phi2, Phi3, A, g, m, n, alpha, beta, mu, lambda1, lambda2, tol, N);

uorig = double(reshape(uorig, dim*dim,1));
unoise = double(reshape(unoise, dim*dim,1));  
errororig = norm(uorig - uguess) / norm(uorig)
errornoise = norm(unoise - uguess) / norm(unoise)

u      = reshape(u,dim,dim);
uguess = reshape(uguess,dim,dim);
unoise = reshape(unoise,dim,dim);
uorig  = reshape(uorig,dim,dim);

hold on

colormap gray;
subplot(2,3,1);
imagesc(uorig);
title('Original Image')

subplot(2,3,2);
imagesc(uguess);
title('Reconstructed Image')

subplot(2,3,3);
imagesc(weights);
title('Paths')

subplot(2,3,4);
imagesc(unoise);
title('Image with noise')

% subplot(2,3,4);
% plot(errplot);
% title('Error')

% subplot(2,3,5);
% plot(energyplot);
% title('Energy')

% [u uguess]
toc;
hold off
profile viewer;

path_lengths = zeros(num_paths,1);
for i = 1:num_paths
	path = paths(i,:);
	path_lengths(i) = sqrt( (path(3)-path(1))^2 + (path(2) - path(4))^2 );
end
