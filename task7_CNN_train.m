data_folder = 'dataset_2025';
imds = imageDatastore(data_folder, ...
    "IncludeSubfolders", true, ...
    'FileExtensions', '.png', ...
    'LabelSource', 'foldernames');
disp(['sum_number: ', num2str(numel(imds.Files))])
disp(['kind: ', num2str(numel(unique(imds.Labels)))])

% 对训练集做预处理
imds.ReadFcn = @preprocessImage;

[imdsTrain, imdsTest] = splitEachLabel(imds, 0.75, 'randomized');

disp(['训练集图像数量: ', num2str(numel(imdsTrain.Files))]);
disp(['测试集图像数量: ', num2str(numel(imdsTest.Files))]);

% 强化训练集
augmenter = imageDataAugmenter( ...
    'RandRotation', [-10, 10], ...     % 随机旋转
    'RandXTranslation', [-3 3], ...    % 随机水平平移
    'RandYTranslation', [-3 3], ...    % 随机垂直平移
    'RandScale', [0.9, 1.1]);          % 随机缩放

imdsTrain = augmentedImageDatastore([128 128], imdsTrain, ...
    'DataAugmentation', augmenter);

% 训练集的预处理函数
function img = preprocessImage(filename)
    img = imread(filename);
    img = im2double(img);
    img = imcomplement(img);
end

%% CNN网络层设计
layers = [
    imageInputLayer([128 128 1], 'Name', 'input')
    
    convolution2dLayer(3, 32, 'Padding', 'same', 'Name', 'conv1')
    batchNormalizationLayer('Name', 'bn1')
    reluLayer('Name', 'relu1')
    maxPooling2dLayer(2, 'Stride', 2, 'Name', 'maxpool1')
    
    convolution2dLayer(3, 64, 'Padding', 'same', 'Name', 'conv2')
    batchNormalizationLayer('Name', 'bn2')
    reluLayer('Name', 'relu2')
    maxPooling2dLayer(2, 'Stride', 2, 'Name', 'maxpool2')
    
    convolution2dLayer(3, 128, 'Padding', 'same', 'Name', 'conv3')
    batchNormalizationLayer('Name', 'bn3')
    reluLayer('Name', 'relu3')
    
    fullyConnectedLayer(128, 'Name', 'fc1')
    reluLayer('Name', 'relu4')
    dropoutLayer(0.7, 'Name', 'dropout')
    
    fullyConnectedLayer(7, 'Name', 'fc2')
    softmaxLayer('Name', 'softmax')
    classificationLayer('Name', 'output')
];

% 设置训练选项
options = trainingOptions('adam', ...
    'InitialLearnRate', 0.001, ...
    'MaxEpochs', 15, ...
    'MiniBatchSize', 32, ...
    'Shuffle', 'every-epoch', ...
    'ValidationData', imdsTest, ...
    'Verbose', true, ...
    'Plots', 'training-progress', ...
    'ExecutionEnvironment', 'cpu');

% 训练网络
disp('开始训练CNN...');
[net, info] = trainNetwork(imdsTrain, layers, options);

% 保存网络模型
save('cnn.mat', 'net');

%% 评估模型性能
% 在测试集上进行预测
[YPred, scores] = classify(net, imdsTest);
YTest = imdsTest.Labels;

% 计算准确率
accuracy = sum(YPred == YTest) / numel(YTest);
disp(['测试集准确率: ', num2str(accuracy * 100), '%']);