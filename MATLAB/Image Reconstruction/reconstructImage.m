%reconstructImage.m A compressed sensing reconstruction using Split Bregman
%
% Authors: Ke Yin, Mitchell Horning, Matthew Lin, Simon Zou
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
%      generatePaths.m.
%
% param: A struct to hold the parameters for Split Bregman.
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
clc; clear all; close all;

file          = 'test10.png';

num_paths     = 20;
path_style    = 'random';

param.p       = 1;
param.alpha   = 1;
param.beta    = 1;
param.mu      = 10;
param.lambda1 = .1;
param.lambda2 = 1;
param.N       = 1;
param.tol     = 1/250;
param.maxiter = 100;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Do not touch below here unless you know what you are doing. %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Read our image in.
u = rgb2gray(imread(file));
dim = size(u);

%% Generate the line-segment paths that we collect data from.
paths = generatePaths(num_paths, dim, path_style);

%% Compute A, our path matrix, convert u to a vector, and compute Au=g.
[A u g] = generateAug(u, paths);

%% Now run the Split Bregman Algorithm to reconstruct u from A and g.
u0 = zeros(prod(dim), 1);
[uguess err energy] = splitBregmanSolve( A, g, u0, dim, param );
trueError = norm(u-uguess) / norm(u);

%% Now plot our results.

u = reshape(u, dim);
u_guess = reshape(uguess, dim);

hold on

colormap gray;
subplot(2,3,1);
imagesc(u);
title('Original Image');

subplot(2,3,2);
imagesc(u_guess);
title('Reconstructed Image');

subplot(2,3,3);
weights = compute_paths(paths,dim);
imagesc(weights);
title('Paths');

subplot(2,3,5);
plot(err);
title('Error');

subplot(2,3,4);
plot(energy);
title('Energy');

subplot(2,3,6);
plot(u-uguess);
title(strcat('True Error = ',num2str(trueError)));

hold off
