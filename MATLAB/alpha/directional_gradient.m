function [dx, dy] = directional_gradient(u, m, n)
% This function returns the gradients of the mxn image u in both the
% horizontal direction and the vertical direction. u is expected to be 
% input as a one dimensional vector. dx and dy are also one dimensional 
% vectors. The gradients are computed as
%
%     del_x u_{i,j} = u_{i,(j+1) % n} - u_{i,j}
%     del_x u_{i,j} = u_{(i+1) % m, j} - u_{i,j}
%

	A = reshape(u, m, n);
	dx = [A(:,2:end) - A(:,1:end-1)  A(:,1) - A(:,end)];
	dy = [A(2:end,:) - A(1:end-1,:); A(1,:) - A(end,:)];
	dx = reshape(dx, m*n, 1);
	dy = reshape(dy, m*n, 1);
end