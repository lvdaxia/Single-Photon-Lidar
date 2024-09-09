for i=1:col
    [time_flight(i),flux(i)]=distance_calculation(data_split(:,i),his_resol,his_length,laser_repetition,pulse_width);
end

function [time_flight,flux]=distance_calculation(data,his_resol,his_length,laser_repetition,pulse_width)
    % 直接寻找最大值
    t=(1:his_length)'*his_resol;
    data(49/his_resol:55/his_resol)=0;
    [~,index]=max(data);
    time_window_lowwer=max([1,round(index-5*pulse_width/his_resol)]);
    time_window_upper=min([his_length,round(index+5*pulse_width/his_resol)]);
    
    time_flight=sum(data(time_window_lowwer:time_window_upper).*t(time_window_lowwer:time_window_upper))/sum(data(time_window_lowwer:time_window_upper));
    P=sum(data(time_window_lowwer:time_window_upper))/laser_repetition;
    flux=-log(1-P);
    figure(1);plot(t(time_window_lowwer:time_window_upper),data(time_window_lowwer:time_window_upper));
    figure(2);plot(t,data);
end