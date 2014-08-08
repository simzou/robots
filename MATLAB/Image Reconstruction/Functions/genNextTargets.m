function newpaths = genNextTargets( data, dim, scale, numpaths )

data = data.*scale;
paths = data( :, 1:end-1 );
u = zeros(dim);
g = data( :, end );
[A,u,~] = generateAug( u, paths );

param.tolSB = 1/255;

uguess= splitBregmanSolve( A, g, u, dim, param );
points = segmentImgGradient(uint8(uguess),dim);

if isempty(points)
    newpaths = generatePaths(numpaths, dim, 'randombounce');
else
    newpaths = generatePaths(numpaths, dim, 'centered', points);
end

newpaths = uint64(newpaths(:,1:2));
fprintf([repmat('%u,', 1, size(newpaths, 2)-1) '%u\n'], newpaths')

end