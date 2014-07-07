function [dx,dy] = directional_gradient_transpose(u, m, n)
	A = reshape(u, m, n);
	dx = [A(:,end) - A(:,1)  A(:,1:end-1) - A(:,2:end)];
	dy = [A(end,:) - A(1,:); A(1:end-1,:) - A(2:end,:)];
	dx = reshape(dx, m*n, 1);
	dy = reshape(dy, m*n, 1);
end