% This script does some preperation.

img_path = '/Volumes/ZJJ-4TB/Photos/16.11.02 Daocheng Yading/timelapse/01/jpg/';
img_pattern.print = 'IMG_%04d_0 copy.jpg';
img_pattern.regexp = '\<IMG_(\d{4})_0 copy\.jpg';

% Read image mask
if exist([img_path, 'mask.png'], 'file')
    mask = imread([img_path, 'mask.png']);
    mask = mask(:,:,1) > 0;
else
    mask = [];
end

% Parameters
default_focal_length = 16;
img_ref_digits = 9302;
index_info.last_index = -1;
index_info.ref_digits = img_ref_digits;
index_info.start_digits = 9302;
index_info.end_digits = 9320;

