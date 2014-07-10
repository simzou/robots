clc; clear all; close all;

dim = 75;
num_paths = 150;

alpha = 1;
beta = 1;
mu = 1;
lambda1 = .1;
lambda2 = 1;
tol = 1/256;
N = 1;

num_tests = 3;

file = strcat('test', int2str(dim), '.png');

uprime = rgb2gray(imread(file));
[m n] = size(uprime);


Phi1 = @(u) u;
Phi2 = @(u) directional_gradient_x(u, m, n);
Phi3 = @(u) directional_gradient_y(u, m, n);

errors = zeros(num_tests,1);
times  = zeros(num_tests,1);
iters  = zeros(num_tests,1);


for i = 1:num_tests
	tic;
	paths = generate_paths(num_paths, [m n], 'bouncy');
	[A u ugrad g] = generate_Aug_from_image(uprime, paths);
	[uguess errplot energyplot iterplot] = ...
	                genSplitBregman_step1solver( Phi1, Phi2, Phi3, A, g, m, n, alpha, beta, mu, lambda1, lambda2, tol, N);
	times(i) = toc;
	errors(i) = norm(u - uguess) / norm(u);
	iters(i) = size(errplot,1);
end

[times errors iters]