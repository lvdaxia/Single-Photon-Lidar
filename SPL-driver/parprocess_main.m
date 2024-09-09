clc;clear all;close all;
% 创建并行池
poolobj = gcp();

% 设置数据采集的任务
future_data = parfeval(poolobj, @acquire_data, 1);
% 主循环，等待数据采集完成并处理
fprintf('正在采集和处理数据...\n');
pause(0.05); % 模拟数据采集需要5秒钟
while 1
    % 检查是否有新的数据采集完成
        % 获取已经完成的数据采集结果
        data = fetchOutputs(future_data);
        
        % 同时启动数据处理任务
        future_result = parfeval(poolobj, @process_data, 1, data);
        
        % 继续设置下一个数据采集的任务
        future_data = parfeval(poolobj, @acquire_data, 1);
    
    % 可选：在这里可以添加一些其他的处理操作
    pause(0.02); % 等待一段时间，可以根据实际情况调整
    % 获取最后一个处理结果
result = fetchOutputs(future_result);
fprintf('所有数据处理完成，最终处理结果为: %f\n', result);
end


% % 清理并行池
% delete(poolobj);

% 数据采集函数
function data = acquire_data()
    fprintf('正在采集数据...\n');
    % 这里模拟数据采集的过程，实际中可能是从传感器、文件或其他源获取数据
    pause(0.01); % 模拟数据采集需要5秒钟
    data = rand(1, 2); % 假设采集到一个长度为10的随机数据
    fprintf('data=%5d\n',data);
end

% 数据处理函数
function result = process_data(data)
    fprintf('正在处理数据...\n');
    % 这里模拟数据处理的过程，可以是任何数据处理操作
    result = sum(data); % 假设数据处理是求和操作
    fprintf('data=%5d\n',result);
end
