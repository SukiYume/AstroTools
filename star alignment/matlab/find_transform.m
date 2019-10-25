function tf = find_transform(pts1, pts2, pair_idx)
% This function find transform between images. The result tf
% transform image1 to image2.
%   img_tf = imwarp(img, tf, 'OutputView', ref);
%
% INPUT
%   pts1, pts2:     struct. including fields of:
%                   'pts', 'polar_feature'
% OUTPUT
%   tf:     tform, the output of projective2d() function

% Find the perspective transformation using the initial match
% Step 1. Randomly choose 20 points evenly distributed on the image
tmp_pts = bsxfun(@times, rand(20, 2), max(pts1));
% Step 2. Find nearest points from pts1
tmp_dist = pdist2(tmp_pts, pts1(pair_idx(:,1),:));
[~, tmp_ind] = min(tmp_dist, [], 2);
tmp_pts1 = pts1(pair_idx(tmp_ind,1),:);
tmp_pts2 = pts2(pair_idx(tmp_ind,2),:);
% Step 3. Find initial homography
[matH, ~] = compute_homography(tmp_pts1, tmp_pts2);

% Use all points to fine tune the matH
p0 = [pts1, ones(size(pts1, 1), 1)] * matH';
p0 = bsxfun(@times, p0(:,1:2), 1./p0(:,3));
dist_mat = pdist2(p0, pts2);
[min_dist, ind] = min(dist_mat, [], 2);
pair_idx = [(1:size(pts1,1))', ind];
pair_idx = pair_idx(min_dist < 5, :);
[matH, pair_idx] = compute_homography(pts1(pair_idx(:,1),:), pts2(pair_idx(:,2),:));
fprintf('Find %d matched points!\n', size(pair_idx, 1));
    
% The result
tf = projective2d(matH');
end
