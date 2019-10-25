function a = grid_map(size_yy, size_xx, spacing)
% This function remaps the test points into a Nx2, and shifts both x and y
% by 5 pixels to the left. This will allow for later sweeping of the
% deformed image to find the most correleated points to the test points.
    size_y = size_yy-5;
    size_x = size_xx-5;
    if (mod(size_x,spacing) == 0)
        x_end = size_x/spacing - 1;
    else
        x_end = floor(size_x/spacing-1);
    end
    if (mod(size_y,spacing) == 0)
        y_end = size_y/spacing - 1;
    else
        y_end = floor(size_y/spacing-1);
    end
    array = ones(x_end*y_end,2);
    for i = 1:1:x_end
        for k = 1:1:y_end
            array((i-1)*(y_end)+k,1) = i*spacing;
            array((i-1)*(y_end)+k,2) = k*spacing;
        end
    end

    
    aa = 5*ones(size(array))+ array;
    a =aa; 
    
end