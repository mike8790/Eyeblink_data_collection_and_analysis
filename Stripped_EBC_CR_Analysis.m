% load a structure containing arrays of timeseries data, 1 for each trial, 
% representing participant eye-lid position over the trial -measured using 
% high-speed camera

clc; clear; close % clear workspace and close figures

% Go to directory containing blink timeseries structure 
cd('') 

% load .mat holding blink timecourses & .mat file containing 
% trial order (5 trial types, T1 = CS+ paired classical, T2 =
% CS+ unpaired classical, T3 = CS-, T4 = CS+ instrumental (probe trial), 
% T5 = CS+ instrumental
load('*alls.mat')
load('*timing.mat')

% extract trial codes to be used as index to sort timeseries from
% structure on basis of trial type
idx = DigMark.codes(:,1);
% remove probe trials at end of session that are not recorded
idx = idx([1:175,177:194,196:213,215:232,234:251,253:end]); 

% Generate new structure organised by trial type
s.T1 = s_new(idx == 1);
s.T2 = s_new(idx == 2);
T3 = s_new(idx == 3);
T45 = s_new(idx == 4);
% Instrumental task (second half of experiment) responses measured 
% differently so T5 blink responses and 2nd half of T3 not required for this script
s.T3 = T3(1:20);
s.T4 = T45(1:15);

s = struct2cell(s);

trial_list = {'T1', 'T2', 'T3', 'T4'};

% clear unnecessary variables
clear file DigMark T45* T3 n s_new idx
    
% set threshold value to register a blink response,
% (number of SDs above pre-stimulus mean)
mag = 5;
mag2 = 2;

% frequency frames were colected (Hz)
fs = 518;

% Next section: defines the entire trial period for analysis - 
% 500ms pre-trial for the baseline, 700 ms presntation of tone, 
% 100 ms presentation of airpuff plus time for eyelid to return to 
% baseline (~1.7 seconds post-trial).
% collected at 518Hz: baseline period (500ms) = 259 frames;
% alpha period (500ms to 750ms) = 260 - 388 frames;
% ISI period (750ms - 1200ms) = 389 - 622 frames; 
% US period (12 -1300ms) = 623 - 673 frames; 
% Post-trial period (1300ms - end)

% Outer loop for number of trial types to be analysed
for n = 1:length(trial_list)
    trial_type = s{n,1};
    
    for i = 1:length(trial_type)
    % Apply lowpass filter to data, eyelid blink occurs at low-frequency 
    % (~75 and below). High power, high-freq. noise introduced by scanner 
    % vibrations so to avoid effect on blink threshold detection filter out
    % higher freq. components of signal.
        CS_trial{i,:} = lowpass(trial_type(i).a,50,fs);
        % calculate mean and SD during baseline period, calculate threshold
        % lid-movement to register blink
        CS_data_baseline = mean(CS_trial{i,1}(1:259));
        CS_data_std = std(CS_trial{i,1}(1:259)); 
        threshold(i,:) = CS_data_baseline + (CS_data_std*mag); 
        
        % specify period where blink is searched for (exclude baseline,
        % alpha period) - 450ms period during CS presentation but before US
        % presentation
        ISI_period{i,:} = CS_trial{i,1}(389:622);
        
        % if loop to check if participant has eye-closed at onset of
        % response period (from excessive blinking/ still has eyes closed
        % after alpha-response) - if so, adjust start time of response
        % period to when eye-lid is back towards baseline.
        if ISI_period{i,:}(1) > threshold(i,:)
            data_return(i,:) = ISI_period{i,:}(1) - (CS_data_std*mag2);
            try 
                starter(i,:) = find(ISI_period{i,:}(1:234) < data_return(i,:),1);
                ISI_period_2(i,:) = 389 + starter(i,1);
                ISI_period{i,:} = CS_trial{i,1}(ISI_period_2(i,1):622);
            catch
                warning('Eye-movement above baseline before ISI period onset, and does not return to baseline before US. Trial assigned NaN');
                ISI_period{i,:} = NaN;
            end
        else
            ISI_period_2(i,:) = 389;
        end
        
        % Specify trial period to present on figure
        trial_period{i,:} = CS_trial{i,1}(1:900);
    end
    
    % initialize empty array to store consditioned blink onset times trialx
    % trial
    blink_onsets = zeros(length(CS_trial),1);
    
    for i = 1:length(CS_trial)
        period_double = double(ISI_period{i,1});
        try
            blink_onsets(i,:) = find(period_double > threshold(i,:),1);
        catch
            warning('Blink not found in ISI period. Assigning NaN.');         
            blink_onsets(i,:) = NaN;
        end
    end
    % calculate time in whole trial where blink is registered, for mapping
    % on figure
    blink_times = blink_onsets + ISI_period_2;
    
    % create array of 1/0 for blink registered/ no blink
    for ii = 1:length(blink_onsets)
        blink_idx(ii,:) = ~isnan(blink_onsets(ii,:));
    end 
    
    % convert 1/0 array to cell array and save in to array for saving later
    % when all trials are calculated
    blink_idx = num2cell(blink_idx);
    classification_blinks{n,:} = blink_idx;
    
    
    % plot each timeseries on figure with important time stamps (i.e. CS
    % onset, US onset, conditioned-blink onset (if applicable), response
    % threshold). Manually check if blink classification is correct. Can
    % manually change if necessary.
    
    x = 1;
    for i = 1:length(CS_trial)

        figure(98)
        trial_period_double = double(trial_period{i,1});
        plot(trial_period_double,'r')
        ylim([0 40])
        xlim([0 900])

        US_on = 623;
        line([US_on,US_on],[0,40],'linestyle','-.');
        text(US_on +6,35,'US');
        US_off = 673;
        line([US_off,US_off],[0,40],'linestyle','-.');
        CS_on = 260;
        line([CS_on,CS_on],[0,40],'linestyle','-.');
        text(CS_on+175,35,'CS');
        title(["T1 trial " + x]);
        alpa = 388;
        line([alpa,alpa],[0,40],'linestyle','-.');
        thresho = threshold(i,:);
        yline(thresho,'linestyle','-.');
        title([trial_list{n} + " trial " + x]);

        % plot onset
        text(blink_times(i,:)+50,35,'R','color','r');
        line([blink_times(i,:),blink_times(i,:)],[0,40],'color','red','linestyle','--');
        
        pause
        x = x+1;
        
    end
    close
    
    clear CS* threshold ISI* data_r* starter trial* x blink*
    clear thresho alpa US_*
    
end

% save blink classifications for all trial types and clear workspace
save IEC_blinks classification_blinks
