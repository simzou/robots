function weights = compute_paths(paths, grid_size)
	weights = zeros(grid_size);

	make_gif = false;

	if make_gif, figure; end

	for i = 1:size(paths,1)
		weights = weights + path_weights(paths(i,:), grid_size);
		%imagesc(weights); colormap gray; pause;

        if make_gif,
            imagesc(weights); colormap gray;
            frame = getframe;
            if i == 1;
                [im, map] = rgb2ind(frame.cdata, 256);
            else
                im(:,:,1,i) = rgb2ind(frame.cdata, map);
            end
        end

	end

	if make_gif,
        imwrite(im, map, 'paths.gif', 'DelayTime', .2, 'LoopCount', inf);
    end
end