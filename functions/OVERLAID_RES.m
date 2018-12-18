function [] = OVERLAID_RES(Time_Milli,Linear_Resultant)

% Overlaid plot of all resultants for abstract
figure
plot(Time_Milli,Linear_Resultant(:,1),'Color','k')
hold on
    for p = 2:21
        if p == 2
        plot(Time_Milli+10,Linear_Resultant(:,p),'Color','k')
        elseif p == 5
        plot(Time_Milli+10,Linear_Resultant(:,p),'Color','k')
        else
        plot(Time_Milli,Linear_Resultant(:,p),'Color','k')
        end
    end
hold off
ylabel('Resultant Linear Acceleration (g)')
xlabel('Time (ms)')
% legend('1','2','3','4','5','6','7','8','9','10','11','12','13','14','15','16','17','18','19','20','21')
grid on
grid minor
xlim([-10 20])
xticks(-10:5:20)
