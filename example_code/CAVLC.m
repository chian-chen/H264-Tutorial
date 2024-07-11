% ================================================================
% The Sample code is from: 
% https://www.mathworks.com/matlabcentral/fileexchange/40359-h-264-baseline-codec-v2 
% (license.txt)
% Modified by chian-chen, Date: 2024/07/03
% Example in Tutorial P.68-74
% ================================================================


% we provide 4 example datas, first 2 are in the tutorial example
data = example_data(1);

% Select code table depend on the left and up block, see p.66, here we set
% them to 0
nL = 0; nU = 0; 

[bits] = enc_cavlc(data, nL, nU);
[data_rec] = dec_cavlc(bits,nL, nU);

check = sum(data == data_rec, 'all');   % it should be 16
bpp = length(bits) / 16;




function data = example_data(i)
switch i
    case 1
        data = [0 3 -1 0
                0 -1 1 0
                1 0 0 0
                0 0 0 0];
    case 2
        data = [-2 4 0 -1
                3 0 0 0
                -3 0 0 0
                0 0 0 0];
    case 3
        data = [0 0 1 0
                0 0 0 0
                1 0 0 1
                -1 0 0 0];
    otherwise
        data = [200 -1 -3 1
                -7 -4 -5 2
                -1 -6 2 4
                 1 -1 20 1]; 
end
end
function [bits] = enc_cavlc(data, nL, nU)
%% CAVLC Encoder. 
% takes in 4x4 block of residual data and produces output bits

load table.mat;
bits = '';

% Convert 4x4 matrix data into a 1x16 data of zig-zag scan
[row, col] = size(data);

% check the correct size of the block
if((row~=4)||(col~=4))
    disp('Residual block size mismatch - exit from CAVLC')
    return;
end

% 4 x 4 zig-zag order
scan = [1,1;1,2;2,1;3,1;2,2;1,3;1,4;2,3;3,2;4,1;4,2;3,3;2,4;3,4;4,3;4,4];

l = zeros(16, 1);
for i=1:16
   m=scan(i,1);
   n=scan(i,2);
   l(i)=data(m,n); % l contains the reordered data
end

i_last = 16;
% find the last non-zero co-eff in reverse order
while ((i_last > 0) && (l(i_last) == 0))
   i_last = i_last - 1; 
end

i_total = 0; % Total non zero coefficients
i_total_zero = 0; % Total zeros
i_trailing = 0;
sign = ''; % find sign for trailing ones
idx = 1;

level = zeros(i_last, 1);

%% find level, trailing ones(sign), run and total zero values
while ((i_last>0) && (abs(l(i_last)) == 1) && (i_trailing < 3))
    level(idx) = l(i_last);
    i_total = i_total + 1;
    i_trailing = i_trailing + 1;
    
    if l(i_last) == -1
        sign = [sign '1'];
    else 
        sign = [sign '0'];
    end
    
    run(idx) = 0;
    i_last = i_last - 1;
    while ((i_last>0) && (l(i_last)==0))
        run(idx) = run(idx) + 1;
        i_total_zero = i_total_zero + 1;
        i_last = i_last - 1; 
    end
    idx = idx + 1;
    
end

while (i_last>0)
    level(idx)=l(i_last);
    i_total = i_total + 1;
    
    
    run(idx) = 0;    
    i_last = i_last - 1;
    while ((i_last>0) && (l(i_last)==0))
        run(idx) = run(idx) + 1;
        i_total_zero = i_total_zero + 1;
        i_last = i_last - 1; 
    end
    idx = idx + 1;
    
end

%% Write coeff_token

% find n parameter (context adaptive)
if (nL>0) && (nU>0)
    n = (nL + nU)/2;
elseif (nL>0) || (nU>0)
    n = nL + nU;
else
    n = 0;
end

% Coeff_token mapping
% Rows are the total coefficient(0-16) and columns are the trailing ones(0-3)
% TABLE_COEFF0,1,2,3 ARE STORED IN TABLE.MAT OR CAVLC_TABLES.M FILE
% Choose proper table_coeff based on n value
if n < 2
    Table_coeff = Table_coeff0;
elseif n < 4
    Table_coeff = Table_coeff1;
elseif n < 8
    Table_coeff = Table_coeff2;
elseif n >= 8
    Table_coeff = Table_coeff3;
end

% Assign coeff_token and append it to output bits
% Here coeff_token is cell array so needs to be coverted to char
coeff_token = Table_coeff(i_total + 1,i_trailing + 1);
bits = [bits char(coeff_token)];

% If the total coefficients == 0 exit from this function
if i_total == 0
    return;
end

% Append sign of trailing ones to bits
if i_trailing>0
    bits = [bits sign];
