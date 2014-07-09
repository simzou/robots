colormap gray;
grid_size = [30 30];

paths = generate_paths(250, grid_size, 'bouncy');


weights = zeros(grid_size);

for i = 1:size(paths,1)
	weights = weights + path_weights(paths(i,:), grid_size);
	imagesc(weights);
	pause;
end

