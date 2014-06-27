function [ A u ugrad g ] = generate_Aug_from_image( image_file, paths )
% Takes an image file and a list of path endpoints
% Returns the A, u, and g, as well as those of the gradient.

% paths should be an nx4 matrix where n is the number of paths.
% In each path, the entries should be xstart, ystart, xend, yend, in that
% order.

umat = rgb2gray(imread(image_file));
ugradmat = zeros(size(umat));

siglength = size(umat,1)*size(umat,2);

A = zeros(size(paths,1),siglength);

utemp = zeros(size(umat)+[1 1]);
utemp(2:size(umat,1)+1,1:size(umat,2)) = umat(:,:);
for i=2:size(umat,1)+1
    for j=1:size(umat,2)
        ugradmat(i-1,j) = sqrt((utemp(i,j+1)-utemp(i,j))^2 + (utemp(i-1,j)-utemp(i,j))^2);
    end
end

for i=1:size(paths,1)
    path = paths(i,:);
    pathmat = zeros(size(umat));
    xstart = path(1,1); xend = path(1,3); ystart = path(1,2); yend = path(1,4);
    ystartind = size(umat,1)-ystart+1; yendind = size(umat,1)-yend+1;
    if xstart==xend && ystart==yend
        pathmat(ystartind,xstart) = 1;
    elseif xstart==xend && ystart~=yend
        pathmat(min([ystartind yendind]):max([ystartind yendind]),xstart) = 1;
    elseif ystart==yend && xstart~=xend
        pathmat(ystartind,min([xstart xend]):max([xstart xend])) = 1;
    end
        A(i,:) = reshape(pathmat,1,siglength);
end

u = reshape(umat,siglength,1);
ugrad = reshape(ugradmat,siglength,1);

g = A*double(u);

end

