clear; clc; close all;

img_path = '/Volumes/ZJJ-4TB/Photos/16.08.11 Perseids at Golmud/background/';
img_pattern = 'IMG_%04d%s.tif';
img_postfix = '_0';
img_start = 8971;
img_end = img_start + 3;
img_max_value = 65535;

img_avg = 0;
for i = img_start : img_end
    n = i - img_start;
    img_name = [img_path, sprintf(img_pattern, i, img_postfix)];
    if ~exist(img_name, 'file')
        continue;
    end
    fprintf('reading image %s ...\n', sprintf(img_pattern, i, img_postfix));
    img = double(imread(img_name)) / img_max_value;
    img_avg = img_avg * n / (n+1) + double(img) / (n+1);
    figure(1); clf;
    imshow(img_avg);
    pause(.1);
end

imwrite(uint16(img_avg * img_max_value), [img_path, sprintf(img_pattern, img_start, ...
    [img_postfix, '_avg'])]);
