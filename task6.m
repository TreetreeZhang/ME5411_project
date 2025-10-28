% Task 6

%% Initialization
clear; clc; close all;
disp('--- Start Task 6 ---');

%% Define folder paths
inputDirTask5 = 'task5_output';
inputDirTask3 = 'task3_output';
outputDir = 'task6_output';
outputDirChars = fullfile(outputDir, 'individual_characters');
if ~exist(outputDir, 'dir'), mkdir(outputDir); end
if ~exist(outputDirChars, 'dir'), mkdir(outputDirChars); end
if exist(outputDirChars, 'dir'), delete(fullfile(outputDirChars, '*.png')); end

%% Load images
inputImagePathBinary = fullfile(inputDirTask5, 'output_for_task6.png');
try
    binaryImage = imread(inputImagePathBinary);
    disp(['Binary image successfully loaded from: ', inputImagePathBinary]);
catch
    error('Failed to read the output image from Task 5.');
end
inputImagePathGray = fullfile(inputDirTask3, 'output_for_task4.png');
try
    subImageGray = imread(inputImagePathGray);
    disp(['Grayscale sub-image successfully loaded from: ', inputImagePathGray]);
catch
    error('Failed to read the output image from Task 3.');
end

%% Get properties of all regions and apply initial filtering
statsInitial = regionprops(binaryImage, 'BoundingBox', 'Area', 'Image');
minArea = 1500;
stats = statsInitial([statsInitial.Area] >= minArea);

%% Intelligent splitting logic
mergedAspectRatioThreshold = 1.1;
finalCharImages = {};
finalBoundingBoxes = [];

disp('Applying intelligent splitting and recalculating precise bounding boxes...');
for i = 1:length(stats)
    bb = stats(i).BoundingBox;
    aspectRatio = bb(3) / bb(4);
    
    if aspectRatio > mergedAspectRatioThreshold
        disp(['Merged characters detected (ID: ', num2str(i), '), attempting to split...']);
        mergedImage = stats(i).Image;
        verticalProfile = sum(mergedImage, 1);
        searchZoneStart = round(size(mergedImage, 2) * 0.4);
        searchZoneEnd = round(size(mergedImage, 2) * 0.6);
        [~, splitColumn] = min(verticalProfile(searchZoneStart:searchZoneEnd));
        splitColumn = splitColumn + searchZoneStart - 1;
        
        char1_img = mergedImage(:, 1:splitColumn);
        char2_img = mergedImage(:, (splitColumn+1):end);
        
        % Recalculate the bounding box for the first split character
        stats1 = regionprops(char1_img, 'BoundingBox');
        if ~isempty(stats1)
            % Convert local bounding box to global coordinates in the original image
            bb1 = [bb(1) + stats1.BoundingBox(1) - 1, ...
                   bb(2) + stats1.BoundingBox(2) - 1, ...
                   stats1.BoundingBox(3), stats1.BoundingBox(4)];
            finalCharImages{end+1} = char1_img;
            finalBoundingBoxes = [finalBoundingBoxes; bb1];
        end

        % Recalculate for the second split character
        stats2 = regionprops(char2_img, 'BoundingBox');
        if ~isempty(stats2)
            bb2 = [bb(1) + splitColumn + stats2.BoundingBox(1) - 1, ...
                   bb(2) + stats2.BoundingBox(2) - 1, ...
                   stats2.BoundingBox(3), stats2.BoundingBox(4)];
            finalCharImages{end+1} = char2_img;
            finalBoundingBoxes = [finalBoundingBoxes; bb2];
        end

    else
        finalCharImages{end+1} = stats(i).Image;
        finalBoundingBoxes = [finalBoundingBoxes; bb];
    end
end

%% Sorting, visualization, and saving — same as before
if ~isempty(finalBoundingBoxes)
    [~, sortOrder] = sort(finalBoundingBoxes(:, 1));
    finalBoundingBoxes = finalBoundingBoxes(sortOrder, :);
    finalCharImages = finalCharImages(sortOrder);
end

hFig = figure('Name', 'Task 6', 'NumberTitle', 'off');
imshow(subImageGray); hold on;
disp(['Segmentation completed, ', num2str(length(finalCharImages)), ' characters obtained. Saving each image...']);
for k = 1:length(finalCharImages)
    bb = finalBoundingBoxes(k, :);
    rectangle('Position', bb, 'EdgeColor', 'r', 'LineWidth', 2);
    text(bb(1), bb(2)-10, num2str(k), 'Color', 'cyan', 'FontSize', 12);
    charImagePadded = padarray(finalCharImages{k}, [4 4], 0, 'both');
    charFilename = sprintf('char_%02d.png', k);
    imwrite(charImagePadded, fullfile(outputDirChars, charFilename));
end
hold off;

%% Save final results
figurePath = fullfile(outputDir, 'segmentation_result.png');
saveas(hFig, figurePath);
disp('--- Task 6 Completed ---');
