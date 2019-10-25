function ci = bspline_func(x_init,x_test,y_init,y_test,int_x,int_y,n)
%  B-spline function calculating the basis using the test points
%  x_init, y_init, the positions of control points in the averaged image
%  x_test, y_test, vectors of locations of the test points
%  int_x,y_int, the intervals between control points
%   n is the number of test points

    t1 = abs((x_test*ones(n,1)-x_init)/int_x);
    t2 = abs((y_test*ones(n,1)-y_init)/int_y);

%Calculating Beta((x_test-x_init)/int_x)
for aa=1:1:n
    
    if(0<=t1(aa) && t1(aa)<=1)
        beta_a(aa) = 2/3-(1-(t1(aa))/2)*(t1(aa))^2;
    elseif(1<=t1(aa) && t1(aa)<=2)
        beta_a(aa) = (2-(t1(aa))^3)/6;
    else
        beta_a(aa) = 0;
    end
    
%Calculating Beta((y_test-y_init)/int_y)
if(0<=t2(aa) && t2(aa)<=1)
    beta_b(aa) = 2/3-(1-(t2(aa))/2)*(t2(aa))^2;
elseif(1<=t2(aa) && t2(aa)<=2)
    beta_b(aa) = (2-(t2(aa))^3)/6;
else
    beta_b(aa) = 0;
end

%ci = Beta((x_test-x_init)/int_x)*Beta((y_test-y_init)/int_y)
ci = (beta_a.*beta_b)';
end

