function params = beamMatrixResourceAllocation(params, otherParams)
    params.resourceAllocation.DL = struct();
    params.resourceAllocation.DL.USMethod = otherParams{2};
    params.resourceAllocation.DL.modelPath = otherParams{1};
    params.resourceAllocation.DL.targetUserGroups = params.userScheduling.(otherParams{2}).schedulingResult;
    params.resourceAllocation.DL.targetGroupNum = size(params.resourceAllocation.DL.targetUserGroups,1);
    params.resourceAllocation.DL.allocationResult = {};
    load(params.resourceAllocation.DL.modelPath,'net_Trained')
    
    % for i = 1:params.resourceAllocation.DL.targetGroupNum
    %     targetUser = params.resourceAllocation.DL.targetUserGroups{i};
    %     %input = params.beamScan.RUTx(:,targetUser);
    %     input = zeros(15,6,1);
    %     input(:,:,1) = params.beamScan.RUTx(:,targetUser);
    %     %input(:,:,2) = params.beamScan.RURx(:,targetUser);
    %     scores = minibatchpredict(net_Trained,input);
    %     groupLabel = {'222','33','321','6','1','42'};
    %     classNames = params.classNames;
    %     output = scores2label(scores,classNames);
    %     output = string(output);
    %     idx = find(strcmp(groupLabel, output));
    %     groupPattern = {[2,2,2],[3,3],[3,2,1],[6],[1,1,1,1,1,1],[4,2]};
    %     targetPattern = groupPattern{idx};
    %     RLres = maxminForDL(params,targetUser,targetPattern);
    %     params.resourceAllocation.DL.allocationResult = cat(1,params.resourceAllocation.DL.allocationResult,RLres);
    % end

    for i = 1:params.resourceAllocation.DL.targetGroupNum
        targetUser = params.resourceAllocation.DL.targetUserGroups{i};
        %input = params.beamScan.RUTx(:,targetUser);
        lat = params.infra.UE.latitude(targetUser);
        lon = params.infra.UE.longitude(targetUser);
        pos = latLonToCartesian(lat, lon, params.map.originLatitude, params.map.originLongitude, params.map.xAxisLat, params.map.xAxisLon);
        input = [pos(:,1);pos(:,2)]';
        scores = minibatchpredict(net_Trained,input);
        groupLabel = {'222','33','321','6','1','42'};
        classNames = params.classNames;
        output = scores2label(scores,classNames);
        output = string(output);
        idx = find(strcmp(groupLabel, output));
        groupPattern = {[2,2,2],[3,3],[3,2,1],[6],[1,1,1,1,1,1],[4,2]};
        targetPattern = groupPattern{idx};
        RLres = maxminForDL(params,targetUser,targetPattern);
        params.resourceAllocation.DL.allocationResult = cat(1,params.resourceAllocation.DL.allocationResult,RLres);
    end

end

function RLres = maxminForDL(params,targetUsers,pattern)
    oldRng = rng;
    rng(42)
    userNum = length(targetUsers);
    RLres = cell(length(pattern),1);
    targetUsers = sort(targetUsers);
    if isequal(pattern,ones(1,userNum))
        for i = 1:length(pattern)
            RLres{i} = targetUsers(i);
        end
        return
    end
    
    if sum(pattern) ~= userNum
        error("pattern isn't matching UE number")
    end
    assignedUser = false(1, userNum);
    pattern = sort(pattern);
    for group = 1:length(pattern)
        availableUser = targetUsers(~assignedUser);
        groupSize = pattern(group);
        if groupSize == 1
            combiCandidate = nchoosek(availableUser,2);
            conflictScore = zeros(size(combiCandidate, 1), 1);
            for i = 1:length(combiCandidate)
                conflictScore(i) = calculateConflict(params,{combiCandidate(i,:)});
            end
            maxConflictScore = max(conflictScore);
            maxCandidate = combiCandidate(conflictScore == maxConflictScore,:);
            bestCombi = maxCandidate(randi(size(maxCandidate,1)), :);
            targetUser = bestCombi(randi(2));
            RLres{group} = targetUser;
            assignedUser(targetUsers == targetUser) = true;
        else
            combiCandidate = nchoosek(availableUser,groupSize);
            conflictScore = zeros(size(combiCandidate, 1), 1);
            for i = 1:size(combiCandidate,1)
                conflictScore(i) = calculateConflict(params,{combiCandidate(i,:)});
            end
            maxConflictScore = max(conflictScore);
            maxCandidate = combiCandidate(conflictScore == maxConflictScore,:);
            bestCombi = maxCandidate(randi(size(maxCandidate,1)), :);
            targetUser = bestCombi(randi(length(bestCombi)));
            targetRows = any(combiCandidate == targetUser, 2);
            targetCombi = combiCandidate(targetRows, :);
            targetScore = conflictScore(targetRows);
            minConflict = min(targetScore);
            minCandidate = targetCombi(targetScore == minConflict, :);
            minCombi = minCandidate(randi(size(minCandidate,1)), :);
            RLres{group} = minCombi;
            [~, idx] = ismember(minCombi, targetUsers);
            assignedUser(idx) = true;
        end
    end
    isDone = all(assignedUser == 1);
    if ~isDone
        error("maxmin wrong! user is left!")
    end
    rng(oldRng)
end