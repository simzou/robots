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

file          = 'testbed03_aligned_70x90.png'; % Image file for error checking
downscale     = 10; % Factor to rescale reconstruction by

times         = [];
errors        = [];
path_style    = 'robot';

param.p       = 1/2;  % We are using the l^p norm.
param.alpha   = 0;  % Alpha weights towards sparsity of the signal.
param.beta    = 1;  % Beta weights towards sparsity of gradient.
param.mu      = 1;  % Parameter on the fidelity term.
param.lambda1 = .1; % Coefficient on the regular constraint.
param.lambda2 = 1.5

;  % Coefficient on the gradient constraints.
param.N       = 1;  % Number of inner loops.
param.tol     = 1/255; % We iterate until the rel. err is under this.
param.maxiter = 100; % Split Bregman performs this many iterations at most.

use_robot_data = false;

view_profile  = false;
show_all_fig  = false;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Do not touch below here unless you know what you are doing. %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if view_profile, profile on; end

%% Read our image in.

u_image = rgb2gray(imread(file));

dim = [900 700]; % Size of the testbed at camera resolution
dim = dim/downscale; % New size for lower resolution reconstruction

if size(u_image)~=dim
    u_image = zeros(dim);
end

%% Generate paths and g from .csv file
[paths g] = paths_g_from_csv('test.csv');
num_paths = size(paths,1);
% g is scaled to more closely match the values expected in g
scale = .22*downscale;
g = g/scale;

% USING ROBOT COLLECTED DATA

%% Compute A, our path matrix, convert u to a vector, and compute Au=g.
paths = paths/downscale;
[A, u, g_from_image] = generateAug(u_image, paths);

%% Now run the Split Bregman Algorithm to reconstruct u from A and g.
u0 = zeros(prod(dim), 1);
tic;
if use_robot_data
    [uguess err energy] = splitBregmanSolve( A, g, u0, dim, param );
else
    [uguess err energy] = splitBregmanSolve( A, g_from_image, u0, dim, param );
end
times=toc;
solveTime = times;
trueError = norm(u-uguess) / norm(u);
errors = trueError;

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
imagesc(img_guess,[0 255]);
% imagesc(img_guess);
title({'Reconstructed Image ', strcat('Solve Time = ', [' ' num2str(solveTime)], 's')});

subplot(subplot_rows,subplot_cols,3);
weights = compute_paths(paths,dim);
imagesc(weights);
title({strcat(num2str(num_paths), ' Paths'), strcat(num2str(num_paths/prod(dim)), ' Path to Pixel Ratio')});

subplot(subplot_rows,subplot_cols,5);
plot(err);
title('Error');

subplot(subplot_rows,subplot_cols,4);
plot(energy);
title('Energy');

subplot(subplot_rows,subplot_cols,6);
imagesc(reshape(abs(u-uguess), dim));
title(strcat('True Error =', [' ' num2str(trueError)]));

hold off



if view_profile, profile viewer; end