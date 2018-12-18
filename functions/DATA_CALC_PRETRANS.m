function [Data_MP_Accel_Cal_Filt,Data_Gold_Accel_Cal_Filt] = DATA_CALC_PRETRANS(Data_MP,Data_Gold,Baseline_MP,Baseline_Gold,Filter)

%% Create Impact Index
    % This value is hard-coded because it can't be derived from the data.
    % Alternatively, this function could be refactored to provide the
    % samples/impact as an argument.
        IMP_samples_per_impact = 283;
        
    % Add a column with each record's impact number, and renumber the
    % indices so that each impact's indices count up from zero.
        Data_MP.Impact = floor(Data_MP.Index/IMP_samples_per_impact)+1;
        Data_MP.Index = mod(Data_MP.Index,IMP_samples_per_impact);

    % Drop the first record of each impact; don't need the
    % metadata for this example.
        Data_MP = Data_MP(Data_MP.Index>0, :);
    % Renumber the indices so they're 0-based
        Data_MP.Index = Data_MP.Index - 1;
        
%% Separate Accel and Gyro
    Data_MP_Accel = Data_MP(:,{'Impact','Index','AccelX','AccelY','AccelZ'});

%% Convert Accel and Gyro Timesteps
    % Accel
        % Constants - These values cannot be derived from the data table.
            % The sample rate of the accelerometer, in Hz.
                accelerometer_sample_rate = 4684;

            % The portion of the sample that precedes the point of impact.
                presample_proportion = 0.25;
                
        % Derived Values
            % The amount of time that passes between each accelerometer sample
                sampling_interval = 1 / accelerometer_sample_rate;

            % Since per-impact indices are zero-based, the number of samples
            % per impact is 1 + the largest index value.
                ACC_samples_per_impact = max(Data_MP_Accel.Index)+1;

            % The number of samples that precede the point of impact.
                presamples = ceil(ACC_samples_per_impact*presample_proportion);

            % Each sample is separated by sampling_interval seconds; just need to offset
            % each sample's index by the number that precede the impact to calculate
            % the offset in milliseconds.
                Accel_timestamps = ((Data_MP_Accel.Index-presamples)*sampling_interval)*1000;
                
        Data_MP_Accel.Timestamp = Accel_timestamps;
                   
%% Convert Accel to g
    if length(fieldnames(Baseline_MP)) == 6
        % Use slope and offset to create calibrated values
            Accel_MP_X_Cal = (Data_MP_Accel.AccelX-Baseline_MP.X_Offset)./(Baseline_MP.X_Slope);
            Accel_MP_Y_Cal = (Data_MP_Accel.AccelY-Baseline_MP.Y_Offset)./(Baseline_MP.Y_Slope);
            Accel_MP_Z_Cal = (Data_MP_Accel.AccelZ-Baseline_MP.Z_Offset)./(Baseline_MP.Z_Slope);
    else
            Accel_MP_X_Cal = (Data_MP_Accel.AccelX-Baseline_MP.X_zero)./((Baseline_MP.X_pos_one-Baseline_MP.X_neg_one)/2);
            Accel_MP_Y_Cal = (Data_MP_Accel.AccelY-Baseline_MP.Y_zero)./((Baseline_MP.Y_pos_one-Baseline_MP.Y_neg_one)/2);
            Accel_MP_Z_Cal = (Data_MP_Accel.AccelZ-Baseline_MP.Z_zero)./((Baseline_MP.Z_pos_one-Baseline_MP.Z_neg_one)/2);
    end
        
    % Create new table
        Accel_MP_cal = [Data_MP_Accel.Impact, Data_MP_Accel.Index, Accel_MP_X_Cal, Accel_MP_Y_Cal, Accel_MP_Z_Cal, Data_MP_Accel.Timestamp]; 
    % Restructure to same shape as original table with same column names
        Data_MP_Accel_Cal = array2table(Accel_MP_cal, 'VariableNames', {'Impact' 'Index' 'AccelX' 'AccelY' 'AccelZ' 'Timestamp'});

%% Filter Accel
    %%mp_filter filters DATA columns using a fourth-order butterworth lowpass filter
    %%with the desired cutoff frequency (fc) and sampling rate (fs) if those are given

    % Accel
    if isempty(Filter.fc_accel) == 1
        Accel_MP_X_Cal_Filt = Data_MP_Accel_Cal.AccelX;
        Accel_MP_Y_Cal_Filt = Data_MP_Accel_Cal.AccelY;
        Accel_MP_Z_Cal_Filt = Data_MP_Accel_Cal.AccelZ;
    else
        w_accel = Filter.fc_accel/(Filter.fs_accel/2);
        [b_accel,a_accel] = butter(4,w_accel);
            Accel_MP_X_Cal_Filt = filtfilt(b_accel,a_accel,Data_MP_Accel_Cal.AccelX);
            Accel_MP_Y_Cal_Filt = filtfilt(b_accel,a_accel,Data_MP_Accel_Cal.AccelY);
            Accel_MP_Z_Cal_Filt = filtfilt(b_accel,a_accel,Data_MP_Accel_Cal.AccelZ);
    end
            
        % Create new table
            Accel_MP_cal_filt = [Data_MP_Accel_Cal.Impact, Data_MP_Accel_Cal.Index, Accel_MP_X_Cal_Filt, Accel_MP_Y_Cal_Filt, Accel_MP_Z_Cal_Filt, Data_MP_Accel_Cal.Timestamp]; 
        
        % Restructure to same shape as original table with same column names
            Data_MP_Accel_Cal_Filt = array2table(Accel_MP_cal_filt, 'VariableNames', {'Impact' 'Index' 'AccelX' 'AccelY' 'AccelZ' 'Timestamp'});
            
