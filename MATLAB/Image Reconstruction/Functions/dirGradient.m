function [dx, dy] = dirGradient(u, dim, option)
% This function returns the gradients of the mxn image u in both the
% horizontal direction and the vertical direction. u is expected to be 
% input as a one dimensional vector. dx and dy are also one dimensional 
% vectors. The gradients are computed as
%
%     del_x u_{i,j} = u_{i,(j+1) % n} - u_{i,j}
%     del_x u_{i,j} = u_{(i+1) % m, j} - u_{i,j}
%

if nargin < 3 || ~strcmp(option, 'transpose')
    A  = reshape(u, dim);
    dx = [A(:,2:end) - A(:,1:end-1)  A(:,1) - A(:,end)];
    dy = [A(2:end,:) - A(1:end-1,:); A(1,:) - A(end,:)];
    dx = reshape(dx, prod(dim), 1);
    dy = reshape(dy, prod(dim), 1);
else 
    A  = reshape(u, dim);
    dx = [A(:,end) - A(:,1)  A(:,1:end-1) - A(:,2:end)];
    dy = [A(end,:) - A(1,:); A(1:end-1,:) - A(2:end,:)];
    dx = reshape(dx, prod(dim), 1);
    dy = reshape(dy, prod(dim), 1);
     
end