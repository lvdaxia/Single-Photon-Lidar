% 20240721
% 可用于T2和T3数据的实时读取
% by 吕林杰
% 全局变量包括：data_mat，cnt_ph，cnt_ov，RecNum，sync_time
%% Decoder functions
function [ph_record_time,ph_flight_time]=tttr_read_old(buffer, Mode)
    global data_mat;  % 输出数据
    global cnt_ph;  % 光子数
    global cnt_ov;  % 溢出次数

    cnt_ov=0;
    cnt_ph=0;
    data_mat=[];
    if Mode==2
        isT2=1;
        ReadHT2(buffer,isT2);
    elseif Mode==3
        isT2=0;
        ReadHT3(buffer,isT2);
    else 
        fprintf('\n Only Mode T2 and T3 are approved.\n');
    end
    ph_record_time=data_mat(:,1);
    ph_flight_time=data_mat(:,2);
    
    figure(1);
    plot(ph_record_time,ph_flight_time,'.');
end
%% Read HydraHarp/TimeHarp260 T2
function ReadHT2(buffer,isT2)
    Version=2;%%%%%% 需要确认一下
    global RecNum;
    
    OverflowCorrection = 0;
    T2WRAPAROUND_V1=33552000;
    T2WRAPAROUND_V2=33554432; % = 2^25  IMPORTANT! THIS IS NEW IN FORMAT V2.0

    for i=1:length(buffer)
        RecNum = i;
        T2Record = buffer(i);     % all 32 bits:
        %   +-------------------------------+  +-------------------------------+
        %   |x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|  |x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|
        %   +-------------------------------+  +-------------------------------+
        dtime = bitand(T2Record,33554431);   % the last 25 bits:
        %   +-------------------------------+  +-------------------------------+
        %   | | | | | | | |x|x|x|x|x|x|x|x|x|  |x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|
        %   +-------------------------------+  +-------------------------------+
        channel = bitand(bitshift(T2Record,-25),63);   % the next 6 bits:
        %   +-------------------------------+  +-------------------------------+
        %   | |x|x|x|x|x|x| | | | | | | | | |  | | | | | | | | | | | | | | | | |
        %   +-------------------------------+  +-------------------------------+
        special = bitand(bitshift(T2Record,-31),1);   % the last bit:
        %   +-------------------------------+  +-------------------------------+
        %   |x| | | | | | | | | | | | | | | |  | | | | | | | | | | | | | | | | |
        %   +-------------------------------+  +-------------------------------+
        % the resolution in T2 mode is 1 ps  - IMPORTANT! THIS IS NEW IN FORMAT V2.0
        timetag = OverflowCorrection + dtime;
        if special == 0   % this means a regular photon record
           GotPhoton(timetag, channel + 1, 0,isT2)
        else    % this means we have a special record
            if channel == 63  % overflow of dtime occured
              if Version == 1
                  OverflowCorrection = OverflowCorrection + T2WRAPAROUND_V1;
                  GotOverflow(1);
              else
                  if(dtime == 0) % if dtime is zero it is an old style single oferflow
                    OverflowCorrection = OverflowCorrection + T2WRAPAROUND_V2;
                    GotOverflow(1);
                  else         % otherwise dtime indicates the number of overflows - THIS IS NEW IN FORMAT V2.0
                    OverflowCorrection = OverflowCorrection + T2WRAPAROUND_V2 * dtime;
                    GotOverflow(dtime);
                  end;
              end;
            end;
            if channel == 0  % Sync event
                GotPhoton(timetag, channel, 0,isT2);
            end;
        end;
    end;
end

