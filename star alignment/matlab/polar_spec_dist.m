function d = polar_spec_dist(X, Y)
% X = X - mean(X);
% Y = bsxfun(@minus, Y, mean(Y, 2));

% X_fft = fft(X);
% Y_fft = fft(Y, [], 2);
% d = real(ifft(bsxfun(@times, X_fft, Y_fft), [], 2));
% d = max(d, [], 2);

% d = sum(bsxfun(@times, X, Y), 2);
d = bsxfun(@times, X, Y);
d = 1-sum(d, 2);
end