%========================================================================%
% Take each file from completeDataDirectory, one at a time and extract   % 
% landmarks using the readLdmkFile. Once you have the landmarks, take the%
% landmark for the nose and find the spin image for it. Extract all spin % 
% images for to form a nose and not-nose training set. Divide the data   %
% into train, test and validation. Then use SVM to classify the data as  %
% nose and not-nose.                                                     %
%========================================================================%

%=======================================================================================================================
%=======================================================================================================================

clear all
close all
clc

fprintf('\t\t\t\t\t\tA basic spin image and Support Vector Machine Classification Setup');
fprintf('\n\n');
disp('Classification of local, pose-invariant descriptors of 3D shape using SVMs..');
fprintf('\n\n');

dataDir = 'completeDataDirectory';
files = dir(dataDir);

[filesRows, filesCols] = size(files);

%=======================================================================================================================
%=======================================================================================================================

spinImagesNose = [];
%positiveTrainingExamples = []; % Add class label '1' to denote positive class (column vector)

disp('Calculating spin images for all the nose-tips. This will take around two and a half minutes..');
fprintf('\n');

% Turn triangulation (or any other) warning OFF
% w = warning('query','last'); % To get last warning message
% id = w.identifier; % To get identifier of warning
id = 'MATLAB:triangulation:PtsNotInTriWarnId';
warning('off', id);

% Get all spin images for nose-tip
for i = 4:3:filesRows
    
    root = files(i).name(1,1:9);
    
    % Define where the data is read from
    absFileName = [dataDir '/' root '.abs'];
    ldmkFileName = [dataDir '/' root '.auto.ldmk'];
    
    % This function reads the MANUALLY-defined landmarks.
    [landmarks, status] = readLdmkFile(ldmkFileName);
    % Landmark #6 is the landmark corresponding to the nose-tip. 
    noseTip = landmarks(6,:);
    
    % Get downsampled points
    [ptCloudData, ~] = readAbsToList(absFileName, 0);
    ptCloudData = gcData3D(ptCloudData,'list2array');
    ptCloudData = gcData3D(ptCloudData,'downSample3Darray',4);
    ptCloudData = gcData3D(ptCloudData,'list2array');
    ptCloudData = gcData3D(ptCloudData,'stripZeroFlaggedVertsFromList');
    
    vdata1 = ptCloudData.vlist;
    
    % Get exact location of the nose-tip  
    x = knnsearch(vdata1, noseTip);
    
    % Get mesh connectivity for point cloud 
    z = pointCloud2mesh(vdata1);
    
    % Call function to calculate the spin image of the nose-tip
    spinImagesNose = [spinImagesNose; generate_spin_image(vdata1, double(z.triangles), x, 8)];
    %positiveTrainingExamples = [positiveTrainingExamples; '1'];
    
end

disp('Calculated spin images for all the nose-tips in the data set..');
fprintf('\n\n');
pause(3);

%=======================================================================================================================
%=======================================================================================================================

disp('Now calculating spin images of random points on the face to get negative examples to train the SVM. This will take another two and a half minutes..');
fprintf('\n');

randomSpinImages = [];
%negativeTrainingExamples = []; % Add class label '0' to denote negative class (column vector)

% Accumulate random spin images to get negative training examples 
for i = 4:3:filesRows
    
    root = files(i).name(1,1:9);
    
    % Define where the data is read from
    absFileName = [dataDir '/' root '.abs'];
    
    % Get downsampled points
    [ptCloudData, ~] = readAbsToList(absFileName, 0);
    ptCloudData = gcData3D(ptCloudData,'list2array');
    ptCloudData = gcData3D(ptCloudData,'downSample3Darray',4);
    ptCloudData = gcData3D(ptCloudData,'list2array');
    ptCloudData = gcData3D(ptCloudData,'stripZeroFlaggedVertsFromList');
    
    vdata1 = ptCloudData.vlist;
    
    % Find 2 random points on the face
    randomPoints = datasample(vdata1,3);
    random1 = knnsearch(vdata1, randomPoints(1,:));
    random2 = knnsearch(vdata1, randomPoints(2,:));
    
    % Get mesh connectivity for point cloud 
    z = pointCloud2mesh(vdata1);
    
    % Call function to calculate the spin image of the random points
    randomSpinImages = [randomSpinImages; generate_spin_image(vdata1, double(z.triangles), random1, 8)];
    %negativeTrainingExamples = [negativeTrainingExamples; '0'];
    randomSpinImages = [randomSpinImages; generate_spin_image(vdata1, double(z.triangles), random2, 8)];
    %negativeTrainingExamples = [negativeTrainingExamples; '0'];
    
end

disp('Calculated spin images for random points on the face from the data set..');
fprintf('\n\n');

%=======================================================================================================================
%=======================================================================================================================
disp('Dividing the data into training and test..');
fprintf('\n\n');
% Divide the data into training and test
trainingData = [];
trainingLabels = [];
trainingData = [trainingData; spinImagesNose(1:4000,:)];
trainingData = [trainingData; randomSpinImages(1:8500,:)];
trainingLabels = [trainingLabels; ones(80,1)];
trainingLabels = [trainingLabels; zeros(170,1)];
[trainingDataRows,~] = size(trainingData);

dataTrain = [];
dataTrain = convertDataToSVMForm(trainingData, trainingDataRows);

testData = [];
testLabels = [];
testData = [testData; spinImagesNose(4001:end,:)];
testData = [testData; randomSpinImages(8501:end,:)];
testLabels = [testLabels; ones(20,1)];
testLabels = [testLabels; zeros(30,1)];
[testDataRows,~] = size(testData);

dataTest = [];
dataTest = convertDataToSVMForm(testData, testDataRows);
pause(3);

%=======================================================================================================================
%=======================================================================================================================

% Training the SVM
disp('Training the SVM..');
SVMStruct = svmtrain(dataTrain,trainingLabels);
fprintf('\n\n');
pause(3);

% Testing the trained SVM on the test set
disp('Testing on the test set..');
Group = svmclassify(SVMStruct,dataTest);
fprintf('\n\n');
pause(3);

%=======================================================================================================================
%=======================================================================================================================

% Check for accuracy
acc = 0;
[testLabelsRows, ~] = size(testLabels);

for i = 1:testLabelsRows
    if testLabels(i,:) == Group(i,:)
        acc = acc + 1;
    end
end
accuracyOfTheSystem = (acc/testLabelsRows)*100;
fprintf('%0.2f%% of the total samples were correctly classified\n\n', accuracyOfTheSystem);

disp('DONE.');
%=======================================================================================================================
%=======================================================================================================================