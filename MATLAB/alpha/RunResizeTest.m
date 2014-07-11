clc; clear all; close all;

dim = 50;
scale_factor = .5;
num_paths = 2500;

alpha = 1;
beta = 1;
mu = 1;
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

u = rgb2gray(imread(file));
[m n] = size(u);

paths = generate_paths(num_paths, [m n], 'bouncy');
smallpaths = (1-scale_factor).*paths;
largepaths = (1+scale_factor).*paths;
weights = compute_paths(paths,[m n]);
[A u ugrad g] = generate_Aug_from_image(u, paths);
smallA = generate_Aug_from_image(zeros((1-scale_factor)*m,(1-scale_factor)*n), smallpaths);
largeA = generate_Aug_from_image(zeros((1+scale_factor)*m,(1+scale_factor)*n), largepaths);

Phi1 = @(u) u;
Phi2 = @(u) directional_gradient_x(u, m, n);
Phi3 = @(u) directional_gradient_y(u, m, n);
sPhi2 = @(u) directional_gradient_x(u, (1-scale_factor)*m, (1-scale_factor)*n);
sPhi3 = @(u) directional_gradient_y(u, (1-scale_factor)*m, (1-scale_factor)*n);
lPhi2 = @(u) directional_gradient_x(u, (1+scale_factor)*m, (1+scale_factor)*n);
lPhi3 = @(u) directional_gradient_y(u, (1+scale_factor)*m, (1+scale_factor)*n);

[uguess errplot energyplot iterplot] = ...
                genSplitBregman_step1solver( Phi1, Phi2, Phi3, A, g, m, n, alpha, beta, mu, lambda1, lambda2, tol, N);
            
[smalluguess errplot energyplot iterplot] = ...
                genSplitBregman_step1solver( Phi1, sPhi2, sPhi3, smallA, g, (1-scale_factor)*m, (1-scale_factor)*n, alpha, beta, mu, lambda1, lambda2, tol, N);
            
[largeuguess errplot energyplot iterplot] = ...
                genSplitBregman_step1solver( Phi1, lPhi2, lPhi3, largeA, g, (1+scale_factor)*m, (1+scale_factor)*n, alpha, beta, mu, lambda1, lambda2, tol, N);

error = norm(u - uguess) / norm(u)

u      = reshape(u,dim,dim);
uguess = reshape(uguess,dim,dim);
smalluguess = reshape(smalluguess,(1-scale_factor)*dim,(1-scale_factor)*dim);
largeuguess = reshape(largeuguess,(1+scale_factor)*dim,(1+scale_factor)*dim);
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
imagesc(smalluguess);
title('Scaled down')

subplot(2,3,5);
imagesc(largeuguess);
title('Scaled up')

% [u uguess]
toc;
hold off
profile viewer;

path_lengths = zeros(num_paths,1);
for i = 1:num_paths
	path = paths(i,:);
	path_lengths(i) = sqrt( (path(3)-path(1))^2 + (path(2) - path(4))^2 );
end
