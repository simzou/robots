function score = ssim(x,y)

u_x = mean(x);
u_y = mean(y);
v_x = var(x);
v_y = var(y);
v_xy = cov(x,y);
v_xy = v_xy(2);

k1 = 0.01;
k2 = 0.03;
L = 255;
c1 = (k1 * L)^2;
c2 = (k2 * L)^2;

num = (2*u_x*u_y + c1) * (2*v_xy + c2);
den = (u_x^2 + u_y^2 + c1) * (v_x + v_y + c2);

score = num/den;