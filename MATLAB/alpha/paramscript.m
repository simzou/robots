clc; clear all;

dim = 20;
num_paths = 70;

alpha = 1;
beta = 1;
mu = 1;
lambda1 = .1;
lambda2 = .1;
tol = 0.01;
N = 1;
% 
% profile on;
% tic;
%for i = 1:dim
%    paths(i,:) = [0 i-.5 dim i-.5];
%    paths(i+dim,:) = [i-.5 0 i-.5 dim];
%end

file = strcat('test', int2str(dim), '.png');

u = rgb2gray(imread(file));
[m n] = size(u);

paths = generate_paths(num_paths, [m n], 'bouncy');
weights = compute_paths(paths,[m n]);
[A u ugrad g] = generate_Aug_from_image(u, paths);

Phi1 = @(u) u;
Phi2 = @(u) directional_gradient_x(u, m, n);
Phi3 = @(u) directional_gradient_y(u, m, n);

iter = 20;

uguess     = zeros(m*n, iter, iter, iter);
errplot    = zeros(iter, iter, iter);
energyplot = zeros(iter, iter, iter);
iterplot   = zeros(iter, iter, iter);
times      = zeros(iter, iter, iter);

for i = 1:1:iter
    for j = 1:1:iter
        for k = 1:1:iter
            
            mu      = 0.1*i;
            lambda1 = 0.1*j;
            lambda2 = 0.1*k;
            
            tic;
            
            [uguess(:,i,j,k) error energy iterplot(i,j,k)] = ... 
                genSplitBregman_step1solver( Phi1, Phi2, Phi3, A, g, m, n, alpha, beta, mu, lambda1, lambda2, tol, N);
            
            errplot(i,j,k) = norm(u-uguess(:,i,j,k))/norm(u);
            energyplot(i,j,k) = energy(end);
            
            times(i,j,k) = toc; 
            
            [i j k]
        end
    end
end


% u      = reshape(u,dim,dim);
% uguess = reshape(uguess,dim,dim);
% 
% hold on
% 
% colormap gray;
% subplot(2,3,1);
% imagesc(u);
% title('Original Image')
% 
% subplot(2,3,2);
% imagesc(uguess);
% title('Reconstructed Image')
% 
% subplot(2,3,3);
% imagesc(weights);
% title('Paths')
% 
% subplot(2,3,4);
% plot(errplot);
% title('Error')
% 
% subplot(2,3,5);
% plot(energyplot);
% title('Energy')
% 
% % [u uguess]
% toc;
% hold off
% profile viewer;
