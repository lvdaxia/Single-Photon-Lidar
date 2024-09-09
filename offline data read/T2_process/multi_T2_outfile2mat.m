
clc; clear; close all;
for i=7:20
    filename1=['F:\ʵ������(��ɾ)\ʵ��11_304������ϵͳ\20240906\20240906-', num2str((22+i)*100)];
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
    %% ����������Ϊ�ı���ȡ:
    % �й���ϸ��Ϣ������� TEXTSCAN �ĵ���
    formatSpec = '%*q%*q%q%q%[^\n\r]';

    %% ���ı��ļ���
    fileID = fopen(filename,'r');

    %% ���ݸ�ʽ��ȡ�����С�
    % �õ��û������ɴ˴������õ��ļ��Ľṹ����������ļ����ִ����볢��ͨ�����빤���������ɴ��롣
    dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter, 'MultipleDelimsAsOne', true, 'TextType', 'string',  'ReturnOnError', false);

    %% �ر��ı��ļ���
    fclose(fileID);

    %% ��������ֵ�ı���������ת��Ϊ��ֵ��
    % ������ֵ�ı��滻Ϊ NaN��
    raw = repmat({''},length(dataArray{1}),length(dataArray)-1);
    for col=1:length(dataArray)-1
        raw(1:length(dataArray{col}),col) = mat2cell(dataArray{col}, ones(length(dataArray{col}), 1));
    end
    numericData = NaN(size(dataArray{1},1),size(dataArray,2));

    for col=[1,2]
        % ������Ԫ�������е��ı�ת��Ϊ��ֵ���ѽ�����ֵ�ı��滻Ϊ NaN��
        rawData = dataArray{col};
        for row=1:size(rawData, 1)
            % ����������ʽ�Լ�Ⲣɾ������ֵǰ׺�ͺ�׺��
            regexstr = '(?<prefix>.*?)(?<numbers>([-]*(\d+[\,]*)+[\.]{0,1}\d*[eEdD]{0,1}[-+]*\d*[i]{0,1})|([-]*(\d+[\,]*)*[\.]{1,1}\d+[eEdD]{0,1}[-+]*\d*[i]{0,1}))(?<suffix>.*)';
            try
                result = regexp(rawData(row), regexstr, 'names');
                numbers = result.numbers;

                % �ڷ�ǧλλ���м�⵽���š�
                invalidThousandsSeparator = false;
                if numbers.contains(',')
                    thousandsRegExp = '^\d+?(\,\d{3})*\.{0,1}\d*$';
                    if isempty(regexp(numbers, thousandsRegExp, 'once'))
                        numbers = NaN;
                        invalidThousandsSeparator = true;
                    end
                end
                % ����ֵ�ı�ת��Ϊ��ֵ��
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


    %% �ų����з���ֵԪ������
    I = ~all(cellfun(@(x) isnumeric(x) || islogical(x),raw),2); % ���Ҿ��з���ֵԪ������
    raw(I,:) = [];

    %% ��ָ���ı��滻Ϊ NaN
    R = cellfun(@(x) ischar(x) && strcmp(x,'('),raw); % ���ҷ���ֵԪ��
    raw(R) = {NaN}; % �滻����ֵԪ��

    %% �����������
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
    bin_t(1:length-length_CHis0-CHis0(1))=0;% ��ʵʱ��
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
        fprintf('����������\n');
        for k=CHis0(end)+1:length
            bin_i=bin_i+1;
            bin(bin_i)=s(k)-s(CHis0(end));
            bin_t(bin_i)=f*s(k);
        end
    else
        fprintf('ȫ��Ϊͬ���źţ���Ŀ�����ݣ�\n');
    end
    data_mat=[bin_t', bin'];
%     figure(1);
%     scatter(bin_t,f*bin,'.');xlabel('����ʱ��/ns');ylabel('����ʱ��/ns');
end

