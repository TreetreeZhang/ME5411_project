%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ME 5411 Computer Project - Script 6: Segment Characters (Improved)
% Task 6: Segment the image to separate and label the different characters
% as clearly as possible.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% 初始化
clear; 
clc; 
close all;
disp('--- 开始执行任务 6 (改进版): 分割字符 ---');

%% 定义输入和输出文件夹
inputDirTask5 = 'task5_output';
inputDirTask3 = 'task3_output';
outputDir = 'task6_output';
outputDirChars = fullfile(outputDir, 'individual_characters');

if ~exist(outputDir, 'dir'), mkdir(outputDir); disp(['已创建文件夹: ', outputDir]); end
if ~exist(outputDirChars, 'dir'), mkdir(outputDirChars); disp(['已创建子文件夹: ', outputDirChars]); end
if exist(outputDirChars, 'dir'), delete(fullfile(outputDirChars, '*.png')); end % 清空旧文件

%% 加载所需图像
inputImagePathBinary = fullfile(inputDirTask5, 'output_for_task6.png');
try, binaryImage = imread(inputImagePathBinary); disp(['成功加载二值图像: ', inputImagePathBinary]);
catch, error('无法读取任务5的输出图像。请先成功运行任务5的脚本。'); end

inputImagePathGray = fullfile(inputDirTask3, 'output_for_task4.png');
try, subImageGray = imread(inputImagePathGray); disp(['成功加载灰度子图像: ', inputImagePathGray]);
catch, error('无法读取任务3的输出图像。请先成功运行任务3的脚本。'); end

%% 使用 regionprops 获取所有区域的属性
% 请求更多属性用于高级过滤
stats = regionprops(binaryImage, 'BoundingBox', 'Area', 'Image', 'Solidity', 'Extent');

% =================== 新增：高级过滤参数定义 ===================
% ** 你可以调整这些参数来优化分割效果 **
% 在你的报告中，可以详细讨论你如何选择这些参数以及它们的影响
filterParams.minArea = 50;         % 最小面积
filterParams.maxArea = 2000;       % 最大面积 (防止识别到粘连的巨大斑块)
filterParams.minAspectRatio = 0.1; % 最小宽高比 (宽/高)
filterParams.maxAspectRatio = 2.0; % 最大宽高比
filterParams.minExtent = 0.25;      % 填充率 (对象面积/边界框面积)
filterParams.minSolidity = 0.3;   % 坚实度 (对象面积/凸包面积)

validObjects = []; % 用于存放通过所有测试的对象

disp('正在应用高级几何过滤器...');
for i = 1:length(stats)
    bb = stats(i).BoundingBox;
    aspectRatio = bb(3) / bb(4); % 计算宽高比
    
    % 检查所有条件
    if stats(i).Area >= filterParams.minArea && ...
       stats(i).Area <= filterParams.maxArea && ...
       aspectRatio >= filterParams.minAspectRatio && ...
       aspectRatio <= filterParams.maxAspectRatio && ...
       stats(i).Extent >= filterParams.minExtent && ...
       stats(i).Solidity >= filterParams.minSolidity
   
        validObjects = [validObjects; stats(i)];
    end
end
stats = validObjects; % 用过滤后的结果覆盖原始stats
% =================================================================

%% 按从左到右的顺序对过滤后的字符排序
if ~isempty(stats)
    [~, sortOrder] = sort(arrayfun(@(s) s.BoundingBox(1), stats));
    stats = stats(sortOrder);
end

%% 可视化分割结果并保存单个字符
hFig = figure('Name', 'Task 6: Improved Segmentation Result', 'NumberTitle', 'off');
imshow(subImageGray);
hold on;

disp(['过滤后找到 ', num2str(length(stats)), ' 个有效字符，正在逐个保存...']);
for k = 1:length(stats)
    bb = stats(k).BoundingBox;
    rectangle('Position', bb, 'EdgeColor', 'r', 'LineWidth', 2);
    text(bb(1), bb(2)-10, num2str(k), 'Color', 'cyan', 'FontSize', 12);
    charImage = stats(k).Image;
    charImagePadded = padarray(charImage, [4 4], 0, 'both');
    charFilename = sprintf('char_%02d.png', k);
    imwrite(charImagePadded, fullfile(outputDirChars, charFilename));
end
hold off;
title(['分割出的 ', num2str(length(stats)), ' 个字符 (已过滤)']);
disp('结果图已显示，请查看。');

%% 保存最终结果
figurePath = fullfile(outputDir, 'segmentation_result_filtered.png');
saveas(hFig, figurePath);
disp(['改进后的分割结果图已保存到: ', figurePath]);
disp(['所有单个字符图像已保存到: ', outputDirChars]);
disp('--- 任务 6 (改进版) 完成 ---');