function db = build_triangle_db(sph_coord, varargin)
% This function builds a database of every three-point group,
% recording the angle distance between every two points in group.
%
% INPUT
%   sph_coord:  m-by-2, the spherical coordinates, [lambda, phi], in rad
%   [max_arc]:  scalar, the max angle distance in a tri-point group,
%               in degree
% OUTPUT
%   db:     the database

if nargin == 1
    max_arc = 20 * pi / 180;
elseif nargin == 2
    max_arc = varargin{1} * pi / 180;
else
    fprintf('ERROR! wrong input arguments!\n');
    db = [];
    return;
end

pts_num = size(sph_coord, 1);
xyz = [cos(sph_coord(:,2)).*cos(sph_coord(:,1)), ...
    cos(sph_coord(:,2)).*sin(sph_coord(:,1)), ...
    sin(sph_coord(:,2))];

dist_mat = acos(1 - pdist2(xyz, xyz, 'cosine'));
comb_idx = combnk(1:pts_num, 3);

[~, IDX] = min(sph_coord(sub2ind(size(sph_coord), comb_idx, 2*ones(size(comb_idx)))), [], 2);
IDX = mod([IDX, IDX + 1, IDX + 2] - 1, 3) + 1;
comb_idx = comb_idx(sub2ind(size(comb_idx), repmat((1:size(comb_idx,1))', [1, 3]), IDX));

IDX = sum((cross(xyz(comb_idx(:,1),:) - xyz(comb_idx(:,2),:), ...
    xyz(comb_idx(:,2),:) - xyz(comb_idx(:,3),:))) .* xyz(comb_idx(:,1),:), 2) < 0;
comb_idx(IDX,2:3) = fliplr(comb_idx(IDX,2:3));

d1 = dist_mat(sub2ind([pts_num, pts_num], comb_idx(:,1), comb_idx(:,2)));
d2 = dist_mat(sub2ind([pts_num, pts_num], comb_idx(:,2), comb_idx(:,3)));
d3 = dist_mat(sub2ind([pts_num, pts_num], comb_idx(:,3), comb_idx(:,1)));
tri_dist = [d1, d2, d3];

IDX = max(tri_dist, [], 2) < max_arc;

db.pts_num = pts_num;
% db.idx = find(IDX);
db.comb_idx = comb_idx(IDX, :);
db.tri_dist = tri_dist(IDX, :);

search_idx = nan(3*sum(IDX), 2);
for i = 1:sum(IDX)
    tmp = sort(combnk(db.comb_idx(i, :), 2), 2);
    search_idx(i*3-2:i*3, :) = [tmp * [pts_num; 1], i*ones(size(tmp,1), 1)];
end
db.search_idx = search_idx;
end