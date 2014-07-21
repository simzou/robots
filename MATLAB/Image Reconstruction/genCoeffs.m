function coeffs = genCoeffs(path)

coeffs = zeros(3);

coeffs(1,1) = sum(sum(path(1:100,1:100)));
coeffs(2,1) = sum(sum(path(101:200,1:100)));
coeffs(3,1) = sum(sum(path(201:300,1:100)));
coeffs(1,2) = sum(sum(path(1:100,101:200)));
coeffs(2,2) = sum(sum(path(101:200,101:200)));
coeffs(3,2) = sum(sum(path(201:300,101:200)));
coeffs(1,3) = sum(sum(path(1:100,201:300)));
coeffs(2,3) = sum(sum(path(101:200,201:300)));
coeffs(3,3) = sum(sum(path(201:300,201:300)));

coeffs = coeffs./100;

end