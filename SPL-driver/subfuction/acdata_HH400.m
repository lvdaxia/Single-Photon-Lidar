clc;clear all;close all;
%% ��������
Tacq=10e3; %  you can change this ��λ��ms �ɼ�ʱ��
Mode=3; %����ModeΪ2��ʾT2ģʽ��modeΪ3��ʾT3ģʽ
Binning=2;
%% ��ʼ��
global sync_time;    sync_time=0;
global cnt_ov;   cnt_ov=0;% �������  T3ģʽÿ1024��ͬ����������һ��
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
%% ��TH260
% [ret,flags] = calllib('TH260lib', 'TH260_GetFlags', dev(1), flagsPtr);

%���� HH_GetFlags ����豸״̬
[ret,flags] = calllib('HHlib', 'HH_GetFlags', dev(1), flagsPtr);
%     [ret,flags] = calllib('TH260lib', 'TH260_GetFlags', dev(1), flagsPtr);
if (ret<0)
      fprintf('\nHH_GetFlags error %ld. Aborted.\n', ret);
end;
if (bitand(uint32(flags),FLAG_FIFOFULL)) 
    fprintf('\nFiFo Overrun!\n'); 
end;

% ��HH
ret = calllib('HHlib', 'HH_StartMeas', dev(1),Tacq); 
%     ret = calllib('TH260lib', 'TH260_StartMeas', dev(1),Tacq); 
if (ret<0)
    fprintf('\nHH_StartMeas error %ld. Aborted.\n', ret);
    closedev;
    return;
end
%% ѭ����ȡ���ݣ���֤��©��
 while ~receivedDone
         %��ȡbuffer��nactualΪbuffer����
        [ret, buffer, nactual] = calllib('HHlib','HH_ReadFiFo', dev(1), bufferptr, TTREADMAX, nactualptr);
%         [ret, buffer, nactual] = calllib('TH260lib','TH260_ReadFiFo', dev(1), bufferptr, TTREADMAX, nactualptr);
        
        if (ret<0)  
            fprintf('\nHH_ReadFiFo error %d\n', ret); 
            break;
        end 
        buffer_all(1,length(buffer_all)+1:length(buffer_all)+nactual)=buffer(1,1:nactual);
    %�������ʱ��T3
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

% ֹͣ����
HH_StopMeas;
%% �ر������豸TH260/HH400
closedev;
fprintf('finish\n');