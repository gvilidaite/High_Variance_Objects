% Script to replicate HighVarObjs RSA analysis on Kaneshiro data. Analyses
% data as a 'supersubject', combining all subjects into one matrix. Enables
% specifying how many trials per condition/per subject to use, what length
% of trial to use and how many subjects to include

% GV 8th October, 2018

close all
clear all


% ------------------------------ FLAGS TO SET -----------------------------
doRSA = 0; % 1 = do RSA using the following flags; 0 = just load in the specified file and plot stuff

whichlabels = 2; % 1 = object category labels; 2 = exemplar labels

no_of_subs = 5; % number of subjects to use

no_of_trials = 12; % number of trials per subject/per exemplar to use

pseudo_trial_size = 5; % number of trials to average over to make pseudotrials. Assign 0 or 1 to not create pseudo trials

just_250ms = 0; % only analyse the first 250ms of data in all frequencies

averagetrials = 0; % number of trials/pseudotrials to average over during classifyEEG

outputFileName = 'kanesh_results'; % file name

outputPath = '/Users/babylab/Greta/RSA/kaneshiro_as_highVarObjs/';

% -------------------------------------------------------------------------


dataPath = '/Users/babylab/Greta/RSA/Kaneshiro_data/';


% Naming the output file properly and adding some information:

if (whichlabels == 1)
    namestr1 = '_categ';
    RSAinfo.labels = 'category level';
else
    namestr1 = '_exemp';
    RSAinfo.labels = 'exemplar level';
end

outputFileName = strcat(outputFileName, namestr1); % renaming the folder properly

if pseudo_trial_size
    namestr2 = strcat('_pseudo', num2str(pseudo_trial_size));
    outputFileName = strcat(outputFileName, namestr2); % adding more to name of file
end

if just_250ms
    namestr3 = '_250ms';
    outputFileName = strcat(outputFileName, namestr3); % adding more to name of file
end



if doRSA % if flag set to 1, do the following RSA analysis and save the results into a .mat file

    inputfiles = dir(strcat(dataPath,'S*.mat'));      

    for file = 1:length(inputfiles)
        fileList{file} = inputfiles(file).name;
    end

    % pick a random sample of subjects (number specified by no_of_subs)
    
    fileList = randsample(fileList, no_of_subs);
    
    % setting up some empty cell arrays to store data in:
    predY = {};
    pVal = {};
    classifierInfo = {};


    start_ind = 1;
    end_ind = 1;

    for n = 1:length(fileList) % go  through fileList but ignore the last cell because it's always just a zero
        n
        currentfilename = fileList{n};

        currentfile = load(strcat(dataPath,'/',currentfilename));

        end_ind = start_ind + length(currentfile.exemplarLabels) - 1;

        if whichlabels == 1 % object category classification
           Y(start_ind:end_ind) = currentfile.categoryLabels; % all category labels in a single vector
        elseif whichlabels == 2 % object exemplar classification
           Y(start_ind:end_ind) = currentfile.exemplarLabels; % all exemplar labels in a single vector
        end


        X(:,:,start_ind:end_ind) = currentfile.X_3D;

        start_ind = end_ind + 1;

        clear currentfile

    end

    if just_250ms
       X = X(:,1:16,:); 
    end

 % subsampling and pseudotrials ---------------------
    unique_labels = unique(Y); % find all unique labels

    lab_start = 1;

    if pseudo_trial_size == 0
        pseudo_trial_size = 1;
    end
    
    
    for lab = unique_labels % iterate over unique labels

        tempX = X(:,:,Y==lab); % retrieve all trials with that label

         % randomly select subsample
        randSampleNumbs = randi([1 size(tempX,3)], 1, no_of_trials*no_of_subs);
        tempX = tempX(:,:,randSampleNumbs);

        no_of_pseudo = size(tempX,3)./pseudo_trial_size; % this should be equal to original number of trials of pseudo_trial_size is 1 or 0
        

        ind1 = 1;
        for ps = 1:no_of_pseudo

            ind2 = ind1 + pseudo_trial_size - 1;

            if no_of_pseudo == size(tempX,3)
                newX(:,:,ps) = tempX(:,:,ps);
                newY(ps) = lab;
            else
                pseudoTrial = mean(tempX(:,:,ind1:ind2),3);

                ind1 = ind2;

                newX(:,:,ps) = pseudoTrial;
                newY(ps) = lab;
            end
        end

    lab_end = lab_start + length(newY) - 1; 

    finishedX(:,:,lab_start:lab_end) = newX;
    finishedY(lab_start:lab_end) = newY;

    lab_start = lab_end + 1;

    has_loop_happened = 1;
    end

    clear X Y
    X = finishedX;
    Y = finishedY;

        

        [CM, accuracy, predY, currentpVal, classifierInfo] = classifyEEG(X, Y, 'classify','LDA','averageTrials',averagetrials);
        totalObs = sum(CM,2); % calculating total number of observations (trials) in each row
        
        clear X Y newX newY pseudoTrial tempX shuffle_indices finishedX finishedY
        
        for col = 1:size(CM,2)
            CM_percent(:,col) = CM(:,col).*100./totalObs(col);
        end

save(strcat(outputPath,'/', outputFileName,'.mat'),'CM','CM_percent','accuracy','predY','pVal','classifierInfo','RSAinfo');

end

if exist(strcat(outputPath,'/', outputFileName,'.mat'))
    load(strcat(outputPath,'/', outputFileName,'.mat'));
else
    disp('Analysis file does not exist')
end


figno = 0;
   
figno = figno+1;
figure(figno)

plotMatrix(CM, 'colorMap', 'jet', 'colorBar', 1, 'matrixLabels', 0);







