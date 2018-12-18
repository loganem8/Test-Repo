% This script is a combination of two already-existing scripts:
% raw2calibrated.m and vt_transform.m. The first section of this script
% (raw2calibrated) will take raw data from the mouthpiece and convert the
% data to the correct units. The second section (vt_transform) will apply
% the transformation matrix to the data at the MP CG and transform it to
% the head CG. By comibing the two scripts, the goal is to create a single
% "RUN ME" file that can process raw MP data.

%% Manual input for cutoff freqs and sample rates. Adding folders to path.
clc; clear; close all;

% define filtering characteristics
a_fc = 1650; % accel cutoff frequency (Hz)
a_cfc = 1000; % use w/ VT filtering function (SAE J211 4 pole butter LPF)
a_fs = 4684; % accel sample rate (Hz)
g_fc = 255; % gyro cutoff frequency (Hz) 
g_cfc = 155; % use w/ VT filtering function
g_fs = 4684; % gyro sample rate (Hz), halved when remove duplicates, 4684 when interpolate before filter 

% data location
data_loc = '\\medctr\dfs\cib$\shared\02_projects\mouthpiece_data_collection\00_MP_Transformation_MATLAB_Code\test_validation_data';

% master code location
master_code_location = '\\medctr\dfs\cib$\shared\02_projects\mouthpiece_data_collection\00_MP_Transformation_MATLAB_Code';

% add functions folder to the path
addpath(fullfile(master_code_location,'functions')); 

% THIS IS FOR ACCESSING THE AVERAGE TRANSFORMATION MATRIX FILE. CAN BE REMOVED IF
% USING SPECIFIC TRANSFORM MATRICES FOR EACH MOUTHPIECE.
addpath('\\medctr\dfs\cib$\shared\02_projects\2018_Soccer_Mouthguard\02_Subject_Specific_Transforms');

% folder containing raw data to be calibrated: 
rawFolder = fullfile(data_loc,'raw');
addpath(rawFolder);

% folder containing calibration output for devices
baselineFolder = fullfile(data_loc,'baselines');
addpath(baselineFolder);

% folder with time and date info
time_data_folder = fullfile(data_loc,'impact_times');
addpath(time_data_folder);

% calibrated data folder
calibratedFolder = fullfile(data_loc,'calibrated');
addpath(calibratedFolder);

%% Calibrate Raw Data

% This scipt combines the functions necessary to calibrate data from VT
% testing for device MP0066, and outputs in the file format desired for use with the
% transformation code. Raw data is stored in folders based on impact
% location.

% create new folder to store calibration output files
[u, ~] = fileparts(rawFolder);
calFolder = strcat(u, '\calibrated');
if ~(7==exist(calFolder, 'dir'))
    mkdir(calFolder);
end

% find all folders in raw data folder
rawFolders = dir(rawFolder);
% find all folders in baseline data folder
baselineFolders = dir(baselineFolder);

