function [finalData] = convertDataToSVMForm(data, loopVar)

finalData = [];

for i = 0:50:(loopVar-50)
    ver = i+50;
    if i == 0
        temp = data(1:50,:);
    else
        temp = data(i+1:ver,:);
    end
    temp1 = reshape(temp, [1,2500]);
    finalData = [finalData; temp1];
end

end
