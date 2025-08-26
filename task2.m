%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ME 5411 Computer Project - Script 2: Image Smoothing
% Task 2: Implement and apply a 5x5 averaging filter to the image. 
% Experiment with filters of different sizes.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% 初始化
clear; 
clc; 
close all;
disp('--- 开始执行任务 2: 图像平滑 ---');

%% 定义输入和输出文件夹
inputDir = 'task1_output';
outputDir = 'task2_output';
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
    disp(['已创建文件夹: ', outputDir]);
end

%% 加载任务1的输出图像
inputImagePath = fullfile(inputDir, 'output_for_task2.png');
try
    enhancedImage = imread(inputImagePath);
    disp(['成功从以下路径加载图像: ', inputImagePath]);
catch
    error('无法读取任务1的输出图像。请先成功运行任务1的脚本。');
end

%% 应用不同尺寸的均值滤波器
% 1. 3x3 均值滤波器
filter_3x3 = fspecial('average', [3 3]);
smoothedImage_3x3 = imfilter(enhancedImage, filter_3x3, 'replicate');

% 2. 5x5 均值滤波器 (项目要求) [cite: 27]
filter_5x5 = fspecial('average', [5 5]);
smoothedImage_5x5 = imfilter(enhancedImage, filter_5x5, 'replicate');

% 3. 9x9 均值滤波器
filter_9x9 = fspecial('average', [9 9]);
smoothedImage_9x9 = imfilter(enhancedImage, filter_9x9, 'replicate');

%% 可视化并比较结果
hFig = figure('Name', 'Task 2: Smoothing Filter Comparison', 'NumberTitle', 'off');
subplot(2, 2, 1);
imshow(enhancedImage);
title('平滑前 (来自任务1)');
subplot(2, 2, 2);
imshow(smoothedImage_3x3);
title('3x3 均值滤波');
subplot(2, 2, 3);
imshow(smoothedImage_5x5);
title('5x5 均值滤波');
subplot(2, 2, 4);
imshow(smoothedImage_9x9);
title('9x9 均值滤波');
disp('结果图已显示，请查看。');

%% 保存所有结果到文件夹
% 1. 保存对比图
figurePath = fullfile(outputDir, 'smoothing_comparison.png');
saveas(hFig, figurePath);
disp(['平滑结果对比图已保存到: ', figurePath]);

% 2. 单独保存每种尺寸滤波器处理后的图像
imwrite(smoothedImage_3x3, fullfile(outputDir, 'smoothed_image_3x3.png'));
disp('已单独保存[3x3滤波]处理的图像。');

imwrite(smoothedImage_5x5, fullfile(outputDir, 'smoothed_image_5x5.png'));
disp('已单独保存[5x5滤波]处理的图像。');

imwrite(smoothedImage_9x9, fullfile(outputDir, 'smoothed_image_9x9.png'));
disp('已单独保存[9x9滤波]处理的图像。');

% 3. 指定并保存用于下一步的图像
% 根据项目要求，我们需要对比并讨论结果[cite: 28]。5x5滤波器在去噪和保留细节之间
% 取得了较好的平衡，我们选择它作为任务3的输入。
outputForNextTaskPath = fullfile(outputDir, 'output_for_task3.png');
imwrite(smoothedImage_5x5, outputForNextTaskPath);
disp(['已将[5x5滤波]图像另存为下一步的输入: ', outputForNextTaskPath]);

disp('--- 任务 2 完成 ---');