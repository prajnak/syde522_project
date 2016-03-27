srcFiles = dir('\\ecfile1.uwaterloo.ca\spspkand\My Documents\MATLAB\SYDE 522\PathologyImages\*.png')
% images;
for i = 1:length(srcFiles)
    filename = strcat('\\ecfile1.uwaterloo.ca\spspkand\My Documents\MATLAB\SYDE 522\PathologyImages\', srcFiles(i).name)
    I = imread(filename);
    images{i} = rgb2gray(imresize(I, [32 32]));
%     imshow(images{i})
end
imageW = 32;
inputSize = imageW*imageW
xTrain = zeros(inputSize, numel(images));
for i = 1:numel(images)
    xTrain(:,i) = images{i}(:);
end

hl_sizes = [512 256 128 64 32 16];
mses = [];
train_times = [];

mses_denoise = [];
train_times_denoise = [];
%% create a feedforward network
hiddensize1 = 1024/64;

autoenc1 = feedforwardnet(hiddensize1);
autoenc1.trainFcn = 'trainscg';
autoenc1.trainParam.epochs = 600;
% Do not use process functions at the input or output
% autoenc1.inputs{1}.processFcns = {};
% autoenc1.outputs{2}.processFcns = {};

% Set the transfer function for both layers to the logistic sigmoid
autoenc1.layers{1}.transferFcn = 'tansig';
autoenc1.layers{2}.transferFcn = 'tansig';

% Use all of the data for training
autoenc1.divideFcn = 'dividetrain'
% autoenc1.performFcn = 'msesparse';

% autoenc1.performParam.L2WeightRegularization = 0.004;
% autoenc1.performParam.sparsityRegularization = 4;
% autoenc1.performParam.sparsity = 0.15;

[autoenc1, trr] = train(autoenc1,xTrain,xTrain);

outputs = autoenc1(xTrain)
% perff = perform(autoenc1, xTrain, outputs)


figure;
subplot(2,1,1)
imshow(reshape(outputs(:,1), [32 32]), [])
title('predicted')
subplot(2,1,2)
imshow(reshape(xTrain(:,1), [32 32]), [])
title('original')


mses = [mses trr.best_perf];
train_times = [train_times trr.time(end)]


%%
figure;
plot(log(hl_sizes), mses, 'o-')
title('MSE and training time v/s Hidden Layer Size')
xlabel('Log scale hidden layer size')
ylabel('MSE')

figure;
plot(log(hl_sizes), train_times, 'o-')
title('Training Times vs Hidden layer size')
xlabel('Log scale hidden layer size')
ylabel('Time [seconds]')

%% repeat the process for a denoising autoencoder
xTrain2 = zeros(inputSize, numel(images));

for i=1:numel(images)
    imm = imnoise(images{i}, 'speckle');
    xTrain2(:,i) = imm(:);
end
hiddensize1 = 1024/64;

autoenc1 = feedforwardnet(hiddensize1);
autoenc1.trainFcn = 'trainscg';
autoenc1.trainParam.epochs = 1200;
% Do not use process functions at the input or output
% autoenc1.inputs{1}.processFcns = {};
% autoenc1.outputs{2}.processFcns = {};

% Set the transfer function for both layers to the logistic sigmoid
autoenc1.layers{1}.transferFcn = 'tansig';
autoenc1.layers{2}.transferFcn = 'tansig';

% Use all of the data for training
autoenc1.divideFcn = 'dividetrain'
% autoenc1.performFcn = 'msesparse';

% autoenc1.performParam.L2WeightRegularization = 0.004;
% autoenc1.performParam.sparsityRegularization = 4;
% autoenc1.performParam.sparsity = 0.15;

[autoenc1, trr] = train(autoenc1,xTrain2,xTrain);

outputs = autoenc1(xTrain)
perff = perform(autoenc1, xTrain, outputs)

msee = mse(autoenc1, xTrain, outputs);
figure;
subplot(3,1,1)
imshow(reshape(outputs(:,1), [32 32]), [])
title('predicted')
subplot(3,1,2)
imshow(reshape(xTrain(:,1), [32 32]), [])
title('original')
subplot(3,1,3)
imshow(reshape(xTrain2(:,1), [32 32]), [])
title('noised')

mses_denoise = [mses_denoise msee]
train_times_denoise = [train_times_denoise trr.time(end)]
%%
figure;
plot(log(hl_sizes), mses_denoise, 'o-');
hold on;
plot(log(hl_sizes), mses, 'o-');
title('MSE v/s Hidden Layer Size')
xlabel('Log scale hidden layer size')
ylabel('MSE')
legend(['De-Noising Autoencoder'], ['Normal Autoencoder'])

figure;
plot(log(hl_sizes), train_times_denoise, 'o-')
hold on;
plot(log(hl_sizes), train_times, 'o-')
title('Training Times vs Hidden layer size')
xlabel('Log scale hidden layer size')
ylabel('Time [seconds]')
legend(['De-Noising Autoencoder'], ['Normal Autoencoder'])