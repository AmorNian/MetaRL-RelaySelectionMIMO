function reward = getReward(matrix)
    global params;
    params.relaySelection.result = matrix;
    % params.relaySelection.result = zeros(1,params.infra.RS.number);
    % for i = 1:size(matrix,1)
    %     idx = find(matrix(i,:) == 1);
    %     if ~isempty(idx)
    %         params.relayselection.result(i) = idx - 1;
    %     else
    %         params.relayselection.result(i) = 0; 
    %     end
    % end
    % disp(params.relayselection.result)
    params.relaySelection.groupNumber = 1;
    params = calculateCapacity(params,"random");
    %reward = sum(params.capacity.channelCapacity);
    reward = params.capacity.channelCapacity;
end