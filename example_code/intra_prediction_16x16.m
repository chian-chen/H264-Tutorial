% ================================================================
% The Sample code is from: 
% https://www.mathworks.com/matlabcentral/fileexchange/40359-h-264-baseline-codec-v2 
% (license.txt)
% The example image is from cifar10 
% https://paperswithcode.com/dataset/cifar-10
% Modified by chian-chen, Date: 2024/06/20
% Example in Tutorial P.30-31
% ================================================================

example_img = double(rgb2gray(imread('../example_data/example.jpg')));

start_index = 5;    % can be chosen between [1, 16]
example_datas = example_img(start_index: start_index + 20, start_index: start_index+20);


figure;
image(example_datas);
colormap(gray(256))
truesize([320, 320]);
rectangle('Position', [1.5, 1.5, 16, 16], 'EdgeColor', 'r', 'LineWidth', 1);
title('source image');

[icp_horz,pred_horz,sae_horz] = pred_horz_16(example_datas, example_datas, 16, 2, 2);
[icp_vert,pred_vert,sae_vert] = pred_vert_16(example_datas, example_datas, 16, 2, 2);
[icp_dc,pred_dc,sae_dc] = pred_dc_16(example_datas, example_datas, 16, 2, 2);
[icp_plane,pred_plane,sae_plane] = pred_plane_16(example_datas, example_datas, 16, 2, 2);

figure;
colormap(gray(256));

subplot(2,2,1);
imshow(pred_horz/255);
title(sprintf('Horizontal Prediction\nSAE: %d', sae_horz));

subplot(2,2,2);
imshow(pred_vert/255);
title(sprintf('Vertical Prediction\nSAE: %d', sae_vert));

subplot(2,2,3);
imshow(pred_dc/255);
title(sprintf('DC Prediction\nSAE: %d', sae_dc));

subplot(2,2,4);
imshow(pred_plane/255);
title(sprintf('Plane Prediction\nSAE: %d', sae_plane));

% 調整 subplot 間距
set(gcf, 'Position', [100, 100, 800, 800]);  % 調整整個 figure 的大小

%-------------------------------------------------------
%% 16x16 Horizontal prediciton

function [icp,pred,sae] = pred_horz_16(Seq,Seq_r,bs,i,j)

pred = Seq_r(i:i+15,j-1)*ones(1,bs);
icp = Seq(i:i+15,j:j+15,1) - pred;
sae = sum(sum(abs(icp)));
end
%-------------------------------------------------------
%% 16x16 Vertical Prediciton

function [icp,pred,sae] = pred_vert_16(Seq,Seq_r,bs,i,j)

pred = ones(bs,1)*Seq_r(i-1,j:j+15);
icp = Seq(i:i+15,j:j+15,1) - pred;
sae = sum(sum(abs(icp)));
end
%-------------------------------------------------------
%% 16x16 DC prediction

function [icp,pred,sae] = pred_dc_16(Seq,Seq_r,bs,i,j)

pred = bitshift(sum(Seq_r(i-1,j:j+15))+ sum(Seq_r(i:i+15,j-1))+bs,-5);
icp = Seq(i:i+15,j:j+15,1) - pred;
sae = sum(sum(abs(icp)));
end
%------------------------------------------------------
%% 16x16 Plane prediction

function [icp,pred,sae] = pred_plane_16(Seq,Seq_r,bs,i,j)

pred = zeros(bs, bs);
x = 0:7;
H = sum((x+1)*(Seq_r(i+x+8,j-1)-Seq_r(i+6-x,j-1)));
y = 0:7;
V = sum((y+1)*(Seq_r(i-1,j+8+y)'-Seq_r(i-1,j+6-y)'));

a = 16*(Seq_r(i-1,j+15) + Seq_r(i+15,j-1));
b = bitshift(5*H + 32,-6,'int64');
c = bitshift(5*V + 32,-6,'int64');

% pred = clipy() << refer to the standard
for m = 1:bs
    for n = 1:bs
        d = bitshift(a + b*(m-8)+ c*(n-8) + 16, -5,'int64');
        if d <0
            pred(m,n) = 0;
        elseif d>255
            pred(m,n) = 255;
        else
            pred(m,n) = d;
        end
    end
end

icp = Seq(i:i+15,j:j+15,1) - pred;
sae = sum(sum(abs(icp)));
end