clc; clear all; close all;
%ɨ��ƽ�淶Χ
yaw1 = -4900;  %����Ƿ�Χ��A1����ʼλ��
yaw2 = -2300;   %����Ƿ�Χ��A1������λ��
pitch1 = 4600; %�����Ƿ�Χ��A2����ʼλ��
pitch2 = 7000;  %�����Ƿ�Χ��A2������λ��
%ɨ�貽��
angle_step = 100; 
%ɨ��ͣ��ʱ��,��λs
Tacq  = 5*1e3;    %  you can change this ��λ��ms
%A1ɨ�跽��
forward = true;
%ɨ�������
points_number = ((abs(yaw1)+abs(yaw2))/angle_step)*((abs(pitch1)+abs(pitch2))/angle_step);
%Ԫ��{A1,A2,T3}
data = cell(points_number,1);
%������ϵ����ھ�����ϵ��ƽ������[tx,ty,tz]����������ϵ��x����ǰƽ��6cm��y�����ƽ��10cm����z������ƽ��10cm
translation_vector=[0.06,-0.1,-0.1];
point_total=[];
receivedDone = false;
%TH260l��ʼ��
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
     
%����ɨ��ƽ̨ COM4 �Ĵ��ڶ���
s_send = serial('COM4', 'BaudRate',9600);
fopen(s_send);%�򿪴���


%ɨ��ƽ̨ת����ʼλ��A1
angle_A1= yaw1;
command =  ['H11,',num2str(angle_A1),',20,10E']; % Ҫ���͵�ָ��,��ԽǶ�0.05��
fprintf(s_send, command);
check_rotation(s_send);

%ɨ��ƽ̨ת����ʼλ��A2
angle_A2 = pitch1;
command = ['H21,',num2str(angle_A2),',20,10E']; 
fprintf(s_send, command);
check_rotation(s_send);

%ɨ�迪ʼ
i = 0;
while(angle_A2 <= pitch2) 
    i=i+1;
    T2=[];
    T3 = [];
    %���� TH260_GetFlags ����豸״̬
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
    
    %����ɨ��ƽ̨��ˮƽɨ�跽��A1��
    if forward == true
        angle_A1 = angle_A1 + angle_step;
    else
        angle_A1 = angle_A1 - angle_step;
    end
    
    %ת��A1
    command = ['H11,',num2str(angle_A1),',20,10E']; 
    fprintf(s_send, command);
    check_rotation(s_send);
    
    %A1�����ٽ�ֵ��ת��A2
    if angle_A1 == yaw2
        angle_A2 = angle_A2 + angle_step;
        command = ['H21,',num2str(angle_A2),',20,10E']; % ����ָ��,A2���ԽǶ�
        fprintf(s_send, command);
        check_rotation(s_send);
        forward = false;     
    end
    if angle_A1 == yaw1
        angle_A2 = angle_A2 + angle_step;
        command = ['H21,',num2str(angle_A2),',20,10E']; % ����ָ��,A2���ԽǶȡ�
        fprintf(s_send, command);
        check_rotation(s_send);
        forward = true;   
    end
    
    %��TH260
    ret = calllib('TH260lib', 'TH260_StartMeas', dev(1),Tacq); 
    if (ret<0)
        fprintf('\nTH260_StartMeas error %s. Aborted.\n', geterrorstring(ret));
        closedev;
    end
     
     while ~receivedDone
         %��ȡbuffer��nactualΪbuffer����
        [ret, buffer, nactual] = calllib('TH260lib','TH260_ReadFiFo', dev(1), bufferptr, TTREADMAX, nactualptr);
        if (ret<0)  
            fprintf('\nTH260_ReadFiFo error %s. Aborted.\n', geterrorstring(ret)); 
            break;
        end 
        %�������ʱ��T3
        if nactual        
           [truetime1,dtime1,isoffset]=buffer2dec(buffer(1:nactual),seq2offset);    
            seq2offset=seq2offset+isoffset;    
            %�ԷֶεĻ���ƴ��
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
    if find(diff(T2)<0)         %�ж��Ƿ񶪰�
        break;
    end
   
    
    %�ر�TH260
    ret = calllib('TH260lib', 'TH260_StopMeas', dev(1)); 
    if (ret<0)
        fprintf('\nTH260_StopMeas error %s. Aborted.\n', geterrorstring(ret));
        closedev;
        return;
    end  

    disp(['angle_A1: ', num2str(angle_A1),'��angle_A2: ', num2str(angle_A2)]);
    data{i} = {angle_A1,angle_A2,T2,T3};

end %while

%�ر������豸
fclose(s_send); 
closedev;   
fprintf('finish');



