% ================================================================
% The Sample code is from: 
% https://www.mathworks.com/matlabcentral/fileexchange/40359-h-264-baseline-codec-v2 
% (license.txt)
% The example image is from cifar10 
% https://paperswithcode.com/dataset/cifar-10
% Modified by chian-chen, Date: 2024/06/20
% Example in Tutorial P.27-28
% ================================================================

example_img = double(rgb2gray(imread('../example_data/example.jpg')));

start_index = 9;    % can be chosen between [1, 16]
example_datas = example_img(start_index: start_index + 16, start_index: start_index + 16);

figure;
image(example_datas);
colormap(gray(256))
truesize([320, 320]);
rectangle('Position', [start_index - 0.5, start_index - 0.5, 4, 4], 'EdgeColor', 'r', 'LineWidth', 1);
title('source image');

[icp_horz, pred_horz, sae_horz] = pred_horz_4(example_datas, example_datas, start_index, start_index);
[icp_vert, pred_vert, sae_vert] = pred_vert_4(example_datas, example_datas, start_index, start_index);
[icp_dc, pred_dc, sae_dc] = pred_dc_4(example_datas, example_datas, start_index, start_index);
[icp_ddl, pred_ddl, sae_ddl] = pred_ddl_4(example_datas, example_datas, start_index, start_index);
[icp_ddr, pred_ddr, sae_ddr] = pred_ddr_4(example_datas, example_datas, start_index, start_index);
[icp_vr, pred_vr, sae_vr] = pred_vr_4(example_datas, example_datas, start_index, start_index);
[icp_hd, pred_hd, sae_hd] = pred_hd_4(example_datas, example_datas, start_index, start_index);
[icp_vl, pred_vl, sae_vl] = pred_vl_4(example_datas, example_datas, start_index, start_index);
[icp_hu, pred_hu, sae_hu] = pred_hu_4(example_datas, example_datas, start_index, start_index);

% 創建一個 figure 來顯示所有預測圖像
figure;
colormap(gray(256));

% Horizontal Prediction
subplot(3,3,1);
imshow(pred_horz/255);
title(sprintf('Horizontal Prediction, SAE: %d', sae_horz));

% Vertical Prediction
subplot(3,3,2);
imshow(pred_vert/255);
title(sprintf('Vertical Prediction, SAE: %d', sae_vert));

% DC Prediction
subplot(3,3,3);
imshow(pred_dc/255);
title(sprintf('DC Prediction, SAE: %d', sae_dc));

% Diagonal Down-Left Prediction
subplot(3,3,4);
imshow(pred_ddl/255);
title(sprintf('Diagonal Down-Left Prediction, SAE: %d', sae_ddl));

% Diagonal Down-Right Prediction
subplot(3,3,5);
imshow(pred_ddr/255);
title(sprintf('Diagonal Down-Right Prediction, SAE: %d', sae_ddr));

% Vertical Right Prediction
subplot(3,3,6);
imshow(pred_vr/255);
title(sprintf('Vertical Right Prediction, SAE: %d', sae_vr));

% Horizontal Down Prediction
subplot(3,3,7);
imshow(pred_hd/255);
title(sprintf('Horizontal Down Prediction, SAE: %d', sae_hd));

% Vertical Left Prediction
subplot(3,3,8);
imshow(pred_vl/255);
title(sprintf('Vertical Left Prediction, SAE: %d', sae_vl));

% Horizontal Up Prediction
subplot(3,3,9);
imshow(pred_hu/255);
title(sprintf('Horizontal Up Prediction, SAE: %d', sae_hu));

% 調整 subplot 間距
set(gcf, 'Position', [100, 100, 800, 800]);  % 調整整個 figure 的大小


%% 4x4 Horizontal prediciton
function [icp,pred,sae] = pred_horz_4(Seq,Seq_r,i,j)

pred = Seq_r(i:i+3,j-1)*ones(1,4);
icp = Seq(i:i+3,j:j+3,1) - pred;
sae = sum(sum(abs(icp)));

end
%-------------------------------------------------------
%% 4x4 Vertical Prediciton
function [icp,pred,sae] = pred_vert_4(Seq,Seq_r,i,j)

pred = ones(4,1)*Seq_r(i-1,j:j+3);
icp = Seq(i:i+3,j:j+3,1) - pred;
sae = sum(sum(abs(icp)));
end
%-------------------------------------------------------
%% 4x4 DC prediction
function [icp,pred,sae] = pred_dc_4(Seq,Seq_r,i,j)

pred = bitshift(sum(Seq_r(i-1,j:j+3))+ sum(Seq_r(i:i+3,j-1))+4,-3);
icp = Seq(i:i+3,j:j+3,1) - pred;
sae = sum(sum(abs(icp)));

end
%--------------------------------------------------------
function [icp,pred,sae] = pred_ddl_4(Seq,Seq_r,i,j)

Seq_r(i+4:i+7,j-1)=Seq_r(i+3,j-1);

for x = 0:3
    for y = 0:3
        if (x==3)&(y==3)
            pred(x+1,y+1) = bitshift(Seq_r(i+6,j-1) + 3*Seq_r(i+7,j-1) + 2,-2);
        else
            pred(x+1,y+1) = bitshift(Seq_r(i+x+y,j-1) + 2*Seq_r(i+x+y+1,j-1) + Seq_r(i+x+y+2,j-1) + 2,-2);
        end
    end
