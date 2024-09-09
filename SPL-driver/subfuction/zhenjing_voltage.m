% �񾵵�ѹ����������
% �������������С���󣩣��������£������С����
function [fast_voltage_array,slow_voltage_array]=zhenjing_voltage(fast_num_point, fast_upper_voltage, fast_lower_voltage, slow_num_point, slow_upper_voltage, slow_lower_voltage)
    % ���������ѹֵ�Ƿ񳬹��߽�ֵ������������б���
    if fast_upper_voltage>3 ||fast_lower_voltage<-3||slow_upper_voltage>3||slow_lower_voltage<-3
        disp('���棺��ֵ���ڡ�3V��');
        error('��ֵ��3V��ֹͣ����');
    else
        fast_voltage=linspace(fast_lower_voltage,fast_upper_voltage,fast_num_point);
        fast_voltage_array=repmat(fast_voltage,[1,slow_num_point])';
        slow_voltage=linspace(slow_lower_voltage,slow_upper_voltage,slow_num_point);
        a=repmat(slow_voltage,[fast_num_point,1]);
        slow_voltage_array=a(:);
    end
end