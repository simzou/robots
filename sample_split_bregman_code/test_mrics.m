%          test_mrics.m by Tom Goldstein  (tagoldst@math.ucla.edu)
%   This file is meant to demonstrate how to properly use mrics.m
%   When this script is run, it will first build a simple test image.  The
%   method then builds a sampling matrix, R, with entries randomly chosen 
%   to be 1 or 0.  The compressed sensing data is then computed using the
%   folrmula F = R.*fft2(image).  Gaussian noisy is added to the CS data.
%   Finally, the mrics method is used to reconstruct the image form the
%   sub-sampled K-Space data.

  
N = 128; % The image will be NxN
sparsity = .25; % use only 25% on the K-Space data for CS 
mu = .1;
lambda = .1;
gamma = mu/1000;

  % build an image of a square
image = zeros(N,N);
image(N/4:3*N/4,N/4:3*N/4)=255;
 
 % build the sampling matrix, R
R = rand(N,N);
R = double(R<sparsity);

 % Form the CS data

F = R.*fft2(image)/N;

% Recover the image
recovered = mrics(R,F, mu, lambda, gamma,10, 4);

% build a figure to display results
figure;
subplot(2,2,1);
imagesc(abs(image)); colormap('gray');
title('Original');
subplot(2,2,2);
imagesc(abs(R)); colormap('gray');
title('R');
subplot(2,2,3);
imagesc(abs(ifft2(F))); colormap('gray');
title('Set unknown to 0');
subplot(2,2,4);
imagesc(abs(recovered)); colormap('gray');
title('Split Bregman Recovery');