function [Baseline_Accel,Baseline_Gyro,r_CG,r_Accel,r_Gyro] = BASELINE_AUTO_RATE_TRANS(Title_initial,Baseline_Folder)

%% Get MP Name and Match to Calibration Folder
    MP = Title_initial(1:2);
    ind = strfind(Title_initial,"P");
    indspace = strfind(Title_initial," ");
    Number = Title_initial((ind+1):(indspace(1,1)-1));
    if length(Number) ==2
            Zeros = '00';
    else
            Zeros = '0';
    end
    Ending = ' - Calibration Data'; 
    
    CallName = strcat(Baseline_Folder, '\', MP, Zeros, Number, Ending);

%% Creates the Baseline Structure
    File_Structure=dir((CallName)); % Finds files in current folder with this start

    Files = table2cell(struct2table(File_Structure)); % Restructures structure variable to a cell array
    [m,~] = size(Files);

    i_list = []; 
    for i = 1:m
        if Files{i,5} == 1 % For some reason, false files are found in every folder, so this finds them
            i_list = [i_list,i];
        end
    end

    Files(i_list,:) = []; % Removes the false files

    Files_Names = Files(:,1); % Separates out the names of the files from the irrelevant information

    r_CG = [];
    r_Accel = [];
    r_Gyro = [];
    
for x = 1:length(Files_Names)
    if contains(Files_Names{x,1},"Accel") == 1
        Filename_Accel = strcat(CallName,'\',Files_Names{x,1});
        Baseline_File_Accel = csvread(Filename_Accel,1,1);
            Baseline_Accel(1).X_Slope = Baseline_File_Accel(1,1); 
            Baseline_Accel(1).X_Offset = Baseline_File_Accel(1,2);
            Baseline_Accel(1).Y_Slope = Baseline_File_Accel(2,1);
            Baseline_Accel(1).Y_Offset = Baseline_File_Accel(2,2);
            Baseline_Accel(1).Z_Slope = Baseline_File_Accel(3,1);
            Baseline_Accel(1).Z_Offset = Baseline_File_Accel(3,2);
            
    elseif contains(Files_Names{x,1},"Gyro") == 1
        Filename_Gyro = strcat(CallName,'\',Files_Names{x,1});
        Baseline_File_Gyro = csvread(Filename_Gyro,1,1);
            Baseline_Gyro(1).X_Slope = Baseline_File_Gyro(1,1); 
            Baseline_Gyro(1).X_Offset = Baseline_File_Gyro(1,2);
            Baseline_Gyro(1).Y_Slope = Baseline_File_Gyro(2,1);
            Baseline_Gyro(1).Y_Offset = Baseline_File_Gyro(2,2);
            Baseline_Gyro(1).Z_Slope = Baseline_File_Gyro(3,1);
            Baseline_Gyro(1).Z_Offset = Baseline_File_Gyro(3,2);
            
    elseif contains(Files_Names{x,1},"Baseline") == 1
        Filename_Baseline = strcat(CallName,'\',Files_Names{x,1});
        Baseline_File_Accel = xlsread(Filename_Baseline);
            Baseline_Accel(1).X_neg_one = Baseline_File_Accel(2,1); 
            Baseline_Accel(1).X_pos_one = Baseline_File_Accel(3,1);
            Baseline_Accel(1).X_zero = Baseline_File_Accel(4,1);
            Baseline_Accel(1).Y_neg_one = Baseline_File_Accel(5,1);
            Baseline_Accel(1).Y_pos_one = Baseline_File_Accel(6,1);
            Baseline_Accel(1).Y_zero = Baseline_File_Accel(7,1);
            Baseline_Accel(1).Z_neg_one = Baseline_File_Accel(8,1);
            Baseline_Accel(1).Z_pos_one = Baseline_File_Accel(9,1);
            Baseline_Accel(1).Z_zero = Baseline_File_Accel(10,1);

        Baseline_Gyro = [];
        
    elseif contains(Files_Names{x,1},"Transform") == 1
        if contains(Files_Names{x,1},"~") == 1
        else
        Filename_Transform = strcat(CallName,'\',Files_Names{x,1});
        info = readtable(Filename_Transform);
            sensorCG = info.sensorCG;
            headCG = [0; 0; 0];
            sensor_to_head = headCG - sensorCG;
            r_CG = sensor_to_head*1/1000;

            ux = info.X;
            uy = info.Y;
            uz = info.Z;

            % Accelerometer orientation
            x1 = ux;
            y1 = uy;
            z1 = uz;
            r_Accel = [x1, y1, z1];
            % Gyro orientation: gyro x is accel -y. gyro y is accel x. 
            %This was determined for rev 3 boards based on how the gyro and accel
            %are oriented relative to each other. 
            x2 = -uy;
            y2 = ux;
            z2 = uz;
            r_Gyro = [x2, y2, z2];
        end
    else
        error("No calibration baselines found");
    end
end

if isempty(r_CG) == 1
    warning("No CG transformation was found for this data");
end

end