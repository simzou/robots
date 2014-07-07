function rhs = make_right_hand_side(lambda1, lambda2, lambda3, A, b, d, bx, dx, by, dy, g, m, n)

	term1 = lambda1 * A' * g;
	term2 = lambda2 * (d - b);
	[delx, ~] = directional_gradient_transpose(dx-bx, m, n);
	[~, dely] = directional_gradient_transpose(dy-by, m, n);
	term3 = lambda3 * delx;
	term4 = lambda3 * dely;

	rhs = term1 + term2 + term3 + term4;