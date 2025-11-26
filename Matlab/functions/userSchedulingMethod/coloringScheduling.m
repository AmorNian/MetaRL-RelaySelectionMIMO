function params = coloringScheduling(params, info)
    % if sum(pattern) ~= params.infra.UE.number
    %     error("pattern isn't matching UE number")
    % end
    % randomPerm = randperm(params.infra.UE.number);
    % params.userScheduling.random = struct();
    % params.userScheduling.random.pattern = pattern;
    % params.userScheduling.random.schedulingResult = cell(length(pattern), 1);
    % currentIdx = 1;
    % for i = 1:length(pattern)
    %     groupSize = pattern(i);
    %     params.userScheduling.random.schedulingResult{i} = randomPerm(currentIdx:currentIdx + groupSize - 1);
    %     currentIdx = currentIdx + groupSize;
    % end
    % for i = 1:length(params.userScheduling.random.schedulingResult)
    %     params.userScheduling.random.schedulingResult{i} = sort(params.userScheduling.random.schedulingResult{i});
    % end
    % params.userScheduling.random.midGroupNumber = length(params.userScheduling.random.schedulingResult);
    threshhold = info{1};
    modelPath = info{2};
    load(modelPath,"net_interferencePredict");
    UENum = params.infra.UE.number;
    %% input:D , TX , RX
    K = 1;
    flag = true;
    count = 20;
    while(flag && count)
        adjacencyMatrix = zeros(UENum, UENum);
        combinations = nchoosek(1:UENum,2)';
        for combi = combinations
            U1 = combi(1);
            U2 = combi(2);
            input = zeros(44,2,3);
            D = params.map.distance.RU(:,combi);
            LosMatrix = params.map.LoSRSMatrix(:,combi);
            Tx = params.beamScan.RUTx(:,combi) .* LosMatrix;
            Rx = params.beamScan.RURx(:,combi) .* LosMatrix;
            input(:,:,1) = D;
            input(:,:,2) = Tx;
            input(:,:,3) = Rx;
            input = normalize_per_channel(input);
            value = predict(net_interferencePredict,input) / K;
            adjacencyMatrix(U1,U2) = value;
        end
        adjacencyMatrix = adjacencyMatrix > threshhold;
        adjacencyMatrix = adjacencyMatrix + adjacencyMatrix';
        color = dsatur_coloring(adjacencyMatrix);
        groupNum = max(color);             % 用了几种颜色
                % 初始化元胞
        if(groupNum == K)
            flag = false;  
        else
            K = groupNum;  
        end
        count = count - 1;
        res = cell(groupNum,1);
    end
    
    for c = 1:groupNum
        res{c} = find(color == c);  % 找出所有颜色为c的点
    end

    params.userScheduling.color = struct();
    params.userScheduling.color.threshhold = threshhold;
    params.userScheduling.color.schedulingResult = res;

    params.resourceAllocation.color = struct();
    params.resourceAllocation.color.allocationResult = res;
end

function color = dsatur_coloring(adj)
    % 输入: adj - 邻接矩阵 (n x n)
    % 输出: color - 每个节点的颜色编号（从1开始）
    
    n = size(adj, 1);
    color = zeros(1, n);            % 初始化颜色，0表示未染色
    saturation = zeros(1, n);       % 每个节点的饱和度
    degree = sum(adj, 2)';          % 每个节点的度数
    
    available_colors = cell(1, n);  % 每个节点相邻颜色集合
    for i = 1:n
        available_colors{i} = [];
    end
    
    for k = 1:n
        % 找到未染色中饱和度最大的节点（如果平局就选度数大的）
        uncolored = find(color == 0);
        [~, idx] = max(saturation(uncolored) + 0.01 * degree(uncolored));
        node = uncolored(idx);
        
        % 找一个最小可用颜色
        neighbor_colors = unique(color(adj(node, :) == 1));
        c = 1;
        while ismember(c, neighbor_colors)
            c = c + 1;
        end
        color(node) = c;
        
        % 更新邻居的饱和度
        for j = find(adj(node, :))
            if color(j) == 0 && ~ismember(c, available_colors{j})
                saturation(j) = saturation(j) + 1;
                available_colors{j} = [available_colors{j}, c];
            end
        end
    end
end