end

%% Encode the levels of remaining non-zero coefficients

% find the suffix length
if (i_total > 10) && (i_trailing < 3)
   i_sufx_len = 1;
else
   i_sufx_len = 0;
end

% loop
for i=(i_trailing + 1):i_total
    
    if level(i)<0
        i_level_code = -2*level(i) - 1;
    else
        i_level_code = 2*level(i) - 2;
    end
    
    if (i == i_trailing + 1) && (i_trailing<3)
       i_level_code = i_level_code - 2; 
    end
    
    if bitshift(i_level_code,-i_sufx_len)<14
        % i_level_code
        % i_sufx_len
        level_prfx = bitshift(i_level_code,-i_sufx_len);
        while(level_prfx>0)
            bits = [bits '0'];
            level_prfx = level_prfx - 1;
        end
        bits = [bits '1'];
        
        if i_sufx_len>0 
            level_sufx = dec2bin(i_level_code,i_sufx_len);
            x = length(level_sufx);
            if x > i_sufx_len
                level_sufx = level_sufx(x-i_sufx_len+1:x);
            end
            bits = [bits level_sufx];
        end
    elseif (i_sufx_len==0) && (i_level_code<30)
       level_prfx = 14;
       while(level_prfx>0)
            bits = [bits '0'];
            level_prfx = level_prfx - 1;
        end
        bits = [bits '1'];
        
       level_sufx = dec2bin(i_level_code-14,4);
       x = length(level_sufx);
            if x>4
                level_sufx = level_sufx(x-4+1:x);
            end
       bits = [bits level_sufx];
    
    elseif (i_sufx_len>0) && (bitshift(i_level_code,-i_sufx_len)==14)
        level_prfx = 14;
       while(level_prfx>0)
            bits = [bits '0'];
            level_prfx = level_prfx - 1;
        end
        bits = [bits '1'];
        
        level_sufx = dec2bin(i_level_code,i_sufx_len);
        x = length(level_sufx);
            if x>i_sufx_len
                level_sufx = level_sufx(x-i_sufx_len+1:x);
            end
        bits = [bits level_sufx];
    else
        level_prfx = 15;
       while(level_prfx>0)
            bits = [bits '0'];
            level_prfx = level_prfx - 1;
        end
        bits = [bits '1'];
        
        i_level_code = i_level_code - bitshift(15,i_sufx_len);
        
        if i_sufx_len==0
           i_level_code = i_level_code - 15; 
        end
        
        if (i_level_code>=bitshift(1,12)) || (i_level_code<0)
            disp('Overflow occured');
        end
        
        level_sufx = dec2bin(i_level_code,12);
        x = length(level_sufx);
            if x>12
                level_sufx = level_sufx(x-12+1:x);
            end
        bits = [bits level_sufx];
    end
    
    if i_sufx_len==0
        i_sufx_len = i_sufx_len + 1;
    end
    if ((abs(level(i)))>bitshift(3,i_sufx_len - 1)) && (i_sufx_len<6)
        i_sufx_len = i_sufx_len + 1;
    end

end

%% Encode Total zeros

% Here Rows(1-16) are Total coefficient and colums(0-15) are total zeros
% Rearranged from the standard for simplicity
% Table_zeros is located in table.mat or cavlc_tables.m file
            
if i_total<16
    total_zeros = Table_zeros(i_total,i_total_zero + 1);
    bits = [bits char(total_zeros)];
end

%% Encode each run of zeros
% Rows are the run before, and columns are zeros left
% Table_run is located in table.mat or cavlc_tables.m file

i_zero_left = i_total_zero;
 if i_zero_left>=1   
    for i=1:i_total
       if (i_zero_left>0) && (i==i_total)
           break;
       end
       if i_zero_left>=1 
           i_zl = min(i_zero_left,7);
           run_before = Table_run(1 + run(i),i_zl);
           bits = [bits char(run_before)];
           i_zero_left = i_zero_left - run(i);
       end
    end
 end
end
function [data,i] = dec_cavlc(bits,nL,nU)

%% CAVLC Decoder
% By A. A. Muhit
% It takes bitstream and decodes 4x4 block of data

load table.mat;

% find n parameter (context adaptive)
if (nL>0) && (nU>0)
    n = (nL + nU)/2;
elseif (nL>0) || (nU>0)
    n = nL + nU;
else
    n = 0;
end

% Coeff_token mapping
% Rows are the total coefficient(0-16) and columns are the trailing ones(0-3)
% TABLE_COEFF0,1,2,3 ARE STORED IN TABLE.MAT OR CAVLC_TABLES.M FILE
% Choose proper Table_coeff based on n value
if n < 2
    Table_coeff = Table_coeff0;
