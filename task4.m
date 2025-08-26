%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ME 5411 Computer Project - Script 4: Binarize Sub-image (v2 - Healing)
% Task 4: Convert the sub-image from Step 3 into a binary image,
%         and apply morphological operations to heal broken characters.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% 初始化
clear; 
clc; 
close all;
disp('--- 开始执行任务 4 (修复版): 图像二值化与字符修复 ---');

%% 定义输入和输出文件夹
inputDir = 'task3_output';
outputDir = 'task4_output';
if ~exist(outputDir, 'dir'), mkdir(outputDir); disp(['已创建文件夹: ', outputDir]); end

%% 加载任务3的输出图像
inputImagePath = fullfile(inputDir, 'output_for_task4.png');
try, subImage = imread(inputImagePath); disp(['成功从以下路径加载图像: ', inputImagePath]);
catch, error('无法读取任务3的输出图像。请先成功运行任务3的脚本。'); end

%% 步骤 1: 基础二值化
%%binaryImageInitial = imbinarize(subImage, 'adaptive', 'ForegroundPolarity', 'bright', 'Sensitivity', 0.6);
binaryImageInitial = imbinarize(subImage, 0.6);

%% =================== 新增：形态学修复步骤 ===================
% 我们的字符是点阵式的，在二值化后很可能会断裂。
% 我们需要用形态学操作将它们重新连接起来。

% 步骤 2: 形态学闭合 (Closing)
% "闭合"操作可以连接邻近的白色区域，非常适合修复断裂的笔画。
% 我们使用一个较小的"线状"结构元素，主要在水平方向上连接。
se = strel('line', 3, 0); % 创建一个长度为3，角度为0（水平）的线状结构元素
binaryImageClosed = imclose(binaryImageInitial, se);

% 步骤 3: 填充内部孔洞 (Fill Holes)
% 对于像 'D', '4', 'A', '0' 这样的字符，其中间的"洞"也需要被填充，
% 这样它们才会被识别为一个坚实的、完整的对象。
binaryImageHealed = imfill(binaryImageClosed, 'holes');
% =================================================================

%% 显示并保存结果
hFig = figure('Name', 'Task 4: Binarization and Healing Process', 'NumberTitle', 'off');
subplot(1, 3, 1);
imshow(binaryImageInitial);
title('步骤1: 初始二值化 (字符破碎)');

subplot(1, 3, 2);
imshow(binaryImageClosed);
title('步骤2: 形态学闭合 (笔画连接)');

%%subplot(1, 3, 3);
%%imshow(binaryImageHealed);
%%title('步骤3: 孔洞填充 (字符完整)');

disp('结果图已显示，请查看修复过程。');

%% 保存最终的、修复好的二值图像
% 保存对比figure
figurePath = fullfile(outputDir, 'binarization_healing_process.png');
saveas(hFig, figurePath);
disp(['二值化修复过程图已保存到: ', figurePath]);

% 保存最终修复好的二值图像，供任务5使用
outputImagePath = fullfile(outputDir, 'output_for_task5.png');
imwrite(binaryImageHealed, outputImagePath);
disp(['修复后的二值图像已保存到: ', outputImagePath]);

disp('--- 任务 4 (修复版) 完成 ---');