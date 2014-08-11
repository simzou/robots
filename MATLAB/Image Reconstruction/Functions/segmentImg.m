function points = segmentImg(uguess,bounds,dim)

img_guess = reshape(uguess, dim);

level = graythresh(img_guess);
bw = im2bw(img_guess, level);
%bw = bwareaopen(bw, 50);

x0 = bounds(1); xF = bounds(3);
y0 = bounds(2); yF = bounds(4);

cc = bwconncomp(bw(y0:yF, x0:xF), 8);

[i, j] = ind2sub([yF-y0 xF-x0],vertcat(cc.PixelIdxList{:}));
i = i + y0;
j = j + x0;
points = [i j];

%points(:,1) = dim(1)-points(:,1);

end
