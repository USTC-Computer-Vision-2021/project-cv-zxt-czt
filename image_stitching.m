function [output_image] = image_stitching(input_A, input_B)

% 读取图片信息
image_A = imread(input_A);
image_B = imread(input_B);
[height_wrap, width_wrap,~] = size(image_A);
[height_unwrap, width_unwrap,~] = size(image_B);

% 转换灰度图
gray_A = im2double(rgb2gray(image_A));
gray_B = im2double(rgb2gray(image_B));

% 进行Harris角检测
[x_A, y_A, v_A] = harris(gray_A, 2, 0.0, 2);
[x_B, y_B, v_B] = harris(gray_B, 2, 0.0, 2);

% 自适应非极大值抑制 (ANMS)
ncorners = 500;
[x_A, y_A, ~] = ada_nonmax_suppression(x_A, y_A, v_A, ncorners);
[x_B, y_B, ~] = ada_nonmax_suppression(x_B, y_B, v_B, ncorners);

% 关键点描述
sigma = 7;
[des_A] = getFeatureDescriptor(gray_A, x_A, y_A, sigma);
[des_B] = getFeatureDescriptor(gray_B, x_B, y_B, sigma);

% 关键点匹配
dist = dist2(des_A,des_B);
[ord_dist, index] = sort(dist, 2);
ratio = ord_dist(:,1)./ord_dist(:,2);
threshold = 0.5;
idx = ratio<threshold;

x_A = x_A(idx);
y_A = y_A(idx);
x_B = x_B(index(idx,1));
y_B = y_B(index(idx,1));
npoints = length(x_A);

matcher_A = [y_A, x_A, ones(npoints,1)]'; 
matcher_B = [y_B, x_B, ones(npoints,1)]'; 
[hh, ~] = ransacfithomography(matcher_B, matcher_A, npoints, 10);

[newH, newW, newX, newY, xB, yB] = getNewSize(hh, height_wrap, width_wrap, height_unwrap, width_unwrap);

[X,Y] = meshgrid(1:width_wrap,1:height_wrap);
[XX,YY] = meshgrid(newX:newX+newW-1, newY:newY+newH-1);
AA = ones(3,newH*newW);
AA(1,:) = reshape(XX,1,newH*newW);
AA(2,:) = reshape(YY,1,newH*newW);

AA = hh*AA;
XX = reshape(AA(1,:)./AA(3,:), newH, newW);
YY = reshape(AA(2,:)./AA(3,:), newH, newW);

% 新图像的拼接
newImage(:,:,1) = interp2(X, Y, double(image_A(:,:,1)), XX, YY);
newImage(:,:,2) = interp2(X, Y, double(image_A(:,:,2)), XX, YY);
newImage(:,:,3) = interp2(X, Y, double(image_A(:,:,3)), XX, YY);

% 按照cross dissolve的方法融合交叉区域
[newImage] = blend(newImage, image_B, xB, yB);

% 输出合成后图像
imshow(uint8(newImage));



