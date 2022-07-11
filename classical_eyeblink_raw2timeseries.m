%% script to loop through all the .avi files collected from camera during 
% classical conditioning trials, collapses each frame down to a single
% value - representing the difference in image values between that frame
% and the first frame. Collapses 4-D camera data to a 2-D timeseries to
% detect image changes (i.e. blinks) accross the trial period (use with 
% 'Stripped_EBC_CR_Analysis.m').

clc; clear; close;

% cd to participant directory with videos for analysis
cd '';

    % create an empty structure to save the timeseries for each of the
    % trials in to for future analysis.
    s = struct('a',{});
    % get a list of all the video files in the directory - last step is to
    % exclude any videos not needed i.e. first four are calibration videos
    % and not classical-conditioning trial videos in most instances, check 
    % lab book for each participant
    video_list = struct2cell(dir('*.avi')).';
    video_list = video_list(:,1);
    video_list = string(video_list);
    video_list = video_list(4:end,:);
    
    % set counter to keep track of which video is being analyses
    gg = 1;
   
    for iii = 1:length(video_list)

        % import video and convert to data structure to be used by script
        eyeblink_converted = importdata(video_list(iii));
        
        % display video name and number on counter - helps keep track of
        % how far the loop is through as slow process - ~25-30 minutes to
        % convert 140 3 second videos to time-series data
        disp(video_list(iii));
        disp(gg);
        
        timepoints = length(eyeblink_converted);
        %loop through each frame of the video and delete the pixel image 
        % values of the current frame from the first frame - to get a calculation
        %of the image value change frame-by-frame from timepoint 1.
        
        % can specify the x/ y values to compare - as the main thing
        % that changes in the video is the blink of the eye - by
        % focusing on section of frame that captures the eye and lid
        % you can a) minimise the processing time for each video and b)
        % accentuate differences between images. Because head is fixed
        % the box that captures the participants eye will not change
        % from video 1 to end
        for n = 1:timepoints
            V_diff{n} = eyeblink_converted(n).cdata(66:275,201:410,1) - eyeblink_converted(1).cdata(21:200,201:410,1);
        end
        
        % collapse difference to a single value - end up with a xy timeseries
        % with as many points in x as frames in videa and y representing
        % difference at each frame from beginning of video - use this to
        % detect occurence, onset and amplitude of blink. Remarkable
        % fidelity of eyeblink capture when simplified timeseries compared
        % to original video
        for ii = 1:timepoints
            V_diff_vector(:,ii) = reshape(V_diff{ii},1,37800);
            V_diff_mean(:,ii) = mean(mean(abs(V_diff_vector(:,ii))));
        end
        
        % save timeseries for video iii to structure s
        s(iii).a = V_diff_mean;
        % iterate counter and display current time (can be used to check
        % each video is being processed at similar speeds.
        gg = gg+1;
        disp(datetime('now'))
        clear V_diff*
    end

% once all videos have been analysed - save timeseries structure
save tester_alls_inst s


