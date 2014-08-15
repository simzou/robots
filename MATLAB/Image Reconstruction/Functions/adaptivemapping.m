function [uguess, paths, err, energy] = adaptivemapping(uguess, u_image, paths, bounds, param)

%% If certain parameters aren't specified, use these defaults.
if ~isfield(param, 'tol')
    param.tol = .1;
end
if ~isfield(param, 'maxpaths')
    param.maxpaths = numel(u_image)/20;
end
if ~isfield(param, 'stepsize')
    param.stepsize = 10;
end

dim = size(u_image);
[A, ~, g] = generateAug(u_image, paths);

% Preallocating our error and energy vectors.
maxiter = int8(param.maxpaths/param.stepsize);

err    = param.tol*ones(maxiter, 1);
energy = zeros(maxiter, 1);

numpaths = size(paths,1);
iter = 1; % Iteration we are on.
lasterr = err(iter);

while numpaths < param.maxpaths && lasterr >= param.tol
    
    points = segmentImg(uguess,bounds,dim);
    
    if isempty(points)
        newpaths = generatePaths(param.stepsize, dim, bounds, 'randombounce');
    else
        newpaths = generatePaths(param.stepsize, dim, bounds, 'centered', points);
    end
    
    paths = [paths ; newpaths];
    numpaths = size(paths,1);
    
    [Anew, ~, gnew] = generateAug(u_image, newpaths);
    
    A = [A ; Anew];
    g = [g ; gnew];
    
    uprev = uguess;
    [uguess, ~ , energies] = splitBregmanSolve( A, g, uguess, dim, param );
    
    err(iter) = norm(uguess-uprev)/norm(uprev);
    energy(iter) = energies(end);
    
    lasterr = err(iter);
    iter = iter + 1;
    
end

% Finally, submit our output.
err = err(1:iter-1);
energy = energy(1:iter-1);

end
