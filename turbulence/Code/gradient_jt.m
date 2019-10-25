function a = gradient_jt(ref_image, x)
%x is non integer point, ref_image is the image R
% possible error, gradient will be 0 if point doesn't move
rx = 1;
ry = 1;
if (mod(x(1),1) == 0)   %check if integer
    rx = 0;
end
if (mod(x(2),1) == 0)
    ry = 0;
end
if (~(rx == 0 && ry == 0))
    if (rx == 0) % rx sits on a point but ry doesn't
        ry = ref_image(x(1),floor(x(2))+1)-ref_image(x(1),floor(x(2)));
    elseif (ry == 0) % ry on point, rx not
       rx = ref_image(floor(x(1)+1), x(2)) - ref_image(floor(x(1)),x(2));
    else %need to do bilinear interpolation
     x1 = floor(x(1));
     x2 = floor(x(1)) + 1;
     y1 = floor(x(2));
     y2 = floor(x(2))+1;
     p11 = [ x1, y1 ];
     p12 = [ x1, y2 ];
     p21 = [ x2, y1 ];
     p22 = [ x2, y2 ];
     term1=ref_image(p11(1),p11(2))/((x2-x1)*(y2-y1))*(x2-x(1))*(y2-x(2));
     term2=ref_image(p21(1),p21(2))/((x2-x1)*(y2-y1))*(x(1)-x1)*(y2-x(2));
     term3=ref_image(p12(1),p12(2))/((x2-x1)*(y2-y1))*(x2-x(1))*(x(2)-y1);
     term4=ref_image(p22(1),p22(2))/((x2-x1)*(y2-y1))*(x(1)-x1)*(x(2)-y1);
     new_point = term1 + term2 + term3 + term4;
     ry = (new_point - ref_image(x1,y1))/(x(2) - y1);
     rx = (new_point - ref_image(x1,y1))/(x(1) - x1);
     % every slope taken with reference to 1,1 point
    end
end
a = [rx , ry ];
end