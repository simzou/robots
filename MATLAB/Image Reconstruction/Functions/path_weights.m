function [ weights ] = path_weights(ends, dimensions)
% gives weights for a path over an image with given dimensions
% ends should be a 1x4 matrix with the x and y coordinates of the start
% point and the x and y coordinates of the end point in that order
% dimensions should be the size of the image matrix

% A start point of [0 0] will refer to the bottom left corner
weights = zeros(dimensions);
x1 = ends(1); x2 = ends(3); y1 = ends(2); y2 = ends(4);

% yfun and xfun allow you to get y given x or vice versa
yfun = [(y2-y1)/(x2-x1) ((y1-y2)/(x2-x1)*x1+y1)];
xfun = [(x2-x1)/(y2-y1) ((x1-x2)/(y2-y1)*y1+x1)];
yfun = @(x) yfun(1)*x + yfun(2);
xfun = @(y) xfun(1)*y + xfun(2);

% build a nx2 matrix with all the intersections, where n is the number of intersections
xintersects = [];
for x = ceil(min([x1 x2])):floor(max([x1 x2]))
    yval = yfun(x);
    xintersects = [xintersects; x yval];
end

yintersects = [];
for y = ceil(min([y1 y2])):floor(max([y1 y2]))
    xval = xfun(y);
    if is_close_to_integer(xval)
    else
        yintersects = [yintersects; xval y];
    end
end

intersects = [xintersects; yintersects];
intersects = sortrows(intersects);

% go through each intersection
for i=1:size(intersects,1)-1
    % calculate distance between two consecutive intersection points
    xx1 = intersects(i,1); yy1 = intersects(i,2);
    xx2 = intersects(i+1,1); yy2 = intersects(i+1,2);
    weight = sqrt((yy2-yy1)^2+(xx2-xx1)^2);

    % determine box/voxel the line segment/weight falls in and 
    % then assign it to the weights matrix (same dimensions as image)
    if is_close_to_integer(xx1)
        xint=round(xx1);
        if is_close_to_integer(yy1)
            yint = round(yy1);
            if yy2-yy1<0
                weights(dimensions(1)-yint+1,xint+1) = weight;
            else
                weights(dimensions(1)-yint,xint+1) = weight;
            end
        else
            weights(ceil(dimensions(1)-yy1),xint+1) = weight;
        end
    else
        yint = round(yy1);
        if yy2-yy1>0
            weights(dimensions(1)-yint,ceil(xx1)) = weight;
        else
            weights(dimensions(1)-yint+1,ceil(xx1)) = weight;
        end
    end
end

end

function bool = is_close_to_integer(i)
    tol = 0.000000001;
    bool = (mod(i,1) < tol || 1-mod(i,1) < tol);
end

