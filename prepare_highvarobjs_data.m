% This script extracts the EEG data, category and exemplar labels from the
% Raw .mat files and combines them into a single file for each subject

% Greta Vilidaite, 11th May 2018


% Note: The RSA toolbox expects an EEG data frame X and a vector of stimulus labels
% Y. X can be a 3D matrix (electrodes x time x trials) or a 2D matrix
% (features x trials).

close all
clear all

subjects = {'nl-0014','nl-0043','nl-0045','nl-0046','nl-0047'};
folders = {'1Hz','2Hz','4Hz'};

downsampling_factor = 4;
no_of_conds = 8;


% EEGpath = '~/Greta/2015_Ensembles_data/EEG_files/';
EEGpath = '~/Greta/2018_HighVarObjs_data/EEG_files/';

cd(EEGpath);

% find and open all Run Time Segment files and put them in one matrix:
for f = 1:length(folders)
    for s = 1:length(subjects)
        allSeg = dir(strcat(EEGpath,folders{f},'/',subjects{s},'/RTSeg*')); % get info (names) of all segment files

        count = 0;
        for n = 1:length(allSeg)

            listSegs{n} = allSeg(n).name;

            load(strcat(folders{f},'/',subjects{s},'/',listSegs{n}));

            if ~isempty(TimeLine) % checks that there is some information in there
                count = count + 1;
                % adding each structure's info onto the end of our vectors
                if count == 1
                    ind_start = 1;
                    ind_end = length(TimeLine);
                else
                    ind_start = ind_end + 1;
                    ind_end = length(TimeLine) + ind_start - 1;
                end

                currentSeg = extractfield(TimeLine, 'cndNmb');
                condNs(ind_start:ind_end) = currentSeg;
                currentSeg = extractfield(TimeLine, 'trlNmb');
                trialNs(ind_start:ind_end) = currentSeg;
            end
        end


        exempNs = mod(trialNs,no_of_conds)+1; % calculating the exemplar level labels from trial numbers;

        exempcodeSeg = (condNs-1)*no_of_conds+exempNs; % giving each exemplar a unique number (1-36)

        count = 0;
        for c = 1:no_of_conds % for each condition

            curExemps = exempcodeSeg((condNs==c)); % retrieving unique exemplar numbers just for this condition

            allRaw = dir(strcat(folders{f},'/',subjects{s},'/Raw_c00',num2str(c),'_t*')); % get info (names) of all segment files

            for t = 1:length(allRaw)

                count = count + 1;

                EEG = load(strcat(folders{f},'/',subjects{s},'/','Raw_c',num2str(c,'%03d'),'_t',num2str(t,'%03d'),'.mat')); % loading the file

                labelsByCond(count) = c;

                labelsByExemp(count) = curExemps(t);
                
                EEGdata(:,:,count) = EEG.RawTrial;

                for el = 1:130 % for each electrode
                    EEGdata_downsampled(:,el,count) = decimate(double(EEG.RawTrial(:,el)), downsampling_factor); % downsampled EEG data
                end    

                clear EEG

            end
        end

        save(strcat('~/Greta/2018_HighVarObjs_data/Matclass_ready/', subjects{s}, '_', folders{f}, '_data4RSA.mat'), 'EEGdata', 'EEGdata_downsampled', 'labelsByCond', 'labelsByExemp')
        clear EEGdata EEGdata_downsampled labelsByCond labelsByExemp
    
    end
end
