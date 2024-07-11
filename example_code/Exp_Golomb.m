% ================================================================
% The Sample code is from: 
% https://www.mathworks.com/matlabcentral/fileexchange/40359-h-264-baseline-codec-v2 
% (license.txt)
% Modified by chian-chen, Date: 2024/07/03
% Example in Tutorial P.63-64
% ================================================================


%% Encode
% We use Zig-Zag map to handle positive and negative number
% Sequence: 0, -1, 1, -2, 2, -3, 3, -4, 4, -5, 5 ......

% positive number p, code_num =  2 * p, for example, p = 3, 3 is 
% in the 6th of the sequence above

% negative number n, code_num = -2 * n - 1, for example, p = -4, -4 is in
% the 7th of the sequence above

number = 5;

max_bits_length = 20;
bits = char(zeros(1, max_bits_length));
bits_length = 0;

if (number == 0)
    symbol = 0;
elseif (number > 0)
    symbol = 2 * number;
else
    symbol = (-2) * number - 1;
end

% Here code_num = symbol
% M is prefix, info is suffix

M = floor(log2(symbol + 1));
info = dec2bin(symbol + 1 - 2^M, M);

for j = 1:M
    bits_length = bits_length + 1;
    bits(bits_length) = '0';
end

bits_length = bits_length + 1;
bits(bits_length) = '1';

bits(bits_length + 1 : bits_length + M) = info;
bits_length = bits_length + M;

bits = bits(1:bits_length);

%% Decode
% First decode the order, and check the parity to get the result

i = 1;
length_M = 0;
x = 0; % x is a flag to exit when decoding of symbol is done

while x<1
    switch bits(i)
        case '1'
            if (length_M == 0)
                symbol_re = 0;
                i = i + 1;
                x = 1;
            else
                info = bin2dec(bits(i+1 : i+length_M));
                symbol_re = 2^length_M + info -1;
                i = i + length_M + 1;
                length_M = 0;
                x = 1;
            end
        case '0'
            length_M = length_M + 1;
            i = i + 1;
    end
end

if mod(symbol_re, 2) == 1
    number_re = -bitshift(symbol_re + 1, -1);
else
    number_re = bitshift(symbol_re , -1);
end
