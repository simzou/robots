function points = segmentImg(uguess,dim)

img_guess = reshape(uguess, dim);

level = graythresh(img_guess);
bw = im2bw(img_guess, level);
bw = gradMag(bw);

bw = bwareaopen(bw, 1,8);
cc = bwconncomp(bw, 8);

[i j] = ind2sub(dim,vertcat(cc.PixelIdxList{:}));
points = [i j];

%points(:,1) = dim(1)-points(:,1);

end
