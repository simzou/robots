function u = resizeu( originalu, dims, scale )

u = zeros(scale*dims(1), scale*dims(2));
temp = reshape(originalu, dims(1), dims(2));

for i = 1:dims(1)
    for j = 1:dims(2)
        u(scale*(i-1)+1:scale*i, scale*(j-1)+1:scale*j) = temp(i,j);
    end
end

u = reshape(u, scale^2*dims(1)*dims(2), 1);

end

