% Generates random A matrix (50x100) and sparse u matrix (1000x1), which has 20
% nonzero values between 1 and 100. Then calculates Au = b and saves these variables
% to a file samplex.mat. To be used for testing the compressed sensing algorithm

clear all; clc;
imax = 100;
samples = 50;
usize = 1000;
num_nonzeros = 20;
num_samples = 5;

for j = 1:num_samples
	A = rand(samples, usize);
	u = zeros(usize,1);

	% setting a few things to be nonzero
	for i = 1:num_nonzeros
		u(randi(usize)) = randi(imax);
	end

	b = A*u;
	% visualizing the sparse vector
	% colormap gray;
	% imagesc(u)
	filename = strcat('sample',num2str(j),'.mat');
	save(filename);
end