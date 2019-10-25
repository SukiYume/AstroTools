% This script reads images, detects stars, align stars between two images, and transform
% one image so that it can align to the other.

clear; clc; close all;

img_path = '/Users/jiajiezhang/Documents/ShootingStar/';
img_pattern.print = 'IMG_%04d_0.jpg';
img_pattern.regexp = '\<IMG_(\d{4})_0\.jpg';

% Read image mask
mask = imread([img_path, 'mask.png']);
mask = mask(:,:,1) > 0;

% Parameters
f = 16;
img_ref_digits = 7208;

% Read reference image
img_ref = read_image(img_path, img_pattern, 'digit', img_ref_digits);
img_size = size(img_ref);
ref = imref2d(img_size(1:2), [1, img_size(2)], [1, img_size(1)]);

% Extract features of reference image
feature_ref = extract_star_feature(rgb2gray(img_ref), mask, f);

% Read image
img = read_image(img_path, img_pattern, 'index', -1);

%% Extract features of this image
feature = extract_star_feature(rgb2gray(img), mask, f);

%% Find the transform between the two images
tf = find_transform(feature_ref, feature);

%% Show image
img_tf = imwarp(img, tf, 'OutputView', ref);
figure(1); clf;
imshow(img_tf);

% Save image