time_flight_mat=reshape(time_flight,[point_axis,point_axis]);
time_flight_mat=reshape(time_flight,[point_axis,point_axis]);
%slow_array,fast_array,Depth_array
[slow_array,fast_array,Depth_array]=location(fast_voltage,slow_voltage,time_flight_mat,C);
scatter_plot(Depth_array,slow_array,fast_array);
scatter_plot_intensity(Depth_array,slow_array,fast_array,flux);



function [slow_array,fast_array,Depth_array]=location(fast_voltage,slow_voltage,flight_time,C)
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
end
function []=scatter_plot_intensity(Depth_array,slow_array,fast_array,flux)
    figure(4);
    scatter3(Depth_array,slow_array,fast_array,10, flux, 'filled');xlabel("distance/m");ylabel("左右");zlabel("上下");colormap gray;
    xlim([0.8,1.3]);ylim([-0.2,0.2]),zlim([-0.15,0.15]);
    % 设置标题和颜色条
    colormap gray;
    colorbar;  % 添加颜色条
    max_flux=max(flux);
    min_flux=min(flux);
    rangeRefl = [min_flux,max_flux]; % 根据探测概率进行更改  有关图像
    caxis(rangeRefl);  % 设置颜色条范围为强度值的最小值和最大值1:
    set(gca,'color','k','gridcolor','w','FontSize',18);
    title_str=sprintf('Scatter Plot with intensity');
    title(title_str);
end
function []=scatter_plot(Depth_array,slow_array,fast_array)
    figure(2);
    scatter3(Depth_array,slow_array,fast_array,10,Depth_array,'filled');xlabel("distance/m");ylabel("左右");zlabel("上下");
    xlim([0.8,1.3]);ylim([-0.2,0.2]),zlim([-0.15,0.15]);
    title_str=sprintf('Scatter Plot');
    title(title_str);
    colormap parula;
    colorbar;  % 添加颜色条
    rangeRefl = [0.8,1.3];
    caxis(rangeRefl);  % 设置颜色条范围为强度值的最小值和最大值1:
    set(gca,'color','k','gridcolor','w','FontSize',18);
end