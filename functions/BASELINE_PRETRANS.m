function [Baseline_MP,Baseline_Gold] = BASELINE_PRETRANS(Title_MP,Title_Gold,Baseline_Folder)

%% Get MP Name and Match to Calibration Folder
    MP = 'MP';
    Zeros = '00';
    Number = Title_MP(1:2);
    Ending = ' - Calibration Data'; 
    
    CallName = strcat(Baseline_Folder, MP, Zeros, Number, Ending);

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

for x = 1:length(Files_Names)
    if contains(Files_Names{x,1},"Accel") == 1
        Baseline_File_Accel = csvread(Files_Names{x,1},1,1);
            Baseline_MP(1).X_Slope = Baseline_File_Accel(1,1); 
            Baseline_MP(1).X_Offset = Baseline_File_Accel(1,2);
            Baseline_MP(1).Y_Slope = Baseline_File_Accel(2,1);
            Baseline_MP(1).Y_Offset = Baseline_File_Accel(2,2);
            Baseline_MP(1).Z_Slope = Baseline_File_Accel(3,1);
            Baseline_MP(1).Z_Offset = Baseline_File_Accel(3,2);
        break
    elseif contains(Files_Names{x,1},"Baseline") == 1
        Baseline_File_Accel = xlsread(Files_Names{x,1});
            Baseline_MP(1).X_neg_one = Baseline_File_Accel(2,1); 
            Baseline_MP(1).X_pos_one = Baseline_File_Accel(3,1);
            Baseline_MP(1).X_zero = Baseline_File_Accel(4,1);
            Baseline_MP(1).Y_neg_one = Baseline_File_Accel(5,1);
            Baseline_MP(1).Y_pos_one = Baseline_File_Accel(6,1);
            Baseline_MP(1).Y_zero = Baseline_File_Accel(7,1);
            Baseline_MP(1).Z_neg_one = Baseline_File_Accel(8,1);
            Baseline_MP(1).Z_pos_one = Baseline_File_Accel(9,1);
            Baseline_MP(1).Z_zero = Baseline_File_Accel(10,1);
        break
    else
        error("No Experimental MP calibration baselines found");
    end
end

%% Get Gold Name and Match to Calibration Folder
    MP = 'MP';
    Zeros = '00';
    Number = Title_Gold(1:2);
    Ending = ' - Calibration Data'; 
    
    CallName = strcat(Baseline_Folder, MP, Zeros, Number, Ending);

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

for x = 1:length(Files_Names)
    if contains(Files_Names{x,1},"Accel") == 1
        Baseline_File_Accel = csvread(Files_Names{x,1},1,1);
            Baseline_Gold(1).X_Slope = Baseline_File_Accel(1,1); 
            Baseline_Gold(1).X_Offset = Baseline_File_Accel(1,2);
            Baseline_Gold(1).Y_Slope = Baseline_File_Accel(2,1);
            Baseline_Gold(1).Y_Offset = Baseline_File_Accel(2,2);
            Baseline_Gold(1).Z_Slope = Baseline_File_Accel(3,1);
            Baseline_Gold(1).Z_Offset = Baseline_File_Accel(3,2);
        break
    elseif contains(Files_Names{x,1},"Baseline") == 1
        Baseline_File_Accel = xlsread(Files_Names{x,1});
            Baseline_Gold(1).X_neg_one = Baseline_File_Accel(2,1); 
            Baseline_Gold(1).X_pos_one = Baseline_File_Accel(3,1);
            Baseline_Gold(1).X_zero = Baseline_File_Accel(4,1);
            Baseline_Gold(1).Y_neg_one = Baseline_File_Accel(5,1);
            Baseline_Gold(1).Y_pos_one = Baseline_File_Accel(6,1);
            Baseline_Gold(1).Y_zero = Baseline_File_Accel(7,1);
            Baseline_Gold(1).Z_neg_one = Baseline_File_Accel(8,1);
            Baseline_Gold(1).Z_pos_one = Baseline_File_Accel(9,1);
            Baseline_Gold(1).Z_zero = Baseline_File_Accel(10,1);
        break
    else
        error("No Gold Standard calibration baselines found");
    end
end

end