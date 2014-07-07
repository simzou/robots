colormap gray;
grid_size = [50 70];
paths = generate_paths(1000, grid_size, []);

weights = zeros(grid_size);

for i = 1:size(paths,1)
	weights = weights + path_weights(paths(i,:), grid_size);
	imagesc(weights);
	pause;
end

