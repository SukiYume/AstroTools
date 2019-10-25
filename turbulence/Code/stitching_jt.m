function a = stitching_jt(img)
% This function goes through the sub-blocks and stitches each row together,
% returning a structure of stitched strips of images.

%First the images are stripped off a few pixels to make sure black line
%artifacts from deformations vectors are not present. Then, a test block is
%taken from a left image and is searched for in the neighboring right
%image, combining the two based on the highest-correlated set. Typical
%correleations are 0.9998

img_temp = img(:,:,4:end,4:end);
pos_y = 8;
y_len = 20;
max_corr = -1;
x_len= 10;


%Correlation loop - goes through and finds most correlated new locations

for j = 1:1:(size(img_temp,2))
    clear init_1; clear init_2; clear a1; clear a2; clear a3; clear i;
    
    init_1(:,:) = img_temp(1,j,pos_y:pos_y+y_len,end-x_len:end);
    
    for i=1:1:(size(img_temp,1))-1
        max_corr = -1;
        corr_val=-1;
        for ii = 1:1:50 % maximum: size(img_temp(i+1,1,:,:),4)
            for jj = 1:1:50
                init_2(:,:) = img_temp(i+1,j,jj:jj+y_len,ii:ii+x_len);
                corr_val = corr2(init_1,init_2);
                
                if(isnan(corr_val))
                    max_corr_coor = [1 1];
                elseif(corr_val > max_corr)
                    max_corr_coor = [ii jj];
                    max_corr = corr_val;
                end
            end
        end
        
        y_shift = pos_y - max_corr_coor(2);
        if(i==1 && j==5)
        end
        if(y_shift > 0)
            clear a2;
            if(i==1)
                a1(:,:) = img_temp(1,j,y_shift+1:end,1:end-x_len-1);
                a2(:,:) = img_temp(i+1,j,1:end-y_shift,...
                    max_corr_coor(1):end);
            elseif(i>1)
                clear a1;
                a1(:,:) = a3(y_shift:end,1:end-x_len-1);
                a2(:,:) = img_temp(i+1,j,1:size(a1,1),...
                    max_corr_coor(1):end);
            end
            
        elseif(y_shift == 0)
            clear a2;
            if(i==1)
                a1(:,:) = img_temp(1,j,1:end,1:end-x_len-1);
                a2(:,:) = img_temp(i+1,j,1:size(a1,1),...
                    max_corr_coor(1):end);
                
            elseif(i>1)
                clear a1;
                a1(:,:) = a3(1:end,1:end-x_len-1);
                a2(:,:) = img_temp(i+1,j,1:size(a1,1),...
                    max_corr_coor(1):end);
            end
        else
            clear a2;
            if(i==1)
                a2(:,:) = img_temp(i+1,j,-y_shift+1:end-1,...
                    max_corr_coor(1):end);
                a1(:,:) = img_temp(1,j,1:end+y_shift-1,1:end-x_len-1);
            elseif(i>1)
                clear a1;
                a1(:,:) = a3(1:min(size(img_temp(i+1,j,:,:),3)+...
                    y_shift,size(a3,1)),1:end-x_len);
                a2(:,:) = img_temp(i+1,j,...
                    (-y_shift+1):(size(a1,1)-y_shift),...
                    max_corr_coor(1):end);
            end
        end
        clear a3;
        a3(:,:) = cat(2,a1,a2);
        a3=a3(:,any(a3));
        
        clear init_1;
        init_1(:,:) = a3(pos_y:pos_y+y_len,end-x_len:end);
    end
    
    a4(j,1:size(a3,1),1:size(a3,2)) = a3(:,:);
end

a = permute(a4,[1 3 2]);

end
