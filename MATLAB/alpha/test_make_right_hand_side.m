dim = 50;
num_paths = 150;
paths = generate_paths(num_paths, [dim dim], 'bouncy');
filename = strcat('test', int2str(dim), '.png');
[A u ugrad g] = generate_Aug_from_image(filename, paths);
u = double(u);
size(u)
mu = 10;
lambda1 = 10;
lambda2 = 10;
lambda3 = 10;
m = dim;
n = dim;

rhs = make_right_hand_side(lambda1, lambda2, lambda3, A, b, d, g, m, n)