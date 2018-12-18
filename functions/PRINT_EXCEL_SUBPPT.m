function [] = PRINT_EXCEL_SUBPPT(Title_initial,Time_Date_Full,Data_Accel,Data_Gyro,Data_Accel_Cal,Data_Gyro_Cal,Data_Accel_Cal_Filt_Zero,Data_Gyro_Cal_Filt_Zero,Linear_Resultant,Rotational_Resultant,Files_Names,Impact_Totals,Filter)

% Formats so all Excel values are only 2 decimals
format bank;

%% Excel Files
    % Creates tables with rounded values to make into Excel files
    Data_Sorted_Pre = [Data_Accel.Impact Data_Accel.Index round(Data_Accel.AccelX,2) round(Data_Accel.AccelY,2) round(Data_Accel.AccelZ,2) round(Data_Gyro.GyroX,2) round(Data_Gyro.GyroY,2) round(Data_Gyro.GyroZ,2) round(Data_Accel.Timestamp,2)];
    Data_Sorted = array2table(Data_Sorted_Pre, 'VariableNames', {'Impact' 'Index' 'AccelX' 'AccelY' 'AccelZ' 'GyroX' 'GyroY' 'GyroZ' 'Timestamp'});

    Data_Converted_Pre = [Data_Accel_Cal.Impact Data_Accel_Cal.Index round(Data_Accel_Cal.AccelX,2) round(Data_Accel_Cal.AccelY,2) round(Data_Accel_Cal.AccelZ,2) round(Data_Gyro_Cal.GyroX,2) round(Data_Gyro_Cal.GyroY,2) round(Data_Gyro_Cal.GyroZ,2) round(Data_Accel_Cal.Timestamp,2)];
    Data_Converted = array2table(Data_Converted_Pre, 'VariableNames', {'Impact' 'Index' 'AccelX' 'AccelY' 'AccelZ' 'GyroX' 'GyroY' 'GyroZ' 'Timestamp'});
    
    Data_Zeroed_Pre = [Data_Accel_Cal_Filt_Zero.Impact Data_Accel_Cal_Filt_Zero.Index round(Data_Accel_Cal_Filt_Zero.AccelX,2) round(Data_Accel_Cal_Filt_Zero.AccelY,2) round(Data_Accel_Cal_Filt_Zero.AccelZ,2) round(Data_Gyro_Cal_Filt_Zero.GyroX,2) round(Data_Gyro_Cal_Filt_Zero.GyroY,2) round(Data_Gyro_Cal_Filt_Zero.GyroZ,2) round(Data_Accel_Cal_Filt_Zero.Timestamp,2)];
    Data_Zeroed = array2table(Data_Zeroed_Pre, 'VariableNames', {'Impact' 'Index' 'AccelX' 'AccelY' 'AccelZ' 'GyroX' 'GyroY' 'GyroZ' 'Timestamp'});
    
    Impact_unique = unique(Data_Accel_Cal_Filt_Zero.Impact);
    Impact_unique_table = array2table(Impact_unique, 'VariableNames', {'Impact'});

    for q = 1:length(Impact_unique)
        Y(q,:) = Time_Date_Full(q,(1:4));
        M(q,:) = Time_Date_Full(q,(5:6));
        D(q,:) = Time_Date_Full(q,(7:8));
        H(q,:) = Time_Date_Full(q,(10:11));
        Mn(q,:) = Time_Date_Full(q,(13:14));
        S(q,:) = Time_Date_Full(q,(16:17));
    end
        
    for t = 1:length(Impact_unique)
        Temp(t,:) = datetime([Y(t,:)  M(t,:)  D(t,:)  H(t,:)  Mn(t,:)  S(t,:)],'InputFormat','yyyyMMddHHmmss');
    end

        DateString = datestr(Temp);
    
    for q = 1:length(Impact_unique)
        Date(q,(1:11)) = DateString(q,(1:11));
        Time(q,(1:8)) = DateString(q,(13:20));
    end

    Time_Cell = cellstr(Time);
    Date_Cell = cellstr(Date);
    Time_Date_Table = cell2table([Date_Cell, Time_Cell], 'VariableNames', {'Date' 'Time'});
    Event_Times = [Impact_unique_table Time_Date_Table];

    Filename_Sorted_cha = sprintf('%s_Time_Sorted.xlsx', Title_initial);
    Filename_Converted_cha = sprintf('%s_Converted.xlsx', Title_initial);
    Filename_Zeroed_cha = sprintf('%s_Zeroed.xlsx', Title_initial);

    writetable(Data_Sorted,Filename_Sorted_cha,'Sheet',1);
        writetable(Event_Times,Filename_Sorted_cha,'Sheet',2);

    writetable(Data_Converted,Filename_Converted_cha,'Sheet',1);
        writetable(Event_Times,Filename_Converted_cha,'Sheet',2);
        
    writetable(Data_Zeroed,Filename_Zeroed_cha,'Sheet',1);
        writetable(Event_Times,Filename_Zeroed_cha,'Sheet',2);
        
