function [ weights ] = path_weights(ends, dimensions)
% gives weights for a path over an image with given dimensions
% ends should be a 1x4 matrix with the x and y coordinates of the start
% point and the x and y coordinates of the end point in that order
% dimensions should be the size of the image matrix

weights = zeros(dimensions);
x1 = ends(1); x2 = ends(3); y1 = ends(2); y2 = ends(4);
yfun = [(y2-y1)/(x2-x1) ((y1-y2)/(x2-x1)*x1+y1)];
xfun = [(x2-x1)/(y2-y1) ((x1-x2)/(y2-y1)*y1+x1)];

xintersects = ceil(min([x1 x2])):floor(max([x1 x2]));
yintersects = [];
for y = ceil(min([y1 y2])):floor(max([y1 y2]))
    xval = xfun(1)*y+xfun(2);
    if mod(xval,1)==0
    else
        yintersects = [yintersects xval];
    end
end

intersects = [xintersects yintersects];
intersects = sort(intersects);
%keyboard

for i=1:size(intersects,2)-1
    xx1 = intersects(i); yy1 = yfun(1)*intersects(i)+yfun(2);
    xx2 = intersects(i+1); yy2 = yfun(1)*intersects(i+1)+yfun(2);
    weight = sqrt((yy2-yy1)^2+(xx2-xx1)^2);
    if mod(xx1,1)==0
        if mod(yy1,1)==0
            weights(ceil(dimensions(1)-yy1)+1,round(xx1+1)) = weight;
        else
            weights(ceil(dimensions(1)-yy1),round(xx1+1)) = weight;
        end
    else
        if yy2-yy1>0
            weights(round(dimensions(1)-yy1),ceil(xx1)) = weight;
        else
            weights(round(dimensions(1)-yy1+1),ceil(xx1)) = weight;
        end
    end
    
end