function A = readBinFile(fname, datasize, datatype)

    if ~exist('datatype', 'var') || isempty(datatype)
        datatype = 'double';
    end

    fileID = fopen(fname);
    if strcmp(datatype,'complex')
        try
            disp(sprintf('You put complex as a datatype, lets assume your input is complex double \n'));
            A = freadcomplex(fileID, prod(datasize), 'double');
        catch ME
            fclose(fileID);
            rethrow(ME)
        end
    else
        try
            A = fread(fileID, prod(datasize), datatype);
        catch ME
            fclose(fileID);
            rethrow(ME)
        end
    end
    fclose(fileID);
    A = reshape(A, datasize);
end