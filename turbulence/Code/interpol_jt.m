function a = interpol_jt(ref_image, x) 
% This function takes in the averaged image R, given here as ref_image and
% the deformation position W(x), given here as x and returns an
% interpolated image based on the deformation posistions.

% Correcting for possible error, gradient will be 0 if point doesn't move
    if (mod(x(1),1) == 0 && mod(x(2),1) == 0)
        a = ref_image(x(1),x(2));
    elseif (mod(x(1),1) == 0)  % sits on x coord
        a = (ref_image(x(1),floor(x(2))+1)-ref_image(x(1),...
            floor(x(2))))*(x(2)-floor(x(2)));
    elseif (mod(x(2),1) == 0) %sits on y coord
        a = (ref_image(floor(x(1))+1,x(2))-ref_image(floor(x(1)),...
            x(2)))*(x(1)-floor(x(1)));
    else       
        x1 = floor(x(1));
        x2 = floor(x(1)) + 1;
        y1 = floor(x(2));
        y2 = floor(x(2))+1;
        p11 = [ x1, y1 ];
        p12 = [ x1, y2 ];
        p21 = [ x2, y1 ];
        p22 = [ x2, y2 ];
        term1 = ref_image(p11(1), p11(2)) /...
            ((x2 - x1)*(y2-y1))*(x2 - x(1)) * (y2 - x(2));
        term2 = ref_image(p21(1), p21(2)) /...
            ((x2 - x1)*(y2-y1))*(x(1) - x1) * (y2 - x(2));
        term3 = ref_image(p12(1), p12(2)) /...
            ((x2 - x1)*(y2-y1))*(x2 - x(1)) * (x(2) - y1);
        term4 = ref_image(p22(1), p22(2)) /...
            ((x2 - x1)*(y2-y1))*(x(1) - x1) * (x(2) - y1);
        new_point = term1 + term2 + term3 + term4;
        a = new_point;
    end
end