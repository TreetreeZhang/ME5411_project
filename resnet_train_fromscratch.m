% train_resnet18_fromscratch_fix.m
% 从头使用 resnet18('Weights','none') 并自动修复残差跳连（strict: 若调用失败则报错）
clear; close all; clc; rng(0);

%% ========== 配置 ==========
data_folder = 'dataset_2025';   % 数据根目录（每个子文件夹为一个类别）
modelSaveName = 'resnet18_fromscratch_fixed.mat';
resultsCsv = 'resnet18_fromscratch_fixed_results.csv';

% 训练超参（可按需调整）
initialLearnRate = 1e-3;
maxEpochs = 40;
miniBatchSize = 32;

%% ========== 读取数据（保持与你原脚本接口一致） ==========
imds = imageDatastore(data_folder, "IncludeSubfolders", true, ...
    'FileExtensions', {'.png'}, 'LabelSource', 'foldernames');

if isempty(imds.Files)
    error('未在 data_folder (%s) 中发现任何 .png 文件，请检查路径。', data_folder);
end

imds.ReadFcn = @preprocessImage;
[imdsTrain, imdsTest] = splitEachLabel(imds, 0.75, 'randomized');

disp(['训练集图像数: ', num2str(numel(imdsTrain.Files)), '  测试集图像数: ', num2str(numel(imdsTest.Files))]);
numClasses = numel(categories(imds.Labels));

%% ========== 数据增强 ==========
augmenter = imageDataAugmenter( ...
    'RandRotation',[-10 10], ...
    'RandXTranslation',[-3 3], ...
    'RandYTranslation',[-3 3], ...
    'RandScale',[0.9 1.1]);

%% ========== 加载 resnet18('Weights','none')（严格）==========
try
    netPre = resnet18('Weights','none'); % 若此处失败会立即报错
catch ME
    error(['调用 resnet18(''Weights'',''none'') 失败：%s\n' ...
        '请确认你的 MATLAB / Deep Learning Toolbox 版本是否支持该调用，或考虑安装预训练支持包（推荐）。'], ME.message);
end

% 将返回对象转换为 layerGraph（多种可能返回类型）
if isa(netPre, 'DAGNetwork') || isa(netPre, 'SeriesNetwork')
    lgraph = layerGraph(netPre);
elseif isprop(netPre, 'Layers')
    lgraph = layerGraph(netPre.Layers);
elseif isvector(netPre) && all(arrayfun(@(x) isa(x,'nnet.cnn.layer.Layer'), netPre))
    lgraph = layerGraph(netPre);
else
    error('resnet18(''Weights'',''none'') 返回对象类型 %s 无法直接转换为 layerGraph。', class(netPre));
end

%% ========== 自动修复残差跳连（shortcut） ==========
% 调用内部函数修复 lgraph 中 addition 层的 in1/in2 连接
lgraph = fixResNetSkipConnections(lgraph);  % 如果修复失败会抛错并显示具体缺失信息

%% ========== 替换最后的全连接层为 numClasses ==========
% 找到最后一个 FullyConnected 层并替换
fcIdx = find(arrayfun(@(L) isa(L,'nnet.cnn.layer.FullyConnectedLayer'), lgraph.Layers), 1, 'last');
if isempty(fcIdx)
    error('在网络中未找到 FullyConnected 层，无法替换输出维度。');
end
fcName = lgraph.Layers(fcIdx).Name;
lgraph = replaceLayer(lgraph, fcName, fullyConnectedLayer(numClasses, 'Name','fc_new', 'WeightLearnRateFactor',10, 'BiasLearnRateFactor',10));

% 确保 softmax 与 classification 层存在/替换
if any(strcmp({lgraph.Layers.Name}, 'prob')), lgraph = replaceLayer(lgraph, 'prob', softmaxLayer('Name','prob')); end
if any(strcmp({lgraph.Layers.Name}, 'ClassificationLayer_predictions')), lgraph = replaceLayer(lgraph, 'ClassificationLayer_predictions', classificationLayer('Name','ClassificationLayer_predictions')); end