end

icp = Seq(i:i+3,j:j+3,1) - pred;
sae = sum(sum(abs(icp)));

end
%--------------------------------------------------------
function [icp,pred,sae] = pred_ddr_4(Seq,Seq_r,i,j)

for x = 0:3
    for y = 0:3
        if (x>y)
            pred(x+1,y+1) = bitshift(Seq_r(i+x-y-2,j-1) + 2*Seq_r(i+x-y-2,j-1) + Seq_r(i+x-y,j-1) + 2,-2);
        elseif (x<y)
            pred(x+1,y+1) = bitshift(Seq_r(i-1,j+y-x-2) + 2*Seq_r(i-1,j+y-x-1) + Seq_r(i-1,j+y-x) + 2,-2);
        else
            pred(x+1,y+1) = bitshift(Seq_r(i,j-1) + 2*Seq_r(i-1,j-1) + Seq_r(i-1,j) + 2,-2);
        end
    end
end

icp = Seq(i:i+3,j:j+3,1) - pred;
sae = sum(sum(abs(icp)));

end
%--------------------------------------------------------
function [icp,pred,sae] = pred_vr_4(Seq,Seq_r,i,j)

for x = 0:3
    for y = 0:3
        z = 2*x-y;
        w = bitshift(y,-1);
        if rem(z,2)==0
            pred(x+1,y+1)= bitshift(Seq_r(i+x-w-1,j-1) + Seq_r(i+x-w,j-1) + 1,-1);
        elseif rem(z,2)==1
            pred(x+1,y+1)= bitshift(Seq_r(i+x-w-2,j-1) + 2*Seq_r(i+x-w-1,j-1) + Seq_r(i+x-w,j-1) + 2,-2);
        elseif z==-1
            pred(x+1,y+1)= bitshift(Seq_r(i-1,j)+ 2*Seq_r(i-1,j-1) + Seq_r(i,j-1) + 2,-2);
        else
            pred(x+1,y+1) = bitshift(Seq_r(i-1,j+y-1)+ 2*Seq_r(i-1,j+y-2) + Seq_r(i-1,j+y-3) + 2,-2);
        end
    end
end

icp = Seq(i:i+3,j:j+3,1) - pred;
sae = sum(sum(abs(icp)));
end
%--------------------------------------------------------
function [icp,pred,sae] = pred_hd_4(Seq,Seq_r,i,j)

for x = 0:3
    for y = 0:3
        z = 2*y-x;
        w = bitshift(x,-1);
        if rem(z,2)==0
            pred(x+1,y+1)= bitshift(Seq_r(i-1,j+y-w-1) + Seq_r(i-1,j+y-w) + 1,-1);
        elseif rem(z,2)==1
            pred(x+1,y+1)= bitshift(Seq_r(i-1,j+y-w-2) + 2*Seq_r(i-1,j+y-w-1) + Seq_r(i-1,j+y-w) + 2,-2);
        elseif z==-1
            pred(x+1,y+1)= bitshift(Seq_r(i-1,j)+ 2*Seq_r(i-1,j-1) + Seq_r(i,j-1) + 2,-2);
        else
            pred(x+1,y+1) = bitshift(Seq_r(i+x-1,j-1)+ 2*Seq_r(i+x-2,j-1) + Seq_r(i+x-3,j-1) + 2,-2);
        end
    end
end

icp = Seq(i:i+3,j:j+3,1) - pred;
sae = sum(sum(abs(icp)));
end
%--------------------------------------------------------
function [icp,pred,sae] = pred_vl_4(Seq,Seq_r,i,j)

Seq_r(i+4:i+7,j-1)=Seq_r(i+3,j-1);

for x = 0:3
    for y = 0:3
        w = bitshift(y,-1);
        if rem(y,2)==0
            pred(x+1,y+1) = bitshift(Seq_r(i+x+w,j-1) + Seq_r(i+x+w+1,j-1) + 1,-1);
        else
            pred(x+1,y+1) = bitshift(Seq_r(i+x+w,j-1) + 2*Seq_r(i+x+w+1,j-1) + Seq_r(i+x+w+2,j-1) + 2,-2);
        end
    end
end

icp = Seq(i:i+3,j:j+3,1) - pred;
sae = sum(sum(abs(icp)));
end
%--------------------------------------------------------
function [icp,pred,sae] = pred_hu_4(Seq,Seq_r,i,j)

for x = 0:3
    for y = 0:3
        z = 2*y+x;
        w = bitshift(x,-1);
        if (z==0)|(z==2)|(z==4)
            pred(x+1,y+1)= bitshift(Seq_r(i-1,j+y+w) + Seq_r(i-1,j+y+w+1) + 1,-1);
        elseif (z==1)|(z==3)
            pred(x+1,y+1)= bitshift(Seq_r(i-1,j+y+w) + 2*Seq_r(i-1,j+y+w+1) + Seq_r(i-1,j+y+w+2) + 2,-2);
        elseif z==5
            pred(x+1,y+1)= bitshift(Seq_r(i-1,j+2)+ 3*Seq_r(i-1,j+3) + 2,-2);
        else
            pred(x+1,y+1) = Seq_r(i-1,j+3);
        end
    end
end
icp = Seq(i:i+3,j:j+3,1) - pred;
sae = sum(sum(abs(icp)));
end

