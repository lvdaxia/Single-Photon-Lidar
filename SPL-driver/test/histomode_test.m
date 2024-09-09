clc;clear all;close all;
Tacq=1000;
Mode=0;
Binning=0;

% [MAXHISTBINS,FLAG_OVERFLOW, dev, Resolution,NumInpChannels]=histomode_initialization_HH_400(Mode,Binning);
histo_init_HH400;
histo_clear_meas_HH400;
ret = calllib('HHlib', 'HH_StartMeas', dev(1),Tacq); 
if (ret<0)
    fprintf('\nHH_StartMeas error %ld. Aborted.\n', ret);
    closedev;
    return;
end;
         
fprintf('\nMeasuring for %1d milliseconds...',Tacq);
        
ctcdone = int32(0);
ctcdonePtr = libpointer('int32Ptr', ctcdone);
while (ctcdone==0)
    [ret,ctcdone] = calllib('HHlib', 'HH_CTCStatus', dev(1), ctcdonePtr);
end;    

ret = calllib('HHlib', 'HH_StopMeas', dev(1)); 
if (ret<0)
    fprintf('\nHH_StopMeas error %ld. Aborted.\n', ret);
    closedev;
    return;
end;

[countsbuffer]=histo_read_HH400(MAXHISTBINS,NumInpChannels,dev,FLAG_OVERFLOW);
plot(countsbuffer');
closedev;

