function paths = generate_paths(num_paths, image_dim, path_type)
	% by default, generate random paths
	paths = [];
	if ~exist(path_type)
		for i = 1:num_paths
			% choosing two edges of the image
			% 1 = left, 2 = top, 3 = right, 4 = bottom
			edges = randperm(4,2);
			switch edges(1)
			case 1
				x1 = 0;
				y1 = rand(1)*image_dim(1);
			case 2
				x1 = rand(1)*image_dim(2);
				y1 = image_dim(1);
			case 3
				x1 = image_dim(2);
				y1 = rand(1)*image_dim(1);
			case 4
				x1 = rand(1)*image_dim(2);
				y1 = 0;
			end
			switch edges(2)
			case 1
				x2 = 0;
				y2 = rand(1)*image_dim(1);
			case 2
				x2 = rand(1)*image_dim(2);
				y2 = image_dim(1);
			case 3
				x2 = image_dim(2);
				y2 = rand(1)*image_dim(1);
			case 4
				x2 = rand(1)*image_dim(2);
				y2 = 0;
			end
			paths = [paths; x1 y1 x2 y2];
		end
	end
end

