% train_resnet18_pretrained_gpu_strict.m
% 严格模式 + 强制使用 GPU（若无可用 GPU 则立即报错）
clear; close all; clc;
rng(0);

%% 配置
data_folder = 'dataset_2025';
gpuIndex = 1;                % 要使用的 GPU 编号（1-based）
miniBatchSize = 32;          % 根据 GPU 显存调整（必要时减小到 16 / 8）
maxEpochs = 15;
initialLR = 1e-4;

%% 检查 Parallel Computing Toolbox & GPU 可用性（严格）
v = ver;
if ~any(strcmp({v.Name}, 'Parallel Computing Toolbox'))
    error(['未检测到 Parallel Computing Toolbox，无法在 GPU 上训练。' ...
           ' 请安装该工具箱或切换到 CPU 训练。']);
end

gpuCount = gpuDeviceCount;
if gpuCount < 1
    error('未检测到可用 GPU (gpuDeviceCount = 0)。请确保系统安装了兼容的 NVIDIA 驱动并能被 MATLAB 识别。');
end
if gpuIndex > gpuCount
    error('请求使用的 GPU 索引 (gpuIndex=%d) 超出可用 GPU 数量 (%d)。', gpuIndex, gpuCount);
end

% 选择并 reset 指定 GPU（确保清理显存）
g = gpuDevice(gpuIndex);
reset(g);
fprintf('使用 GPU %d: %s (ComputeCapability %s, FreeMemory %.2f GB)\n', ...
    gpuIndex, g.Name, g.ComputeCapability, g.FreeMemory/1024^3);

%% 读取数据（保持你之前的接口）
imds = imageDatastore(data_folder, "IncludeSubfolders", true, ...
    'FileExtensions', {'.png'}, 'LabelSource', 'foldernames');
imds.ReadFcn = @preprocessImage;
[imdsTrain, imdsTest] = splitEachLabel(imds, 0.75, 'randomized');

augmenter = imageDataAugmenter('RandRotation',[-10 10], 'RandXTranslation',[-3 3], ...
    'RandYTranslation',[-3 3], 'RandScale',[0.9 1.1]);

%% 加载 resnet18（严格要求预训练支持包）
try
    netPre = resnet18(); % 若未安装支持包会抛错并停止
catch ME
    error(['无法调用 resnet18()：%s\n' ...
           '请在 MATLAB 的 Add-On Explorer 中安装 "Deep Learning Toolbox Model for ResNet-18 Network" 支持包，' ...
           '路径：Home -> Add-Ons -> Get Add-Ons。'], ME.message);
end

% 确保能转为 layerGraph
if isa(netPre, 'DAGNetwork') || isa(netPre, 'SeriesNetwork')
    lgraph = layerGraph(netPre);
elseif isprop(netPre, 'Layers')
    lgraph = layerGraph(netPre.Layers);
else
    error('resnet18() 返回的对象无法转换为 layerGraph，请检查 MATLAB/Toolbox 版本或支持包安装情况。');
end

% 替换最后 FC 为类别数
numClasses = numel(categories(imds.Labels));
fcIdx = find(arrayfun(@(L) isa(L,'nnet.cnn.layer.FullyConnectedLayer'), lgraph.Layers), 1, 'last');
if isempty(fcIdx)
    error('在 resnet18 网络中未找到全连接层，无法替换输出维度为 %d。', numClasses);
end
lgraph = replaceLayer(lgraph, lgraph.Layers(fcIdx).Name, fullyConnectedLayer(numClasses,'Name','fc_new','WeightLearnRateFactor',10,'BiasLearnRateFactor',10));
if any(strcmp({lgraph.Layers.Name}, 'prob')), lgraph = replaceLayer(lgraph, 'prob', softmaxLayer('Name','prob')); end
if any(strcmp({lgraph.Layers.Name}, 'ClassificationLayer_predictions')), lgraph = replaceLayer(lgraph, 'ClassificationLayer_predictions', classificationLayer('Name','ClassificationLayer_predictions')); end

%% 数据准备（resnet18 期望三通道输入）
inputSize = lgraph.Layers(1).InputSize; % 一般 [224 224 3]
augImdsTrain = augmentedImageDatastore(inputSize(1:2), imdsTrain, 'DataAugmentation', augmenter, 'ColorPreprocessing','gray2rgb');
augImdsTest  = augmentedImageDatastore(inputSize(1:2), imdsTest, 'ColorPreprocessing','gray2rgb');

%% 训练选项（强制 GPU）
options = trainingOptions('sgdm', ...
    'InitialLearnRate', initialLR, ...
    'Momentum', 0.9, ...
    'MaxEpochs', maxEpochs, ...
    'MiniBatchSize', miniBatchSize, ...
    'Shuffle', 'every-epoch', ...
    'ValidationData', augImdsTest, ...
    'ValidationFrequency', max(1, floor(numel(imdsTrain.Files)/miniBatchSize)), ...
    'Verbose', true, ...
    'Plots', 'training-progress', ...
    'ExecutionEnvironment', 'gpu', ...        % 强制 GPU（严格）
    'DispatchInBackground', false);          % 不在后台分发，便于出现错误时立即可见

%% 训练（捕获显存不足等错误并给出建议）
disp('开始在 GPU 上微调 ResNet18（严格模式）...');
try
    [trainedNet, info] = trainNetwork(augImdsTrain, lgraph, options);
catch ME
    % 若是 GPU OOM，可以给出改进建议
    msg = ME.message;
    if contains(msg, 'OutOfMemory') || contains(msg, 'out of memory') || contains(msg, 'OOM')
        error(['训练过程中 GPU 内存不足：%s\n' ...
               '建议：减小 miniBatchSize（当前 %d），或在训练前执行 reset(gpuDevice(%d)); 或在训练前关闭占用 GPU 的其他进程。' ...
               ' 例如尝试 miniBatchSize = max(1, floor(%d/2)).'], msg, miniBatchSize, gpuIndex, miniBatchSize);
    else
        rethrow(ME);
    end
end

% 保存模型
save('resnet18_pretrained_strict_gpu.mat', 'trainedNet', 'info', '-v7.3');
disp('训练完成并已保存：resnet18_pretrained_strict_gpu.mat');

%% 评估
[YPred, scores] = classify(trainedNet, augImdsTest);
YTest = imdsTest.Labels;
acc = mean(YPred == YTest);
fprintf('测试集准确率: %.2f%%\n', acc*100);
figure; confusionchart(YTest, YPred); title('混淆矩阵（预训练 GPU 严格模式）');

%% 预处理函数（与原脚本接口一致）
function img = preprocessImage(filename)
    img = imread(filename);
    if ndims(img)==3 && size(img,3)==4, img(:,:,4)=[]; end
    if size(img,3)==3, img = rgb2gray(img); end
    img = im2double(img);
    img = imcomplement(img);
    if ismatrix(img), img = reshape(img, [size(img,1), size(img,2), 1]); end
end
