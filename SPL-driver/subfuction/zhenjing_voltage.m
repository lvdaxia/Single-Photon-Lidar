% 振镜电压工作点生成
% 从右往左（慢轴从小到大），从上往下（快轴从小到大）
function [fast_voltage_array,slow_voltage_array]=zhenjing_voltage(fast_num_point, fast_upper_voltage, fast_lower_voltage, slow_num_point, slow_upper_voltage, slow_lower_voltage)
    % 检验输入电压值是否超过边界值，如果超过进行报警
    if fast_upper_voltage>3 ||fast_lower_voltage<-3||slow_upper_voltage>3||slow_lower_voltage<-3
        disp('警告：数值大于±3V！');
        error('数值±3V，停止运行');
    else
        fast_voltage=linspace(fast_lower_voltage,fast_upper_voltage,fast_num_point);
        fast_voltage_array=repmat(fast_voltage,[1,slow_num_point])';
        slow_voltage=linspace(slow_lower_voltage,slow_upper_voltage,slow_num_point);
        a=repmat(slow_voltage,[fast_num_point,1]);
        slow_voltage_array=a(:);
    end
end