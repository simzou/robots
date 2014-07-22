function [uguess err energy] = adaptiveMapping(A, g, uguess, dim, param)

%% If certain parameters aren't specified, use these defaults.
if ~isfield(param, 'tol')
    param.tol = .1;
end
if ~isfield(param, 'maxiter')
    param.tol = .1;
end
if ~isfield(param, 'initpaths')
    param.num_initpaths = 50;
end
if ~isfield(param, 'stepsize')
    param.recal_after = 50;
end

% Preallocating our error and energy vectors.
err    = param.tol*ones(param.maxiter, 1);
energy = zeros(param.maxiter, 1);

%% Generate the line-segment paths that we collect data from.
paths = generatePaths(param.initpaths, dim, 'randombounce', [80 15]);

%% Compute A0, our path matrix, convert u to a vector, and compute Au=g.
[A u g] = generateAug(u_image, paths);

%% Now run the Split Bregman Algorithm to reconstruct u from A and g.
uguess = zeros(prod(dim), 1);
[uguess err energy] = splitBregmanSolve( A, g, uguess, dim, param );

points = segmentImg(uguess,dim);

tic;

for j = num_initpaths+1:recal_after:num_paths

    newpaths = generatePaths(recal_after, dim, 'centered', points);
    paths = [paths ; newpaths];
    
    [Anew u gnew] = generateAug(u_image, newpaths);
    
    A = [A ; Anew];
    g = [g ; gnew];

    [uguess err energy] = splitBregmanSolve( A, g, uguess, dim, param );

    points = segmentImg(uguess,dim);
    
end

times(i)=toc;
solveTime = times(i);
trueError = norm(u-uguess) / norm(u);
errors(i) = trueError;

end
