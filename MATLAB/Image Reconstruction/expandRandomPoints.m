clear all; close; clc;
file =  'test50.png';
type = 'grid';

image = rgb2gray(imread(file));
dim = size(image);
result = zeros(dim);

if type == 'rand'
    num_points = 200;
    points = [randi(dim(1),num_points,1) randi(dim(2),num_points,1)];
elseif type == 'grid'
    grid_scale = 10;
    points = [];
    for ind = 1:grid_scale:dim(2)
        points = [points; [1:grid_scale:dim(1)]' ind*ones(ceil(dim(1)/grid_scale),1)];
    end
    num_points = size(points,1);
end

tic;
for i = 1:dim(1)
    for j = 1:dim(2)
        closest = [i j Inf];
        for k = 1:num_points
            dist = pdist([i j; points(k,:)]);
            if dist < closest(3)
                closest = [points(k,:) dist];
            end
            %[i j k]
        end
        result(i,j) = image(closest(1),closest(2));
    end
end
toc;
ssim = ssim(double(reshape(image,dim(1)*dim(2),1)),reshape(result,dim(1)*dim(2),1))
for point = 1:num_points
    %result(points(point,1),points(point,2)) = 300;
end



imagesc(result)
colormap gray