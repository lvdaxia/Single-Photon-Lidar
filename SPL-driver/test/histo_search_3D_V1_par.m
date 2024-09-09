%% 单光子探测激光雷达实时驱动程序
% 可用于直方图数据的实时读取
% 振镜的扫描
% by linjie lyu
% 2024年07月26日
% 采用并行处理方式
clc;clear all;close all;
%% 参数设置
Tacq=0.002e3; %  you can change this 单位：ms 采集时间
Mode=0; %其中Mode为2表示T2模式，mode为3表示T3模式,mode=0表示直方图模式
Binning=11; % 计数器时间分辨率
pulse_width=0.07;

%% 生成振镜电压值
[fast_voltage_array,slow_voltage_array]=zhenjing_voltage(50, -0.2, -0.9, 50, 0.5, -0.5);
daq_fast = daqmx_Task('dev1/ao0');  % create control object.
daq_slow = daqmx_Task('dev1/ao1');  % create control object.

%% 计数器TH260l初始化
%[MAXHISTBINS,FLAG_OVERFLOW, dev, Resolution,NumInpChannels]=histomode_init_HH_400(Mode,Binning);
histo_init_HH400;
Resolution=Resolution_ps/1000;
if isempty(gcp('nocreate'))
    parpool; % 创建并行池
end

%% 预先分配内存
num_steps = length(fast_voltage_array); % 振镜扫描步数
count_all = cell(1, num_steps);
flight_time = zeros(1, num_steps);
flux = zeros(1, num_steps);
slow_axis = zeros(1, num_steps);
fast_axis = zeros(1, num_steps);
Depth_array = zeros(1, num_steps);
future=cell(num_steps);
output=cell(1, num_steps);
step = 0;
tic;
    %% 扫描开始
while(step<num_steps) 
    step=step+1;
    histo_clear_meas_HH400;
    disp(['No：', num2str(step)]);
    daq_fast.write(fast_voltage_array(step));
    daq_slow.write(slow_voltage_array(step));
     %打开HH
    histo_start_meas_HH400;

    ctcdone = int32(0);
    ctcdonePtr = libpointer('int32Ptr', ctcdone);
    while (ctcdone==0)
        [ret,ctcdone] = calllib('HHlib', 'HH_CTCStatus', dev(1), ctcdonePtr);
    end; 

    histo_stop_meas_HH400;

    [countsbuffer_all]=histo_read_HH400(MAXHISTBINS,NumInpChannels,dev,FLAG_OVERFLOW);
    countsbuffer=double(countsbuffer_all(1,:));
%         figure(1),plot((1:length(countsbuffer))*Resolution,countsbuffer');xlabel('飞行时间/ns');ylabel('counts');
    count_all{step}={fast_voltage_array(step),slow_voltage_array(step),countsbuffer};
%     [time_flight,flux(step)]=flight_time_calculation(countsbuffer,Resolution,length(countsbuffer),double(Syncrate),pulse_width);
%     [output{step}]=flight_time_calculation(countsbuffer,Resolution,length(countsbuffer),double(Syncrate),pulse_width,fast_voltage_array(step),slow_voltage_array(step));
    future{step}= parfeval(@flight_time_calculation, 1, countsbuffer, Resolution,length(countsbuffer),double(Syncrate),pulse_width,fast_voltage_array(step),slow_voltage_array(step));
%          figure(3);scatter3(Depth_array,slow_axis,fast_axis,'b.');hold on;xlabel('深度/m');ylabel('慢轴/m');zlabel('快轴/m');
end %while
toc;
 figure(3);scatter3(slow_axis,fast_axis,Depth_array,'b.');hold on;
 xlabel('快轴/m'); ylabel('慢轴/m');zlabel('深度/m');
%% 关闭所有设备
closedev;
fprintf('finish\n');
% 删除并行池
delete(gcp('nocreate'));
