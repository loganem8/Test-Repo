function [Time_Date_Full,Data_Accel,Data_Gyro,Data_Accel_Cal,Data_Gyro_Cal,Data_Accel_Cal_Filt_Zero,Data_Gyro_Cal_Filt_Zero,Linear_Resultant,Rotational_Resultant,Impact_Totals] = DATA_CALC_15_RATE_FILT(Data,Baseline_Accel,Baseline_Gyro,Filter,Impact_Totals)

%% Setting default values 
% This is only because these variables must return a value even if the
% filtering/zero steps are commented out.
Data_Accel_Cal_Filt_Zero = 0;
Data_Gyro_Cal_Filt_Zero = 0;
Linear_Resultant = 0;
Rotational_Resultant = 0;

%% Create Impact Index
    % This value is hard-coded because it can't be derived from the data.
    % Alternatively, this function could be refactored to provide the
    % samples/impact as an argument.
        IMP_samples_per_impact = 283;
        
    % Add a column with each record's impact number, and renumber the
    % indices so that each impact's indices count up from zero.
        Data.Impact = floor(Data.Index/IMP_samples_per_impact)+1;
        Data.Index = mod(Data.Index,IMP_samples_per_impact);

    % Separate Date timestamps.
        Data_Date = Data(Data.Index<1,:);
            Date_Time = Data_Date.Timestamp;

    % Drop the first record of each impact; don't need the
    % metadata for this example.
        Data = Data(Data.Index>0, :);
    % Renumber the indices so they're 0-based
        Data.Index = Data.Index - 1;
        
%% Separate Accel and Gyro
    Data_Accel = Data(:,{'Impact','Index','AccelX','AccelY','AccelZ'});
    Data_Gyro = Data(:,{'Impact','Index','GyroX','GyroY','GyroZ','Timestamp'});
    Events = max(Data_Accel.Impact);

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
                ACC_samples_per_impact = max(Data_Accel.Index)+1;

            % The number of samples that precede the point of impact.
                presamples = ceil(ACC_samples_per_impact*presample_proportion);

            % Each sample is separated by sampling_interval seconds; just need to offset
            % each sample's index by the number that precede the impact to calculate
            % the offset in milliseconds.
                Accel_timestamps = ((Data_Accel.Index-presamples)*sampling_interval)*1000;
                
        Data_Accel.Timestamp = Accel_timestamps;
        
    % Gyro
        % The number of clock ticks per second on the CC2640.
            ticks_per_second = 65536;
                    
        % The records in the original data table are in chronological order for
        % the accelerometer samples. The Timestamp column corresponds to the
        % timing of the gyroscope sample on each row. The Timestamp values are
        % the number of ticks before or after the point of impact that the sample
        % was recorded. So to put the gyroscope data in chronological order, we
        % just reorder the table by timestamp, taking care to first sort by impact
        % to keep the samples of each impact independent.
            Data_Gyro = sortrows(Data_Gyro, {'Impact', 'Timestamp'});

        % Then, just convert the number of ticks before/after the sample to the
        % number of milliseconds before/after the sample.
            Data_Gyro.Timestamp = (Data_Gyro.Timestamp*1000/ticks_per_second);

%% Gyro Interpolation
%     % Gyro data is on a time scale of -45:45 ms while Accelerometer is on
%     % -15:45. Interpolation of gyro time to match accel time will mean that
%     % a single timestamp column (-15:45) can be used for all data
%     Gyro_Data = [Data_Gyro.GyroX, Data_Gyro.GyroY, Data_Gyro.GyroZ];
%     for q = 1:Events
%         Gyro_Time = Data_Gyro.Timestamp((q*282-281):(q*282));
%         Accel_Time = Data_Accel.Timestamp((q*282-281):(q*282));
%         if length(unique(Gyro_Time)) == length(unique(Accel_Time))
%             break
%         end
%     end
% 
%     Gyro_Data_Int = zeros(size(Gyro_Data)); 
% 
%         for d = 1:3
%             for Separate = 1:Events
%                 Gyro_sep = Gyro_Data((Separate*282-281):(Separate*282),d);
%                     Interpolation = interp1(Gyro_Time,Gyro_sep,Accel_Time);
%                 Gyro_Data_Int((Separate*282-281):(Separate*282),d) = Interpolation;
%             end
%         end
%         
%     % Create new table
%         Data_Gyro_pre = [Data_Gyro.Impact, Data_Gyro.Index, Gyro_Data_Int(:,1), Gyro_Data_Int(:,2), Gyro_Data_Int(:,3), Data_Accel.Timestamp]; 
%         
%     % Restructure to same shape as original table with same column names
%         Data_Gyro = array2table(Data_Gyro_pre, 'VariableNames', {'Impact' 'Index' 'GyroX' 'GyroY' 'GyroZ' 'Timestamp'});
            
