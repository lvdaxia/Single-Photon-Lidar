%% ������̽�⼤���״�ʵʱ��������
% ������T2��T3���ݵ�ʵʱ��ȡ
% by linjie lyu
% 2024��07��22��

clc;clear all;close all;
%% ��������
Tacq=1e3; %  you can change this ��λ��ms �ɼ�ʱ��
Mode=2; %����ModeΪ2��ʾT2ģʽ��modeΪ3��ʾT3ģʽ
%% ��ʼ��
global sync_time;    sync_time=0;
global cnt_ov;   cnt_ov=0;% �������  T3ģʽÿ1024��ͬ����������һ��
global OverflowCorrection; OverflowCorrection = 0;

% �����񾵵�ѹֵ
[fast_voltage_array,slow_voltage_array]=zhenjing_voltage(3, -1, -3, 3, -0.5, -3);

% daq_fast = daqmx_Task('dev1/ao0');  % create control object.
% daq_slow = daqmx_Task('dev1/ao1');  % create control object.

% ������TH260l��ʼ��
 [TTREADMAX,FLAG_FIFOFULL,dev,Resolution,laser_period] = Initialization_TH_260(Tacq,Mode);
% [TTREADMAX,FLAG_FIFOFULL,dev,Resolution,laser_period] = Initialization_HH_400(Tacq,Mode);
buffer  = uint32(zeros(1,TTREADMAX));
bufferptr = libpointer('uint32Ptr', buffer);

nactual = int32(0);
nactualptr = libpointer('int32Ptr', nactual);

ctcdone = int32(0);
ctcdonePtr = libpointer('int32Ptr', ctcdone); 
receivedDone=false;

Record_time=[];
flight_time=[];
flags = int32(0);
flagsPtr = libpointer('int32Ptr', flags);
step = 0;

%% ɨ�迪ʼ
while(step<length(fast_voltage_array)) 
    step=step+1;
    disp(['No��', num2str(step)]);
    %���� HH_GetFlags ����豸״̬
    flags = int32(0);
    flagsPtr = libpointer('int32Ptr', flags);
%     [ret,flags] = calllib('HHlib', 'HH_GetFlags', dev(1), flagsPtr);
    [ret,flags] = calllib('TH260lib', 'TH260_GetFlags', dev(1), flagsPtr);
    if (ret<0)
    	  fprintf('\nHH_GetFlags error %ld. Aborted.\n', ret);
    	  break
    end;
    if (bitand(uint32(flags),FLAG_FIFOFULL)) 
        fprintf('\nFiFo Overrun!\n'); 
        break;
    end;
    
%     daq_fast.write(fast_voltage_array(i));
%     daq_slow.write(slow_voltage_array(i));
    
     %��HH
%     ret = calllib('HHlib', 'HH_StartMeas', dev(1),Tacq); 
    ret = calllib('TH260lib', 'TH260_StartMeas', dev(1),Tacq); 
    if (ret<0)
        fprintf('\nHH_StartMeas error %ld. Aborted.\n', ret);
        closedev;
        return;
    end
     
      while ~receivedDone
         %��ȡbuffer��nactualΪbuffer����
%         [ret, buffer, nactual] = calllib('HHlib','HH_ReadFiFo', dev(1), bufferptr, TTREADMAX, nactualptr);
        [ret, buffer, nactual] = calllib('TH260lib','TH260_ReadFiFo', dev(1), bufferptr, TTREADMAX, nactualptr);
        
        if (ret<0)  
            fprintf('\nHH_ReadFiFo error %d\n', ret); 
            break;
        end 
        %�������ʱ��T3
        if nactual   
            [ph_record_time,ph_flight_time]=tttr_read(buffer(1:nactual),Mode);
            %�ԷֶεĻ���ƴ��
%             Index_select_RT=1+length(Record_time):length(ph_record_time)+length(Record_time);
%             Index_select_FT=1+length(flight_time):length(ph_flight_time)+length(flight_time);
%             Record_time(1,Index_select_RT)=ph_record_time;
%             flight_time(1,Index_select_FT)=ph_flight_time;
            Record_time=[Record_time; ph_record_time];
            flight_time=[flight_time; ph_flight_time];
            if Mode==2
                figure(1);
                plot(Record_time*Resolution*1e-12,Resolution/1000*flight_time,'.');xlabel('ʱ��/s');ylabel('����ʱ��/ns');ylim([0 3e5]);
            elseif Mode==3
                figure(1);
                plot(Record_time*laser_period,Resolution/1000*flight_time,'.');xlabel('ʱ��/s');ylabel('����ʱ��/ns');
            else
                fprintf('��֧��T2��T3ģʽ������');
            end
        else
%             [ret,ctcdone] = calllib('HHlib', 'HH_CTCStatus', dev(1), ctcdonePtr);
            [ret,ctcdone] = calllib('TH260lib', 'TH260_CTCStatus', dev(1), ctcdonePtr);
            if (ret<0)  
                fprintf('\nHH_CTCStatus error %d\n',ret); 
                break;
            end;       
            if (ctcdone) 
                fprintf('\nCTCDone\n'); 
                break;
            end;
        end
      end
     
%     %disp(size(T2));
%     if find(diff(T2)<0)         %�ж��Ƿ񶪰�
%         break;
%     end
%     
    %�ر�HH
%     ret = calllib('HHlib', 'HH_StopMeas', dev(1)); 
    ret = calllib('TH260lib', 'TH260_StopMeas', dev(1)); 
    if (ret<0)
        fprintf('\nHH_StopMeas error %ld. Aborted.\n', ret);
        closedev;
        return;
    end  
        
    disp(['angle_fast: ', num2str(fast_voltage_array(step)),'��angle_slow: ', num2str(slow_voltage_array(step))]);
    data{step} = {fast_voltage_array(step),slow_voltage_array(step),Record_time,flight_time};
    Record_time=[];flight_time=[];OverflowCorrection = 0;
end %while

%% �ر������豸
closedev;
fprintf('finish\n');
