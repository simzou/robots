function weights = compute_paths(paths, grid_size)
	weights = zeros(grid_size);
	for i = 1:size(paths,1)
		weights = weights + path_weights(paths(i,:), grid_size);
		%imagesc(weights); colormap gray; pause;
	end
end