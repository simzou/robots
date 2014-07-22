function [uguess paths err energy] = adaptiveMapping(uguess, u_image, paths, param)

%% If certain parameters aren't specified, use these defaults.
if ~isfield(param, 'tol')
    param.tol = .1;
end
if ~isfield(param, 'maxiter')
    param.maxiter = .1;
end
if ~isfield(param, 'stepsize')
    param.stepsize = int8((numel(u_image)/200));
end

dim = size(u_image);
[A, ~, g] = generateAug(u_image, paths);

% Preallocating our error and energy vectors.
err    = param.tol*ones(param.maxiter, 1);
energy = zeros(param.maxiter, 1);

iter = 1; % Iteration we are on.
while iter <= param.maxiter && err(iter) >= param.tol
    
    points = segmentImg(uguess,dim);
    
    if isempty(points)
        newpaths = generatePaths(param.stepsize, dim, 'randombounce');
    else
        newpaths = generatePaths(param.stepsize, dim, 'centered', points);
    end
    
    paths = [paths ; newpaths];
    
    [Anew, ~, gnew] = generateAug(u_image, newpaths);
    
    A = [A ; Anew];
    g = [g ; gnew];
    
    uprev = uguess;
    [uguess, ~ , energies] = splitBregmanSolve( A, g, uguess, dim, param );
   
    err(iter) = norm(uguess-uprev)/norm(uprev);
    energy(iter) = energies(end);
    
    iter = iter + 1;
    
end

% Finally, submit our output.
err = err(1:iter-1);
energy = energy(1:iter-1);

end
