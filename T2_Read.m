close all;clc;clear;

bianjie_right=5*10^4;
f=0.025;
file=importdata('D:\1.北京航空航天大学\9.实验\实验数据\实验3(高精度调试)\20230228\20230228-2-xiu.txt');
s=file(:,2);
CH=file(:,1);
[length,~]=size(file) ;
CHis0=find(CH==0);
[length_CHis0,~]=size(CHis0);
bin(1:length-length_CHis0-CHis0(1))=0;
bin_t(1:length-length_CHis0-CHis0(1))=0;% 真实时间
bin_i=0;
for i=1:length_CHis0-1
    for j=CHis0(i)+1:CHis0(i+1)-1
        bin_i=bin_i+1;
        bin(bin_i)=s(j)-s(CHis0(i));
        bin_t(bin_i)=f*s(j);
    end
%     waitbar(i/length_CHis0);
end
if CHis0(end)~=length_CHis0
    for k=CHis0(end)+1:length
        bin_i=bin_i+1;
        bin(bin_i)=s(k)-s(CHis0(end));
        bin_t(bin_i)=f*s(k);
    end
end
figure(1);
scatter(bin_t,f*bin,'.');ylim([1,2000]);xlabel('测量时间/ns');ylabel('飞行时间/ns');
% save('20230228-1-bin_t','bin_t');
% save('20230228-1-bin','bin');


% 输出为txt文件
% file_name='D:\1.北京航空航天大学\9.实验\实验数据\实验3(高精度调试)\20230228\20230228_after_matlab.txt';
% fid=fopen(file_name,'a');
% [~,length_bin]=size(bin);
% for z=1:floor(length_bin/6)  % 参数9 输出文件大小
%      if f*bin<3e4
%         fprintf(fid,'%d\t',bin_t(1,z));
%         fprintf(fid,'%d\n',bin(1,z));
%     end
% end
% fclose(fid);