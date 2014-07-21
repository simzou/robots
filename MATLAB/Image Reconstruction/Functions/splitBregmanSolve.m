function [uguess err energy] = splitBregmanSolve( A, g, u0, dim, param )
% TODO

%% If certain parameters aren't specified, use these defaults.
if ~isfield(param, 'p')
    param.p = 1;
end
if ~isfield(param, 'alpha')
    param.alpha = 1;
end
if ~isfield(param, 'beta')
    param.beta = 1;
end
if ~isfield(param, 'mu')
    param.mu = 10;
end
if ~isfield(param, 'lambda1')
    param.lambda1 = .1;
end
if ~isfield(param, 'lambda2')
    param.lambda2 = 1;
end
if ~isfield(param, 'N')
    param.N = 1;
end
if ~isfield(param, 'tol')
    param.tol = 1/250;
end
if ~isfield(param, 'maxiter')
    param.maxiter = 100;
end
if ~isfield(param, 'makegif')
    param.makegif = false;
end
if ~isfield(param, 'gifname')
<<<<<<< HEAD
    param.gifname = 'iter.gif';
=======
    param.gifname = 'iter.gif'
>>>>>>> 6591b3276ad0c5329cb68c3f75142e5bd7c17989
end

%% Initialize our iterates and other variables.
n = prod(dim);

% Preallocating our error and energy vectors.
err    = param.tol*ones(param.maxiter, 1);
energy = zeros(param.maxiter, 1);

u  = [zeros(n,1) u0];
d  = zeros(n, 1);
b  = zeros(n, 1);
dx = zeros(n, 1);
bx = zeros(n, 1);
dy = zeros(n, 1);
by = zeros(n, 1);

iter = 1; % Iteration we are on.
last_err = err(iter);

%% Begin the Split Bregman algorithm.
while iter <= param.maxiter && last_err >= param.tol
    for i = 1:param.N
        
        % Save our previous iteration's value for u.
        u(:,1) = u(:,2);
        
        %% Perform step 1 of the algorithm, solve for u^{k+1}.
        u(:,2) = solveStep1(A, g, d, b, dx, bx, dy, by, dim, param);
        
        % If make_gif is true, the iterates will be made into an animated gif
        
        if param.makegif,

            imagesc(reshape(u(:,2), dim)); colormap gray;
            % pause;

            %% code for writing each iteration to a gif
            frame = getframe;

            if iter == 1;
                [im, map] = rgb2ind(frame.cdata, 256);
            else
                im(:,:,1,iter) = rgb2ind(frame.cdata, map);
            end
        end

        %% Perform step 2 of the algorithm, p-shrinkage.
        [gradX gradY] = dirGradient(u(:,2), dim);
        
        d  = pshrink( u(:,2)+b, param.alpha/param.lambda1, param.p  ); 
        dx = pshrink( gradX+bx, param.beta/param.lambda2, param.p ); 
        dy = pshrink( gradY+by, param.beta/param.lambda2, param.p  ); 
    end
    
    %% Step 3: Update b.
    b  = b  + ( u(:,2) - d );
    bx = bx + ( gradX - dx );
    by = by + ( gradY - dy );
    
    %% Record our progress so far.
    
    err(iter)    = norm( u(:,2)-u(:,1) )/norm(u(:,1));
<<<<<<< HEAD
    energy(iter) = param.alpha*sum(u(:,2))+param.beta*sum(gradX)+...
        param.beta*sum(gradY)+(param.mu/2)*norm(A*u(:,2)-g)^2;
=======
    energy(iter) = param.lambda1*sum(u(:,2))+param.lambda2*sum(gradX)+...
        param.lambda2*sum(gradY)+(param.mu/2)*norm(A*u(:,2)-g)^2;
>>>>>>> 6591b3276ad0c5329cb68c3f75142e5bd7c17989
    last_err = err(iter);
    iter = iter + 1;
end

if param.makegif,
    imwrite(im, map, param.gifname, 'DelayTime', .1, 'LoopCount', inf);
end

% Finally, submit our output.
err = err(1:iter-1);
energy = energy(1:iter-1);
uguess = u(:,2);

end

function d = pshrink( x, gamma, p )
% The p-shrinkage function carries out step 2 of the algorithm.

xabs = abs(x)+eps;
d = (x./xabs).*max( xabs-gamma.*xabs.^(p-1), 0 );

end