for k = 3:length(rawFolders) % start at 3 b/c first 2 folders created with dir contain metadata
    % for each mouthpiece folder in main raw data folder:
    currentFolder = strcat(rawFolders(k).folder, '\', rawFolders(k).name);
    % find all .csv files in folder
    filePattern = fullfile(currentFolder, '*.csv'); 
    theFiles = dir(filePattern);
    % create a folder for each impact location in the main calibration output
    % folder. It will have the same name as the current folder + calibrated
    [up_dir, low_dir] = fileparts(currentFolder);
    newFolder = strcat(low_dir, ' - Calibrated');
    saveFolder = fullfile(calFolder, newFolder);
    if ~(7==exist(strcat(calFolder, '\', newFolder), 'dir'))
        mkdir(calFolder, newFolder);
    end
    
    fprintf('Calibrating data for %s\n', low_dir)
    
    % find the corresponding baseline folder for the current mouthpiece
    if (contains(low_dir, 'BP'))
        MP_baseline_folder = strcat(baselineFolders(1).folder, '\MP0066 - Calibration Data');
    else
        for b = 3:length(baselineFolders) % start at 3
            currentBaselineFolder = strcat(baselineFolders(b).folder, '\', baselineFolders(b).name);
            if (strcmp(strcat(low_dir(1:2), '00', low_dir(3:end)), baselineFolders(b).name(1:6)) == 1)
                MP_baseline_folder = currentBaselineFolder;
            end
        end
    end
    
    % check if the mouthpiece requires the old or new calibration
    % calculation
    files_in_baseline = dir(MP_baseline_folder);
    flag_old_calc = 1;
    
    for f=3:length(files_in_baseline) % start at 3
        if (contains(files_in_baseline(f).name, "Baseline"))
            flag_old_calc = 1;
        end
    end
    
    if (flag_old_calc == 1)
        
        for j = 1:length(theFiles) % start at 1
            % for each file in each impact location folder:
            baseFileName = theFiles(j).name;
            [accel_cal, gyro_cal, time_and_date] = cal_baseline_data(currentFolder,baseFileName, baselineFolder, a_fs, a_fc, g_fs, g_fc);
            saveName = strcat(baseFileName(1:end-4), ' - Calibrated.csv');
            output_calibration_files(accel_cal, gyro_cal, saveFolder, saveName);
            output_impact_times(time_data_folder, currentFolder, baseFileName, time_and_date);
        end
        
    else
    
        for j = 1:length(theFiles) % start at 1
            % for each file in each impact location folder:
            baseFileName = theFiles(j).name;
            accel_cal = cal_accel_data(MP_baseline_folder, baseFileName);
            gyro_cal = cal_gyro_data(MP_baseline_folder, baseFileName);
            saveName = strcat(baseFileName(1:end-4), ' - Calibrated.csv');
            time_and_date = get_impact_time(baseFileName);
            output_calibration_files(accel_cal, gyro_cal, saveFolder, saveName);
            output_impact_times(time_data_folder, currentFolder, baseFileName, time_and_date);
        end
        
    end
end

%% Transform Calibrated Data

% transform WF data from VT tests and save into appropriate folders 
% with same naming convention and data format as VT data
% each impact will be saved into separate file

% create folder to store transformed data in
[u, l] = fileparts(calibratedFolder);
tFolder = strcat(u, '\transformed');
if ~(7==exist(tFolder, 'dir'))
    mkdir(tFolder);
end

calibratedFolders = dir(calibratedFolder); % find all folders in calibrated data folder

for k = 3:length(calibratedFolders) % start at 3 b/c first 2 folders created with dir contain metadata
    
    % get file containing transformation info (rotation matrix and position vector)
    testing = false;
    if (contains(calibratedFolders(k).name, 'BP'))
        mp_number = 66;
        testing = true;
%         transform_file = 'MP66_Transform.xlsx';
        test_name_temp = strsplit(calibratedFolders(k).name);
        test_name = test_name_temp{1};
        mp_time_folder = strcat(time_data_folder, '\', test_name);     
    else 
        mp_number = calibratedFolders(k).name(3:4);
%         transform_file = strcat('MP', mp_number, '_Transform.xlsx');
        mp_time_folder = strcat(time_data_folder, '\MP', mp_number);
        mp_number = str2double(mp_number);
    end

%     transform_file = 'transform_estimated_10-8-2018.xlsx'; % REMOVE THIS IF NOT USING THE AVERAGE TRANSFORMATION MATRIX
    transform_file = '\\medctr\dfs\cib$\shared\02_projects\mouthpiece_data_collection\00_MP_Transformation_MATLAB_Code\test_validation_data\MP66_Transform.xlsx';
    mp_time_files = dir(strcat(mp_time_folder, '\*.csv'));
    
    % for each impact location folder in main raw data folder:
    currentFolder = strcat(calibratedFolders(k).folder, '\', calibratedFolders(k).name);
    
    % find all .csv files in folder
    filePattern = fullfile(currentFolder, '*.csv');
    theFiles = dir(filePattern);
    [up_dir, low_dir] = fileparts(currentFolder);
    newFolder = strcat(low_dir, '_Transformed');
    saveFolder = fullfile(tFolder, newFolder);
    if ~(7==exist(strcat(tFolder, '\', newFolder), 'dir'))
        mkdir(tFolder, newFolder);
    end
 
    fprintf('Transforming data for %s\n', low_dir)
    
    for j = 1:length(theFiles) % start at 1
        % for each file in each impact location folder:
        baseFileName = theFiles(j).name;
        % load calibrated sensor data
        wf_data_all = readtable(fullfile(currentFolder,baseFileName));

        % get time info
        mp_impact_times = readtable(strcat(mp_time_folder, '\', mp_time_files(j).name));
        mp_impact_times = table2array(mp_impact_times);
        
        for i = 0:max(wf_data_all.Impact) % look at one impact at a time, start at 0
                            
            % avoid processing ("filler") data. when the mouthpiece dies,
            % it creates this filler data to reach 100 impacts. all
            % filler data is written within the final minute before the
            % MP dies.
            if (testing == false && mp_impact_times(i+1,2) > mp_impact_times(end,2) - minutes(1))
                % fprintf('Breaking out of transform loop.\nFirst impact time: %s\nCurrent impact time: %s\n',char(mp_impact_times(1,2)), char(mp_impact_times(i+1,2)));
                break
            end

            impact_time = char(mp_impact_times(i+1,2));
            impact_time = strrep(impact_time, ':', '.');               
                       
            % extract accel and gyro data
            wf_data = wf_data_all(wf_data_all.Impact==i, :); 
            wf_accel = [wf_data.AccelX, wf_data.AccelY, wf_data.AccelZ];
            wf_gyro = [wf_data.GyroX, wf_data.GyroY, wf_data.GyroZ].*(pi/180); %convert to rad/s
            accel_time = round(wf_data.AccelTime, 5); %round timestamps to remove errors caused by precision during interpolation
            gyro_time = round(wf_data.GyroTime, 5);
            
            % remove duplicate gyroscope data
            [new_gyro_x, new_gyro_y, new_gyro_z, new_time_x, new_time_y, new_time_z] = mp_remove_duplicates(wf_gyro, gyro_time);
            
            % in interp1.m, all of the query values (accel_time) must be <= the last value of X (new_time_X), or else NaN is returned. 
            if(accel_time(end) > new_time_x(end))
                new_time_x(end) = accel_time(end);
            end
            if(accel_time(end) > new_time_y(end))
                new_time_y(end) = accel_time(end);
            end
            if(accel_time(end) > new_time_z(end))
                new_time_z(end) = accel_time(end);
            end
            
            % interpolate
            % g_interp = mp_gyro_interp(gyro_time, wf_gyro, accel_time);
            g_interp_x = mp_gyro_interp(new_time_x, new_gyro_x, accel_time);
            g_interp_y = mp_gyro_interp(new_time_y, new_gyro_y, accel_time);
            g_interp_z = mp_gyro_interp(new_time_z, new_gyro_z, accel_time);
            % g_interp = [g_interp_x, g_interp_y, g_interp_z];

            % filter data
            % g_filt = mp_filter(wf_gyro, g_fs, g_fc);
            g_filt_x = j211filtfilt(g_cfc, g_fs, g_interp_x);
            g_filt_y = j211filtfilt(g_cfc, g_fs, g_interp_y);
            g_filt_z = j211filtfilt(g_cfc, g_fs, g_interp_z);
            a_filt = j211filtfilt(a_cfc, a_fs, wf_accel); 
            
            % zero offset
            % g_zero = mp_zero_offset(g_filt);
            a_zero = mp_zero_offset(a_filt);
            g_zero_x = mp_zero_offset(g_filt_x);
            g_zero_y = mp_zero_offset(g_filt_y);
            g_zero_z = mp_zero_offset(g_filt_z);
            g_zero = [g_zero_x, g_zero_y, g_zero_z];
  
            % rotate
            [r_cg, r_accel, r_gyro] = read_transformation_info(transform_file);
            a_rotated = mp_rotation_accel(r_accel, a_zero);
            g_rotated = mp_rotation_gyro(r_gyro, g_zero);
            
            % calc rotational accel
            % calculated using VT method; added row in beginning to preserve
            % vector length. g should start at 0 0 0, additional timestep
            % should be 0.2ms before first.
            % rot_acc = diff([0 0 0;g_rotated])./diff([-0.0154; wf_data.AccelTime]); 
            rot_acc = mp_angular_accel(accel_time, g_rotated);
            
            % transform
            a_trans = mp_transform(r_cg, a_rotated, g_rotated, rot_acc);
            a_trans = [a_trans(:,1), a_trans(:,2), a_trans(:,3)];
            
            % create table that contains transformed data
            % has time, transformed accel (x,y,z), rotated gyro (x,y,z), and
            % rotated ang accel (x,y,z) for easy comparison to VT data
            trans_table = table(accel_time, a_trans(:,1), a_trans(:,2), a_trans(:,3),...
                g_rotated(:,1), g_rotated(:,2), g_rotated(:,3), rot_acc(:,1), rot_acc(:,2), rot_acc(:,3),...
                'VariableNames', {'Time', 'AccelX', 'AccelY', 'AccelZ', 'GyroX', 'GyroY', 'GyroZ', 'AngAccX', 'AngAccY', 'AngAccZ'});
            
            % save file in folder
            test = sprintf('T%d', i+1); % test number is impact index+1
            saveFile = strcat(baseFileName(1:end-4),' - ', test, ' - ', impact_time, ' - Transformed', '.csv');
            save_file_name = fullfile(saveFolder, saveFile);
            if ~isfolder(saveFolder)
                error('Error: The folder does not exist.'); 
            end
            writetable(trans_table, save_file_name); % write combined table to csv using new filename
            fprintf('Saved data for Impact %d: %s\n',i+1, saveFile);
        end
    end
end