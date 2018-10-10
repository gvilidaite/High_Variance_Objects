% High Variance Object (Seibert stimuli) RSA analysis, pretty much copied
% from ensemble_rsa.m with an added bit at the start that combines subject
% data into a matrix. Analyses all three presentation frequencies (1Hz, 2Hz, 4Hz)
%
% Currently treats all subjects as one: combining trials. No trial
% averaging done.
%
% GV 28th September 2018

close all
clear all

% SOME FLAGS TO SET:
doRSA = 0; % 1 = do RSA using the following flags; 0 = just load in the specified file and plot stuff

freqs = {'1Hz','2Hz','4Hz'};

% Add any other information here (e.g. if you used some averaging
% procedures, artefact rejection, etc):
RSAinfo.other = '';

whichlabels = 2; % 1 = object category labels; 2 = exemplar labels

pseudo_trial_size = 5; % number of trials to average over to make pseudotrials. Assign 0 to not create pseudo trials

just_250ms = 0; % only analyse the first 250ms of data in all frequencies

averagetrials = 0; % number of trials/pseudotrials to average over during classifyEEG

% plotting settings
no_boats = 0; % 1 = don't plot the boat data



outputFileName = 'highVarObjs_RSAresults'; % leave as is
% this is the first part of the folder name that RSA results will be saved in;
% or if RSA is not being done, this is the folder that will be used to get RSA files and
% plot data, completing the folder name using the below flags (the folder name is
% auto-completed based on them)

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

% RSA analysis ------------------------------------------------------------
if doRSA
    dataPath = uigetdir('Choose folder containing _data4RSA.mat files');
end

outputPath = uigetdir('Choose output folder');

if doRSA % if flag set to 1, do the following RSA analysis and save the results into a .mat file

    for freq = 1:length(freqs)

        inputfiles = dir(strcat(dataPath,'/*_',freqs{freq},'_data4RSA.mat'));      
        
        for file = 1:length(inputfiles)
            fileList{file} = inputfiles(file).name;
        end

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

            end_ind = start_ind + length(currentfile.labelsByCond) - 1;

            if whichlabels == 1 % object category classification
               Y(start_ind:end_ind) = currentfile.labelsByCond; % all category labels in a single vector
            elseif whichlabels == 2 % object exemplar classification
               Y(start_ind:end_ind) = currentfile.labelsByExemp; % all exemplar labels in a single vector
            end

            
            X(:,:,start_ind:end_ind) = currentfile.EEGdata_downsampled;

            start_ind = end_ind + 1;

            clear currentfile

        end
        
                
        if just_250ms
           X = X(1:27,:,:); 
        end
        
       
        if pseudo_trial_size
            unique_labels = unique(Y); % find all unique labels
            
            lab_start = 1;

            for lab = unique_labels % iterate over unique labels

                tempX = X(:,:,Y==lab); % retrieve all trials with that label
                
                
                shuffle_indices = randperm(size(tempX,3));
                
                tempX = tempX(:,:,shuffle_indices); %randomise order of trials
                
                no_of_pseudo = size(tempX,3)./pseudo_trial_size;
                
                ind1 = 1;
                for ps = 1:no_of_pseudo
                    
                    ind2 = ind1 + pseudo_trial_size - 1;

                    pseudoTrial = mean(tempX(:,:,ind1:ind2),3);
                    
                    ind1 = ind2;
                    
                    newX(:,:,ps) = pseudoTrial;
                    newY(ps) = lab;
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
        end
        
        
        
        [CM(freq,:,:), accuracy, predY, currentpVal, classifierInfo] = classifyEEG(X, Y, 'classify','LDA','averageTrials',averagetrials);
        totalObs = sum(CM,2); % calculating total number of observations (trials) in each row
        
        clear X Y newX newY pseudoTrial tempX shuffle_indices finishedX finishedY
        
        for col = 1:size(CM,2)
            CM_percent(freq,:,col) = CM(freq,:,col).*100./totalObs(col);
        end

    end
save(strcat(outputPath,'/', outputFileName,'.mat'),'CM','CM_percent','accuracy','predY','pVal','classifierInfo','RSAinfo');

end             

if exist(strcat(outputPath,'/', outputFileName,'.mat'))
    load(strcat(outputPath,'/', outputFileName,'.mat'));
else
    disp('Analysis file does not exist')
end


figno = 0;


for freq = 1:length(freqs)
    
    if no_boats
        plotCM(1:8,1:8) = squeeze(CM(freq,1:8,1:8)); 
        plotCM(9:56,9:56) = squeeze(CM(freq,17:64,17:64)); 
        plotCM(1:8,9:56) = squeeze(CM(freq,1:8,17:64));
        plotCM(9:56,1:8) = squeeze(CM(freq,17:64,1:8));
    else
        plotCM = squeeze(CM(freq,:,:)); 
        
    end
    
    figno = figno+1;
    figure(figno)

    plotMatrix(plotCM, 'colorMap', 'jet', 'colorBar', 1, 'matrixLabels', 0);
end




