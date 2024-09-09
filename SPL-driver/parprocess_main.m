clc;clear all;close all;
% �������г�
poolobj = gcp();

% �������ݲɼ�������
future_data = parfeval(poolobj, @acquire_data, 1);
% ��ѭ�����ȴ����ݲɼ���ɲ�����
fprintf('���ڲɼ��ʹ�������...\n');
pause(0.05); % ģ�����ݲɼ���Ҫ5����
while 1
    % ����Ƿ����µ����ݲɼ����
        % ��ȡ�Ѿ���ɵ����ݲɼ����
        data = fetchOutputs(future_data);
        
        % ͬʱ�������ݴ�������
        future_result = parfeval(poolobj, @process_data, 1, data);
        
        % ����������һ�����ݲɼ�������
        future_data = parfeval(poolobj, @acquire_data, 1);
    
    % ��ѡ��������������һЩ�����Ĵ������
    pause(0.02); % �ȴ�һ��ʱ�䣬���Ը���ʵ���������
    % ��ȡ���һ��������
result = fetchOutputs(future_result);
fprintf('�������ݴ�����ɣ����մ�����Ϊ: %f\n', result);
end


% % �����г�
% delete(poolobj);

% ���ݲɼ�����
function data = acquire_data()
    fprintf('���ڲɼ�����...\n');
    % ����ģ�����ݲɼ��Ĺ��̣�ʵ���п����ǴӴ��������ļ�������Դ��ȡ����
    pause(0.01); % ģ�����ݲɼ���Ҫ5����
    data = rand(1, 2); % ����ɼ���һ������Ϊ10���������
    fprintf('data=%5d\n',data);
end

% ���ݴ�����
function result = process_data(data)
    fprintf('���ڴ�������...\n');
    % ����ģ�����ݴ���Ĺ��̣��������κ����ݴ������
    result = sum(data); % �������ݴ�������Ͳ���
    fprintf('data=%5d\n',result);
end
