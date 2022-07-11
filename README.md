# Eyeblink_data_collection_and_analysis
Scripts written in most recent position to collect human blink data during fMRI experiments, transform video recordings of blinks to timeseries data for analysis and analyse timeseries data to identify participant conditioned blink occurence, timing etc 

Two types of experiment:

Classical conditioning of eyeblink conditition - participants were presented with conditional stim. (CS) - tone of 800ms, and unconditional stim. (US) - airpuff to cheek of 100ms. US co-occurs at last 100ms of CS. Consistent pairing of CS and US leads participants to give a conditioned response (CR) - a well-timed blink that begins before the onset of the US and peaks at the delivery of the US. 

In addition to normal conditioning trial ^ other trial types are same tone (CS+ tone) with no airpuff delivery and different tone/ no airpuff (CS-) 

Instrumental conditioning - after classical conditioning participants were then given an instrumental training protocol. Presented with similar but different tone stimuli to CS+ (CSi+) paired with airpuff (600Hz sinewave tone vs 750Hz sinewave tone). If participant blinks at correct time (during window of tone presentation) can prevent the delivery of airpuff.

Blink data for both experiment types collected with high-speed, fMRI compatible camera fixed on participants left eye.

Classical conditioning data was collected and saved during experiment - then videos were transformed and analysed post-hoc:
  scripts used on classical conditioning data: 'classical_eyeblink_raw2timeseries.m' & 'Stripped_EBC_CR_Analysis.m'

Instrumental conditioning data was accessed during experiment to control experiment (detect if participant gave CR at correct time and stop/ allow airpuff deliver):
  script used to access camera data to control instrumental conditioning experiments in real-time: 'real_time_eyeblink_detection.m'
  script used to transform captured camera data to check post-hoc that detections/ non-detections of CRs in real-time was accurate: 'instrumental_eyeblink_raw2timeseries.m'
