%%% script to use on video-camera computer - will find camera, collect images 
% from it during trials and calculate whether the participant gives a blink
% during the trial period - and then signal to the 1401 whether or not to 
% deliver the airpuff

%% first section adapted from code sent by MRC-systems 
% connects to camera, sets default settings and takes snapshop to set
% dark values - sample code for one MRC camera in the network

% clear environment     
close all; clear;  

%open Gige device, you can add th eIP address to select a specific camera
%with gigecamlist you can get a list of available cameras
src = gigecam;

src.PacketSize = 9000;
src.PacketDelay = 500;

%here you can change the sensor resolution
src.Width = 640;
src.Height = 240;
src.OffsetX = 0;
src.OffsetY = 0;

% set frames per second, limited by sensor resolution
src.FPS = 518;
% Set GlobalGain value
src.GlobalGain = 4;
%set exosure time to shortest time for acquiring dark image
src.ExposureTime = 8;

for i = 1:20
    % the last image is our dark reference
    dark = snapshot(src);
end
%set exposure time to ~2ms
src.ExposureTime = 1975;

%% connect to ports on DAQ card - 
% 1401 (for controlling experiment) connected to computer via BNC ports on 
% DAQ card. Ports 0-5 are input (0-7 lines each), 
% ports 6-11 are output (0-7 lines each)

ADLINK_INFO = daqhwinfo('mwadlink');
dio_device = digitalio( 'mwadlink', 0);

di_lines = addline(dio_device, 0:7, 0, 'in'); 
di_lines2 = addline(dio_device, 0:7, 1, 'in'); 
di_lines3 = addline(dio_device, 0:7, 2, 'in');
di_lines4 = addline(dio_device, 0:7, 3, 'in');
di_lines5 = addline(dio_device, 0:7, 4, 'in'); 
di_lines6 = addline(dio_device, 0:7, 5, 'in'); 

do_lines = addline(dio_device, 0:7, 7, 'out'); 

% reset output lines to 0s so changes can be detected by 1401 when sent out
% during experiment
putvalue(do_lines, [0 0 0 0 0 0 0 0]);


%% define square of camera image to be analysed in real-time:
% minimizing processing to just area of eye and close - reduces memory 
% load + makes frame-to-frame differences more pronounced 

img = (snapshot(src)-dark)*1.5;
imshow(img);

% getrect allows manual drawing of rectangle around eye
rect = getrect; 
close

% take x/y coordinates of rectangle to use in later snapshots
xmin = ceil(rect(1));
xmax = ceil(rect(1) + rect(3));
ymin = ceil(rect(2));
ymax = ceil(rect(2) + rect(4));

vector1 = (xmax - xmin)+1;
vector2 = (ymax - ymin)+1;
vector3 = vector1*vector2;

%% input from 1401 = 1; no input = 0
% Wait for input from 1401 to signal beginning of instrumental protocol

while (sum(getvalue(dio_device))) == 55
end

% number of frames to collect during baseline period
collect_frames = 33;
% the number of *s.d. over mean to set a threshold for img change to 
% signal a blink
thresh = 5;

% start loop for all trials (100 trials in instrumental protocol) 
for qqqq = 1:100
    
    % preallocate empty array to reduce memore load
    baseline = zeros(240,640,collect_frames);
    
    %wait for input from 1401 that signals 1s before next trial period -
    %pre-trial period to collect baseline
    while (sum(getvalue(dio_device))) == 55
    end

    for i = 1:collect_frames
        baseline(:,:,i) = (snapshot(src)-dark)*1.5;
    end
    
    % preallocate all arrays that are updated online, to minimize use of
    % mem
    V_diff = cell(collect_frames,1);
    V_diff_mean = zeros(1,collect_frames);
    
    % run through collected baseline images - delete all subsequent images
    % from first image, so each pixel of each frame is a reflection of
    % change from the first image. Take the mean/mean of the frame to
    % collapse whole 3-D array down to a single value representing change
    % from first images at each frame
    for n = 1:collect_frames
        V_diff{n,:} = baseline(ymin:ymax,xmin:xmax,n) - ...
            baseline(ymin:ymax,xmin:xmax,1);
        V_diff_mean(:,n) = mean(mean(V_diff{n}(:,:,1)));
    end
    
    % take mean of whole baseline period changes in image values and s.d. -
    % use this to calculate a threshold value of image difference that would
    % likely represent a eye-blink
    base_mean = mean(V_diff_mean(:,5:collect_frames));
    base_sd = std(V_diff_mean(:,5:collect_frames));
    base_thresh = base_mean + (base_sd)*thresh;

    % wait here for begining of trial - signalled as input from 1401 to
    % computer ~100ms before the trial begins
    sum(getvalue(dio_device))
    while (sum(getvalue(dio_device))) == 55
    end
    
    trial_collect = [];
    pause(0.1)
    
    % initialise image counter - each time an image snapshop is taken and
    % assessed the image will be added as the :,:,nth value to array (trial_collect)
    x = 1;
    
    % now collect 55 frames (speed of loop = 55 frames collected ~800ms)  
    % whilst collecting frames script checks frame for change in image that
    % would indicate the participant has made a blink - if blink detected 
    % send output to 1401, if blink is detected before delivery of blink 
    % this will stop delivery of airpuff 
    
    for x = 1:55
        clear realt_mean diff_realt
        trial_collect(:,:,x) = (snapshot(src)-dark)*1.5;
        % calculate difference between current image and baseline, collapse
        % difference to a single value and compare it to threshold value. 
        % Iterate x-image counter
        diff_realt = trial_collect(:,:,x) - baseline(:,:,1);
        realt_mean = mean(mean(diff_realt(ymin:ymax,xmin:xmax)));
        tester = realt_mean > base_thresh;
        % if current image value is not different from baseline images
        % jump to start of loop and collect next image. If current image
        % is significantly different from baseline images - 
        % send an output to 1401 to stop
        % delivery of airpuff then start loop again
        if tester == 0
            continue
        end
        putvalue(do_lines, [1 1 1 1 1 1 1 1]); 
        putvalue(do_lines, [0 0 0 0 0 0 0 0]);
        continue
    end
    
    % once trial is over and 1401 sends input to computer to exit while loop
    % save the trial image and baseline image arrays for later examination
    % and clear all variables to reduce likelihood of contamination/ disruption
    
    savename1 = strcat('trial_collect_', num2str(qqqq), '.mat');
    savename2 = strcat('trial_baseline_', num2str(qqqq), '.mat');
    save (savename1, 'trial_collect')
    save (savename2, 'baseline')
    
    clear realt* diff_realt base_thresh V_diff* x trial_collect

end

