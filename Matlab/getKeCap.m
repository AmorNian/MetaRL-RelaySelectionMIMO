function cap = getKeCap()
    global params;
    relaySelectionMethod = @LoSRSBasedRelaySelection;
    otherParamsRS = {"resourceAllocation","random"};
    params = relaySelection(relaySelectionMethod, params, otherParamsRS);
    %reward = sum(params.capacity.channelCapacity);
    
    params.relaySelection.groupNumber = 1; 
    params = calculateCapacity(params,"random");
    %reward = sum(params.capacity.channelCapacity);
    cap = params.capacity.channelCapacity;
end