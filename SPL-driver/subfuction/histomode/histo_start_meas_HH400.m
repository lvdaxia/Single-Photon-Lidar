ret = calllib('HHlib', 'HH_StartMeas', dev(1),Tacq); 
if (ret<0)
    fprintf('\nHH_StartMeas error %ld. Aborted.\n', ret);
    closedev;
    return;
end;
fprintf('\nMeasuring for %1d milliseconds...',Tacq);