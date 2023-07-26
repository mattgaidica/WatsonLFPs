## Validation Workflow
1. `run_compileTransitions.m` will make `TTransition.mat` which contains the sleepToWake ratio for each subject.
2. `run_compileSurrogates.m` will use sleepToWake ratio (threshold) and compile *n* surrogates for each subject into `TSurrogate.mat`.
3. `run_compareSurrogates.m` will apply the nestSenseAlg() to the motion data (as ODBA, zero'ing temperature) and compare actual vs. predicted states.


Using the surrogate method insures that each subject has equal representation. Eg, if you just combined all the motion data and did a state comparison without surrogates/randomizing the sample, it could be heavily biased for subjects with long recordings.