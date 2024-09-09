function [output]=flight_time_calculation(data,his_resol,his_length,laser_repetition,pulse_width,fast_voltage,slow_voltage)
    % 直接寻找最大值
    t=(1:his_length)*his_resol;
    data(his_resol/his_resol:round(200/his_resol))=0;
%     data(130/his_resol:end)=0;
    [~,index]=max(data);
    time_window_lowwer=max([1,round(index-3*pulse_width/his_resol)]);
    time_window_upper=min([his_length,round(index+5*pulse_width/his_resol)]);
    
    flight_time=sum(data(time_window_lowwer:time_window_upper).*t(time_window_lowwer:time_window_upper))/sum(data(time_window_lowwer:time_window_upper));
    P=sum(data(time_window_lowwer:time_window_upper))/laser_repetition;
    flux=-log(1-P);
%     figure(1);plot(t(time_window_lowwer:time_window_upper),data(time_window_lowwer:time_window_upper));
%     figure(2);plot(t,data);

    C=299552816;
    fast_rad=2.2*fast_voltage*2*(pi/180);  %X转镜转角,电压与角度2倍数关系，转弧度，振镜转角2.2°/V
    slow_rad=2.2*slow_voltage*2*(pi/180);   %y转镜转角
    flight_distance=flight_time*C/2*1e-9;
%     e=0;    % 修正枕形畸变，设X振镜到Y振镜距离0.03m
%     Y=(flight_distance-e)*tan(y_rad);
%     X=(sqrt((flight_time-e)^2+Y^2)+e)*tan(x_rad);
%     Z=(flight_time-e)*cos(x_rad)*cos(y_rad);
    e=0.2529*C/2*1e-9; % 两个振镜之间的距离
    D0=51.7078*C/2*1e-9;% 系统原点
%     target_Distance=flight_distance-D0-e;
    Depth=((flight_distance-D0).*cos(slow_rad)-e).*cos(fast_rad);
    fast_axis=Depth.*tan(fast_rad);
    slow_axis=(Depth./cos(fast_rad)+e).*tan(slow_rad);
    fast_array=fast_axis(:);
    slow_array=slow_axis(:);
    Depth_array=Depth(:);
    output=[fast_array;slow_array;Depth_array];
%     if flux>2e-4
%         figure(2);plot((1:length(data))*his_resol,data);
%         figure(3);plot3(Depth_array,slow_axis,fast_axis,'b.');hold on;xlabel('深度/m');ylabel('慢轴/m');zlabel('快轴/m');
%     end
    fid=fopen('data.bin','wb');
    fwrite(fid, data, 'float64');
    fclose(fid);
end