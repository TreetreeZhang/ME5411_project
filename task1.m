% Task 1

%% Initialization
clear; 
clc; 
close all;
disp('--- Start Task 1 ---');

%% Create output folder
outputDir = 'task1_output';
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
    disp(['Folder created: ', outputDir]);
end

%% Load original image
try
    originalImage_rgb = imread('charact2.bmp');
catch
    error('Failed to read "charact2.bmp". Please make sure the file is in the same directory as this script.');
end

% Convert to grayscale
if size(originalImage_rgb, 3) == 3
    disp('The image is read as RGB format, converting to grayscale...');
    originalImage = rgb2gray(originalImage_rgb);
else
    originalImage = originalImage_rgb;
end

%% Perform contrast enhancement experiments
% 1. Method 1: Histogram equalization
enhancedImageHistEq = histeq(originalImage);

% 2. Method 2: Contrast stretching
enhancedImageAdjust = imadjust(originalImage);

%% Visualize results
hFig = figure('Name', 'Task 1', 'NumberTitle', 'off');
subplot(1, 3, 1);
imshow(originalImage);
title('Original Image (Grayscale)');
subplot(1, 3, 2);
imshow(enhancedImageHistEq);
title('Histogram Equalization');
subplot(1, 3, 3);
imshow(enhancedImageAdjust);
title('Contrast Stretching');
disp('The result images have been displayed. Please check.');

%% Save all results to the folder
% 1. Save the figure containing all subplots
figurePath = fullfile(outputDir, 'contrast_enhancement_comparison.png');
saveas(hFig, figurePath);
disp(['Comparison figure has been saved to: ', figurePath]);

% 2. Save each processed image separately
imwrite(enhancedImageHistEq, fullfile(outputDir, 'enhanced_image_histeq.png'));
disp('Saved the image processed with histogram equalization.');

imwrite(enhancedImageAdjust, fullfile(outputDir, 'enhanced_image_imadjust.png'));
disp('Saved the image processed with contrast stretching.');

% 3. Select and save the image for the next step
outputForNextTaskPath = fullfile(outputDir, 'output_for_task2.png');
imwrite(enhancedImageAdjust, outputForNextTaskPath);
disp(['Saved the contrast-stretched image as the input for the next task: ', outputForNextTaskPath]);

disp('--- Task 1 Completed ---');