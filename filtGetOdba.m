function odba = filtGetOdba(axy,nFilt)
stdThresh = 3000;

x_odba = abs(axy(:,1)-medfilt1(axy(:,1),nFilt));
x_std = movstd(x_odba,nFilt);
x_odba(x_std > stdThresh) = 0;

y_odba = abs(axy(:,2)-medfilt1(axy(:,2),nFilt));
y_std = movstd(y_odba,nFilt);
y_odba(y_std > stdThresh) = 0;

z_odba = abs(axy(:,3)-medfilt1(axy(:,3),nFilt));
z_std = movstd(z_odba,nFilt);
z_odba(z_std > stdThresh) = 0;

odba = x_odba + y_odba + z_odba;