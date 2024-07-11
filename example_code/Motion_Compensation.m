% ================================================================
% The example image is from cifar10 
% https://paperswithcode.com/dataset/cifar-10
% Modified by chian-chen, Date: 2024/06/20
% Example in Tutorial P.45, a simple algorithm for motion compensation
% using different block size
% ================================================================


% read the video, extract two frames
v = VideoReader('../example_data/cat_mid.mov');

num_frams = v.NumFrames;    % 372
frames_rate = v.FrameRate;  % 30.004
duration = v.Duration;  % 12.3983 sec

frames = read(v,[1 10]);

frame1 = frames(:, :, :, 1);
frame2 = frames(:, :, :, 2);

% Part2: block size compensation, using only Y channal (grayscale)
% 0.2989 * R + 0.5870 * G + 0.1140 * B 
% Convert the data type from uint8 to double to avoid overflow

f1 = double(rgb2gray(frame1));
f2 = double(rgb2gray(frame2));

figure;
imshow(uint8(f1));
title('first frame');

figure;
imshow(uint8(f2));
title('second frame');


% Try different block size, search region: 5 x 5 windows

% 1. no compensation, directly difference
figure;
imshow(uint8(f1 - f2));
SAD = sum(sum(abs(f1 - f2)));
title(sprintf('difference, SAE: %d', SAD));

% 2. 16 x 16 block
tic;
[f_16, ~] = Block_compensation(16, f1, f2);
time_16 = toc;
figure;
imshow(uint8(abs(f_16 - f2)));
SAD_16 = sum(sum(abs(f_16 - f2)));
title(sprintf('16 x 16 block, SAE: %d, time: %.4f', SAD_16, time_16));

% 3. 8 x 8 block
tic;
[f_8, ~] = Block_compensation(8, f1, f2);
time_8 = toc;
figure;
imshow(uint8(abs(f_8 - f2)));
SAD_8 = sum(sum(abs(f_8 - f2)));
title(sprintf('8 x 8 block, SAE: %d, time: %.4f', SAD_8, time_8));

% 4. 4 x 4 block
tic;
[f_4, ~] = Block_compensation(4, f1, f2);
time_4 = toc;
figure;
imshow(uint8(abs(f_4 - f2)));
SAD_4 = sum(sum(abs(f_4 - f2)));
title(sprintf('4 x 4 block, SAE: %d, time: %.4f', SAD_4, time_4));



function [new_frame, Motion_Vectors] = Block_compensation(block_size, previous_frame, current_frame)
    new_frame = previous_frame;

    
    [rows, cols] = size(current_frame);
    block_rows = floor(rows / block_size);
    block_cols = floor(cols / block_size);

    Motion_Vectors = zeros(block_rows, block_cols, 2);
     

    for i = 1:block_rows
        for j = 1:block_cols

            current_block = current_frame((i-1)*block_size+1:i*block_size, (j-1)*block_size+1:j*block_size);
       
            best_match_value = inf;
            best_match_position = [i, j];
            

            for x = max(1, (i-1)*block_size - 2):min(rows-block_size+1, (i-1)*block_size + 2)
                for y = max(1, (j-1)*block_size - 2):min(cols-block_size+1, (j-1)*block_size + 2)

                    block_to_compare = previous_frame(x:x+block_size-1, y:y+block_size-1);
                    
         
                    similarity = sum(sum(abs(block_to_compare - current_block ))); % SAD

                    if similarity < best_match_value
                        best_match_value = similarity;                  
                        best_match_position = [x, y];
                    end
                end
            end
            
            new_frame((i-1)*block_size+1:i*block_size, (j-1)*block_size+1:j*block_size) = ...
                previous_frame(best_match_position(1):best_match_position(1)+block_size-1, ...
                               best_match_position(2):best_match_position(2)+block_size-1);
            Motion_Vectors(i, j, :) = [(i-1)*block_size+1 - best_match_position(1), ...
                (j-1)*block_size+1 - best_match_position(2)];
        end
    end
    
    new_frame = cast(new_frame, class(current_frame));
end
