clc;clear all;close all;
%% 参数设置
Tacq=10e3; %  you can change this 单位：ms 采集时间
Mode=3; %其中Mode为2表示T2模式，mode为3表示T3模式
Binning=2;
%% 初始化
global sync_time;    sync_time=0;
global cnt_ov;   cnt_ov=0;% 溢出次数  T3模式每1024个同步脉冲会溢出一个
global OverflowCorrection; OverflowCorrection = 0;

% [TTREADMAX,FLAG_FIFOFULL,dev,Resolution,laser_period] = Initialization_TH_260(Tacq,Mode);
[TTREADMAX,FLAG_FIFOFULL,dev,Resolution,laser_period, ~] = Initialization_HH_400(Tacq,Mode,Binning);

buffer  = uint32(zeros(1,TTREADMAX));
bufferptr = libpointer('uint32Ptr', buffer);

nactual = int32(0);
nactualptr = libpointer('int32Ptr', nactual);

ctcdone = int32(0);
ctcdonePtr = libpointer('int32Ptr', ctcdone); 
receivedDone=false;

flags = int32(0);
flagsPtr = libpointer('int32Ptr', flags);
Record_time=[];
flight_time=[];
buffer_all=[];
%% 打开TH260
% [ret,flags] = calllib('TH260lib', 'TH260_GetFlags', dev(1), flagsPtr);

%调用 HH_GetFlags 检查设备状态
[ret,flags] = calllib('HHlib', 'HH_GetFlags', dev(1), flagsPtr);
%     [ret,flags] = calllib('TH260lib', 'TH260_GetFlags', dev(1), flagsPtr);
if (ret<0)
      fprintf('\nHH_GetFlags error %ld. Aborted.\n', ret);
end;
if (bitand(uint32(flags),FLAG_FIFOFULL)) 
    fprintf('\nFiFo Overrun!\n'); 
end;

% 打开HH
ret = calllib('HHlib', 'HH_StartMeas', dev(1),Tacq); 
%     ret = calllib('TH260lib', 'TH260_StartMeas', dev(1),Tacq); 
if (ret<0)
    fprintf('\nHH_StartMeas error %ld. Aborted.\n', ret);
    closedev;
    return;
end
%% 循环读取数据，保证不漏数
 while ~receivedDone
         %读取buffer，nactual为buffer长度
        [ret, buffer, nactual] = calllib('HHlib','HH_ReadFiFo', dev(1), bufferptr, TTREADMAX, nactualptr);
%         [ret, buffer, nactual] = calllib('TH260lib','TH260_ReadFiFo', dev(1), bufferptr, TTREADMAX, nactualptr);
        
        if (ret<0)  
            fprintf('\nHH_ReadFiFo error %d\n', ret); 
            break;
        end 
        buffer_all(1,length(buffer_all)+1:length(buffer_all)+nactual)=buffer(1,1:nactual);
    %处理飞行时间T3
    if nactual
    else
        [ret,ctcdone] = calllib('HHlib', 'HH_CTCStatus', dev(1), ctcdonePtr);
%             [ret,ctcdone] = calllib('TH260lib', 'TH260_CTCStatus', dev(1), ctcdonePtr);
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

% 停止测量
HH_StopMeas;
%% 关闭所有设备TH260/HH400
closedev;
fprintf('finish\n');