%% eyelid data captured during instrumnetal learning protocol (see 
% 'real_time_eyeblink_detection.m') is captured as a series of snapshots in
% two distinct phases: 33 snapshots before trial onset for baseline 
% eye- position calculatiosn and 50 snapshots during trial period for 
% detection of blink to control delivery of US/ airpuff. 
% Script loops through *baseline*.mat and trial_collect*.mat data, stitches 
% together to creat one continuous timeseries for each trial. Then, as with 
% 'classical_eyeblink_raw*.m script, collapses each snapshot down to a
% single value - representing the difference in image values between that snapshot
% and the first snapshot. Collapses 4-D array to a 2-D timeseries to
% detect image changes (i.e. blinks) accross the trial period.

clc; clear; close

% cd to participant directory with data for analysis
cd '';

    % create an empty structure to save the timeseries for each of the
    % trials in to for future analysis.
    s = struct('a',{});
    
    % get a sorted list of all baseline and trial files for each trial.
    baseline_list = struct2table(dir('trial_baseline*.mat'));
    trial_list = struct2table(dir('trial_collect*.mat'));
    sorted_baseline = sortrows(baseline_list, 'date');
    sorted_trial = sortrows(trial_list, 'date'); 
    sorted_baseline = struct2cell(table2struct(sorted_baseline)).';
    sorted_baseline = sorted_baseline(:,1);
    sorted_trial = struct2cell(table2struct(sorted_trial)).';
    sorted_trial = sorted_trial(:,1);
    
    % set counter to keep track of which trial is being analyses
    gg = 1;
    
    for iii = 1:length(sorted_trial)
        
        % concatenate baseline and trial snapshots for current trial 
        baseline_converted = load(sorted_baseline{iii,:});
        trial_converted = load(sorted_trial{iii,:});
        eyeblink_converted = cat(3, baseline_converted.baseline, ...
            trial_converted.trial_collect);
        
        disp(gg);
        disp(datetime('now'))
        
        timepoints = size(eyeblink_converted, 3);
        
        % calculate image change at each pixel from first snaphot for each 
        % subsequent snapshot
        for n = 1:timepoints
            V_diff{n} = eyeblink_converted(66:205,226:400,1) - ...
                eyeblink_converted(66:205,226:400,1);
        end
        
        % collapse image change values for each snapshot in to a single
        % value - creating a 2-D timeseries showing image value fluctuation
        % accross the trial- because of the nature of the fixed camera 
        % position, head-held position of participant and constant lighting
        % changes in image are driven by blinking of participant.
        for ii = 1:timepoints
            V_diff_vector(:,ii) = reshape(V_diff{ii},1,24500);
            V_diff_mean(:,ii) = mean(mean(abs(V_diff_vector(:,ii))));
        end
        
        % save timeseries for trial iii to structure s
        s(iii).a = V_diff_mean;
        % iterate counter and display current time 
        gg = gg+1;
        disp(datetime('now'))
        clear V_diff*
    end

% once all videos have been analysed - save timeseries structure
save *alls_inst s


