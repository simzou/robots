%           mrics.m  by Tom Goldstein (TomGoldstein1@gmail.com)
%     This file contains methods for performing compressed sensing
%  recontructions of images from k-space data using the Split Bregman 
%  method.  
%     To use the method, simply add this "m" file to your current directory, 
%  and then call the following method:
%   
%              u = mrics(R,F, mu, lambda, gamma, nInner, nOuter);
%   
%  The inputs to this function are described below:
%  
%  R - This is a matrix which determines which elements of K-Space
%           are known.  Take R(m,n)=0 if Fourier mode (m,n) is unknown,
%           and R(m,n)=1 if the corresponding mode is known.
%  F - This is the K-Space (Fourier) data.  In other words, F is the 
%           Fourier transform of the image you wish to recover.  If a
%           Fourier mode is known, then it should have a non-zero value.
%           If a Fourier mode is unknown, then simply set the corresponding
%           entry in this matrix to zero.  If you have set the values
%           in this matrix properly, then you should have (R.*F==F).
%  mu- The parameter on the fidelity term in the Split Bregman method.  The
%           best choice will depend on how the data is scaled.
% lambda - The coefficient of the constraint term in the Split Bregman
%      model. For most problems, I suggest using lambda=mu.
% gamma - This is a regularization parameter.  I suggest that you take
%      gamma = mu/100.
% nInner - This determines how many "inner" loops the Split Bregman method
%      performs (i.e. loop to enforce the constraint term).  I suggest
%      using nInner = 30 to be safe.  This will usually guarantee good
%      convergence, but will make things a bit slow.  You may find that you
%      can get away with nInner = 5-10
% nOuter - The number of outer (fidelity term) Bregman Iterations.  This
%      parameter depends on how noisy your data is, but I find that
%      nOuter=5 is usually about right.


function u = mrics(R,f, mu, lambda, gamma, nInner, nBreg)
    [rows,cols] = size(f);
    
        
         % Reserve memory for the auxillary variables
    f0 = f;
    u = zeros(rows,cols);
    x = zeros(rows,cols);
    y = zeros(rows,cols);
    bx = zeros(rows,cols);
    by = zeros(rows,cols);

     % Build Kernels
    scale = sqrt(rows*cols);
    murf = ifft2(mu*(conj(R).*f))*scale;
    
    uker = zeros(rows,cols);
    uker(1,1) = 4;uker(1,2)=-1;uker(2,1)=-1;uker(rows,1)=-1;uker(1,cols)=-1;
    uker = mu*(conj(R).*R)+lambda*fft2(uker)+gamma;
  

    %  Do the reconstruction
    for outer = 1:nBreg;
        for inner = 1:nInner;
             % update u   
            rhs = murf+lambda*Dxt(x-bx)+lambda*Dyt(y-by)+gamma*u;
            u = ifft2(fft2(rhs)./uker);

            % update x and y
            dx = Dx(u);
            dy  =Dy(u);
            [x,y] = shrink2( dx+bx, dy+by,1/lambda);

            % update bregman parameters
            bx = bx+dx-x;
            by = by+dy-y;
        end
      
        f = f+f0-R.*fft2(u)/scale;
        murf = ifft2(mu*R.*f)*scale;
    end

  
return;


function d = Dx(u)
[rows,cols] = size(u); 
d = zeros(rows,cols);
d(:,2:cols) = u(:,2:cols)-u(:,1:cols-1);
d(:,1) = u(:,1)-u(:,cols);
return

function d = Dxt(u)
[rows,cols] = size(u); 
d = zeros(rows,cols);
d(:,1:cols-1) = u(:,1:cols-1)-u(:,2:cols);
d(:,cols) = u(:,cols)-u(:,1);
return

function d = Dy(u)
[rows,cols] = size(u); 
d = zeros(rows,cols);
d(2:rows,:) = u(2:rows,:)-u(1:rows-1,:);
d(1,:) = u(1,:)-u(rows,:);
return

function d = Dyt(u)
[rows,cols] = size(u); 
d = zeros(rows,cols);
d(1:rows-1,:) = u(1:rows-1,:)-u(2:rows,:);
d(rows,:) = u(rows,:)-u(1,:);
return

function [xs,ys] = shrink2(x,y,lambda)

s = sqrt(x.*conj(x)+y.*conj(y));
ss = s-lambda;
ss = ss.*(ss>0);

s = s+(s<lambda);
ss = ss./s;

xs = ss.*x;
ys = ss.*y;

return;

