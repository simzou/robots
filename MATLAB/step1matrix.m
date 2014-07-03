function result = step1matrix(mu, lambda1, lambda2, A, u, m, n)
	[dx dy] = directional_gradient(u, m, n);
	term1 = mu*A'*(A*u);
	term2 = lambda1*u;
	term3 = lambda2*directional_gradient_transpose(dx, m, n);
	[ [] term4 ] = lambda2*directional_gradient_transpose(dy, m, n)
	result = term1 + term2 + term3 + term4;
end