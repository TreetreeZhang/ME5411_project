outputFolder = 'CNN-result';
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

load("cnn.mat")

path = "task6_output\individual_characters\char_";

for i = 1:10
    imgPath = sprintf('%s%02d.png', path, i);
    disp(imgPath);
    img = imread(imgPath);
    [height, width] = size(img);
    padding = floor((height - width) / 2);
    img = padarray(img, [0 padding], 0, 'both');

    img = imresize(img, [128 128]);
    img = im2double(img);

    [prediction, scores] = classify(net, img);
    
    % 显示结果并保存
    fig = figure;
    subplot(1, 2, 1);
    imshow(img)
    title(['预测: ', char(prediction)]);
    subplot(1, 2, 2);
    bar(scores);
    title('各类别置信度');
    ylabel('置信度分数');
    categories = {'0', '4', '7', '8', 'A', 'D', 'H'};
    set(gca, 'XTick', 1:length(scores));
    set(gca, 'XTickLabel', categories);
    outputFilename = fullfile(outputFolder, sprintf('CNN_classify_result_%02d.png', i));
    saveas(fig, outputFilename);
end
