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

file          = 'mulcorner.png';

num_paths     = 100;
num_initpaths = num_paths/10;
recal_after   = num_paths/10;

num_tests     = 1;
times         = zeros(num_tests, 1);
errors        = zeros(num_tests, 1);

param.p       = 1;  % We are using the l^p norm.
param.alpha   = 1;  % Alpha weights towards sparsity of the signal.
param.beta    = 1;  % Beta weights towards sparsity of gradient.
param.mu      = .01;  % Parameter on the fidelity term.
param.lambda1 = .1; % Coefficient on the regular constraint.
param.lambda2 = 1;  % Coefficient on the gradient constraints.
param.N       = 1;  % Number of inner loops.
param.tol     = 1/255; % We iterate until the rel. err is under this.
param.maxiter = 100; % Split Bregman performs this many iterations at most.

view_profile  = false;
show_all_fig  = false;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Do not touch below here unless you know what you are doing. %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if view_profile, profile on; end

%% Read our image in.
u_image = rgb2gray(imread(file));
dim = size(u_image);

for i = 1:num_tests

%% Generate the line-segment paths that we collect data from.
paths = generatePaths(num_initpaths, dim, 'randombounce', [80 15]);

%% Compute A0, our path matrix, convert u to a vector, and compute Au=g.
[A u g] = generateAug(u_image, paths);

%% Now run the Split Bregman Algorithm to reconstruct u from A and g.
uguess = zeros(prod(dim), 1);
[uguess err energy] = splitBregmanSolve( A, g, uguess, dim, param );

img_guess = reshape(uguess, dim);
points = segmentImg(img_guess,dim);

tic;

for j = num_initpaths+1:recal_after:num_paths

    newpaths = generatePaths(recal_after, dim, 'centered', points);
    paths = [paths ; newpaths];
    
    [Anew u gnew] = generateAug(u_image, newpaths);
    
    A = [A ; Anew];
    g = [g ; gnew];

    [uguess err energy] = splitBregmanSolve( A, g, uguess, dim, param );

    img_guess = reshape(uguess, dim);
    points = segmentImg(img_guess,dim);
    
    %[row,col] = find(img_guess == max(img_guess(:)));
    %coords = [row dim(2)-col];
    %centers = reshape(coords, 1, numel(coords));
    
end

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
title('Original Image');

subplot(subplot_rows,subplot_cols,2);
imagesc(img_guess);
title({'Reconstructed Image ', strcat('Solve Time = ',' ', num2str(solveTime), 's')});

subplot(subplot_rows,subplot_cols,3);
weights = compute_paths(paths,dim);
imagesc(weights);
title({strcat(num2str(num_paths), ' Paths'),'Adaptive Paths'});

subplot(subplot_rows,subplot_cols,5);
plot(err);
title('Error');

subplot(subplot_rows,subplot_cols,4);
plot(energy);
title('Energy');

subplot(subplot_rows,subplot_cols,6);
imagesc(reshape(abs(u-uguess), dim));
title(strcat('True Error = ', num2str(trueError)));

hold off

end % end of for loop for each test

if view_profile, profile viewer; end