%% Gold Standard
%% Create Impact Index
    % This value is hard-coded because it can't be derived from the data.
    % Alternatively, this function could be refactored to provide the
    % samples/impact as an argument.
        IMP_samples_per_impact = 283;
        
    % Add a column with each record's impact number, and renumber the
    % indices so that each impact's indices count up from zero.
        Data_Gold.Impact = floor(Data_Gold.Index/IMP_samples_per_impact)+1;
        Data_Gold.Index = mod(Data_Gold.Index,IMP_samples_per_impact);

    % Drop the first record of each impact; don't need the
    % metadata for this example.
        Data_Gold = Data_Gold(Data_Gold.Index>0, :);
    % Renumber the indices so they're 0-based
        Data_Gold.Index = Data_Gold.Index - 1;
        
%% Separate Accel and Gyro
    Data_Gold_Accel = Data_Gold(:,{'Impact','Index','AccelX','AccelY','AccelZ'});

%% Convert Accel and Gyro Timesteps
    % Accel
        % Constants - These values cannot be derived from the data table.
            % The sample rate of the accelerometer, in Hz.
                accelerometer_sample_rate = 4684;

            % The portion of the sample that precedes the point of impact.
                presample_proportion = 0.25;
                
        % Derived Values
            % The amount of time that passes between each accelerometer sample
                sampling_interval = 1 / accelerometer_sample_rate;

            % Since per-impact indices are zero-based, the number of samples
            % per impact is 1 + the largest index value.
                ACC_samples_per_impact = max(Data_Gold_Accel.Index)+1;

            % The number of samples that precede the point of impact.
                presamples = ceil(ACC_samples_per_impact*presample_proportion);

            % Each sample is separated by sampling_interval seconds; just need to offset
            % each sample's index by the number that precede the impact to calculate
            % the offset in milliseconds.
                Accel_timestamps = ((Data_Gold_Accel.Index-presamples)*sampling_interval)*1000;
                
        Data_Gold_Accel.Timestamp = Accel_timestamps;
                   
%% Convert Accel to g
    if length(fieldnames(Baseline_Gold)) == 6
        % Use slope and offset to create calibrated values
            Accel_Gold_X_Cal = (Data_Gold_Accel.AccelX-Baseline_Gold.X_Offset)./(Baseline_Gold.X_Slope);
            Accel_Gold_Y_Cal = (Data_Gold_Accel.AccelY-Baseline_Gold.Y_Offset)./(Baseline_Gold.Y_Slope);
            Accel_Gold_Z_Cal = (Data_Gold_Accel.AccelZ-Baseline_Gold.Z_Offset)./(Baseline_Gold.Z_Slope);
    else
            Accel_Gold_X_Cal = (Data_Gold_Accel.AccelX-Baseline_Gold.X_zero)./((Baseline_Gold.X_pos_one-Baseline_Gold.X_neg_one)/2);
            Accel_Gold_Y_Cal = (Data_Gold_Accel.AccelY-Baseline_Gold.Y_zero)./((Baseline_Gold.Y_pos_one-Baseline_Gold.Y_neg_one)/2);
            Accel_Gold_Z_Cal = (Data_Gold_Accel.AccelZ-Baseline_Gold.Z_zero)./((Baseline_Gold.Z_pos_one-Baseline_Gold.Z_neg_one)/2);
    end
        
    % Create new table
        Accel_Gold_cal = [Data_Gold_Accel.Impact, Data_Gold_Accel.Index, Accel_Gold_X_Cal, Accel_Gold_Y_Cal, Accel_Gold_Z_Cal, Data_Gold_Accel.Timestamp]; 
    % Restructure to same shape as original table with same column names
        Data_Gold_Accel_Cal = array2table(Accel_Gold_cal, 'VariableNames', {'Impact' 'Index' 'AccelX' 'AccelY' 'AccelZ' 'Timestamp'});

%% Filter Accel
    %%mp_filter filters DATA columns using a fourth-order butterworth lowpass filter
    %%with the desired cutoff frequency (fc) and sampling rate (fs) if those are given

    % Accel
    if isempty(Filter.fc_accel) == 1
        Accel_Gold_X_Cal_Filt = Data_Gold_Accel_Cal.AccelX;
        Accel_Gold_Y_Cal_Filt = Data_Gold_Accel_Cal.AccelY;
        Accel_Gold_Z_Cal_Filt = Data_Gold_Accel_Cal.AccelZ;
    else
        w_accel = Filter.fc_accel/(Filter.fs_accel/2);
        [b_accel,a_accel] = butter(4,w_accel);
            Accel_Gold_X_Cal_Filt = filtfilt(b_accel,a_accel,Data_Gold_Accel_Cal.AccelX);
            Accel_Gold_Y_Cal_Filt = filtfilt(b_accel,a_accel,Data_Gold_Accel_Cal.AccelY);
            Accel_Gold_Z_Cal_Filt = filtfilt(b_accel,a_accel,Data_Gold_Accel_Cal.AccelZ);
    end
            
        % Create new table
            Accel_Gold_cal_filt = [Data_Gold_Accel_Cal.Impact, Data_Gold_Accel_Cal.Index, Accel_Gold_X_Cal_Filt, Accel_Gold_Y_Cal_Filt, Accel_Gold_Z_Cal_Filt, Data_Gold_Accel_Cal.Timestamp]; 
        
        % Restructure to same shape as original table with same column names
            Data_Gold_Accel_Cal_Filt = array2table(Accel_Gold_cal_filt, 'VariableNames', {'Impact' 'Index' 'AccelX' 'AccelY' 'AccelZ' 'Timestamp'});
            
end 
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            