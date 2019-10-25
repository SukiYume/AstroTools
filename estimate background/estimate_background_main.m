clear; clc; close all;

img_path = '/Volumes/ZJJ-4TB/Photos/17.08.12 Perseids/6D/';
img_name = 'IMG_3598_ground Panorama_back.tif';
img = imread([img_path, img_name]);
max_value = intmax(class(img));
img = double(img) / double(max_value);
img_size = size(img);

%%
f = figure(1); clf;
imshow(img);
hold on;

%%
select_radius = 0.008 * min(img_size(1:2));
sample_radius = 0.01 * min(img_size(1:2));
sample_pts_short_side = 5;
sample_interval = min(img_size(1:2)) / sample_pts_short_side;

[sample_x, sample_y] = meshgrid(linspace(1, img_size(2), floor(img_size(2) / sample_interval)), ...
    linspace(1, img_size(1), floor(img_size(1) / sample_interval)));
sample_pts = [sample_x(:), sample_y(:)];
p = [];
while true
    if ~isempty(p)
        delete(p);
    end
    p = plot(sample_pts(:,1), sample_pts(:,2), 'y+', 'markersize', 14);
    
    [selected_x, selected_y] = getpts(f);
    selected_pts = [selected_x, selected_y];
    if isempty(selected_pts);
        break;
    end
    
    [dist_mat, idx] = pdist2(sample_pts, selected_pts, 'euclidean', 'smallest', 1);
    del_idx = dist_mat < select_radius;
    add_idx = dist_mat >= select_radius;
    sample_pts(idx(del_idx), :) = [];
    sample_pts = [sample_pts; selected_pts(add_idx, :)];
end
sample_pts_num = size(sample_pts, 1);

%%
sample_value = nan(sample_pts_num, 3);
for i = 1:sample_pts_num
    min_x = max(min(floor(sample_pts(i, 1) - sample_radius), img_size(2)), 1);
    max_x = max(min(floor(sample_pts(i, 1) + sample_radius), img_size(2)), 1);
    min_y = max(min(floor(sample_pts(i, 2) - sample_radius), img_size(1)), 1);
    max_y = max(min(floor(sample_pts(i, 2) + sample_radius), img_size(1)), 1);
    sample_value(i, :) = median(reshape(img(min_y:max_y, min_x:max_x, :), [], 3));
end

%%
downsample_rate = 4;
background = zeros([floor(img_size(1:2) / downsample_rate), 3]);
background_size = size(background);
progress_step = 0.05;
for i = 1:3
    fprintf('fitting data of channel #%d...\n', i);
    f = tpaps(sample_pts', sample_value(:, i)', 0.5);
    fprintf('interpolating channel #%d...\n', i);
    tmp_count = 0;
    for x = 1:background_size(2)
        tmp_count = tmp_count + 1 / background_size(2);
        [x_grid, y_grid] = meshgrid(x, 1:background_size(1));
        background(:, x, i) = fnval(f, [x_grid(:)'; y_grid(:)'] * downsample_rate);
        if tmp_count > progress_step
            fprintf(' progress %.2f%%...\n',  100 * x / background_size(2));
            tmp_count = tmp_count - progress_step;
        end
    end
end

figure(2); clf;
imshow(background);
