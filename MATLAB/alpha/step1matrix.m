
function result = step1matrix(mu, lambda1, lambda2, A, v, m, n)
	[dx dy] = directional_gradient(v, m, n);
	term1 = mu*A'*(A*v);
	term2 = lambda1*v;
	term3 = lambda2*directional_gradient_transpose(dx, m, n);
	[ ~, term4 ] = directional_gradient_transpose(dy, m, n);
	term4 = lambda2*term4;
	result = term1 + term2 + term3 + term4;
end