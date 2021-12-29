function [xp, yp, value] = harris(input_image, sigma,thd, r)

% 转换灰度图
g1 = fspecial('gaussian', 7, 1);
gray_image = imfilter(input_image, g1);

% 滤波并分别定位
h = fspecial('sobel');
Ix = imfilter(gray_image,h,'replicate','same');
Iy = imfilter(gray_image,h','replicate','same');

% 生成高斯滤波器
g = fspecial('gaussian',fix(6*sigma), sigma);

Ix2 = imfilter(Ix.^2, g, 'same').*(sigma^2); 
Iy2 = imfilter(Iy.^2, g, 'same').*(sigma^2);
Ixy = imfilter(Ix.*Iy, g, 'same').*(sigma^2);

% 寻找Harris关键点
R = (Ix2.*Iy2 - Ixy.^2)./(Ix2 + Iy2 + eps); 
R([1:20, end-20:end], :) = 0;
R(:,[1:20,end-20:end]) = 0;
d = 2*r+1; 
localmax = ordfilt2(R,d^2,true(d)); 
R = R.*(and(R==localmax, R>thd));

% 返回关键点坐标
[xp,yp,value] = find(R);

