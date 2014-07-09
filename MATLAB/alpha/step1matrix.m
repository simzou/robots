function result = step1matrix(mu, lambda1, lambda2, A, u, m, n)
% function to minimize in split Bregman
% includes gradient 
% We want to minimize 
% result = a|u| + b|grad_x(u)| + b|grad_y(u)| st Au = g
% 		 = a|u| + b|grad_x(u)| + b|grad_y(u)| + mu/2 || Au - g ||^2
% which is now translated below to the function
%		 = (mu*A'A + lambda1*I + lambda2*grad_x'*grad_x + lambda2*grad_y'*grad_y)*u
% 
% mu, lambda1, lambda2 are constants determining scale/accuracy
% A is the matrix of the paths
% u is the input variable that we aim to minimize, which will eventually be a reconstruction
% m and n are the dimensions of the image u and m*n should be the number of columns in A

% result is a vector the same size of u

% depends on directional_gradient.m and directional_gradient_transpose.m
	%disp('step1matrix start')
	%keyboard
	[dx dy] = directional_gradient(u, m, n);
	term1 = mu*A*u;
	term2 = lambda1*u;
	term3 = lambda2*directional_gradient_transpose(dx, m, n);
	[ ~, term4 ] = directional_gradient_transpose(dy, m, n);
	term4 = lambda2*term4;
	result = term1 + term2 + term3 + term4;
end