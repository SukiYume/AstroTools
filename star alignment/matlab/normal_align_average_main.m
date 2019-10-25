clear; clc; close all;

img_path = '/Volumes/ZJJ-4TB/Photos/17.04.21 Ming_antu/6D 03/';
out_path = '/Volumes/ZJJ-4TB/Photos/17.04.21 Ming_antu/6D 03/';
regexp_pattern = '\<IMG_(\d{4})_0\.tif$';

% Read image mask
if exist([img_path, 'mask.png'], 'file')
    fprintf('Reading mask image...\n');
    mask = imread([img_path, 'mask.png']);
    mask = mask(:,:,1) > 0;
else
    mask = [];
end

[files, digits, img_info] = get_image_files(img_path, regexp_pattern);

start_digits = 3966;
end_digits = 3971;
ref_digits = 3971;

file_idx = (digits >= start_digits & digits <= end_digits);
files = files(file_idx);
digits = digits(file_idx);
ref_idx = find(abs(digits - ref_digits) < 0.5);

metric_th = 1000;
img_store = cell(length(files), 1);
feature_store = cell(length(files), 1);

k = 1;
for i = 1:length(files)
    if digits(i) < start_digits || digits(i) > end_digits
        continue;
    end
    fprintf('Reading image %s...\n', files(i).name);
    img = imread([img_path, files(i).name]);
    if isinteger(img)
        img = double(img) / double(intmax(class(img)) - 1);
    end
    img_store{k} = img;
    
    fprintf('Converting image to gray...\n');
    img_gray = rgb2gray(img_store{k});
    
    fprintf('Detecting features...\n');
    if ~isempty(mask)
        points = detectSURFFeatures(img_gray .* mask, 'MetricThreshold', metric_th);
    else
        points = detectSURFFeatures(img_gray, 'MetricThreshold', metric_th);
    end
    [features, points] = extractFeatures(img_gray, points);
    f.features = features;
    f.points = points;
    f.pts = double(points.Location);
    feature_store{k} = f;
    
    k = k + 1;
end
    
%%
fprintf('Denoising...\n');
img = align_average(img_store, feature_store, ref_idx, ...
    @(f1, f2)matchFeatures(f1.features, f2.features, 'Unique', true));

figure(1); clf;
imshow(img);
drawnow;

%%
fprintf('Writing image...\n');
imwrite(uint16(img*65535), [out_path, files(ref_idx).name, '_grd_avg.tif']);

