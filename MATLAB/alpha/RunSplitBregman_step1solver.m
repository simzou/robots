clc; clear all; close all;

% dim = 50;

num_paths = 100;


p = .5;
alpha = 1;
beta = 1;
mu = .1;
lambda1 = .1;
lambda2 = 1;
tol = 1/256;
N = 1;

profile on;
%tic;
%for i = 1:dim
%    paths(i,:) = [0 i-.5 dim i-.5];
%    paths(i+dim,:) = [i-.5 0 i-.5 dim];
%end

%file = strcat('test', int2str(dim), '.png');

file = 'test50.png';

u = rgb2gray(imread(file));
[m n] = size(u);

paths = generate_paths(num_paths, [m n], 'randombounce');
weights = compute_paths(paths,[m n]);
[A u ugrad g] = generate_Aug_from_image(u, paths);

Phi1 = @(u) u;
Phi2 = @(u) directional_gradient_x(u, m, n);
Phi3 = @(u) directional_gradient_y(u, m, n);

tic;
[uguess errplot energyplot iterplot] = ...
                genSplitBregman_step1solver( Phi1, Phi2, Phi3, A, g, m, n, alpha, beta, mu, lambda1, lambda2, tol, N);            
toc;
tic;
[uguessp errplotp energyplotp iterplotp] = ...
                genSplitBregman_step1solver_pshrink( Phi1, Phi2, Phi3, A, g, m, n, p, alpha, beta, mu, lambda1, lambda2, tol, N);
toc;
            
error = norm(u - uguess) / norm(u)
errorp = norm(u - uguessp) / norm(u)

u      = reshape(u,m,n);
uguess = reshape(uguess,m,n);
uguessp = reshape(uguessp,m,n);

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
imagesc(uguessp);
title('Reconstructed with p-shrink')

subplot(2,3,5);
plot(energyplot);
title('Energy')

subplot(2,3,6);
plot(energyplotp);
title('Energy with p-shrink')

% [u uguess]
%toc;
hold off
profile viewer;

path_lengths = zeros(num_paths,1);
for i = 1:num_paths
	path = paths(i,:);
	path_lengths(i) = sqrt( (path(3)-path(1))^2 + (path(2) - path(4))^2 );
end
