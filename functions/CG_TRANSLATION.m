function [transform] = CG_TRANSLATION(coordinates)

%%Head_CG

% This program uses the Hardy C428 test to estimate the subject's head CG
% from 2D pictures and calculates the transform vector from the mouthpiece sensor to the
% head CG.
% Before using this code, see the protocol for taking pictures and
% selecting/saving landmark coordinates as an Excel file to be imported to
% this program

warning('off','images:initSize:adjustingMag'); 

%% Left and Right Views
% (+X picture = -X head CS, +Y picture = -Z head CS)

for i = 1:2
    if i == 1 %right orientation
        IOM_x = xlsread(coordinates,'A5:A5'); %import coordinates from Excel sheet
        IOM_y = xlsread(coordinates,'B5:B5');
        EAM_x = xlsread(coordinates,'A7:A7'); 
        EAM_y = xlsread(coordinates,'B7:B7');
        canine_x = xlsread(coordinates,'A9:A9');
        canine_y = xlsread(coordinates,'B9:B9');
        grid = xlsread(coordinates,'A14:B19');
    
        figure ('Name','Right') %import corresponding image (see naming protocol) and create figure 
        R = strrep(coordinates,'.xlsx', '_R.JPG');
        R = strrep(R,'Coordinates_', ''); 
        R = imread(R);
        imshow(R);
        hold on;
    
    else %left orientation
        IOM_x = xlsread(coordinates,'D5:D5');%import coordinates from Excel sheet
        IOM_y = xlsread(coordinates,'E5:E5');
        EAM_x = xlsread(coordinates,'D7:D7');
        EAM_y = xlsread(coordinates,'E7:E7');
        canine_x = xlsread(coordinates,'D9:D9');
        canine_y = xlsread(coordinates,'E9:E9');
        grid = xlsread(coordinates,'D14:E19');      

        figure ('Name','Left') %import corresponding image (see naming protocol) and create figure
        L = strrep(coordinates,'.xlsx', '_L.JPG');
        L = strrep(L,'Coordinates_', ''); 
        L = imread(L);
        imshow(L);
        hold on;
    end

%Grid Calibration
dist = zeros(5,1);
for a = 1:3:4
    for b = a:(a + 1)
    c = b + 1;
    dist(b,1) = sqrt((grid(a,1) - grid(c,1))^2 + (grid(a,2) - grid(c,2))^2);
    end
end
avg = sum(dist([1 2 4 5],1)) / 4; 
pixel_per_mm = avg / 25.4; %divide by mm between selected grid lines (1 inch)

%Conversion of Hardy Test transformation values from mm to pixels:
shift_x = pixel_per_mm * 10.95; %CG located 10.95 mm anterior to EAM wrt the Frankfort plane
shift_y = pixel_per_mm * 30.00; %CG located 30.00 mm superior to EAM wrt the Frankfort plane

%Frankfort Plane (line between EAM and IOM)and reference horizontal)
% horizontal = plot([IOM_x EAM_x], [EAM_y EAM_y],'r');
% Frankfort_plane = plot([EAM_x IOM_x], [EAM_y IOM_y],'b');

% Slope of Frankfort Plane and angle to horizontal
m = (EAM_y - IOM_y) / (EAM_x - IOM_x);
theta = atan(abs(m));

%X- and Y-direction Hardy test transform wrt Frankfort plane
if m < 0  && i == 1
    X = (shift_x - (shift_y * sin(theta))) * cos(theta);
    Y = - (shift_y * cos(theta) + (shift_x - (shift_y * sin(theta))) * sin(theta));   
elseif m < 0 && i == 2
    X = - (shift_x * cos(theta) + shift_y * sin(theta));
    Y = - shift_y * cos(theta);    
elseif m > 0 && i == 1
    X = shift_y * sin(theta) + shift_x * cos(theta);
    Y = shift_x * sin(theta) - shift_y * cos(theta);      
elseif m > 0 && i == 2
    X = - (shift_x - (shift_y * sin(theta)) * cos(theta));
    Y = - (shift_y * cos(theta) + (shift_x - (shift_y * sin(theta))) * sin(theta));   
end
    
% Plot CG 
CG_x = EAM_x + X;
CG_y = EAM_y + Y;
CG = scatter(CG_x,CG_y,20,'filled','MarkerEdgeColor','w','MarkerFaceColor','w');
% EAM_CG = plot([EAM_x CG_x], [EAM_y CG_y], 'g'); %EAM to CG vector

%Canine to CG y- and z- distance
X_transform(i) = -abs(canine_x - CG_x) / pixel_per_mm; %Picture coordinate +x = head coordinate -x, converted to mm
Z_transform(i) = abs(canine_y - CG_x) / pixel_per_mm; %Picture coordinate -y = head coordinate +z, converted to mm
plot([canine_x CG_x], [CG_y CG_y],'g'); 
plot([canine_x canine_x], [canine_y CG_y],'g');

hold off;
end

%average of right/left Y- and Z- transforms:
canine2CG(1,1) = mean(X_transform);
canine2CG(1,2) = 0;
canine2CG(1,3) = mean(Z_transform);

%% Front View (right canine to CG Y-distance)
% +X picture = +Y head CS, +Y picture = -Z head CS

figure('Name','Front') %import corresponding image (see naming protocol) and create figure
S = strrep(coordinates,'.xlsx', '_S.JPG');
S = strrep(S,'Coordinates_', ''); 
S = imread(S);
imshow(S);
hold on;