elseif n < 4
    Table_coeff = Table_coeff1;
elseif n < 8
    Table_coeff = Table_coeff2;
elseif n >= 8
    Table_coeff = Table_coeff3;
end

i = 1;
coeff_token = '';

% Find total coefficients and trailing ones
while (i<=length(bits))
    coeff_token = [coeff_token bits(i)];
    x = strcmp(Table_coeff,coeff_token);
    [r,c]=find(x==1);
    i = i + 1;
    if (r>0) & (c>0)
        break;
    end
end

% Find total coefficients and trailing ones
i_total = r - 1;
i_trailing = c - 1;

% if no coefficients return 4x4 empty blocks of data
if i_total==0
    data = zeros(4,4);
    return;
end

k = 1;
m = i_trailing;

while m>0
    if bits(i)=='0'
        level(k)=1;
    elseif bits(i)=='1'
        level(k)=-1;
    end
    k = k + 1;
    m = m - 1;
    i = i + 1;
end

%% Decode the non-zero coefficient/level values

if (i_total>10) && (i_trailing<3)
   i_sufx_len = 1;
else
   i_sufx_len = 0;
end

while k<=i_total
    % Decode level prefix
    [level_prfx,i]= dec_prfx(bits,i);
    
    % Decode level suffix
    level_sufx_size = 0;
    
    if (i_sufx_len>0)||(level_prfx>=14)
        if (level_prfx==14) && (i_sufx_len==0)
            level_sufx_size = 4;
        elseif level_prfx>=15
           level_sufx_size = level_prfx - 3;
        else
            level_sufx_size = i_sufx_len;
        end
    end
    
    if level_sufx_size==0
        level_sufx = 0;
    else
        sufx = bits(i : i + level_sufx_size -1);
        level_sufx = bin2dec(sufx);
        i = i + level_sufx_size;
    end
    
    i_level_code = bitshift(min(15,level_prfx),i_sufx_len) + level_sufx;
    
    if (level_prfx>=15) && (i_sufx_len==0)
        i_level_code = i_level_code + 15;
    end
    if level_prfx>=16
        i_level_code = i_level_code + (bitshift(1,level_prfx - 3) - 4096);
    end
    
    if (k == i_trailing + 1) && (i_trailing<3)
       i_level_code = i_level_code + 2; 
    end
    
    if rem(i_level_code,2)==0 % i_level_code is even
        level(k) = bitshift(i_level_code + 2,-1,'int64');
    else % odd number
        level(k) = bitshift(-i_level_code - 1, -1,'int64');
    end
    
    if i_sufx_len==0
        i_sufx_len = 1;
    end
    
    if ((abs(level(k)))>bitshift(3,i_sufx_len - 1)) && (i_sufx_len<6)
        i_sufx_len = i_sufx_len + 1;
    end
    
    k = k + 1;
end

%% Decode total zeros

s='';
i_total_zero = 0;

if i_total==16
   i_zero_left = 0;
else
    while (i<=length(bits))
    s = [s bits(i)];
    x = strcmp(Table_zeros(i_total,:),s);
    r = find(x==1);
    i = i + 1;
        if r>0
            i_total_zero = r-1;
            break;
        end
    end
end


%% Decode run information

i_zero_left = i_total_zero;
j=1;
ss = '';
run = zeros(1,length(level));

while i_zero_left>0
    while (j<i_total) && (i_zero_left>0)
    ss = [ss bits(i)];
    i_zl = min(i_zero_left,7);
    x = strcmp(Table_run(:,i_zl),ss);
    r = find(x==1);
    i = i + 1;
        if r>0
            run(j)=r-1;
            i_zero_left = i_zero_left - run(j);
            j = j + 1;
            ss = '';
        end     
    end
    if i_zero_left>0
        run(j)=i_zero_left;
        i_zero_left = 0;
    end
end

%% Combine level and run information

k = i_total + i_total_zero;
l = zeros(1,16);

while k>0
    for j=1:length(level)
        l(k)=level(j);
        k = k - 1;
        k = k - run(j);
    end
end

%% Reorder the data into 4x4 block

scan = [1,1;1,2;2,1;3,1;2,2;1,3;1,4;2,3;3,2;4,1;4,2;3,3;2,4;3,4;4,3;4,4];

for k=16:-1:1
   m=scan(k,1);
   n=scan(k,2);
   data(m,n)=l(k); % l contains the reordered data
end
end
function [level_prfx,i]= dec_prfx(bits,i)
level_prfx = 0;

while i<=length(bits)
    switch bits(i)
        case '0'
            level_prfx = level_prfx + 1;
            i = i + 1;
        case '1'
            i = i + 1;
            return;
    end        
end
end