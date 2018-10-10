% Makes the image into a cirle and puts mid-grey around. Also adds a
% fixation cross. This is for a greyscale, normalized ensemble experiment

% G Vilidaite 18th July 2018

function makeHighVariationExpImages

clear all
close all

% settings:
output_mode = 2; % 1 = .jpg; 2 = .mat
size_multiplier = 4; % how many times to scale up the image size


inputdir = uigetdir('~/Users/','Select directory containing the images');
savedir = uigetdir('~/Users/','Select directory to save output images');

inputimages = dir(strcat(inputdir,'/*.png'));

no_images = length(inputimages);

for im = 1:no_images
    currimage = imread(strcat(inputdir,'/',inputimages(im).name));
    
    if im ==1
    imshow(currimage)
    end
    
    
    % increasing image size:
    currimage = imresize(currimage,size_multiplier);
    
    imsize = size(currimage);

    currimage = double(currimage);
    
    middle = round(imsize./2);   

    
    currimage((middle-3):(middle+3),(middle-30):(middle+30)) = round(255/2);  % horizontal grey stripe
    currimage((middle-30):(middle+30),(middle-3):(middle+3)) = round(255/2);  % vertical grey stripe
    currimage((middle-1):(middle+1),(middle-28):(middle+28)) = 255;  % horizontal white stripe
    currimage((middle-28):(middle+28),(middle-1):(middle+1)) = 255;  % vertical white stripe
    
    
    imagecell{im} = uint8(currimage);
end

if output_mode == 1 % if we want .jpg's
    for im = 1:no_images
        
            imwrite(imagecell{im}, strcat(savedir,'/',inputimages(im).name))
    end

else % if we want .mat files that are ready for xDiva

    % setting up the image sequence (prel for the experiment
    imageSequence = uint32(zeros(60,1));
    imageSequence(1) = 1;
%     imageSequence(16) = 1; not needed for this experiment because we're showing images back to back
%     imageSequence(31) = 3;
%     imageSequence(46) = 4;
%     imageSequence(60) = 3;
    
    count = 1;
    for im = 1:no_images
        images(:,:,1,1) = imagecell{im};
        images(:,:,1,2) = uint8(zeros(imsize(1),imsize(2)));
        switch im
            case num2cell(1:8)
                im_name = 'Animals';
                cond_no = 1;
            case num2cell(9:16)
                im_name = 'Boats';
                cond_no = 2;
            case num2cell(17:24)
                im_name = 'Cars';
                cond_no = 3;
            case num2cell(25:32)
                im_name = 'Chair';
                cond_no = 4;
            case num2cell(33:40)
                im_name = 'Faces';
                cond_no = 5;
            case num2cell(41:48)
                im_name = 'Fruit';
                cond_no = 6;
            case num2cell(49:56)
                im_name = 'Planes';
                cond_no = 7;
            case num2cell(57:64)
                im_name = 'Tables';
                cond_no = 8;
        end
        
        
        im_file_name = sprintf('%d_%s_%02d.mat',cond_no,im_name,count);
        save(strcat(savedir,'/',im_file_name), 'images', 'imageSequence')
        
        count = count + 1;
        if count > 8
            count = 1;
        end
        
    end
end
end
%--------------------------------------------------------------------------
