clc;close all;clear all;
% 系统参数
his_length=65536;
his_resol=4e-3; % 单位ns
pulse_width=0.5;% 均方根宽度，单位ns
laser_repetition=1e6; % 激光脉冲频率，单位Hz
point_axis=31;
fast_voltage=repmat((linspace(1.5,-1.5,point_axis))',[1,point_axis]);%转镜X转角电压,上下
slow_voltage=repmat(linspace(1.1,-1.1,point_axis),[point_axis,1]);%转镜Y转角电压，左右
C=299552816;    %空气中光速

fid1 = fopen('E:\matlab_file\spl_driver_V5\reference\2024-7-12-23-51-36-0-0.txt','r');
data= fread(fid1,inf,'uint32');%读一个直方图结果
data_split=reshape(data,[his_length,length(data)/his_length]);
[row,col]=size(data_split);
time_flight=zeros([col,1]);
flux=zeros([col,1]);
% for i=1:col
%     [time_flight(i),flux(i)]=distance_calculation(data_split(:,i),his_resol,his_length,laser_repetition,pulse_width);
% end
load('zhixin.mat');
flight_time2location;
