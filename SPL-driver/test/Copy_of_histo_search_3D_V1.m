%% ������̽�⼤���״�ʵʱ��������
% ������ֱ��ͼ���ݵ�ʵʱ��ȡ
% �񾵵�ɨ��
% by linjie lyu
% 2024��07��26��
% ���ò��д���ʽ
clc;clear all;close all;
%% ��������
Tacq=0.2e3; %  you can change this ��λ��ms �ɼ�ʱ��
Mode=0; %����ModeΪ2��ʾT2ģʽ��modeΪ3��ʾT3ģʽ,mode=0��ʾֱ��ͼģʽ
Binning=2; % ������ʱ��ֱ���
pulse_width=0.07;

%% �����񾵵�ѹֵ
[fast_voltage_array,slow_voltage_array]=zhenjing_voltage(200, -0.2, -0.9, 200, 0.5, -0.5);
% daq_fast = daqmx_Task('dev1/ao0');  % create control object.
% daq_slow = daqmx_Task('dev1/ao1');  % create control object.

%% ������TH260l��ʼ��
%[MAXHISTBINS,FLAG_OVERFLOW, dev, Resolution,NumInpChannels]=histomode_init_HH_400(Mode,Binning);
% histo_init_HH400;
Resolution=4/1000;

%% Ԥ�ȷ����ڴ�
num_steps = length(fast_voltage_array); % ��ɨ�貽��
count_all = cell(1, num_steps);
flight_time = zeros(1, num_steps);
flux = zeros(1, num_steps);
slow_axis = zeros(1, num_steps);
fast_axis = zeros(1, num_steps);
Depth_array = zeros(1, num_steps);
step = 30749;
output=cell(1, num_steps- 30749);
future=cell(1, num_steps- 30749);
% ����ѭ��
if isempty(gcp('nocreate'))
    parpool('local',2); % �������г�
end
load('count_all_2.mat');
Syncrate=1000040;
% future=;
    %% ɨ�迪ʼ
    tic;
while(step<num_steps) 
    step=step+1;
%     histo_clear_meas_HH400;
    disp(['No��', num2str(step)]);
%     daq_fast.write(fast_voltage_array(step));
%     daq_slow.write(slow_voltage_array(step));
     %��HH
%     histo_start_meas_HH400;
% 
%     ctcdone = int32(0);
%     ctcdonePtr = libpointer('int32Ptr', ctcdone);
%     while (ctcdone==0)
%         [ret,ctcdone] = calllib('HHlib', 'HH_CTCStatus', dev(1), ctcdonePtr);
%     end; 

%     histo_stop_meas_HH400;

%     [countsbuffer_all]=histo_read_HH400(MAXHISTBINS,NumInpChannels,dev,FLAG_OVERFLOW);
%     countsbuffer=double(countsbuffer_all(1,:));
%         figure(1),plot((1:length(countsbuffer))*Resolution,countsbuffer');xlabel('����ʱ��/ns');ylabel('counts');
%     count_all{step}={fast_voltage_array(step),slow_voltage_array(step),countsbuffer};
    countsbuffer=count_all{step}{3};
%     [time_flight,flux(step)]=flight_time_calculation(countsbuffer,Resolution,length(countsbuffer),double(Syncrate),pulse_width);
    future{step- 30749}= parfeval(@flight_time_calculation, 1, countsbuffer, Resolution,length(countsbuffer),double(Syncrate),pulse_width,fast_voltage_array(step),slow_voltage_array(step));
%  [output{step- 30749}]=flight_time_calculation(countsbuffer,Resolution,length(countsbuffer),double(Syncrate),pulse_width,fast_voltage_array(step),slow_voltage_array(step));
%     wait(future);
%      future_all=fetchOutputs(future);
    
    %     result = parfeval(func, arg1, arg2, ...);
%          figure(3);scatter3(Depth_array,slow_axis,fast_axis,'b.');hold on;xlabel('���/m');ylabel('����/m');zlabel('����/m');
end %while
toc;

 figure(3);scatter3(slow_axis,fast_axis,Depth_array,'b.');hold on;
 xlabel('����/m'); ylabel('����/m');zlabel('���/m');
%% �ر������豸
closedev;
fprintf('finish\n');
% ɾ�����г�
delete(gcp('nocreate'));
