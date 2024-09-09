clc; clear all; close all;
%扫描平面范围
yaw1 = -4900;  %方向角范围（A1）初始位置
yaw2 = -2300;   %方向角范围（A1）结束位置
pitch1 = 4600; %俯仰角范围（A2）初始位置
pitch2 = 7000;  %俯仰角范围（A2）结束位置
%扫描步长
angle_step = 100; 
%扫描停顿时间,单位s
Tacq  = 5*1e3;    %  you can change this 单位：ms
%A1扫描方向
forward = true;
%扫描点数量
points_number = ((abs(yaw1)+abs(yaw2))/angle_step)*((abs(pitch1)+abs(pitch2))/angle_step);
%元胞{A1,A2,T3}
data = cell(points_number,1);
%新坐标系相对于旧坐标系的平移向量[tx,ty,tz]，即新坐标系沿x轴向前平移6cm，y轴向后平移10cm，沿z轴向下平移10cm
translation_vector=[0.06,-0.1,-0.1];
point_total=[];
receivedDone = false;
%TH260l初始化
[TTREADMAX,FLAG_FIFOFULL,dev] = Initialization(Tacq);

buffer  = uint32(zeros(1,TTREADMAX));
bufferptr = libpointer('uint32Ptr', buffer);

nactual = int32(0);
nactualptr = libpointer('int32Ptr', nactual);

ctcdone = int32(0);
ctcdonePtr = libpointer('int32Ptr', ctcdone); 

seq2offset=0;
truetime  = [];
truetime1  = [];
dtime  = [];
T3 = [];
     
%设置扫描平台 COM4 的串口对象
s_send = serial('COM4', 'BaudRate',9600);
fopen(s_send);%打开串口


%扫描平台转至初始位置A1
angle_A1= yaw1;
command =  ['H11,',num2str(angle_A1),',20,10E']; % 要发送的指令,相对角度0.05°
fprintf(s_send, command);
check_rotation(s_send);

%扫描平台转至初始位置A2
angle_A2 = pitch1;
command = ['H21,',num2str(angle_A2),',20,10E']; 
fprintf(s_send, command);
check_rotation(s_send);

%扫描开始
i = 0;
while(angle_A2 <= pitch2) 
    i=i+1;
    T2=[];
    T3 = [];
    %调用 TH260_GetFlags 检查设备状态
    flags = int32(0);
    flagsPtr = libpointer('int32Ptr', flags);
    [ret,flags] = calllib('TH260lib', 'TH260_GetFlags', dev(1), flagsPtr);
    if (ret<0)
    	  fprintf('\nTH260_GetFlags error %s. Aborted.\n', geterrorstring(ret));
    	  break
    end
    if (bitand(uint32(flags),FLAG_FIFOFULL)) 
        fprintf('\nFiFo Overrun!\n'); 
        break;
    end
    
    %控制扫描平台的水平扫描方向（A1）
    if forward == true
        angle_A1 = angle_A1 + angle_step;
    else
        angle_A1 = angle_A1 - angle_step;
    end
    
    %转动A1
    command = ['H11,',num2str(angle_A1),',20,10E']; 
    fprintf(s_send, command);
    check_rotation(s_send);
    
    %A1到达临界值，转动A2
    if angle_A1 == yaw2
        angle_A2 = angle_A2 + angle_step;
        command = ['H21,',num2str(angle_A2),',20,10E']; % 发送指令,A2绝对角度
        fprintf(s_send, command);
        check_rotation(s_send);
        forward = false;     
    end
    if angle_A1 == yaw1
        angle_A2 = angle_A2 + angle_step;
        command = ['H21,',num2str(angle_A2),',20,10E']; % 发送指令,A2绝对角度°
        fprintf(s_send, command);
        check_rotation(s_send);
        forward = true;   
    end
    
    %打开TH260
    ret = calllib('TH260lib', 'TH260_StartMeas', dev(1),Tacq); 
    if (ret<0)
        fprintf('\nTH260_StartMeas error %s. Aborted.\n', geterrorstring(ret));
        closedev;
    end
     
     while ~receivedDone
         %读取buffer，nactual为buffer长度
        [ret, buffer, nactual] = calllib('TH260lib','TH260_ReadFiFo', dev(1), bufferptr, TTREADMAX, nactualptr);
        if (ret<0)  
            fprintf('\nTH260_ReadFiFo error %s. Aborted.\n', geterrorstring(ret)); 
            break;
        end 
        %处理飞行时间T3
        if nactual        
           [truetime1,dtime1,isoffset]=buffer2dec(buffer(1:nactual),seq2offset);    
            seq2offset=seq2offset+isoffset;    
            %对分段的缓存拼接
            T2(1,1+length(T2):length(truetime1)+length(T2))=truetime1;
            T3(1,1+length(T3):length(dtime1)+length(T3))=dtime1;
        else
            [ret,ctcdone] = calllib('TH260lib', 'TH260_CTCStatus', dev(1), ctcdonePtr);
            if (ret<0)  
                fprintf('\nTH260_CTCStatus error %s. Aborted.\n', geterrorstring(ret)); 
                break;
            end       
            if (ctcdone) 
                %fprintf('\nCTCDone\n'); 
                break;
            end
        end
     end
     
    %disp(size(T2));
    if find(diff(T2)<0)         %判断是否丢包
        break;
    end
   
    
    %关闭TH260
    ret = calllib('TH260lib', 'TH260_StopMeas', dev(1)); 
    if (ret<0)
        fprintf('\nTH260_StopMeas error %s. Aborted.\n', geterrorstring(ret));
        closedev;
        return;
    end  

    disp(['angle_A1: ', num2str(angle_A1),'，angle_A2: ', num2str(angle_A2)]);
    data{i} = {angle_A1,angle_A2,T2,T3};

end %while

%关闭所有设备
fclose(s_send); 
closedev;   
fprintf('finish');



