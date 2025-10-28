% Task 5

%% Initialization
clear; 
clc; 
close all;
disp('--- Start Task 5 ---');

%% Define input and output folders
inputDir = 'task4_output';
outputDir = 'task5_output';
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
    disp(['Folder created: ', outputDir]);
end

%% Load the output image from Task 4
inputImagePath = fullfile(inputDir, 'output_for_task5.png');
try
    binaryImage = imread(inputImagePath);
    disp(['Image successfully loaded from: ', inputImagePath]);
catch
    error('Failed to read the output image from Task 4. Please make sure Task 4 has been successfully executed.');
end

%% Detect and draw contours
% The bwboundaries function can trace the boundaries of objects in the image.
% B is a cell array, where each cell contains the (x, y) coordinates of one object (one character).
% L is a label matrix that assigns a unique integer to each object for colored display.
% The 'noholes' option ensures only outer boundaries are detected, ignoring inner holes
% (for example, the hole inside the character '0'), which improves efficiency.
[B, L] = bwboundaries(binaryImage, 'noholes');

%% Display and save results
% Create a figure window for visualization
hFig = figure('Name', 'Task 5', 'NumberTitle', 'off');

% Use label2rgb to convert the label matrix L into a color image,
% so that each character is shown in a different color
imshow(label2rgb(L, @jet, [.5 .5 .5])); 
hold on; % Keep the current image to draw the contour lines on top

% Loop through all detected boundaries and draw them as white lines
for k = 1:length(B)
    boundary = B{k};
    plot(boundary(:,2), boundary(:,1), 'w', 'LineWidth', 2);
end

hold off;
disp('The result image has been displayed. Please check.');

% Save the figure
figurePath = fullfile(outputDir, 'character_outlines.png');
saveas(hFig, figurePath);
disp(['Character outline image saved to: ', figurePath]);

% Task 6 still requires the binary image from Task 4 as input.
% To maintain a consistent workflow, copy the file to the current output folder
% and rename it as the input for Task 6.
outputImagePath = fullfile(outputDir, 'output_for_task6.png');
copyfile(inputImagePath, outputImagePath);
disp(['Binary image for the next task has been copied to: ', outputImagePath]);

disp('--- Task 5 Completed ---');
