%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ME 5411 Computer Project - Script 1: Image Enhancement
% Task 1: Display the original image on screen. Experiment with contrast 
% enhancement of the image.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% 初始化
clear; 
clc; 
close all;
disp('--- 开始执行任务 1: 图像加载与对比度增强 ---');

%% 创建输出文件夹
outputDir = 'task1_output';
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
    disp(['已创建文件夹: ', outputDir]);
end

%% 加载原始图像
try
    originalImage_rgb = imread('charact2.bmp');
catch
    error('无法读取 "charact2.bmp"。请确保该文件与脚本在同一目录下。');
end

% 转换为灰度图
if size(originalImage_rgb, 3) == 3
    disp('图像被读取为RGB格式，正在转换为灰度图...');
    originalImage = rgb2gray(originalImage_rgb);
else
    originalImage = originalImage_rgb;
end

%% 执行对比度增强实验
% 1. 方法一: 直方图均衡化
enhancedImageHistEq = histeq(originalImage);

% 2. 方法二: 对比度拉伸
enhancedImageAdjust = imadjust(originalImage);

%% 可视化结果
hFig = figure('Name', 'Task 1: Contrast Enhancement Results', 'NumberTitle', 'off');
subplot(1, 3, 1);
imshow(originalImage);
title('原始图像 (灰度)');
subplot(1, 3, 2);
imshow(enhancedImageHistEq);
title('直方图均衡化');
subplot(1, 3, 3);
imshow(enhancedImageAdjust);
title('对比度拉伸');
disp('结果图已显示，请查看。');

%% 保存所有结果到文件夹
% 1. 保存包含所有子图的对比figure
figurePath = fullfile(outputDir, 'contrast_enhancement_comparison.png');
saveas(hFig, figurePath);
disp(['对比结果图已保存到: ', figurePath]);

% 2. 单独保存每种方法处理后的图像
imwrite(enhancedImageHistEq, fullfile(outputDir, 'enhanced_image_histeq.png'));
disp('已单独保存[直方图均衡化]处理的图像。');

imwrite(enhancedImageAdjust, fullfile(outputDir, 'enhanced_image_imadjust.png'));
disp('已单独保存[对比度拉伸]处理的图像。');

% 3. 指定并保存用于下一步的图像
% 根据项目要求，我们需要进行实验和比较[cite: 26]。对比度拉伸效果更佳，
% 因此我们选择它作为任务2的输入。
outputForNextTaskPath = fullfile(outputDir, 'output_for_task2.png');
imwrite(enhancedImageAdjust, outputForNextTaskPath);
disp(['已将[对比度拉伸]图像另存为下一步的输入: ', outputForNextTaskPath]);

disp('--- 任务 1 完成 ---');