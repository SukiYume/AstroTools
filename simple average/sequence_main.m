clear; clc; close all;

proj_path = '/Users/jiajiezhang/Documents/Timelapse/15.06.20 Wulong Gou/2/';
img_path = 'tif/';
out_path = 'tmp tif/';
img_pattern = '_MG_%d.tif';
mask_img_name = 'ground_mask.png';
avg_half_n = 5;

start_num = 4208;
end_num = 4391;
img_max_val = 65535;
mask_max_val = 65535;

img_mask = double(imread([proj_path, mask_img_name])) / mask_max_val;
if size(img_mask, 3) > 1
    img_mask = img_mask(:, :, 1);
end

avg_img = 0;
for i = start_num : start_num+2*avg_half_n
    fprintf('reading image %s...\n', sprintf(img_pattern, i));
    img = double(imread([proj_path, img_path, sprintf(img_pattern, i)])) / img_max_val;
    avg_img = avg_img + img;
end
for i = start_num : end_num
    fprintf('reading image %s...\n', sprintf(img_pattern, i));
    img = double(imread([proj_path, img_path, sprintf(img_pattern, i)])) / img_max_val;
    if i - start_num > avg_half_n && end_num - i > avg_half_n
        fprintf('reading old image %s...\n', sprintf(img_pattern, i - avg_half_n));
        old_img = double(imread([proj_path, img_path, sprintf(img_pattern, i - avg_half_n)])) / img_max_val;
        fprintf('reading new image %s...\n', sprintf(img_pattern, i + avg_half_n));
        new_img = double(imread([proj_path, img_path, sprintf(img_pattern, i + avg_half_n)])) / img_max_val;
        avg_img = avg_img - old_img;
        avg_img = avg_img + new_img;
    end
    out_img = bsxfun(@times, avg_img / (2*avg_half_n + 1), img_mask) + bsxfun(@times, img, 1-img_mask);
    fprintf('writing image %s(%d/%d)...\n', sprintf(img_pattern, i), i-start_num+1, end_num-start_num+1);
    imwrite(uint16(out_img * img_max_val), [proj_path, out_path, sprintf(img_pattern, i)]);
end
