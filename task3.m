% Task 3

%% Initialization
clear; 
clc; 
close all;
disp('--- Start Task 3 ---');

%% Define input and output folders
inputDir = 'task2_output';
outputDir = 'task3_output';
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
    disp(['Folder created: ', outputDir]);
end

%% Load the output image from Task 2
inputImagePath = fullfile(inputDir, 'output_for_task3.png');
try
    smoothedImage = imread(inputImagePath);
    disp(['Image successfully loaded from: ', inputImagePath]);
catch
    error('Failed to read the output image from Task 2. Please make sure Task 2 has been successfully executed.');
end

%% Crop the sub-image
% Define the cropping area
cropRect = [1, 200, size(smoothedImage, 2), 135]; 
subImage = imcrop(smoothedImage, cropRect);

%% Display and save the result
% Create a figure window for display
hFig = figure('Name', 'Task 3', 'NumberTitle', 'off');
imshow(subImage);
title('Cropped Sub-image: HD44780A00');
disp('The result image has been displayed. Please check.');

% Save the figure
figurePath = fullfile(outputDir, 'cropped_image_figure.png');
saveas(hFig, figurePath);
disp(['Cropped result figure saved to: ', figurePath]);

% Save the cropped image as input for the next task
outputImagePath = fullfile(outputDir, 'output_for_task4.png');
imwrite(subImage, outputImagePath);
disp(['Sub-image saved for the next task: ', outputImagePath]);

disp('--- Task 3 Completed ---');
