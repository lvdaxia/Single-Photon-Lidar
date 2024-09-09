%% 单光子探测激光雷达实时驱动程序
% 可用于T2和T3数据的实时读取
% by linjie lyu
% 2024年07月22日

clc;clear all;close all;
%% 参数设置
Tacq=1e3; %  you can change this 单位：ms 采集时间
Mode=2; %其中Mode为2表示T2模式，mode为3表示T3模式
%% 初始化
global sync_time;    sync_time=0;
global cnt_ov;   cnt_ov=0;% 溢出次数  T3模式每1024个同步脉冲会溢出一个
global OverflowCorrection; OverflowCorrection = 0;

% 生成振镜电压值
[fast_voltage_array,slow_voltage_array]=zhenjing_voltage(3, -1, -3, 3, -0.5, -3);

% daq_fast = daqmx_Task('dev1/ao0');  % create control object.
% daq_slow = daqmx_Task('dev1/ao1');  % create control object.

% 计数器TH260l初始化
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

%% 扫描开始
while(step<length(fast_voltage_array)) 
    step=step+1;
    disp(['No：', num2str(step)]);
    %调用 HH_GetFlags 检查设备状态
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
    
     %打开HH
%     ret = calllib('HHlib', 'HH_StartMeas', dev(1),Tacq); 
    ret = calllib('TH260lib', 'TH260_StartMeas', dev(1),Tacq); 
    if (ret<0)
        fprintf('\nHH_StartMeas error %ld. Aborted.\n', ret);
        closedev;
        return;
    end
     
      while ~receivedDone
         %读取buffer，nactual为buffer长度
%         [ret, buffer, nactual] = calllib('HHlib','HH_ReadFiFo', dev(1), bufferptr, TTREADMAX, nactualptr);
        [ret, buffer, nactual] = calllib('TH260lib','TH260_ReadFiFo', dev(1), bufferptr, TTREADMAX, nactualptr);
        
        if (ret<0)  
            fprintf('\nHH_ReadFiFo error %d\n', ret); 
            break;
        end 
        %处理飞行时间T3
        if nactual   
            [ph_record_time,ph_flight_time]=tttr_read(buffer(1:nactual),Mode);
            %对分段的缓存拼接
%             Index_select_RT=1+length(Record_time):length(ph_record_time)+length(Record_time);
%             Index_select_FT=1+length(flight_time):length(ph_flight_time)+length(flight_time);
%             Record_time(1,Index_select_RT)=ph_record_time;
%             flight_time(1,Index_select_FT)=ph_flight_time;
            Record_time=[Record_time; ph_record_time];
            flight_time=[flight_time; ph_flight_time];
            if Mode==2
                figure(1);
                plot(Record_time*Resolution*1e-12,Resolution/1000*flight_time,'.');xlabel('时间/s');ylabel('飞行时间/ns');ylim([0 3e5]);
            elseif Mode==3
                figure(1);
                plot(Record_time*laser_period,Resolution/1000*flight_time,'.');xlabel('时间/s');ylabel('飞行时间/ns');
            else
                fprintf('仅支持T2和T3模式！！！');
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
%     if find(diff(T2)<0)         %判断是否丢包
%         break;
%     end
%     
    %关闭HH
%     ret = calllib('HHlib', 'HH_StopMeas', dev(1)); 
    ret = calllib('TH260lib', 'TH260_StopMeas', dev(1)); 
    if (ret<0)
        fprintf('\nHH_StopMeas error %ld. Aborted.\n', ret);
        closedev;
        return;
    end  
        
    disp(['angle_fast: ', num2str(fast_voltage_array(step)),'，angle_slow: ', num2str(slow_voltage_array(step))]);
    data{step} = {fast_voltage_array(step),slow_voltage_array(step),Record_time,flight_time};
    Record_time=[];flight_time=[];OverflowCorrection = 0;
end %while

%% 关闭所有设备
closedev;
fprintf('finish\n');
