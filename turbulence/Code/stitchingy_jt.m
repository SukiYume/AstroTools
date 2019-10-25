function a = stitchingy_jt(img)
% This function takes the sets of images generated as a structure img
% from the stitching_jt function that has already stitched sub-frames
% in the x-direction and does the stitching in the y direction using
% the same algorithm but adjusted initial positions and test size
%


img_temp = img(:,1:end-3,1:end);

pos_y = 6;
y_len = 8;
max_corr = -1;
x_len= 4;

init_1(:,:) = img_temp(1,pos_y:pos_y+y_len,end-x_len:end);

for i=1:1:(size(img_temp,1))-1
    
    max_corr = -1;
    corr_val=-1;
    for ii = 1:1:(size(img_temp(i+1,:,:),3)-x_len)
        for jj = 1:1:40 %(size(img_temp(i+1,:,:),2)-y_len)
            init_2(:,:) = img_temp(i+1,jj:jj+y_len,ii:ii+x_len);
            corr_val = corr2(init_1,init_2);
            
            if(isnan(corr_val))
                max_corr_coor = max_corr_coor;
            elseif(corr_val > max_corr)
                max_corr_coor = [ii jj];
                max_corr = corr_val;
            end
        end
    end
    y_shift = pos_y - max_corr_coor(2);
    
    if(y_shift > 0)
        clear a2;
        if(i==1)
            a1(:,:) = img_temp(1,y_shift:end,1:end-x_len-1);
            a2(:,:) = img_temp(i+1,1:end-y_shift+1,max_corr_coor(1):end);
        elseif(i>1)
            clear a1;
            a1(:,:) = a3(y_shift:end,1:end-x_len-1);
            a2(:,:) = img_temp(i+1,1:size(a1,1),max_corr_coor(1):end);
        end
        
    elseif(y_shift == 0)
        clear a2;
        if(i==1)
            a1(:,:) = img_temp(1,1:end,1:end-x_len-1);
            a2(:,:) = img_temp(i+1,1:size(a1,1),max_corr_coor(1):end);
            
        elseif(i>1)
            clear a1;
            a1(:,:) = a3(1:end,1:end-x_len-1);
            a2(:,:) = img_temp(i+1,1:size(a1,1),max_corr_coor(1):end); %
        end
    else
        clear a2;
        if(i==1)
            a2(:,:) = img_temp(i+1,-y_shift+1:end-1,max_corr_coor(1):end);
            a1(:,:) = img_temp(1,1:end+y_shift-1,1:end-x_len-1);
        elseif(i>1)
            clear a1;
            a1(:,:) = a3(1:min(size(img_temp(i+1,:,:),2)+y_shift,size(a3,1)),1:end-x_len);
            a2(:,:) = img_temp(i+1,(-y_shift+1):(size(a1,1)-y_shift),max_corr_coor(1):end); %
        end
    end
    clear a3;  clear init_1;
    a3(:,:) = cat(2,a1,a2);
    a3=a3(:,any(a3));
    
    init_1(:,:) = a3(pos_y:pos_y+y_len,end-x_len:end);
end
a4(1:size(a3,1),1:size(a3,2)) = a3(:,:);

a = permute(a4,[2 1]);

end