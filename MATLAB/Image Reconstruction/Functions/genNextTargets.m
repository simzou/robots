function newpaths = genNextTargets( data, dim, bounds, scale, numpaths )

rng('shuffle')

data = data.*scale;
bounds = bounds.*scale;
dim = dim.*scale;

if isempty(data)
    newpaths = generatePaths(numpaths, dim, bounds, 'randombounce');
    newpaths = uint64(newpaths(:,1:2)./scale);
    fprintf('%u ', newpaths')
    return
end

paths = data( :, 1:end-1 );
u = zeros(dim);
g = data( :, end );
[A,u,~] = generateAug( u, paths );

param.tolSB = 1/255;

uguess = splitBregmanSolve( A, g, u, dim, param );
points = segmentImg(uint8(uguess), bounds, dim);

if isempty(points)
    newpaths = generatePaths(numpaths, dim, bounds, 'randombounce');
else
    newpaths = generatePaths(numpaths, dim, bounds, 'centered', points);
end

newpaths = uint64(newpaths(:,1:2)./scale);
fprintf('%u ', newpaths')

end