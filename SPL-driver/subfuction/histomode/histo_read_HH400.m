
function [countsbuffer]=histo_read_HH400(MAXHISTBINS,NumInpChannels,dev,FLAG_OVERFLOW)
    countsbuffer  = uint32(zeros(NumInpChannels,MAXHISTBINS));
    for i=0:NumInpChannels-1  
        bufferptr = libpointer('uint32Ptr', countsbuffer(i+1,:));
        [ret,countsbuffer(i+1,:)] = calllib('HHlib', 'HH_GetHistogram', dev(1), bufferptr, i, 0); 
        if (ret<0)
            fprintf('\nHH_GetHistogram error %ld. Aborted.\n', ret);
            closedev;
            return;
        end;
    end;

    flags = int32(0);
    flagsPtr = libpointer('int32Ptr', flags);
    [ret,flags] = calllib('HHlib', 'HH_GetFlags', dev(1), flagsPtr);
    if (ret<0)
        fprintf('\nHH_GetFlags error %ld. Aborted.\n', ret);
        closedev;
        return;
    end;

    if(bitand(uint32(flags),FLAG_OVERFLOW)) 
        fprintf('  Overflow.');
    end;
end
