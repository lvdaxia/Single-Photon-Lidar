clc;clear all;close all;
% ����һ�����г�
parpool('local', 2);

% ����һ��������������ڲ���ִ�е�����
writeToFile = @(fileName, data) writeFileFunction(fileName, data);

% �첽ִ�е�����
futures = [];
for i = 1:2
    fileName = sprintf('output_file_%d.bin', i);  % ���ɲ�ͬ���ļ���
    data = rand(1, 10);  % ����һЩʾ������
    futures(end+1) = parfeval(@(fn, d) writeToFile(fn, d), 0, fileName, data);
end

% �ȴ������������
for i = 1:numel(futures)
    fetchOutputs(futures(i));
end

% �رղ��г�
delete(gcp('nocreate'));

% ����д�ļ��ĺ���
function writeFileFunction(fileName, data)
    fid = fopen(fileName, 'wb');  % ���ļ�
    if fid == -1
        error('Cannot open file: %s', fileName);
    end
    fwrite(fid, data, 'double');  % д������
    fclose(fid);  % �ر��ļ�
end
