ret = calllib('HHlib', 'HH_StopMeas', dev(1)); 
if (ret<0)
    fprintf('\nHH_StopMeas error %ld. Aborted.\n', ret);
    closedev;
    return;
end;