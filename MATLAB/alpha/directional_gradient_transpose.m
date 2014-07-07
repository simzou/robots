function [dx,dy] = directional_gradient_transpose(u, m, n)
% computes a directional gradient
% takes in a 1-D vector (or 2-D) and dimensions of matrix A
% returns two matrices as vectors
% one is horizontal gradient and the other vertical gradient
% dx_ij = A_(i-1)j - A_ij, for the first column i-1 refers to the last column
% dy_ij = A_i(j-1) - A_ij, for the first row j-1 refers to the last row
	A = reshape(u, m, n);
	dx = [A(:,end) - A(:,1)  A(:,1:end-1) - A(:,2:end)];
	dy = [A(end,:) - A(1,:); A(1:end-1,:) - A(2:end,:)];
	dx = reshape(dx, m*n, 1);
	dy = reshape(dy, m*n, 1);
end