%% ========== 准备 augmentedImageDatastore ==========
% resnet18 通常期望 3 通道输入；我们使用 gray2rgb 将灰度复制为三通道
inputSize = lgraph.Layers(1).InputSize;
if numel(inputSize) < 3 || inputSize(3) ~= 3
    error('检测到网络输入通道数与预期不同：%s. 本脚本预期三通道输入。', mat2str(inputSize));
end

augImdsTrain = augmentedImageDatastore(inputSize(1:2), imdsTrain, 'DataAugmentation', augmenter, 'ColorPreprocessing', 'gray2rgb');
augImdsTest  = augmentedImageDatastore(inputSize(1:2), imdsTest,  'ColorPreprocessing', 'gray2rgb');

%% ========== 训练选项与训练 ==========
valFreq = max(1, floor(numel(imdsTrain.Files)/miniBatchSize));
options = trainingOptions('sgdm', ...
    'InitialLearnRate', initialLearnRate, ...
    'Momentum', 0.9, ...
    'MaxEpochs', maxEpochs, ...
    'MiniBatchSize', miniBatchSize, ...
    'Shuffle', 'every-epoch', ...
    'ValidationData', augImdsTest, ...
    'ValidationFrequency', valFreq, ...
    'Verbose', true, ...
    'Plots', 'training-progress', ...
    'ExecutionEnvironment', 'auto', ...
    'L2Regularization', 1e-4);

disp('开始训练（从头，已修复跳连）...');
[trainedNet, info] = trainNetwork(augImdsTrain, lgraph, options);

% 保存模型
save(modelSaveName, 'trainedNet', 'info', '-v7.3');
disp(['训练完成并保存模型：', modelSaveName]);

%% ========== 在测试集上评估并保存结果 ==========
disp('在测试集上评估...');
scores = predict(trainedNet, augImdsTest); % NxC
[~, idxMax] = max(scores, [], 2);
classes = trainedNet.Layers(end).Classes;
YPred = classes(idxMax);
YTrue = imdsTest.Labels;
accuracy = mean(YPred == YTrue);
fprintf('测试集准确率: %.2f%%\n', accuracy*100);

figure; confusionchart(YTrue, YPred); title('混淆矩阵（从头训练，修复跳连）');

% 保存预测结果到 CSV
maxScores = max(scores, [], 2);
scoreStr = cell(size(scores,1),1);
for i = 1:size(scores,1)
    scoreStr{i} = sprintf('%.4f,', scores(i,:));
    scoreStr{i}(end) = [];
end
T = table(imdsTest.Files(:), cellstr(YTrue), cellstr(YPred), maxScores, scoreStr, ...
    'VariableNames', {'Filename','TrueLabel','PredLabel','MaxScore','AllScores'});
writetable(T, resultsCsv);
disp(['测试结果已保存为 ', resultsCsv]);

