colormap gray;
grid_size = [50 50];
paths = generate_paths(8, grid_size, []);

for i = 1:size(paths,1)
	imagesc(path_weights(paths(i,:), grid_size));
	pause;
end

