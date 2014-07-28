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

file          = 'SheppLogan128.png';

num_tests     = 1;
times         = zeros(num_tests, 1);
errors        = zeros(num_tests, 1);

param.tol       = -.01;
param.maxpaths  = 200;
param.stepsize  = 10;
num_initpaths   = param.maxpaths/20;

view_profile  = false;
show_all_fig  = false;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Do not touch below here unless you know what you are doing. %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if view_profile profile on; end

%% Read our image in.
u_image = rgb2gray(imread(file));
dim = size(u_image);

for i = 1:num_tests
tic;
    
%% Generate the line-segment paths that we collect data from.
initpaths = generatePaths(num_initpaths, dim, 'randombounce');

%% Compute A0, our path matrix, convert u to a vector, and compute Au=g.
[A, u, g] = generateAug(u_image, initpaths);

%% Now run the Split Bregman Algorithm to reconstruct u from A and g.
uguess = zeros(prod(dim), 1); uold = uguess;
[uguess, ~, energy] = splitBregmanSolve( A, g, uguess, dim, param );

initerr = norm(u-uguess) / norm(u);
initenergy = energy(end);

%% Run the adaptive reconstruction.
[uguess paths err energy] = adaptiveMapping(uguess, u_image, initpaths, param);

%% Collect some more results.

err = [initerr ; err];
energy = [initenergy ; energy];

times(i)=toc;

solveTime = times(i);
trueError = norm(u-uguess) / norm(u);
errors(i) = trueError;

%% Now plot our findings.
img = reshape(u, dim);
img_guess = reshape(uguess, dim);

if show_all_fig, figure; end

subplot_rows = 2;
subplot_cols = 3;

hold on

colormap gray;
subplot(subplot_rows,subplot_cols,1);
imagesc(img);
title('Original Image');

subplot(subplot_rows,subplot_cols,2);
imagesc(img_guess);
title({'Reconstructed Image ', strcat('Solve Time =',[' ' num2str(solveTime)], 's')});

subplot(subplot_rows,subplot_cols,3);
weights = compute_paths(paths,dim);
imagesc(weights);
title({strcat(num2str(size(paths,1)),' Adaptive Paths'),...
    strcat(num2str(param.stepsize),' Paths/Iter'), ...
    strcat(num2str(size(paths,1)/prod(dim)), ' Path to Pixel Ratio')});

subplot(subplot_rows,subplot_cols,4);
plot(energy);
title({'Energy', strcat('Iter =', [' ' num2str(size(err,1))])});

subplot(subplot_rows,subplot_cols,5);
plot(err);
title('Error');

subplot(subplot_rows,subplot_cols,6);
imagesc(reshape(abs(u-uguess), dim));
title({strcat('True Error =', [' ' num2str(trueError)]), ...
    strcat('Tol =', [' ' num2str(param.tol)])});

hold off

end % end of for loop for each test

if view_profile, profile viewer; end