%% ========== 辅助函数：自动修复跳连 ==========
function lgraph = fixResNetSkipConnections(lgraph)
    % 自动为 resnet 风格 layerGraph 中的 addition 层连接 in1/in2
    % 假定层命名遵循常见模式：
    %   - branch2b 的 BN 名称为 'bn<suffix>_branch2b'（例如 'bn2a_branch2b'）
    %   - 可选的 projection shortcut BN 名称为 'bn<suffix>_branch1'（例如 'bn3a_branch1'）
    %   - addition 层名如 'res2a', 'res3a' 等（即残差块标签）
    %
    % 如果遇到找不到预期层名，会报错以便你检查具体层名。

    layerNames = arrayfun(@(L) L.Name, lgraph.Layers, 'UniformOutput', false);

    % 找出所有 addition layer（AdditionLayer 类型）
    addIdx = find(arrayfun(@(L) isa(L,'nnet.cnn.layer.AdditionLayer'), lgraph.Layers));
    addNames = layerNames(addIdx);

    if isempty(addNames)
        error('在 lgraph 中未找到任何 addition 层。请检查网络结构是否为 resnet 风格。');
    end

    fprintf('修复 %d 个 addition 层的跳连...\n', numel(addNames));

    for i = 1:numel(addNames)
        addName = addNames{i}; % e.g. 'res2a'
        % 推断 suffix（如 '2a'）
        if strncmp(addName, 'res', 3)
            suffix = addName(4:end);
        else
            % 允许其它命名，但当前脚本主要支持 res* 前缀
            error('不支持的 addition 层名称格式：%s（期望以 "res" 开头）', addName);
        end

        % branch2b 对应 BN 层名（常见）
        bn2b = ['bn' suffix '_branch2b'];
        if ~ismember(bn2b, layerNames)
            error('修复失败：未找到 %s（用于 %s 的 in2）。请检查层名列表。', bn2b, addName);
        end

        % 连接 bn2b -> addName/in2（如果尚未连接）
        conns = lgraph.Connections;
        if ~any(strcmp([addName '/in2'], conns.Destination))
            lgraph = connectLayers(lgraph, bn2b, [addName '/in2']);
            fprintf('连接 %s -> %s/in2\n', bn2b, addName);
        else
            fprintf('跳过（in2 已连接）: %s -> %s/in2\n', bn2b, addName);
        end

        % shortcut 源：优先寻找 projection bn1（bn<suffix>_branch1）
        bn1 = ['bn' suffix '_branch1'];
        if ismember(bn1, layerNames)
            srcShort = bn1;
        else
            % 否则找到 branch2a 层并选择其前一层作为 shortcut 源
            branch2a = [addName '_branch2a'];
            idxBranch2a = find(strcmp(layerNames, branch2a), 1, 'first');
            if isempty(idxBranch2a)
                error('修复失败：未找到 %s（用于确定 %s 的 shortcut 源）。', branch2a, addName);
            end
            if idxBranch2a <= 1
                error('修复失败：%s 索引不合法，无法确定 shortcut 源。', branch2a);
            end
            srcShort = layerNames{idxBranch2a - 1};
            % 这里选择 branch2a 之前那一层作为 identity shortcut 的源（通常是上游 relu 或 pool）
        end

        % 连接 shortcut -> addName/in1（若尚未连接）
        if ~any(strcmp([addName '/in1'], lgraph.Connections.Destination))
            lgraph = connectLayers(lgraph, srcShort, [addName '/in1']);
            fprintf('连接 %s -> %s/in1\n', srcShort, addName);
        else
            fprintf('跳过（in1 已连接）: %s -> %s/in1\n', srcShort, addName);
        end
    end

    % 最后确认所有 addition 层都已连好
    dests = lgraph.Connections.Destination;
    missing = {};
    for i = 1:numel(addNames)
        a = addNames{i};
        if ~any(strcmp([a '/in1'], dests)) || ~any(strcmp([a '/in2'], dests))
            missing{end+1} = a; %#ok<AGROW>
        end
    end
    if ~isempty(missing)
        error('以下 addition 层仍有未连接输入：%s', strjoin(missing, ', '));
    end

    fprintf('所有 addition 层的 in1/in2 均已连接。\n');
end

%% ========== 预处理函数（与训练/推理保持一致） ==========
function img = preprocessImage(filename)
    img = imread(filename);
    if ndims(img) == 3 && size(img,3) == 4
        img(:,:,4) = [];
    end
    if size(img,3) == 3
        img = rgb2gray(img);
    end
    img = im2double(img);
    % 保持原来脚本的行为：当前脚本默认使用 imcomplement；如果你不想反转请删除下一行
    img = imcomplement(img);
    if ismatrix(img)
        img = reshape(img, [size(img,1), size(img,2), 1]);
    end
end
