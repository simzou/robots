function u = solve_Laplace(f, lambda1, lambda2, m, n)
% solve the linear equation
% (lambda1*I + lambda2*Laplace)u = f
% in square domain of size (m, n)
% where Laplace is the Laplace operator in 2D
cx = [-1 zeros(1, n-2) 1];
cxT = [-1 1 zeros(1, n-2)];
cy = [-1 zeros(1, m-2) 1]';
cyT = [-1 1 zeros(1, m-2)]';
Cx = zeros(m, n);
Cy = zeros(m, n);
for ii=1:m
	Cx(ii,:) = fft(cxT) .* fft(cx);
end
for jj=1:n
	Cy(:,jj) = fft(cyT) .* fft(cy);
end
F = reshape(f, m, n);
U = ifft2(fft2(F)./(lambda1*ones(m,n) + lambda2*(Cx+Cy)));
u = reshape(U, m*n, 1);
end
