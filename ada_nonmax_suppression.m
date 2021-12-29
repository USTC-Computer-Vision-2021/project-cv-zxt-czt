function [newx, newy, newvalue] = ada_nonmax_suppression(xp, yp, value, n)
% 自适应非极大值抑制  
if(length(xp) < n)
newx = xp;
newy = yp;
newvalue = value;
return;
end

radius = zeros(n,1);
c = .9;
maxvalue = max(value)*c;
for i=1:length(xp)
if(value(i)>maxvalue)
radius(i) = 99999999;
continue;
else
dist = (xp-xp(i)).^2 + (yp-yp(i)).^2;
dist((value*c) < value(i)) = [];
radius(i) = sqrt(min(dist));
end
end

[~, index] = sort(radius,'descend');
index = index(1:n);

newx = xp(index);
newy = yp(index);
newvalue = value(index);


