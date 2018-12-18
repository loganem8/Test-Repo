function [angles,rotation] = CG_ROTATION(Data_MP_Accel_Cal_Filt,Data_Gold_Accel_Cal_Filt)

filt_local = [Data_MP_Accel_Cal_Filt.AccelX,Data_MP_Accel_Cal_Filt.AccelY,Data_MP_Accel_Cal_Filt.AccelZ];
filt_global = [Data_Gold_Accel_Cal_Filt.AccelX,Data_Gold_Accel_Cal_Filt.AccelY,Data_Gold_Accel_Cal_Filt.AccelZ];
theta = 0;

%extract data at single timepoint (sample 140, chosen arbitrarily, should be close to peak of impact)
i=140;
x_local = filt_local(i, 1);
y_local = filt_local(i, 2).*-1;%y and z times -1 to flip 180 degress about x axis to match how device sits in mouth
z_local = filt_local(i, 3).*-1;%y and z times -1 to flip 180 degress about x axis to match how device sits in mouth
v_local = [x_local; y_local; z_local];
u_local = v_local./norm(v_local); %unit vector

x_global = filt_global(i, 1);
y_global = filt_global(i, 2);
z_global = filt_global(i, 3);
v_global = [x_global; y_global; z_global];
u_global = v_global./norm(v_global);

%%Next section of code is for finding rotation matrix to align two column
%%vectors found above. MP0038, in cube, is orientation MP0061, in
%%mouthpiece, needs to be transformed to.

% Given two unit vectors, return the rotation matrix to align the vectors
%https://math.stackexchange.com/questions/180418/calculate-rotation-matrix-to-align-vector-a-to-vector-b-in-3d
ssc = @(v) [0 -v(3) v(2); v(3) 0 -v(1); -v(2) v(1) 0]; %Skewed-Symmetric Cross product matrix function
RU = @(A,B) eye(3) + ssc(cross(A,B)) + ssc(cross(A,B))^2*(1-dot(A,B))/(norm(cross(A,B))^2); % Rotation matrix function

%find rotation matrix that rotates local onto global
R1 = RU(u_local, u_global); 

%rotate global CS CW (about y axis) to account for angle of mouthpiece in
%head
R1_Y = [cosd(theta), 0, sind(theta); 0, 1, 0; -sind(theta), 0, cosd(theta)]; %rotation matrix by theta about global y
R_final = R1_Y*R1;
DCM = R_final;
rotation = R_final; %final rotation matrix 

%find new Euler angles
[Y, X, Z] = dcm2angle(DCM,'YXZ');
X = X*180/pi;
Y = Y*180/pi;
Z = Z*180/pi;
angles = [X, Y, Z];

end