colormap gray;

grid_size = [3 3];

% bottom left corner to top right corner
start_point = [0 0];
end_point = [3 3];
weights = path_weights([start_point end_point], grid_size);
imagesc(weights);
pause;

grid_size = [50 50];

% bottom edge to top edge
start_point = [20.5 0];
end_point = [45.2 50];
weights = path_weights([start_point end_point], grid_size);
imagesc(weights);
pause;

% top edge to bottom edge
start_point = [40 50];
end_point = [20 0];
weights = path_weights([start_point end_point], grid_size);
imagesc(weights);
pause;

% top edge to right edge
start_point = [12 50];
end_point = [50 2];
weights = path_weights([start_point end_point], grid_size);
imagesc(weights);
pause;


% horizontal
start_point = [0 20.4];
end_point = [50 20.4];
weights = path_weights([start_point end_point], grid_size);
imagesc(weights);
pause;

% vertical
start_point = [35.3 0];
end_point = [35.3 50];
weights = path_weights([start_point end_point], grid_size);
imagesc(weights);
pause;