clc;close all;clear all;
% ϵͳ����
his_length=65536;
his_resol=4e-3; % ��λns
pulse_width=0.5;% ��������ȣ���λns
laser_repetition=1e6; % ��������Ƶ�ʣ���λHz
point_axis=31;
fast_voltage=repmat((linspace(1.5,-1.5,point_axis))',[1,point_axis]);%ת��Xת�ǵ�ѹ,����
slow_voltage=repmat(linspace(1.1,-1.1,point_axis),[point_axis,1]);%ת��Yת�ǵ�ѹ������
C=299552816;    %�����й���

fid1 = fopen('E:\matlab_file\spl_driver_V5\reference\2024-7-12-23-51-36-0-0.txt','r');
data= fread(fid1,inf,'uint32');%��һ��ֱ��ͼ���
data_split=reshape(data,[his_length,length(data)/his_length]);
[row,col]=size(data_split);
time_flight=zeros([col,1]);
flux=zeros([col,1]);
% for i=1:col
%     [time_flight(i),flux(i)]=distance_calculation(data_split(:,i),his_resol,his_length,laser_repetition,pulse_width);
% end
load('zhixin.mat');
flight_time2location;