%% Convert Accel to g
    if isempty(Baseline_Gyro) == 0
        % Use slope and offset to create calibrated values
            Accel_X_Cal = (Data_Accel.AccelX-Baseline_Accel.X_Offset)./(Baseline_Accel.X_Slope);
            Accel_Y_Cal = (Data_Accel.AccelY-Baseline_Accel.Y_Offset)./(Baseline_Accel.Y_Slope);
            Accel_Z_Cal = (Data_Accel.AccelZ-Baseline_Accel.Z_Offset)./(Baseline_Accel.Z_Slope);
    else
            Accel_X_Cal = (Data_Accel.AccelX-Baseline_Accel.X_zero)./((Baseline_Accel.X_pos_one-Baseline_Accel.X_neg_one)/2);
            Accel_Y_Cal = (Data_Accel.AccelY-Baseline_Accel.Y_zero)./((Baseline_Accel.Y_pos_one-Baseline_Accel.Y_neg_one)/2);
            Accel_Z_Cal = (Data_Accel.AccelZ-Baseline_Accel.Z_zero)./((Baseline_Accel.Z_pos_one-Baseline_Accel.Z_neg_one)/2);
    end
        
    % Create new table
        Accel_cal = [Data_Accel.Impact, Data_Accel.Index, Accel_X_Cal, Accel_Y_Cal, Accel_Z_Cal, Data_Accel.Timestamp]; 
    % Restructure to same shape as original table with same column names
        Data_Accel_Cal = array2table(Accel_cal, 'VariableNames', {'Impact' 'Index' 'AccelX' 'AccelY' 'AccelZ' 'Timestamp'});

%% Convert Gyro to dps
    if isempty(Baseline_Gyro) == 0
        % Use slope and offset to create calibrated values
            Gyro_X_Cal = (Data_Gyro.GyroX-Baseline_Gyro.X_Offset)./(Baseline_Gyro.X_Slope);
            Gyro_Y_Cal = (Data_Gyro.GyroY-Baseline_Gyro.Y_Offset)./(Baseline_Gyro.Y_Slope);
            Gyro_Z_Cal = (Data_Gyro.GyroZ-Baseline_Gyro.Z_Offset)./(Baseline_Gyro.Z_Slope);
    else
            Gyro_X_Cal = Data_Gyro.GyroX.*0.07;
            Gyro_Y_Cal = Data_Gyro.GyroY.*0.07;
            Gyro_Z_Cal = Data_Gyro.GyroZ.*0.07;
    end
        
    % Create new table
        Gyro_cal = [Data_Gyro.Impact, Data_Gyro.Index, Gyro_X_Cal, Gyro_Y_Cal, Gyro_Z_Cal, Data_Gyro.Timestamp]; 
    % Restructure to same shape as original table with same column names
        Data_Gyro_Cal = array2table(Gyro_cal, 'VariableNames', {'Impact' 'Index' 'GyroX' 'GyroY' 'GyroZ' 'Timestamp'});

%% Filter Accel and Gyro
    %%mp_filter filters DATA columns using a fourth-order butterworth lowpass filter
    %%with the desired cutoff frequency (fc) and sampling rate (fs) if those are given

    % Accel