%% Read HydraHarp/TimeHarp260 T3
function ReadHT3(buffer,isT2)
    Version=2;
    global RecNum;
    OverflowCorrection = 0;
    T3WRAPAROUND = 1024;
    global cnt_ph;
    for i = 1:length(buffer)
        RecNum = i;
        T3Record = buffer(i);     % all 32 bits:
        %   +-------------------------------+  +-------------------------------+
        %   |x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|  |x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|x|
        %   +-------------------------------+  +-------------------------------+
        nsync = bitand(T3Record,1023);       % the lowest 10 bits:
        %   +-------------------------------+  +-------------------------------+
        %   | | | | | | | | | | | | | | | | |  | | | | | | |x|x|x|x|x|x|x|x|x|x|
        %   +-------------------------------+  +-------------------------------+
        dtime = bitand(bitshift(T3Record,-10),32767);   % the next 15 bits:
        %   the dtime unit depends on "Resolution" that can be obtained from header
        %   +-------------------------------+  +-------------------------------+
        %   | | | | | | | |x|x|x|x|x|x|x|x|x|  |x|x|x|x|x|x| | | | | | | | | | |
        %   +-------------------------------+  +-------------------------------+
        channel = bitand(bitshift(T3Record,-25),63);   % the next 6 bits:
        %   +-------------------------------+  +-------------------------------+
        %   | |x|x|x|x|x|x| | | | | | | | | |  | | | | | | | | | | | | | | | | |
        %   +-------------------------------+  +-------------------------------+
        special = bitand(bitshift(T3Record,-31),1);   % the last bit:   %溢出位
        %   +-------------------------------+  +-------------------------------+
        %   |x| | | | | | | | | | | | | | | |  | | | | | | | | | | | | | | | | |
        %   +-------------------------------+  +-------------------------------+
        if special == 0   % this means a regular input channel
           true_nSync = OverflowCorrection + nsync;
           %  one nsync time unit equals to "syncperiod" which can be
           %  calculated from "SyncRate"
           GotPhoton(true_nSync, channel, dtime,isT2);
        else    % this means we have a special record
            if channel == 63  % overflow of nsync occured
              if (nsync == 0) || (Version == 1) % if nsync is zero it is an old style single oferflow or old Version
                OverflowCorrection = OverflowCorrection + T3WRAPAROUND;
                GotOverflow(1);
              else         % otherwise nsync indicates the number of overflows - THIS IS NEW IN FORMAT V2.0
                OverflowCorrection = OverflowCorrection + T3WRAPAROUND * nsync;
                GotOverflow(nsync);
              end;
            end;
            if (channel >= 1) && (channel <= 15)  % these are markers
              fprintf('(channel >= 1) && (channel <= 15)! 错误!！')
            end;
        end;

        %save([name,'-',num2str(j) '.mat'],'data_mat');
        cnt_ph=0;
    end
end

%% Got Photon
%    TimeTag: Raw TimeTag from Record * Globalresolution = Real Time arrival of Photon
%    DTime: Arrival time of Photon after last Sync event (T3 only) DTime * Resolution = Real time arrival of Photon after last Sync event
%    Channel: Channel the Photon arrived (0 = Sync channel for T2 measurements)
function GotPhoton(TimeTag, Channel, DTime,isT2)
  global cnt_ph;
  global data_mat;
  cnt_ph = cnt_ph + 1;
  global sync_time;
  if(isT2)
      % Edited: formatting changed by PK
      % data_mat(cnt_ph,:)=[Channel TimeTag];
      if Channel==0
          sync_time=TimeTag;
      end
      Dtime_by_T2=TimeTag-sync_time;
      if Dtime_by_T2
          data_mat=[data_mat;TimeTag Dtime_by_T2];
      end
%       data_mat(cnt_ph,:)=[Channel TimeTag];
      %fprintf(fpout,'\n%10i CHN %i %18.0f (%0.1f ps)' , RecNum, Channel, TimeTag, (TimeTag * MeasDesc_GlobalResolution * 1e12));
  else
      % Edited: formatting changed by PK
      % fprintf(fpout,'\n%10i CHN %i %18.0f (%0.1f ns) %ich', RecNum, Channel, TimeTag, (TimeTag * MeasDesc_GlobalResolution * 1e9), DTime);
      data_mat(cnt_ph,:)=[TimeTag DTime];
  end;
end


%% Got Overflow
%  Count: Some TCSPC provide Overflow compression = if no Photons between overflow you get one record for multiple Overflows
function GotOverflow(Count)
  global cnt_ov;
  cnt_ov = cnt_ov + Count;
  % Edited: formatting changed by PK
  % fprintf(fpout,'\n%10i OFL * %i', RecNum, Count);
end