%% Plots

if length(Impact_Totals) == 1
    ind = strfind(Title_initial," ");
    inddot = strfind(Title_initial,".");
    Title_ppt = char(strcat(Title_initial(ind(1,2)+1:ind(1,3)-1),": ",Title_initial(ind(1,6)+1:inddot(1,3)-1)));
    toPPT('setTitle',Title_ppt,'SlideNumber','append')
    toPPT('addSection','Title Page','SlideNumber','current','SlideAddMethod','before')
end

i = 2;
figure(1)
imshow('Legend.jpg')
    for p=1:length(Impact_unique)
        Index = sprintf('Event: %.0f',p);
        Time_Title = sprintf('Time: %s',Time(p,:));
        MP = Title_initial(1:24);
        Title = sprintf('%s (%s, %s)',MP,Time_Title,Index);

            figure
                subplot(2,2,1)
                    plot(Data_Accel_Cal_Filt_Zero.Timestamp((p*282-281):(p*282)),Data_Accel_Cal_Filt_Zero.AccelX((p*282-281):(p*282)),'Color',[0, 0.4470, 0.7410])
                    hold on
                    plot(Data_Accel_Cal_Filt_Zero.Timestamp((p*282-281):(p*282)),Data_Accel_Cal_Filt_Zero.AccelY((p*282-281):(p*282)),'Color',[0.8500, 0.3250, 0.0980])
                    plot(Data_Accel_Cal_Filt_Zero.Timestamp((p*282-281):(p*282)),Data_Accel_Cal_Filt_Zero.AccelZ((p*282-281):(p*282)),'Color',[0.9290, 0.6940, 0.1250])
                    hold off
                    ylabel('Linear Acceleration (g)')
                    xlabel('Time (ms)')
%                     legend('X axis','Y axis','Z axis','Location','southeast')
                    grid on
                    grid minor
                    xlim([-15 45]);
                    xticks(-15:5:45)
                subplot(2,2,3)
                    plot(Data_Accel_Cal_Filt_Zero.Timestamp((p*282-281):(p*282)),Linear_Resultant((p*282-281):(p*282)),'Color','k')
                    ylabel('Linear Resultant Acceleration (g)')
                    xlabel('Time (ms)')
                    grid on
                    grid minor
                    xlim([-15 45]);
                    xticks(-15:5:45)
                subplot(2,2,2)
                    plot(Data_Gyro_Cal_Filt_Zero.Timestamp((p*282-281):(p*282)),Data_Gyro_Cal_Filt_Zero.GyroX((p*282-281):(p*282)),'Color',[0, 0.4470, 0.7410])
                    hold on
                    plot(Data_Gyro_Cal_Filt_Zero.Timestamp((p*282-281):(p*282)),Data_Gyro_Cal_Filt_Zero.GyroY((p*282-281):(p*282)),'Color',[0.8500, 0.3250, 0.0980])
                    plot(Data_Gyro_Cal_Filt_Zero.Timestamp((p*282-281):(p*282)),Data_Gyro_Cal_Filt_Zero.GyroZ((p*282-281):(p*282)),'Color',[0.9290, 0.6940, 0.1250])
                    hold off
                    ylabel('Angular Velocity (dps)')
                    xlabel('Time (ms)')
                    xlim([-15 45]);
                    xticks(-15:5:45)
