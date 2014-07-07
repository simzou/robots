function [dx, dy] = directional_gradient(u, m, n)
	A = reshape(u, m, n);
	dx = [A(:,2:end) - A(:,1:end-1)  A(:,1) - A(:,end)];
	dy = [A(2:end,:) - A(1:end-1,:); A(1,:) - A(end,:)];
	dx = reshape(dx, m*n, 1);
	dy = reshape(dy, m*n, 1);
end