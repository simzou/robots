function grad_u = iso_gradient(u, m, n)
% Calculates grad(u)_i = sqrt(del_x(u)_i^2+del_y(u)_i^2)

[dx, dy] = directional_gradient(u, m, n);

grad_u = sqrt(dx.^2 + dy.^2);

end