%     if isempty(Filter.fc_accel) == 1
%         Accel_X_Cal_Filt = Data_Accel_Cal.AccelX;
%         Accel_Y_Cal_Filt = Data_Accel_Cal.AccelY;
%         Accel_Z_Cal_Filt = Data_Accel_Cal.AccelZ;
%     else
%         w_accel = Filter.fc_accel/(Filter.fs_accel/2);
%         [b_accel,a_accel] = butter(4,w_accel);
%             Accel_X_Cal_Filt = filtfilt(b_accel,a_accel,Data_Accel_Cal.AccelX);
%             Accel_Y_Cal_Filt = filtfilt(b_accel,a_accel,Data_Accel_Cal.AccelY);
%             Accel_Z_Cal_Filt = filtfilt(b_accel,a_accel,Data_Accel_Cal.AccelZ);
%     end
%             
%         % Create new table
%             Accel_cal_filt = [Data_Accel_Cal.Impact, Data_Accel_Cal.Index, Accel_X_Cal_Filt, Accel_Y_Cal_Filt, Accel_Z_Cal_Filt, Data_Accel_Cal.Timestamp]; 
%         
%         % Restructure to same shape as original table with same column names
%             Data_Accel_Cal_Filt = array2table(Accel_cal_filt, 'VariableNames', {'Impact' 'Index' 'AccelX' 'AccelY' 'AccelZ' 'Timestamp'});
%             
%     % Gyro
%     if isempty(Filter.fc_gyro) == 1
%         Gyro_X_Cal_Filt = Data_Gyro_Cal.GyroX;
%         Gyro_Y_Cal_Filt = Data_Gyro_Cal.GyroY;
%         Gyro_Z_Cal_Filt = Data_Gyro_Cal.GyroZ;
%     else
%         w_gyro = Filter.fc_gyro/(Filter.fs_gyro/2);
%         [b_gyro,a_gyro] = butter(4,w_gyro);
%             Gyro_X_Cal_Filt = filtfilt(b_gyro,a_gyro,Data_Gyro_Cal.GyroX);
%             Gyro_Y_Cal_Filt = filtfilt(b_gyro,a_gyro,Data_Gyro_Cal.GyroY);
%             Gyro_Z_Cal_Filt = filtfilt(b_gyro,a_gyro,Data_Gyro_Cal.GyroZ);
%     end
%         % Create new table
%             Gyro_cal_filt = [Data_Gyro_Cal.Impact, Data_Gyro_Cal.Index, Gyro_X_Cal_Filt, Gyro_Y_Cal_Filt, Gyro_Z_Cal_Filt, Data_Gyro_Cal.Timestamp]; 
%         
%         % Restructure to same shape as original table with same column names
%             Data_Gyro_Cal_Filt = array2table(Gyro_cal_filt, 'VariableNames', {'Impact' 'Index' 'GyroX' 'GyroY' 'GyroZ' 'Timestamp'});

%% Zero Accel and Gyro
%     % Zeroes each event based on the first impact of the duration (each
%     % event will start at 0)
%     for zero = 1:Events
%             AccelX_zero = Data_Accel_Cal_Filt.AccelX((zero*282-281),1);
%             AccelY_zero = Data_Accel_Cal_Filt.AccelY((zero*282-281),1);
%             AccelZ_zero = Data_Accel_Cal_Filt.AccelZ((zero*282-281),1);
%            
%                 Accel_X_Cal_Filt_Zero((zero*282-281):(zero*282),1) = Data_Accel_Cal_Filt.AccelX((zero*282-281):(zero*282),1)-AccelX_zero; % Zeroes the circuit impacts
%                 Accel_Y_Cal_Filt_Zero((zero*282-281):(zero*282),1) = Data_Accel_Cal_Filt.AccelY((zero*282-281):(zero*282),1)-AccelY_zero; % Zeroes the circuit impacts
%                 Accel_Z_Cal_Filt_Zero((zero*282-281):(zero*282),1) = Data_Accel_Cal_Filt.AccelZ((zero*282-281):(zero*282),1)-AccelZ_zero; % Zeroes the circuit impacts
%            
%            GyroX_zero = Data_Gyro_Cal_Filt.GyroX((zero*282-281),1);
%            GyroY_zero = Data_Gyro_Cal_Filt.GyroY((zero*282-281),1);
%            GyroZ_zero = Data_Gyro_Cal_Filt.GyroZ((zero*282-281),1);
%            
%                 Gyro_X_Cal_Filt_Zero((zero*282-281):(zero*282),1) = Data_Gyro_Cal_Filt.GyroX((zero*282-281):(zero*282),1)-GyroX_zero; % Zeroes the circuit impacts
%                 Gyro_Y_Cal_Filt_Zero((zero*282-281):(zero*282),1) = Data_Gyro_Cal_Filt.GyroY((zero*282-281):(zero*282),1)-GyroY_zero; % Zeroes the circuit impacts
%                 Gyro_Z_Cal_Filt_Zero((zero*282-281):(zero*282),1) = Data_Gyro_Cal_Filt.GyroZ((zero*282-281):(zero*282),1)-GyroZ_zero; % Zeroes the circuit impacts
%     end
%     
%     % Create new table
%         Accel_cal_filt_zero = [Data_Accel_Cal_Filt.Impact, Data_Accel_Cal_Filt.Index, Accel_X_Cal_Filt_Zero, Accel_Y_Cal_Filt_Zero, Accel_Z_Cal_Filt_Zero, Data_Accel_Cal_Filt.Timestamp]; 
%         Gyro_cal_filt_zero = [Data_Gyro_Cal_Filt.Impact, Data_Gyro_Cal_Filt.Index, Gyro_X_Cal_Filt_Zero, Gyro_Y_Cal_Filt_Zero, Gyro_Z_Cal_Filt_Zero, Data_Gyro_Cal_Filt.Timestamp]; 
%         
%     % Restructure to same shape as original table with same column names
%         Data_Accel_Cal_Filt_Zero = array2table(Accel_cal_filt_zero, 'VariableNames', {'Impact' 'Index' 'AccelX' 'AccelY' 'AccelZ' 'Timestamp'});
%         Data_Gyro_Cal_Filt_Zero = array2table(Gyro_cal_filt_zero, 'VariableNames', {'Impact' 'Index' 'GyroX' 'GyroY' 'GyroZ' 'Timestamp'});
% 
%     % If you do not want to zero the data, comment the above section and
%     % uncomment the 2 lines below
% %         Data_Accel_Cal_Filt_Zero = Data_Accel_Cal_Filt;
% %         Data_Gyro_Cal_Filt_Zero = Data_Gyro_Cal_Filt;
        