%                     legend('X axis','Y axis','Z axis','Location','southeast')
                    grid on
                    grid minor
                subplot(2,2,4)
                    plot(Data_Gyro_Cal_Filt_Zero.Timestamp((p*282-281):(p*282)),Rotational_Resultant((p*282-281):(p*282)),'Color','k')
                    ylabel('Resultant Angular Velocity (dps)')
                    xlabel('Time (ms)')
                    xlim([-15 45]);
                    xticks(-15:5:45)
                    grid on
                    grid minor
                    % This creates a centered title over the subplots
                    bb = annotation('textbox', [0 0.9 1 0.1], ...
                                'String', Title, ...
                                'EdgeColor', 'none', ...
                                'HorizontalAlignment', 'center');
                            bb.FontSize = 20;
                            bb.FontName = 'Times New Roman';
            if i == 2
                toPPT(figure(1),'SlideNumber','append','Height',50,'Width',90,'pos','NW','gapN',-60,'gapWE',-350);
                toPPT(figure(i),'SlideNumber','current','gapN',60,'Height%',120,'Width%',80)
                MP_Name = Title_initial(1:4);
                toPPT('addSection',MP_Name,'SlideNumber','current','SlideAddMethod','before')
            else
                toPPT(figure(1),'SlideNumber','append','Height',50,'Width',100,'pos','NW','gapN',-60,'gapWE',-350);
                toPPT(figure(i),'SlideNumber','current','gapN',60,'Height%',120,'Width%',80)
            end
        i = i+1;
    end
    
%% Plot the Title Slide after all other slides
if length(Impact_Totals) == length(Files_Names)
    ind = strfind(Title_initial," ");
    inddot = strfind(Title_initial,".");
    Title_ppt = char(strcat(Title_initial(ind(1,2)+1:ind(1,3)-1),": ",Title_initial(ind(1,6)+1:inddot(1,3)-1)));
    
    % MP bullet and Events bullet
        for y = 1:length(Files_Names)
            Name = Files_Names{y,1};
            MP_names(y,:) = Name(3:4);
        end
        MPs_bullet = 'MPs:';
        Events_bullet = 'Number of Events:';
            for s = 1:length(Impact_Totals)
                MPs_bullet = sprintf('%s %s;',MPs_bullet,MP_names(s,:));
                Events_bullet = sprintf('%s %d;',Events_bullet,Impact_Totals(s,1));
            end
    % Filter
        if isempty(Filter.fs_gyro) == 1
            GFS_bullet = 'Gyro sampling rate: Not Known';
        else
            GFS_bullet = sprintf('Gyro sampling rate: %d Hz',Filter.fs_gyro);
        end
        
        if isempty(Filter.fc_gyro) == 1
            GFC_bullet = 'Gyro cutoff frequency: N/A';
        else
            GFC_bullet = sprintf('Gyro cutoff frequency: %d Hz',Filter.fc_gyro);
        end
        
        if isempty(Filter.fs_accel) == 1
            AFS_bullet = 'Accel sampling rate: Not Known';
        else
            AFS_bullet = sprintf('Accel sampling rate: %d Hz',Filter.fs_accel);
        end
        
        if isempty(Filter.fc_accel) == 1
            AFC_bullet = 'Accel cutoff frequency: N/A';
        else
            AFC_bullet = sprintf('Accel cutoff frequency: %d Hz',Filter.fc_accel);
        end

    toPPT({MPs_bullet,Events_bullet,GFS_bullet,GFC_bullet,AFS_bullet,AFC_bullet},'SlideNumber',Title_ppt,'gapN',130,'gapWE',70)
end
    
    
end