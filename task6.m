%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ME 5411 Computer Project - Script 6: Segment Characters (v5 - Final)
% This version recalculates precise bounding boxes for split components.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% 初始化
clear; clc; close all;
disp('--- 开始执行任务 6 (最终优化版): 分割字符 ---');

%% 定义文件夹路径
inputDirTask5 = 'task5_output';
inputDirTask3 = 'task3_output';
outputDir = 'task6_output';
outputDirChars = fullfile(outputDir, 'individual_characters');
if ~exist(outputDir, 'dir'), mkdir(outputDir); end
if ~exist(outputDirChars, 'dir'), mkdir(outputDirChars); end
if exist(outputDirChars, 'dir'), delete(fullfile(outputDirChars, '*.png')); end

%% 加载图像
inputImagePathBinary = fullfile(inputDirTask5, 'output_for_task6.png');
try, binaryImage = imread(inputImagePathBinary); disp(['成功加载二值图像: ', inputImagePathBinary]);
catch, error('无法读取任务5的输出图像。'); end
inputImagePathGray = fullfile(inputDirTask3, 'output_for_task4.png');
try, subImageGray = imread(inputImagePathGray); disp(['成功加载灰度子图像: ', inputImagePathGray]);
catch, error('无法读取任务3的输出图像。'); end

%% 获取所有区域的属性并应用初级过滤
statsInitial = regionprops(binaryImage, 'BoundingBox', 'Area', 'Image');
filterParams.minArea = 1500;
stats = statsInitial([statsInitial.Area] >= filterParams.minArea);

%% 智能切割逻辑
mergedAspectRatioThreshold = 1.1;
finalCharImages = {};
finalBoundingBoxes = [];

disp('正在应用智能切割与精确边界框重算...');
for i = 1:length(stats)
    bb = stats(i).BoundingBox;
    aspectRatio = bb(3) / bb(4);
    
    if aspectRatio > mergedAspectRatioThreshold
        disp(['检测到合并字符 (ID: ', num2str(i), ')，尝试切割...']);
        mergedImage = stats(i).Image;
        verticalProfile = sum(mergedImage, 1);
        searchZoneStart = round(size(mergedImage, 2) * 0.4);
        searchZoneEnd = round(size(mergedImage, 2) * 0.6);
        [~, splitColumn] = min(verticalProfile(searchZoneStart:searchZoneEnd));
        splitColumn = splitColumn + searchZoneStart - 1;
        
        char1_img = mergedImage(:, 1:splitColumn);
        char2_img = mergedImage(:, (splitColumn+1):end);
        
        % =================== 新增：精确重算边界框 ===================
        % 对切割出的第一个字符，重新计算其在自己小图框内的边界框
        stats1 = regionprops(char1_img, 'BoundingBox');
        if ~isempty(stats1)
            % 将局部边界框转换为在原图上的全局边界框
            bb1 = [bb(1) + stats1.BoundingBox(1) - 1, ...
                   bb(2) + stats1.BoundingBox(2) - 1, ...
                   stats1.BoundingBox(3), stats1.BoundingBox(4)];
            finalCharImages{end+1} = char1_img;
            finalBoundingBoxes = [finalBoundingBoxes; bb1];
        end
        
        % 对切割出的第二个字符做同样操作
        stats2 = regionprops(char2_img, 'BoundingBox');
        if ~isempty(stats2)
            bb2 = [bb(1) + splitColumn + stats2.BoundingBox(1) - 1, ...
                   bb(2) + stats2.BoundingBox(2) - 1, ...
                   stats2.BoundingBox(3), stats2.BoundingBox(4)];
            finalCharImages{end+1} = char2_img;
            finalBoundingBoxes = [finalBoundingBoxes; bb2];
        end
        % =================================================================
        
    else
        finalCharImages{end+1} = stats(i).Image;
        finalBoundingBoxes = [finalBoundingBoxes; bb];
    end
end

%% 排序、可视化、保存 - 与之前版本相同
if ~isempty(finalBoundingBoxes)
    [~, sortOrder] = sort(finalBoundingBoxes(:, 1));
    finalBoundingBoxes = finalBoundingBoxes(sortOrder, :);
    finalCharImages = finalCharImages(sortOrder);
end

hFig = figure('Name', 'Task 6: Final Segmentation (Precise BBox)', 'NumberTitle', 'off');
imshow(subImageGray); hold on;
disp(['分割完成，共得到 ', num2str(length(finalCharImages)), ' 个字符，正在逐个保存...']);
for k = 1:length(finalCharImages)
    bb = finalBoundingBoxes(k, :);
    rectangle('Position', bb, 'EdgeColor', 'r', 'LineWidth', 2);
    text(bb(1), bb(2)-10, num2str(k), 'Color', 'cyan', 'FontSize', 12);
    charImagePadded = padarray(finalCharImages{k}, [4 4], 0, 'both');
    charFilename = sprintf('char_%02d.png', k);
    imwrite(charImagePadded, fullfile(outputDirChars, charFilename));
end
hold off;
title(['最终分割出 ', num2str(length(finalCharImages)), ' 个字符']);

%% 保存最终结果
figurePath = fullfile(outputDir, 'segmentation_result_final_precise.png');
saveas(hFig, figurePath);
disp('--- 任务 6 (最终优化版) 完成 ---');