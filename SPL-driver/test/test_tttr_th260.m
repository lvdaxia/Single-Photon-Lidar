clc;clear all;close all;
%% 参数设置
Tacq=5e3; %  you can change this 单位：ms 采集时间
Mode=3; %其中Mode为2表示T2模式，mode为3表示T3模式
%% 初始化
global sync_time;    sync_time=0;
global cnt_ov;   cnt_ov=0;% 溢出次数  T3模式每1024个同步脉冲会溢出一个
global OverflowCorrection; OverflowCorrection = 0;

[TTREADMAX,FLAG_FIFOFULL,dev,Resolution,laser_period] = Initialization_TH_260(Tacq,Mode);

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
%% 打开TH260
[ret,flags] = calllib('TH260lib', 'TH260_GetFlags', dev(1), flagsPtr);
if (ret<0)
      fprintf('\nTH260_GetFlags error %s. Aborted.\n', geterrorstring(ret));
end
if (bitand(uint32(flags),FLAG_FIFOFULL)) 
    fprintf('\nFiFo Overrun!\n'); 
end

ret = calllib('TH260lib', 'TH260_StartMeas', dev(1),Tacq); 
if (ret<0)
    fprintf('\nTH260_StartMeas error %s. Aborted.\n', geterrorstring(ret));
    closedev;
end
%% 循环读取数据，保证不漏数
 while ~receivedDone
     %读取buffer，nactual为buffer长度
    [ret, buffer, nactual] = calllib('TH260lib','TH260_ReadFiFo', dev(1), bufferptr, TTREADMAX, nactualptr);
    if (ret<0)  
        fprintf('\nTH260_ReadFiFo error %s. Aborted.\n', geterrorstring(ret)); 
        break;
    end 
    %处理飞行时间T3
    if nactual        
        [ph_record_time,ph_flight_time]=tttr_read(buffer(1:nactual),Mode);
        %对分段的缓存拼接
        Record_time(1,1+length(Record_time):length(ph_record_time)+length(Record_time))=ph_record_time;
        flight_time(1,1+length(flight_time):length(ph_flight_time)+length(flight_time))=ph_flight_time;
        if Mode==2
            figure(1);
            plot(Record_time*Resolution*1e-12,Resolution/1000*flight_time,'.');xlabel('时间/s');ylabel('飞行时间/ns');
        elseif Mode==3
            figure(1);
            plot(Record_time*laser_period,Resolution/1000*flight_time,'.');xlabel('时间/s');ylabel('飞行时间/ns');
        else
            fprintf('仅支持T2和T3模式！！！');
        end
    else
        [ret,ctcdone] = calllib('TH260lib', 'TH260_CTCStatus', dev(1), ctcdonePtr);
        if (ret<0)  
            fprintf('\nTH260_CTCStatus error %s. Aborted.\n', geterrorstring(ret)); 
            break;
        end       
        if (ctcdone) 
            fprintf('\nCTCDone\n'); 
            break;
        end
    end
 end

% 停止测量
ret = calllib('TH260lib', 'TH260_StopMeas', dev(1)); 
if (ret<0)
    fprintf('\nTH260_StopMeas error %s. Aborted.\n', geterrorstring(ret));
    closedev;
    return;
end  
%% 关闭所有设备TH260/HH400
closedev;
fprintf('finish\n');