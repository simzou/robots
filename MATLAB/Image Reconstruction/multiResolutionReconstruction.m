% reconstructImage.m A compressed sensing reconstruction using Split Bregman
%
% Authors: Ke Yin, Mitchell Horning, Matthew Lin, Sid Srinivasan, Simon Zou 
%
%% Summary
%
% This script performs a compressed sensing reconstruction of an image 
% from data collected from a set of line segments across the image. For 
% each line segment, the sum of the pixel values weighted by the 
% proportion of the line segment that is in each pixel is the only piece 
% of data that is recorded, other than the line segments themselves. We 
% then run the Split Bregman algorithm to reconstruct the image.
% 
% Technically, let u be a vector representing an mxn image. Then, 
% construct a num_paths x m*n matrix A, where row i contains the portion 
% of the i'th path that each pixel in u contains. Let g be the vector 
% where g(i) is the sum of the weighted pixel values along path i. Then, 
% we have the linear system
%
%     Au=g.
% 
% We then attempt to reconstruct u, knowing only A and g by using the 
% Split Bregman algorithm on the minimization problem
%
%     argmin_u alpha*|u|+beta*(|grad_x(u)|+|grad_y(u)|)+(mu/2)*||Au-g||^2, 
%
% where |.| is the l^p quasi-norm, where 0<p<=1, and ||.|| is the l^2 norm.
%
%% Usage:
%
% file: A str with the file name of the image to be reconstructed.
%
% num_paths: The number of paths to collect data along.
% path_style: How to generate the paths. Options are described in 
%     generatePaths.m.
%
% param: struct to hold the parameters for Split Bregman. Described below.
%
%% Output:
%
% The script outputs a figure with 6 subplots. These are the original
% image, the reconstructed image, the paths taken across the image, a plot
% of the relative error against the previous guess after each iteration, a 
% plot of the energy after each iteration, and the relative error against 
% the true image after the algorithm has been run and the difference
% between the pixel values of the original image and the guess.
%

%% Define the file path, paths options, and Split Bregman parameters.
clc; clear all; close all;

file          = 'testbed03_aligned_70x90.png';

num_paths     = 50;
num_tests     = 1;
times         = zeros(num_tests, 1);
errors        = zeros(num_tests, 1);
path_style    = 'points';
num_reconstr  = 1;

param.p       = 1/2;  % We are using the l^p norm.
param.alpha   = 1;  % Alpha weights towards sparsity of the signal.
param.beta    = 1;  % Beta weights towards sparsity of gradient.
param.mu      = 1;  % Parameter on the fidelity term.
param.lambda1 = .1; % Coefficient on the regular constraint.
param.lambda2 = 1;  % Coefficient on the gradient constraints.
param.N       = 1;  % Number of inner loops.
param.tol     = 1/255; % We iterate until the rel. err is under this.
param.maxiter = 100; % Split Bregman performs this many iterations at most.
param.makegif = false; % determines if a gif of the iterations will be made
param.gifname = 'iter_50.gif';

view_profile  = true;
show_all_fig  = false;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Do not touch below here unless you know what you are doing. %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if view_profile, profile on; end

%% Read our image in.
u_image = rgb2gray(imread(file));
dim = size(u_image);

for i = 1:num_tests
	paths = generatePaths(num_paths, dim, path_style);
	[A u g] = generateAug(u_image, paths);
	err = [];
	energy = [];
	tic
	for j = 1:num_reconstr
		scaling_factor = 2^(num_reconstr-j);
		scaled_dim = 1/scaling_factor * dim;
		if j == 1
			u0 = zeros(prod(scaled_dim),1);
		else
			u0 = resizeu(partial_uguess, scaled_dim_old, 2);
		end

		%% Generate the line-segment paths that we collect data from.
		partial_paths = paths(1:j*num_paths/num_reconstr, :);
		scaled_partial_paths = 1/scaling_factor * partial_paths;

		%% Compute A, our path matrix, convert u to a vector, and compute Au=g.
		partial_A = generateAug(zeros(scaled_dim), scaled_partial_paths);
		partial_A = 1/scaling_factor * partial_A;
		% partial_g = 1/scaling_factor * g(1:j*num_paths/num_reconstr, :);
		partial_g = g(1:j*num_paths/num_reconstr, :);

		%% Now run the Split Bregman Algorithm to reconstruct u from A and g.
		[partial_uguess partial_err partial_energy] = splitBregmanSolve( partial_A, partial_g, u0, scaled_dim, param );
		err = [err; partial_err];
		energy = [energy; partial_energy];

		scaled_dim_old = scaled_dim;
		%imagesc(reshape(partial_uguess, scaled_dim)); colormap gray;
		%pause;

	end

	uguess = partial_uguess;

	times(i)=toc;
	solveTime = times(i);
	trueError = norm(u-uguess) / norm(u);
	errors(i) = trueError;

	%% Now plot our results.

	img = reshape(u, dim);
	img_guess = reshape(uguess, dim);

	if show_all_fig, figure; end

	subplot_rows = 2;
	subplot_cols = 3;

	hold on

	colormap gray;
	subplot(subplot_rows,subplot_cols,1);
	imagesc(img);
	title(strcat('Original Image: ', num2str(dim(1)), 'x', num2str(dim(2))));

	subplot(subplot_rows,subplot_cols,2);
	imagesc(img_guess, [0 255]);
	title({'Reconstructed Image ', strcat('Solve Time = ', num2str(solveTime), 's')});

	subplot(subplot_rows,subplot_cols,3);
	weights = compute_paths(paths,dim);
	imagesc(weights);
	title({strcat(num2str(num_paths), ' Paths'), strcat(num2str(num_paths/prod(dim)), ' Path to Pixel Ratio')});

	subplot(subplot_rows,subplot_cols,5);
	plot(err);
	title(strcat('Error: ', num2str(size(err,1)), ' iterations'));

	subplot(subplot_rows,subplot_cols,4);
	plot(energy);
	title('Energy');

	subplot(subplot_rows,subplot_cols,6);
	imagesc(reshape(abs(u-uguess), dim));
	title(strcat('True Error = ', num2str(trueError)));

	hold off

end % end of for loop for each test

if view_profile, profile viewer; end