clc; clear all;
profile on;
tic;

file_path = 'test10.png';
num_paths = 20;

u = rgb2gray(imread(file_path));
[m n] = size(u);

paths = generate_paths(num_paths, [m n], 'bouncy');
[A u ugrad g] = generate_Aug_from_image(u, paths);
u = double(u);

Phi1 = @(u) u;
Phi2 = @(u) iso_gradient(u, m, n);

uguess = genSplitBregmanIso( Phi1, Phi2, A, g, m, n);

error  = norm(u-uguess)
u      = reshape(u,m,n);
uguess = reshape(uguess,m,n);

hold on

subplot(1,2,1);
imshow(u);
title('Original Image')

subplot(1,2,2);
imshow(uguess);
title('Reconstructed Image')

toc;
profile viewer;
hold off