%% Remove Junk
    % If the device dies without reaching the requested # of impacts, junk
    % data will fil in the missing values. The accelerations of these junk
    % events are never above 1 after being zeroed.
%     for peak = 1:Events          
%         Accel_X_Peak(peak,1) = max(abs(Data_Accel_Cal_Filt_Zero.AccelX((peak*282-281):(peak*282),1)));
%         Accel_Y_Peak(peak,1) = max(abs(Data_Accel_Cal_Filt_Zero.AccelY((peak*282-281):(peak*282),1)));
%         Accel_Z_Peak(peak,1) = max(abs(Data_Accel_Cal_Filt_Zero.AccelZ((peak*282-281):(peak*282),1)));
%     end    
% 
% Delete_Impact = [];
%     Max_Counter = 1;
%         for Max_Events = 1:Events-2
%             if ( (Accel_X_Peak(Max_Events,1)<2 && Accel_Y_Peak(Max_Events,1) < 2 && Accel_Z_Peak(Max_Events,1)<2) && (Accel_X_Peak(Max_Events+1,1)<2 && Accel_Y_Peak(Max_Events+1,1) < 2 && Accel_Z_Peak(Max_Events+1,1)<2) && (Accel_X_Peak(Max_Events+2,1)<2 && Accel_Y_Peak(Max_Events+2,1) < 2 && Accel_Z_Peak(Max_Events+2,1)<2) )
%                 Delete_Impact(Max_Counter,1) = Max_Events;
%                 Max_Counter = Max_Counter+1;
%             end
%         end
%         
%         Delete_Impact(Max_Counter, 1) = Events-1;
%         Delete_Impact(Max_Counter+1, 1) = Events;
% 
% if isempty(Delete_Impact) == 0
%     for Delete = 1:length(Delete_Impact)
%         Indices = find(Data_Accel_Cal.Impact == Delete_Impact(Delete,1));
%             Data_Accel_Cal(Indices,:) = [];
%             Data_Gyro_Cal(Indices,:) = [];
%     end
% 
%     Date_Time(Delete_Impact(:,1),:) = [];
% end
%% Time
    % Converts Epoch datetime to EST datetime
    time_reference = datenum('1970', 'yyyy'); 
    Time_Date_Temp = (time_reference+(Date_Time-14400)./8.64e4);
    Time_Date_Full = datestr(Time_Date_Temp, 'yyyymmdd HH:MM:SS.FFF');

%% Resultant 
%         % Resultant of linear and rotational values
%             Linear_Resultant = sqrt(Data_Accel_Cal_Filt_Zero.AccelX.^2+Data_Accel_Cal_Filt_Zero.AccelY.^2+Data_Accel_Cal_Filt_Zero.AccelZ.^2);
%             Rotational_Resultant = sqrt(Data_Gyro_Cal_Filt_Zero.GyroX.^2+Data_Gyro_Cal_Filt_Zero.GyroX.^2+Data_Gyro_Cal_Filt_Zero.GyroX.^2);

%% Note the number of events this MP had
%     Impact_unique = max(unique(Data_Accel_Cal_Filt_Zero.Impact));
%     Counter = length(Impact_Totals)+1;
%     Impact_Totals(Counter,1) = Impact_unique;

end 
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            
            