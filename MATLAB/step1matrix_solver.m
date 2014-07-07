function u = step1matrix_solver(mu, lambda1, lambda2, A, m, n, rhs)
	step1 = @(v) step1matrix(mu, lambda1, lambda2, A, v, m, n);
	tol = 10e-8;
	max_iter = 1000;
	preconditioner = @(f) solve_Laplace(f, lambda1, lambda2, m, n);
	u = pcg(step1, rhs, tol, max_iter, preconditioner);
end
