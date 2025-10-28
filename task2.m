% Task 2

%% Initialization
clear; 
clc; 
close all;
disp('--- Start Task 2 ---');

%% Define input and output folders
inputDir = 'task1_output';
outputDir = 'task2_output';
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
    disp(['Folder created: ', outputDir]);
end

%% Load the output image from Task 1
inputImagePath = fullfile(inputDir, 'output_for_task2.png');
try
    enhancedImage = imread(inputImagePath);
    disp(['Image successfully loaded from: ', inputImagePath]);
catch
    error('Failed to read the output image from Task 1. Please make sure Task 1 has been successfully executed.');
end

%% Apply averaging filters of different sizes
% 1. 3x3 averaging filter
filter_3x3 = fspecial('average', [3 3]);
smoothedImage_3x3 = imfilter(enhancedImage, filter_3x3, 'replicate');

% 2. 5x5 averaging filter (required by the project) [cite: 27]
filter_5x5 = fspecial('average', [5 5]);
smoothedImage_5x5 = imfilter(enhancedImage, filter_5x5, 'replicate');

% 3. 9x9 averaging filter
filter_9x9 = fspecial('average', [9 9]);
smoothedImage_9x9 = imfilter(enhancedImage, filter_9x9, 'replicate');

%% Visualize and compare results
hFig = figure('Name', 'Task 2', 'NumberTitle', 'off');
subplot(2, 2, 1);
imshow(enhancedImage);
title('Before Filtering');
subplot(2, 2, 2);
imshow(smoothedImage_3x3);
title('3x3 Averaging Filter');
subplot(2, 2, 3);
imshow(smoothedImage_5x5);
title('5x5 Averaging Filter');
subplot(2, 2, 4);
imshow(smoothedImage_9x9);
title('9x9 Averaging Filter');
disp('The result images have been displayed. Please check.');

%% Save all results to the folder
% 1. Save the comparison figure
figurePath = fullfile(outputDir, 'smoothing_comparison.png');
saveas(hFig, figurePath);
disp(['Smoothing comparison figure saved to: ', figurePath]);

% 2. Save each filtered image separately
imwrite(smoothedImage_3x3, fullfile(outputDir, 'smoothed_image_3x3.png'));
disp('Saved the image processed with the 3x3 filter.');

imwrite(smoothedImage_5x5, fullfile(outputDir, 'smoothed_image_5x5.png'));
disp('Saved the image processed with the 5x5 filter.');

imwrite(smoothedImage_9x9, fullfile(outputDir, 'smoothed_image_9x9.png'));
disp('Saved the image processed with the 9x9 filter.');

% 3. Select and save the image for the next step
outputForNextTaskPath = fullfile(outputDir, 'output_for_task3.png');
imwrite(smoothedImage_5x5, outputForNextTaskPath);
disp(['Saved the 5x5 filtered image as the input for the next task: ', outputForNextTaskPath]);

disp('--- Task 2 Completed ---');
