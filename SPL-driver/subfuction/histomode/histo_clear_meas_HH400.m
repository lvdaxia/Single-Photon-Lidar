ret = calllib('HHlib', 'HH_ClearHistMem', dev(1));    
if (ret<0)
    fprintf('\nHH_ClearHistMem error %ld. Aborted.\n', ret);
    closedev;
    return;
end