%Grid Calibration
grid =  xlsread(coordinates,'G14:H19'); %import grid coordinates from Excel sheet
dist = zeros(5,1);
for a = 1:3:4
    for b = a:(a + 1)
    c = b + 1;
    dist(b,1) = sqrt((grid(a,1) - grid(c,1))^2 + (grid(a,2) - grid(c,2))^2);
    end
end
avg = sum(dist([1 2 4 5],1)) / 4; 
pixel_per_mm = avg / 25.4; %divide by mm between selected grid lines (1 inch)

%Estimate location of XZ plane using average of canine coordinates
canine_L = xlsread(coordinates,'G5:H5');
canine_R = xlsread(coordinates,'G7:H7');
y_0 = [(canine_L(1,1) + canine_R(1,1)) / 2, canine_R(1,2)]; %y=0 (head CS) assumed to be midpoint of canines
scatter(y_0(1,1),y_0(1,2),20,'filled','MarkerEdgeColor','w','MarkerFaceColor','w');
scatter(canine_R(1,1),canine_R(1,2),20,'filled','MarkerEdgeColor','w','MarkerFaceColor','w');
plot([canine_R(1,1) y_0(1,1)], [canine_R(1,2) y_0(1,2)],'g'); 

% canine2CG(1,2) = -(y_0(1,1) - canine_R(1,1)) / pixel_per_mm; %Y transform from right canine y=0 head CS
canine2CG(1,2) = (y_0(1,1) - canine_R(1,1)) / pixel_per_mm; %Y transform from right canine y=0 head CS

hold off;
%% Dentition (sensor to canine x- and y-distances, z-distance assumed to be negligible)

%import coordinates from Excel sheet
canine_x = xlsread(coordinates,'J5:J5');
canine_y = xlsread(coordinates,'K5:K5');
sensor_corners = xlsread(coordinates,'K7:J10');
grid = xlsread(coordinates,'J14:K19');

figure('Name','Dentition') %import corresponding image (see naming protocol) and create figure
D = strrep(coordinates,'.xlsx', '_Dentition.JPG');
D = strrep(D,'Coordinates_', ''); 
D = imread(D);
imshow(D);
hold on;

%Grid Calibration
dist = zeros(5,1);
for a = 1:3:4
    for b = a:(a + 1)
    c = b + 1;
    dist(b,1) = sqrt((grid(a,1) - grid(c,1))^2 + (grid(a,2) - grid(c,2))^2);
    end
end
avg = sum(dist([1 2 4 5],1)) / 4; 
pixel_per_mm = avg / 25.4; %divide by mm between selected grid lines (1 inch)

%approximate center of sensor board via side lengths and midpoints
for n = 1:4
    if n == 1 %top left to top right
        P1 = sensor_corners(1,1:2);
        P2 = sensor_corners(2,1:2);
    elseif n == 2 %bottom left to bottom right
        P1 = sensor_corners(4,1:2);
        P2 = sensor_corners(3,1:2);
    elseif n == 3 %bottom left to top left
        P1 = sensor_corners(4,1:2);
        P2 = sensor_corners(1,1:2);
    elseif n ==4 %bottom right to top right
        P1 = sensor_corners(3,1:2);
        P2 = sensor_corners(2,1:2);
    end
    mp(n,1) = (P1(1,1) + P2(1,1)) / 2; %x coord
    mp(n,2) = (P1(1,2) + P2(1,2)) / 2; %y coord
    %scatter(mp(n,1),mp(n,2));
end
horiz = plot([mp(3,1) mp(4,1)],[mp(3,2) mp(4,2)],'m'); % plot horizontal line through mp of vertical sensor boundaries
vert = plot([mp(1,1) mp(2,1)],[mp(1,2) mp(2,2)],'m'); % plot vertical line through mp of horizontal sensor boundaries 

%find intersection of horiz/vert (center of sensor board)
m_horiz = (mp(4,2)-mp(3,2))/(mp(4,1)-mp(3,1)); %slope of horiz
m_vert = (mp(2,2)-mp(1,2))/(mp(2,1)-mp(1,1));%slope of vert

center_x = ((m_vert * mp(1,1)) - mp(1,2) - (m_horiz * mp(3,1)) + mp(3,2)) / (m_vert - m_horiz); %x coordinate of intersection
center_y = m_vert * (center_x - mp(1,1)) + mp(1,2); %y coordinate of intersection
scatter(center_x,center_y)

%distance from sensor board center to accelerometer center
center2accel = 6.0591 * pixel_per_mm; %distance found from manual measurement of sensor board center to accelerometer center

accel_location = menu('Accelerometer Orientation:','anterior portion of board','posterior portion of board');
if accel_location == 1
    accel_x = center_x + (center2accel / sqrt(1+ m_vert^2));
else
    accel_x = center_x - (center2accel / sqrt(1+ m_vert^2));
end
accel_y =  center_y + m_vert * (accel_x - center_x);
scatter(accel_x,accel_y); %plot accel location

%accel to canine transform
accel2canine(1,1) = abs(canine_y - accel_y) / pixel_per_mm; %+y picture coordinates = -x head coordinates, converted to mm
accel2canine(1,2) = - abs(canine_x - accel_x) / pixel_per_mm; %+x picture coordinates = -y head coordinates, converted to mm
accel2canine(1,3) = 0; %assume z-distance to be negligible

plot([canine_x accel_x], [accel_y accel_y],'g'); 
plot([canine_x canine_x], [canine_y accel_y],'g');

%% Sensor to CG transform
transform = accel2canine + canine2CG;
