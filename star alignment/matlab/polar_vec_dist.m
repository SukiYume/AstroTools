function d = polar_vec_dist(X, Y)
% The distance function
% Taking as arguments a 1-by-n vector X containing a single observation from set1 or set1, 
% an m2-by-n matrix Y containing multiple observations from set1 or set2, 
% and returning an m2-by-1 vector of distances d, whose Jth element is the distance 
% between the observations X and Y(J,:).
dim = length(X);
n = 3;
X = reshape(X, [], n);
Y = Y';
Y = [reshape(Y(1:dim/n,:), [], 1), reshape(Y(dim/n+1:dim/n*2, :), [], 1), reshape(Y(dim/n*2+1:dim, :), [], 1)];
D = pdist2(X, Y);
d = median(reshape(min(D), dim/n, []))';
end