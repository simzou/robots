function [A u g] = generateAug( u, paths )
% Takes an image file and a list of path endpoints
% Returns the A, u, and g, as well as those of the gradient.

% paths should be an nx4 matrix where n is the number of paths.
% In each path, the entries should be xstart, ystart, xend, yend, in that
% order.

ugradmat = zeros(size(u));

siglength = size(u,1)*size(u,2);

A = zeros(size(paths,1),siglength);

utemp = zeros(size(u)+[1 1]);
utemp(2:size(u,1)+1,1:size(u,2)) = u(:,:);
for i=2:size(u,1)+1
    for j=1:size(u,2)
        ugradmat(i-1,j) = sqrt((utemp(i,j+1)-utemp(i,j))^2 + (utemp(i-1,j)-utemp(i,j))^2);
    end
end

for i=1:size(paths,1)
    path = paths(i,:);
    pathmat = zeros(size(u));
    xstart = path(1,1); xend = path(1,3); ystart = path(1,2); yend = path(1,4);
    ystartind = size(u,1)-ystart; yendind = size(u,1)-yend+1;
    if xstart==xend && ystart==yend
    elseif xstart==xend && ystart~=yend
        pathmat(min([ystartind yendind])+1:max([ystartind yendind]),ceil(xstart)) = 1;
    elseif ystart==yend && xstart~=xend
        pathmat(ceil(ystartind),min([xstart xend])+1:max([xstart xend])) = 1;
    else
        pathmat = path_weights(path,size(u));
    end
        A(i,:) = reshape(pathmat,1,siglength);
end

u = double(reshape(u,siglength,1));
g = A*double(u);

end

