% ================================================================
% The Sample code is from: 
% https://www.mathworks.com/matlabcentral/fileexchange/40359-h-264-baseline-codec-v2 
% (license.txt)
% Modified by chian-chen, Date: 2024/07/03
% Example in Tutorial P.59-61
% ================================================================
load table;
X = [58, 64, 51, 58;
     52, 64, 56, 66;
     62, 63, 61, 64;
     59, 51, 63, 69];

figure;
colormap(gray(256));

subplot(3, 3, 1);
imshow(X/255);
title('Source');

W = integer_transform(X);
QP_values = 0:6:42;
subplot_positions = 2:9;

for i = 1:length(QP_values)
    QP = QP_values(i);
    
    W = integer_transform(X);
    Z = quantization(W, QP);
    W = inv_quantization(Z, QP);
    Y = inv_integer_transform(W);
    X_re = round(Y/64);
    
    subplot(3, 3, subplot_positions(i));
    imshow(X_re/255);
    colormap(gray(256));
    title(['QP = ' num2str(QP)]);
end

set(gcf, 'Position', [100, 100, 800, 800]);
  
 
function [W]= integer_transform(X)
% X is a 4x4 block of data
% W is the trasnsformed coefficients
% U is the 4 x 4 DCT
% C is the core transform matrix, derived from U
% a = 1/2;
% b = sqrt(2) * cos(pi / 8);
% c = sqrt(1/2) * cos(3 * pi / 8);
% U = [a c a c
%      c b c b
%      a c a c
%      c b c b];


C =  [1 1 1 1
      2 1 -1 -2
      1 -1 -1 1
      1 -2 2 -1];
 
W = (C*X*C'); 
end
function [Z] = quantization(W,QP)
% q is qbits
q = 15 + floor(QP/6);

% M is the multiplying factor which is found from QP value
% MF is the multiplying factor matrix
% rem(QP,6) alpha   beta    gamma
%           (a)     (b)      (g)
% 0         13107   5243    8066
% 1         11916   4660    7490
% 2         10082   4194    6554
% 3         9362    3647    5825
% 4         8192    3355    5243
% 5         7282    2893    4559

MF =[13107 5243 8066
     11916 4660 7490
     10082 4194 6554
     9362  3647 5825
     8192  3355 5243
     7282  2893 4559];
 
x = rem(QP,6);
 
a = MF(x+1,1);
b = MF(x+1,2);
g = MF(x+1,3);

M = [a g a g
     g b g b
     a g a g
     g b g b];

% scaling and quantization 
Z = round(W.*(M/2^q));
end
function [W]= inv_quantization(Z,QP)
% q is qbits
q = 15 + floor(QP/6);

% The scaling factor matrix V depend on the QP and the position of the
% coefficient.
% delta lambda miu
SM = [10 16 13
      11 18 14
      13 20 16
      14 23 18
      16 25 20
      18 29 23];
 
 x = rem(QP,6);
 
 % find delta, lambda and miu values
 d = SM(x+1,1);
 l = SM(x+1,2);
 m = SM(x+1,3);

 V = [d m d m
      m l m l
      d m d m
      m l m l];
  
 % find the inverse quantized coefficients
  W = Z.*V;
  W = bitshift(W,q-15,'int64');
end
function [Y] = inv_integer_transform(W)
% Ci is the inverse core transform matrix
Ci =  [1 1 1 1
      1 1/2 -1/2 -1
      1 -1 -1 1
      1/2 -1 1 -1/2];

Y = Ci'*W*Ci;
end


