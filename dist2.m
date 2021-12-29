function n2 = dist2(x, c)
% 计算关键点距离

[ndata, dimx] = size(x);
[ncentres, dimc] = size(c);
if dimx ~= dimc
error('Data dimension does not match dimension of centres')
end

n2 = (ones(ncentres, 1) * sum((x.^2)', 1))' + ...
ones(ndata, 1) * sum((c.^2)',1) - ...
2.*(x*(c'));

if any(any(n2<0))
n2(n2<0) = 0;
end
