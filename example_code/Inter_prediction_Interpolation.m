% ================================================================
% The example image is from cifar10 
% https://paperswithcode.com/dataset/cifar-10
% Modified by chian-chen, Date: 2024/06/20
% Example in Tutorial P.37-40
% ================================================================


example_img = double(rgb2gray(imread('../example_data/example.jpg')));
figure;
image(example_img);
colormap(gray(256))
truesize([320, 320]);
title('source image');

% Luma
expanded_img = step1(example_img);
interpolation_img = imresize(expanded_img, 2, 'bilinear');
figure;
image(interpolation_img);
colormap(gray(256))
truesize([320, 320]);
title('interpolation for luma component');

% Chroma
img_resized = imresize(example_img, 8, 'bilinear');
figure;
image(img_resized);
colormap(gray(256))
truesize([320, 320]);
title('interpolation for chroma component');

%-------------------------------------------------------
%% Luma Interpolation, using 6-tap filter

function expanded_img = step1(example_img)
    [h, w] = size(example_img);
    expanded_img = zeros(2 * h, 2 * w);
    filter = [1, -5, 20, 20, -5, 1] / 32;
    img_interpolated_horizontal = conv2(example_img, filter, 'same');
    img_interpolated_vertical = conv2(example_img, filter', 'same');
    cross = conv2(img_interpolated_horizontal, filter', 'same');
    for i = 1: h
        for j = 1: w
            expanded_img(i * 2 - 1, j * 2 - 1) = example_img(i, j);
            expanded_img(i * 2, j * 2 - 1) = img_interpolated_vertical(i, j);
            expanded_img(i * 2 - 1, j * 2) = img_interpolated_horizontal(i, j);
            expanded_img(i * 2, j * 2) = cross(i, j);
        end
    end
end