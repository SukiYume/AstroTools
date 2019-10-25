% This script aligns the star to a given reference image,
% and average them to get a denoised image.

clear; clc; close all;

img_path = '/Volumes/ZJJ-4TB/Photos/17.04.21 Ming_antu/6D 03/';
out_path = '/Volumes/ZJJ-4TB/Photos/17.04.21 Ming_antu/6D 03/';
regexp_pattern = '\<IMG_(\d{4})_0\.tif$';

[files, digits, img_info] = get_image_files(img_path, regexp_pattern);
default_focal_length = 20;

start_digit = 3960;
end_digit = 3965;

file_idx = (digits >= start_digit & digits <= end_digit);
files = files(file_idx);
digits = digits(file_idx);

img_num = length(files);

avg_img = 0;

k = 1;
for i = 1:length(files)
    if digits(i) < start_digit || digits(i) > end_digit
        continue;
    end
    fprintf('Reading image %s...\n', files(i).name);
    img = imread([img_path, files(i).name]);
    if isinteger(img)
        img = double(img) / double(intmax(class(img)) - 1);
    end
    avg_img = avg_img * (k - 1) / k + img / k;
    
    k = k + 1;
end
    
%%
figure(1); clf;
imshow(avg_img);
drawnow;

fprintf('Writing image...\n');
imwrite(uint16(avg_img*65535), [out_path, files(1).name, '_ground_avg.tif']);




% % This script average images to get a denoised image.
% 
% clear; clc; close all;
% 
% prepare_config;
% 
% % Read reference image
% [img_ref, index_info, info] = read_image(img_path, img_pattern, index_info);
% img_size = size(img_ref);
% ref = imref2d(img_size(1:2), [1, img_size(2)], [1, img_size(1)]);
% if isfield(info, 'DigitalCamera') && isfield(info.DigitalCamera, 'FocalLength')
%     f = info.DigitalCamera.FocalLength;
% else
%     f = default_focal_length;
% end
% 
% % Read image
% index_info.method = 'continous';
% index_info.last_index = -1;
% 
% img = 0; mean_img = img_ref;
% img_num = 1;
% while ~isempty(img)
%     [img, index_info, info] = read_image(img_path, img_pattern, index_info);
%     if isempty(img)
%         break;
%     end
%     if isfield(info, 'DigitalCamera') && isfield(info.DigitalCamera, 'FocalLength')
%         f = info.DigitalCamera.FocalLength;
%     else
%         f = default_focal_length;
%     end
%     img_num = img_num + 1;
%     mean_img = mean_img / img_num * (img_num - 1) + img / img_num;
%     
%     % show image
%     figure(1); clf;
%     imshow(mean_img);
%     pause(.1);
% end
% 
% %% Write image
% image_name = [sprintf(img_pattern.print, img_ref_digits), '_naive_avg.tif'];
% imwrite(uint16(mean_img * double(intmax('uint16'))), [img_path, image_name]);
