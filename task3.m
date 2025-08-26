%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ME 5411 Computer Project - Script 3: Create Sub-image
% Task 3: Create a sub-image that includes the line - HD44780A00.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% 初始化
clear; 
clc; 
close all;
disp('--- 开始执行任务 3: 创建子图像 ---');

%% 定义输入和输出文件夹
inputDir = 'task2_output';
outputDir = 'task3_output';
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
    disp(['已创建文件夹: ', outputDir]);
end

%% 加载任务2的输出图像
inputImagePath = fullfile(inputDir, 'output_for_task3.png');
try
    smoothedImage = imread(inputImagePath);
    disp(['成功从以下路径加载图像: ', inputImagePath]);
catch
    error('无法读取任务2的输出图像。请先成功运行任务2脚本。');
end

%% 裁剪子图像
% 定义裁剪区域: rect = [xmin ymin width height]
% 注意: 这里的 [1, 100, size(smoothedImage, 2), 90] 是基于图像的估算值。
% 如果裁剪结果不理想，你可以微调 ymin 和 height 的值。
cropRect = [1, 200, size(smoothedImage, 2), 135]; 
subImage = imcrop(smoothedImage, cropRect);

%% 显示并保存结果
% 创建一个图形窗口用于显示
hFig = figure('Name', 'Task 3: Cropped Sub-image', 'NumberTitle', 'off');
imshow(subImage);
title('裁剪出的子图像: HD44780A00');
disp('结果图已显示，请查看。');

% 保存figure
figurePath = fullfile(outputDir, 'cropped_image_figure.png');
saveas(hFig, figurePath);
disp(['裁剪结果图已保存到: ', figurePath]);

% 保存裁剪后的图像数据，并命名为任务4的输入
outputImagePath = fullfile(outputDir, 'output_for_task4.png');
imwrite(subImage, outputImagePath);
disp(['用于下一步的子图像已保存到: ', outputImagePath]);

disp('--- 任务 3 完成 ---');