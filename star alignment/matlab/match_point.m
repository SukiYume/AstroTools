function IDX = match_point(varargin)
% This function matches tow point sets
% IDX = match_point(dist_mat)
% IDX = match_point(sph1, sph2)
%
% INPUT
%   dist_mat:       m-by-n distance matrix
%   sph1, sph2:     m-by-2, n-by-2 spherical coordinates, [lambda, phi]
% OUTPUT
%   IDX:        n-by-2, index matrix

if nargin == 1
    IDX = match_point_by_dist_mat(varargin{1});
elseif nargin == 2
    IDX = match_point_by_tri_dist(varargin{1}, varargin{2});
end
end


function IDX = match_point_by_dist_mat(dist_mat)
[D12, I12] = sort(dist_mat, 2);
[D21, I21] = sort(dist_mat);
D21 = D21'; I21 = I21';

ind = I21(I12(:,1),1) == (1:size(dist_mat,1))';
d_th = min(prctile(D12(:,1), 30), prctile(D21(:,1), 30));
ind = ind & D12(:,1) < d_th;
IDX = [find(ind), I12(ind, 1)];
end


function pair_idx = match_point_by_tri_dist(sph1, sph2)
fprintf('building all triple distance data of image #1...\n');
db1 = build_triangle_db(sph1, 10);
fprintf('building all triple distance data of image #2...\n');
db2 = build_triangle_db(sph2, 10);

tri_dist1 = db1.tri_dist;
tri_dist2 = db2.tri_dist;
comb_idx1 = db1.comb_idx;
comb_idx2 = db2.comb_idx;

d_th = 0.003;
pair_idx = [];

candidate_num = 4;
[dist_mat, IDX] = pdist2(tri_dist2, tri_dist1, 'euclidean', 'smallest', candidate_num);
IDX = sub2ind([size(tri_dist1,1), size(tri_dist2,1)], ...
    repmat(1:size(tri_dist1,1), candidate_num, 1), IDX);
IDX = IDX(dist_mat < d_th);
[IDX1, IDX2] = ind2sub([size(tri_dist1,1), size(tri_dist2,1)], IDX);
IDX = [IDX1, IDX2];

msg_count = 0;
for i = 1:size(IDX,1)
    p1 = IDX(i, :);
    msg_count = msg_count + 1;
    if msg_count > 100
        fprintf('checking pair <%d,%d>, progress %.2f%%...\n', ...
            p1(1), p1(2), i/size(IDX,1)*100);
        msg_count = msg_count - 100;
    end
    sk1 = sort(combnk(comb_idx1(p1(1), :), 2), 2) * [db1.pts_num; 1];
    tmp_comb_idx1 = comb_idx1(p1(1), :);
    tmp_comb_idx2 = comb_idx2(p1(2), :);
    for j = 1:length(sk1)
        secondary_idx1 = setdiff(db1.search_idx(db1.search_idx(:,1) == sk1(j), 2), p1(1));
        for k = 1:length(secondary_idx1)
            tmp_secondary_comb_idx1 = comb_idx1(secondary_idx1(k), :);
            tmp_pattern1 = abs(bsxfun(@minus, tmp_comb_idx1', tmp_secondary_comb_idx1)) < 1;
            secondary_idx2 = IDX(IDX(:,1) == secondary_idx1(k), 2);
            for m = 1:length(secondary_idx2)
                tmp_secondary_comb_idx2 = comb_idx2(secondary_idx2(m), :);
                tmp_pattern2 = abs(bsxfun(@minus, tmp_comb_idx2', tmp_secondary_comb_idx2)) < 1;
                if all(tmp_pattern1(:) == tmp_pattern2(:))
                    pair_idx = [pair_idx; ...
                        unique([tmp_comb_idx1, tmp_secondary_comb_idx1], 'stable')', ...
                        unique([tmp_comb_idx2, tmp_secondary_comb_idx2], 'stable')'];
%                     tmp_idx1 = unique([tmp_comb_idx1, tmp_secondary_comb_idx1], 'stable');
%                     tmp_idx2 = unique([tmp_comb_idx2, tmp_secondary_comb_idx2], 'stable');
%                     [~, matH] = estimate_perspective_transform(pts1(tmp_idx1,:), pts2(tmp_idx2,:));
%                     disp(matH);
                end
            end
        end
    end
end

[pair_idx, ~, ic] = unique(pair_idx, 'rows');
ic_count = histc(ic, unique(ic));
pair_idx = pair_idx(ic_count > 10, :);

xyz1 = [cos(sph1(:,2)).*cos(sph1(:,1)), cos(sph1(:,2)).*sin(sph1(:,1)), sin(sph1(:,2))];
xyz2 = [cos(sph2(:,2)).*cos(sph2(:,1)), cos(sph2(:,2)).*sin(sph2(:,1)), sin(sph2(:,2))];
theta = acos(sum(xyz1(pair_idx(:,1), :) .* xyz2(pair_idx(:,2), :), 2));
pair_idx = pair_idx(theta < pi/6, :);
end


% function matH = find_perspective_projection(pts1, pts2)
% % 4-point algorithm
% if size(pts1,1) ~= 4 || size(pts2,1) ~= 4
%     error('ERROR! must take 4 points!');
% end
% 
% A = nan(9, 9);
% for i = 1:4
%     A(i*2-1:i*2, :) = kron([pts1(1), pts1(2), 1], -[1, 0, pts2(1); 0, 1, pts2(2)]);
% end
% A(9, :) = 0; A(9, 9) = 1;
% end
