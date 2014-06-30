function [ ] = make_image( u, dimensions, filename )
% Gives the image for the found solution
% dimensions should be have the x dimension and y dimension in that order
% filename should be a string with the filetype, i.e. 'test.png'
imwrite(uint8(reshape(u,dimensions(2),dimensions(1))), filename)

end

