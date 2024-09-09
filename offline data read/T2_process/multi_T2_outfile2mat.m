
clc; clear; close all;
for i=7:20
    filename1=['F:\实验数据(勿删)\实验11_304单光子系统\20240906\20240906-', num2str((22+i)*100)];
    filename=[filename1,'.out'];
    [data_mat]=single_T2_outfile_2_mat(filename);
    save([filename1, '.mat'],'data_mat');
end


function [data_mat]=single_T2_outfile_2_mat(filename)
    matT2 = single_T2_2_mat(filename);
    data_mat=T2mat_2_T3(matT2);
end

function matT2 = single_T2_2_mat(filename)
    delimiter = ' ';
    %% 将数据列作为文本读取:
    % 有关详细信息，请参阅 TEXTSCAN 文档。
    formatSpec = '%*q%*q%q%q%[^\n\r]';

    %% 打开文本文件。
    fileID = fopen(filename,'r');

    %% 根据格式读取数据列。
    % 该调用基于生成此代码所用的文件的结构。如果其他文件出现错误，请尝试通过导入工具重新生成代码。
    dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'MultipleDelimsAsOne', true, 'TextType', 'string',  'ReturnOnError', false);

    %% 关闭文本文件。
    fclose(fileID);

    %% 将包含数值文本的列内容转换为数值。
    % 将非数值文本替换为 NaN。
    raw = repmat({''},length(dataArray{1}),length(dataArray)-1);
    for col=1:length(dataArray)-1
        raw(1:length(dataArray{col}),col) = mat2cell(dataArray{col}, ones(length(dataArray{col}), 1));
    end
    numericData = NaN(size(dataArray{1},1),size(dataArray,2));

    for col=[1,2]
        % 将输入元胞数组中的文本转换为数值。已将非数值文本替换为 NaN。
        rawData = dataArray{col};
        for row=1:size(rawData, 1)
            % 创建正则表达式以检测并删除非数值前缀和后缀。
            regexstr = '(?<prefix>.*?)(?<numbers>([-]*(\d+[\,]*)+[\.]{0,1}\d*[eEdD]{0,1}[-+]*\d*[i]{0,1})|([-]*(\d+[\,]*)*[\.]{1,1}\d+[eEdD]{0,1}[-+]*\d*[i]{0,1}))(?<suffix>.*)';
            try
                result = regexp(rawData(row), regexstr, 'names');
                numbers = result.numbers;

                % 在非千位位置中检测到逗号。
                invalidThousandsSeparator = false;
                if numbers.contains(',')
                    thousandsRegExp = '^\d+?(\,\d{3})*\.{0,1}\d*$';
                    if isempty(regexp(numbers, thousandsRegExp, 'once'))
                        numbers = NaN;
                        invalidThousandsSeparator = true;
                    end
                end
                % 将数值文本转换为数值。
                if ~invalidThousandsSeparator
                    numbers = textscan(char(strrep(numbers, ',', '')), '%f');
                    numericData(row, col) = numbers{1};
                    raw{row, col} = numbers{1};
                end
            catch
                raw{row, col} = rawData{row};
            end
        end
    end


    %% 排除具有非数值元胞的行
    I = ~all(cellfun(@(x) isnumeric(x) || islogical(x),raw),2); % 查找具有非数值元胞的行
    raw(I,:) = [];

    %% 将指定文本替换为 NaN
    R = cellfun(@(x) ischar(x) && strcmp(x,'('),raw); % 查找非数值元胞
    raw(R) = {NaN}; % 替换非数值元胞

    %% 创建输出变量
    matT2 = cell2mat(raw);

end

function data_mat=T2mat_2_T3(file)
    f=0.025;
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
        fprintf('数据正常！\n');
        for k=CHis0(end)+1:length
            bin_i=bin_i+1;
            bin(bin_i)=s(k)-s(CHis0(end));
            bin_t(bin_i)=f*s(k);
        end
    else
        fprintf('全部为同步信号，无目标数据！\n');
    end
    data_mat=[bin_t', bin'];
%     figure(1);
%     scatter(bin_t,f*bin,'.');xlabel('测量时间/ns');ylabel('飞行时间/ns');
end

