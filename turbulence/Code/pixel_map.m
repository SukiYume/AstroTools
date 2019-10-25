function a = pixel_map(size_x, size_y)
% this function remaps the image matrix into a Nx2 matrix with first column
% giving the x coordinates of the pixels and second column giving y
% coordinates of the pixels.
    array = ones(size_x*size_y,2);
    for i = 1:1:size_x
        for k=1:1:size_y
            array((i-1)*size_y+k,2) = i;
            array((i-1)*size_y+k,1) = k;
        end
    end
    a = array;
end