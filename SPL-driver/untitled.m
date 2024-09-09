clc;clear all;close all;
% 创建一个并行池
parpool('local', 2);

% 创建一个函数句柄，用于并行执行的任务
writeToFile = @(fileName, data) writeFileFunction(fileName, data);

% 异步执行的任务
futures = [];
for i = 1:2
    fileName = sprintf('output_file_%d.bin', i);  % 生成不同的文件名
    data = rand(1, 10);  % 生成一些示例数据
    futures(end+1) = parfeval(@(fn, d) writeToFile(fn, d), 0, fileName, data);
end

% 等待所有任务完成
for i = 1:numel(futures)
    fetchOutputs(futures(i));
end

% 关闭并行池
delete(gcp('nocreate'));

% 定义写文件的函数
function writeFileFunction(fileName, data)
    fid = fopen(fileName, 'wb');  % 打开文件
    if fid == -1
        error('Cannot open file: %s', fileName);
    end
    fwrite(fid, data, 'double');  % 写入数据
    fclose(fid);  % 关闭文件
end
