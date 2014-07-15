function u = solve_Laplace(f, dim, param)
% solve the linear equation
% (lambda1*I + lambda2*Laplace)u = f
% in square domain of size (m, n)
% where Laplace is the Laplace operator in 2D

cx = [-1 zeros(1, dim(2)-2) 1];
cxT = [-1 1 zeros(1, dim(2)-2)];
cy = [-1 zeros(1, dim(1)-2) 1]';
cyT = [-1 1 zeros(1, dim(1)-2)]';
Cx = zeros(dim);
Cy = zeros(dim);

for ii=1:dim(1)
	Cx(ii,:) = fft(cxT) .* fft(cx);
end

for jj=1:dim(2)
	Cy(:,jj) = fft(cyT) .* fft(cy);
end

F = reshape(f, dim);
U = ifft2(fft2(F)./(param.lambda1*ones(dim) + param.lambda2*(Cx+Cy)));
u = reshape(U, dim, 1);

end
