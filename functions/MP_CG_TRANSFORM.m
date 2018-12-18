function [Data_Accel_Trans,Data_Gyro_Trans,Linear_Resultant_CG,Rotational_Resultant_CG] = MP_CG_TRANSFORM(Data_Accel_Cal_Filt_Zero,Data_Gyro_Cal_Filt_Zero,r_CG,r_Accel,r_Gyro)

Accel = [Data_Accel_Cal_Filt_Zero.AccelX, Data_Accel_Cal_Filt_Zero.AccelY, Data_Accel_Cal_Filt_Zero.AccelZ];
Gyro = [Data_Gyro_Cal_Filt_Zero.GyroX, Data_Gyro_Cal_Filt_Zero.GyroY, Data_Gyro_Cal_Filt_Zero.GyroZ];

%% Convert Gyro to rps
    Gyro_rps = Gyro./57.29578;

%% Rotation
    % Accel
        Accel_Rot = zeros(size(Accel));
        for i = 1:size(Accel,1)
            Accel_Rot(i, :) = r_Accel*Accel(i,:)';
        end
        
    %Gyro
        Gyro_Rot_rps = zeros(size(Gyro_rps));
        Gyro_Rot = zeros(size(Gyro));
        for i = 1:size(Gyro_rps,1)
            Gyro_Rot_rps(i, :) = r_Gyro*Gyro_rps(i,:)';
            Gyro_Rot(i, :) = r_Gyro*Gyro(i,:)';
        end

%% Angular Acceleration for Transform
    Angular_Accel = zeros(size(Gyro_Rot_rps));
        for i = 1:size(Gyro_Rot_rps, 2)
            current_data = Gyro_Rot_rps(:,i)';
            Gyro_accel_Temp = dt_order_4_or_five_point_stencil(Data_Gyro_Cal_Filt_Zero.Timestamp', current_data);
            Angular_Accel(:,i) = Gyro_accel_Temp';
        end
        
%% Transform
    a = zeros(size(Accel_Rot));
        for i = 1:size(Accel_Rot, 1)
            lin_accel = Accel_Rot(i,:)*9.80665; %linear acceleration, in m/s^2
            current_ang_acc = Angular_Accel(i,:); %x, y, z ang Accel_Data for current row
            current_ang_vel = Gyro_Rot_rps(i,:); %current ang velocity x, y, z
            %find total transformed acceleration in m/s^2
            a(i,:) = lin_accel + cross(current_ang_acc,r_CG') + cross(current_ang_vel,cross(current_ang_vel,r_CG'));
        end
    %convert back to g:
    Linear_Accel_CG = a./9.80665;
    
%% Make New Table
	% Create new table
        Accel_Trans = [Data_Accel_Cal_Filt_Zero.Impact, Data_Accel_Cal_Filt_Zero.Index, Linear_Accel_CG(:,1), Linear_Accel_CG(:,2), Linear_Accel_CG(:,3), Data_Accel_Cal_Filt_Zero.Timestamp]; 
        Gyro_Trans = [Data_Gyro_Cal_Filt_Zero.Impact, Data_Gyro_Cal_Filt_Zero.Index, Gyro_Rot(:,1), Gyro_Rot(:,2), Gyro_Rot(:,3), Data_Gyro_Cal_Filt_Zero.Timestamp]; 
    % Restructure to same shape as original table with same column names
        Data_Accel_Trans = array2table(Accel_Trans, 'VariableNames', {'Impact' 'Index' 'AccelX' 'AccelY' 'AccelZ' 'Timestamp'});
        Data_Gyro_Trans = array2table(Gyro_Trans, 'VariableNames', {'Impact' 'Index' 'GyroX' 'GyroY' 'GyroZ' 'Timestamp'});

%% Resultant 
        % Resultant of linear and rotational values
            Linear_Resultant_CG = sqrt(Data_Accel_Trans.AccelX.^2+Data_Accel_Trans.AccelY.^2+Data_Accel_Trans.AccelZ.^2);
            Rotational_Resultant_CG = sqrt(Data_Gyro_Trans.GyroX.^2+Data_Gyro_Trans.GyroX.^2+Data_Gyro_Trans.GyroX.^2);
        