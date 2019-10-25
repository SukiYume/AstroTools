function plot_matches(pts1, pts2, IDX)
if isempty(IDX)
    assert(size(pts1,1) == size(pts2,1));
    IDX = repmat((1:size(pts1,1))', 1, 2);
end
% figure;
hold on;
plot(pts1(IDX(:,1),1), pts1(IDX(:,1),2), 'o');
plot(pts2(IDX(:,2),1), pts2(IDX(:,2),2), 'xr');
for i = 1:size(IDX,1)
    plot([pts1(IDX(i,1),1), pts2(IDX(i,2),1)], [pts1(IDX(i,1),2), pts2(IDX(i,2),2)], 'g');
end
end