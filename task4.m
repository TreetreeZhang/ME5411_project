% Task 4

%% Initialization
clear; 
clc; 
close all;
disp('--- Start Task 4 ---');

%% Define input and output folders
inputDir = 'task3_output';
outputDir = 'task4_output';
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
    disp(['Folder created: ', outputDir]);
end

%% Load the output image from Task 3
inputImagePath = fullfile(inputDir, 'output_for_task4.png');
try
    subImage = imread(inputImagePath);
    disp(['Image successfully loaded from: ', inputImagePath]);
catch
    error('Failed to read the output image from Task 3. Please make sure Task 3 has been successfully executed.');
end

%% Binarization
% Method 1: Adaptive thresholding
binaryImageAdaptive = imbinarize(subImage, 'adaptive');

% Method 2: Fixed thresholding
binaryImageManual = imbinarize(subImage, 0.6);

% Method 3: Global automatic thresholding
level = graythresh(subImage); 
binaryImageGlobal = imbinarize(subImage, level);

imwrite(binaryImageAdaptive, fullfile(outputDir, 'binary_image_adaptive.png'));
disp('Saved the image processed with adaptive thresholding.');

imwrite(binaryImageManual, fullfile(outputDir, 'binary_image_manual.png'));
disp('Saved the image processed with fixed thresholding.');

imwrite(binaryImageGlobal, fullfile(outputDir, 'binary_image_global.png'));
disp('Saved the image processed with global automatic thresholding.');

%% Denoising

% Create structural element
se = strel('disk', 3);
binaryImageDenoised = imopen(binaryImageGlobal, se);

imwrite(binaryImageDenoised, fullfile(outputDir, 'binary_image_denoised.png'));

%% Display and save results
hFig = figure('Name', 'Task 4', 'NumberTitle', 'off');

subplot(1, 4, 1);
imshow(binaryImageAdaptive);
title('Adaptive Thresholding');
subplot(1, 4, 2);
imshow(binaryImageManual);
title('Fixed Thresholding');
subplot(1, 4, 3);
imshow(binaryImageGlobal);
title('Global Automatic Thresholding');
subplot(1, 4, 4);
imshow(binaryImageDenoised);
title('Denoised Global Threshold Result');

disp('The result images have been displayed.');

%% Save the final binary image
% Save the comparison figure
figurePath = fullfile(outputDir, 'binarization_process.png');
saveas(hFig, figurePath);
disp(['Binarization process figure saved to: ', figurePath]);

% Save the final denoised binary image for Task 5
outputImagePath = fullfile(outputDir, 'output_for_task5.png');
imwrite(binaryImageDenoised, outputImagePath);
disp(['Final binary image saved to: ', outputImagePath]);

disp('--- Task 4 Completed ---');
