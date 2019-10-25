%%Project V1.0
% Timur Starobinets
% James Peng

% This project addresses the issues that arise from turbulance distortions
% of images by taking a set of frames of the same object, calculating
% deformation patterns and then, through iteration, interpolating the
% correct, adjusted image


close all; clear all;
load ../MoonSurface; %File containing the frames


%images info: x = 400 x y = 430

% Using 80x80 pixel blocks with 30 pixel overlap to localize deformation
% errors. The image is reshaped into a Nx2 with first column giving X
% coordinates and second column giving Y coordinates
size_y = 80;
size_x = 80;
gamma = 5000; % value suggested in the Peyman Milanfar's paper
initx = 1;
inity = 1;
pix_vect = pixel_map(size_x, size_y); % form: (x,y)
spacing = 15;
overlap = 30;


spacing_dim = round(min(size_x,size_y)/spacing)-1;

img_cnt = 1;
% The following forloops run through all pixels and test points and
% generate sets of sub-frames with the corrected images

for x=1:1:4      %maximum value: ceil(size(frames_gray,2)/(size_x-10))
    inity = 1;
    for y=1:1:4  %maximum value: ceil(size(frames_gray,1)/(size_y-10))
        
        %average image computation loop
        for k = 1 : 50
            whole_im = im2double(frames_gray(:,:,k));
            thisImage = im2double(frames_gray(inity:(inity+size_y-1),initx:(initx+size_x-1),k)); %frame(y,x)
            if k == 1
                R = thisImage;
                whole_R = whole_im;
            else
                R = R + thisImage;
                whole_R = whole_R + whole_im;
            end
        end
        
        R = R/k; % R is an averaged subrame
        
        whole_R = whole_R/k; % whole_R is a whole averaged image
        
        %Pulling out a single subframe out of the video for analysis
        test_im = im2double(frames_gray(inity:(inity+size_y-1), ...
                  initx:(initx+size_x-1), 1));
        R_im = reshape(R,1,size_x*size_y);
        G = reshape(test_im,1,size_x*size_y);
        
        % Storing data as two column and single column matricies for ease
        % of further manipulations
        init_loc = grid_map(size_y, size_x,spacing);  %init_loc form: (x,y)
        init_loc_comp = init_loc(:,1)+1j*init_loc(:,2); %form (x+jy)
        
        %test point size for loops
        tp_size = length(init_loc);
        %declaring correlation vector
        corr_vec = zeros(tp_size,121);
        
        %initializing conditions:
        max_corr = -1;
        max_corr_coor = zeros(tp_size,2);
        c = zeros(tp_size,1);
        
        % Correlation loop - goes through and finds most correlated new
        % locations of the test points
        for k=1:1:tp_size
            cnt = 1;
            init_x = init_loc(k,1);
            init_y = init_loc(k,2);
            
            for ii = -5:1:5
                for jj = -5:1:5
                    posx = init_loc(k,1)+ii;
                    posy = init_loc(k,2)+jj;
                    % Using function: r = corr2(A,B) to find correlation
                    % between images
                    corr_val = corr2(R(init_y-5:init_y+5, ...
                        init_x-5:init_x+5),test_im(posy-5:posy+5, ...
                        posx-5:posx+5));
                    
                    if(isnan(corr_val))
                        max_corr_coor(k,:) = [init_x init_y];
                    elseif(corr_val > max_corr)
                        max_corr_coor(k,:) = [posx posy];
                        max_corr = corr_val;
                    end
                    cnt = cnt + 1;
                end
       
            end
            max_corr = -1;
        end
        %% Plotting (can be removed)
        %figure
        %imshow(R);
        %hold on;
        %plot(init_loc(:,1),init_loc(:,2), '.', 'MarkerEdgeColor', 'r');
        %plot(max_corr_coor(:,1),max_corr_coor(:,2), ...
        %    '.','MarkerEdgeColor','b');
        
        %%
        
        
        % Deformation vector
        p_deform1 = (max_corr_coor(:,1)-(init_loc(:,1)))'; %X deformations
        p_deform2 = (max_corr_coor(:,2)-(init_loc(:,2)))'; %Y deformations
        
        % Deformation vector p_deform is defined as the set of x and y
        % deformations: p_deform = [x1_def,..., xm_def, y1_def,..., yn_def]
        p_deform = (cat(2,p_deform1,p_deform2))';
        p_deform_l = - p_deform;
        p_new = (cat(2,p_deform',p_deform_l'))';
        
        %Cost minimization loop
        for cost_cnt=1:1:10
            p = p_new;  %p_(l+1) = p_l - H^(-1)b
            %Running deformation algorithm through non-linear interpolation
            %for each pixel using all test points. 
            for im_cnt = 1:1:length(pix_vect)
                % B-Spline basis calculations
                % calling bspline_func: ci =
                % bspline_func(x_t,x_init,y_t,y_init,x_int,y_int,k);
                c = bspline_func(real(init_loc_comp(:)), ...
                    pix_vect(im_cnt,1), imag(init_loc_comp(:)), ...
                    pix_vect(im_cnt,2),spacing,spacing, tp_size);
                ci(im_cnt,:) = (c');
                
                
                %Basis function matrix for each pixel:
                % A(x) = [ c1 ... cn  0 ... 0  ]
                %        [  0 ... 0   c1 ...cn ] 
                
                A = zeros(2,2*tp_size);
                A(1,1:tp_size) = ci(im_cnt,:);
                A(end,(tp_size+1):end) = ci(im_cnt,:);
                
                %W_r is deformation position matrix for any given 
                %W_l is the reverse deformation matrix for correction
                % Both call function Wx. Wx = x + A(x)*p_right
                W_r(im_cnt,:) = Wx(pix_vect(im_cnt,:),A,p_deform);
                W_l(im_cnt,:) = Wx(pix_vect(im_cnt,:),A,p_deform_l);
                
                % Making sure the deformation matrix does not force pixels
                % out of the bounds of the original subframe. This causes
                % errors at the edges of the corrected subframe, and thus
                % the overlapping technique is used to correct for the
                % distortions near the edges.
                if(W_r(im_cnt,2)>size_x)
                    W_r(im_cnt,2) = size_x;
                end
                if(W_r(im_cnt,2)<1)
                    W_r(im_cnt,2)=1;
                end
                if(W_r(im_cnt,1)>size_y)
                    W_r(im_cnt,1)= size_y;
                end
                if(W_r(im_cnt,1)<1)
                    W_r(im_cnt,1)=1;
                end
                
                if(W_l(im_cnt,2)>size_x)
                    W_l(im_cnt,2) = size_x;
                end
                if(W_l(im_cnt,2)<1)
                    W_l(im_cnt,2)=1;
                end
                if(W_l(im_cnt,1)>size_y)
                    W_l(im_cnt,1)= size_y;
                end
                if(W_l(im_cnt,1)<1)
                    W_l(im_cnt,1)=1;
                end
                
                
                % Recomputing deformation and motion vectors through the
                % introduction of the symmetry constraints into B-spline
                % algorithm and then using Gauss-Newton method to optimize
                % the cost function
                W_r(im_cnt,1:2) = [W_r(im_cnt,2) W_r(im_cnt,1)];
                W_l(im_cnt,1:2) = [W_l(im_cnt,2) W_l(im_cnt,1)];
                r(im_cnt,:) = gradient_jt(R,W_r(im_cnt,:));
                r_l(im_cnt,:) = gradient_jt(test_im,W_l(im_cnt,:));
                Cx(im_cnt,:,:) = ci(im_cnt,:)'*ci(im_cnt,:);
                rx2Cx(:,:) = (r(im_cnt,1))^2*Cx(im_cnt,:,:);
                rx2Cx_l(:,:) = (r_l(im_cnt,1))^2*Cx(im_cnt,:,:);
                rrCx(:,:) = r(im_cnt,1)*r(im_cnt,2)*Cx(im_cnt,:,:);
                rrCx_l(:,:) = r_l(im_cnt,1)*r_l(im_cnt,2)*Cx(im_cnt,:,:);
                ry2Cx(:,:) = (r(im_cnt,2))^2*Cx(im_cnt,:,:);
                ry2Cx_l(:,:) = (r_l(im_cnt,2))^2*Cx(im_cnt,:,:);
                Hx_r(im_cnt,:,:) = [rx2Cx(:,:) rrCx(:,:); ...
                    rrCx(:,:) ry2Cx(:,:)];
                Hx_l(im_cnt,:,:) = [rx2Cx_l(:,:) rrCx_l(:,:); ...
                    rrCx_l(:,:) ry2Cx_l(:,:)];
                dx_r(im_cnt,:) = (r(im_cnt,:)*A)';
                dx_l(im_cnt,:) = (r_l(im_cnt,:)*A)';
                b_rx(im_cnt,:) = dx_r(im_cnt,:)* ...
                    (interpol_jt(R,W_r(im_cnt,:))-G(im_cnt));
                b_lx(im_cnt,:) = dx_l(im_cnt,:)* ...
                    (interpol_jt(test_im,W_l(im_cnt,:))-R_im(im_cnt));
                
            end
            b_r = (sum(b_rx,1))';
            b_l = (sum(b_lx,1))';
            
            H_r(:,:) = sum(Hx_r,1);
            H_l(:,:) = sum(Hx_l,1);
            gam_ident = gamma*eye(size(H_r));
            H1 = H_r+gam_ident;
            H2 = gam_ident;
            H3 = H_l+gam_ident;
            H = [H1 H2; H2 H3];
            
            b = (cat(2,(b_r+p_deform+p_deform_l)', ...
                (b_l+p_deform+p_deform_l)'))';
            p_new = p-pinv(H)*b; % updated deformation vector 
        end
        
        p_new_inv = p_new(length(p_deform)+1:end);
        
        for im_cnt = 1:1:length(pix_vect)
            W_r_fin(im_cnt,:) = Wx(pix_vect(im_cnt,:),A,p_new_inv);
            
            if(W_r_fin(im_cnt,2)>size_x)
                W_r_fin(im_cnt,2) = size_x;
            end
            if(W_r_fin(im_cnt,2)<1)
                W_r_fin(im_cnt,2)=1;
            end
            if(W_r_fin(im_cnt,1)>size_y)
                W_r_fin(im_cnt,1)= size_y;
            end
            if(W_r_fin(im_cnt,1)<1)
                W_r_fin(im_cnt,1)=1;
            end
            
            W_r_fin(im_cnt,1:2) = [W_r_fin(im_cnt,2) W_r_fin(im_cnt,1)];
            
            % Using Reverse-deformation function to do correction on the
            % image. This must minimize the difference to the averged img 
            modif_Im(im_cnt,:) = R_w_jt(test_im, W_r_fin(im_cnt,:));
        end
        
        
        
        %%
        modif_Im_shaped = reshape(modif_Im(1:1:size_y*size_x,1), size_y,[]);
        
        modif_im_reshaped(x,y,:,:) = modif_Im_shaped';
        inity = inity+size_y-overlap;
    end
    initx = initx+size_x-overlap;
end
%%
% Stitching functions to first stitch in x direction and then stitching the
% image in y direction to get an overall image.
img_stitched_x = stitching_jt(modif_im_reshaped(1:4,1:4,:,:));
img_stitched = stitchingy_jt(img_stitched_x);
%figure; imshow(img_stitched);

%%
% Running sharpening filter. In the future could use Bayesian
% reconstruction for this to allow for finetuning and sharper results
filt_new = fspecial('log',[4 4],0.75); %low pass
modif_im_conv = imfilter(img_stitched,filt_new,'symmetric'); %low passed

final_image(:,:) = (img_stitched-modif_im_conv)'; %high=initial-low filter

start_img = im2double(frames_gray(1:size(final_image,1),...
                      1:size(final_image,2),1));
figure;
subplot(2,2,1); imshow(whole_R(1:size(final_image,1),...
                       1:size(final_image,2))); %averaged
subplot(2,2,2); imshow(start_img); %single frame
subplot(2,2,3); imshow(img_stitched); %corrected
subplot(2,2,4); imshow(final_image'); %corrected and sharpened
