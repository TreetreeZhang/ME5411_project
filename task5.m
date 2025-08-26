%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ME 5411 Computer Project - Script 5: Determine Outlines
% Task 5: Determine the outline(s) of characters in the image. 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% 初始化
clear; 
clc; 
close all;
disp('--- 开始执行任务 5: 确定字符轮廓 ---');

%% 定义输入和输出文件夹
inputDir = 'task4_output';
outputDir = 'task5_output';
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
    disp(['已创建文件夹: ', outputDir]);
end

%% 加载任务4的输出图像
inputImagePath = fullfile(inputDir, 'output_for_task5.png');
try
    binaryImage = imread(inputImagePath);
    disp(['成功从以下路径加载图像: ', inputImagePath]);
catch
    error('无法读取任务4的输出图像。请先成功运行任务4的脚本。');
end

%% 查找并描绘轮廓
% bwboundaries 函数可以追踪图像中对象的轮廓。
% B 是一个元胞数组，每个元胞包含一个对象 (一个字符) 的 (x,y) 边界坐标。
% L 是一个标签矩阵，用不同的整数标记了不同的对象，方便彩色显示。
% 'noholes' 选项让函数只查找外边界，不查找内部的洞（例如'0'中间的洞），可以提高效率。
[B, L] = bwboundaries(binaryImage, 'noholes');

%% 显示并保存结果
% 创建一个图形窗口用于显示
hFig = figure('Name', 'Task 5: Character Outlines', 'NumberTitle', 'off');

% 使用 label2rgb 将标签矩阵 L 转换为彩色图像，让每个字符显示不同颜色
imshow(label2rgb(L, @jet, [.5 .5 .5])); 
hold on; % 保持当前图像，以便在上面绘制轮廓线

% 遍历所有找到的边界并在图上用白线画出来
for k = 1:length(B)
    boundary = B{k};
    plot(boundary(:,2), boundary(:,1), 'w', 'LineWidth', 2);
end

title('检测到的字符轮廓');
hold off;
disp('结果图已显示，请查看。');

% 保存figure
figurePath = fullfile(outputDir, 'character_outlines.png');
saveas(hFig, figurePath);
disp(['字符轮廓图已保存到: ', figurePath]);

% 任务6（分割）仍然需要任务4的二值图像作为输入。
% 为保持流程的线性，我们将该文件复制到当前输出文件夹，并重命名为任务6的输入。
outputImagePath = fullfile(outputDir, 'output_for_task6.png');
copyfile(inputImagePath, outputImagePath);
disp(['已将用于下一步的二值图像复制到: ', outputImagePath]);

disp('--- 任务 5 完成 ---');