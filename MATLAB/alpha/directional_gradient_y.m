function dy = directional_gradient_y(u, m, n)
% computes a directional gradient
% takes in a 1-D vector (or 2-D) and dimensions of matrix A
% returns two matrices as vectors
% one is horizontal gradient and the other vertical gradient
% dx_ij = A_(i+1)j - A_ij, for the last column i+1 refers to the first column
% dy_ij = A_i(j+1) - A_ij, for the last row j+1 refers to the first row
	%keyboard
	A = reshape(u, m, n);
	dy = [A(2:end,:) - A(1:end-1,:); A(1,:) - A(end,:)];
	dy = reshape(dy, m*n, 1);
end