function [user_pos, rs_pos, matrix, rs_num, ue_num] = simulatorInit(rand_seed)
    rng(rand_seed)
    global params;
    params = getParameters(rand_seed);
    viewer = siteviewer("Name","Shinjuku","Basemap","streets","Buildings",params.map.file);

    newset = false;
    params = createUE(params);                
    params = getRaytracing(params,newset);
    params = cartesianCoordinate(params);
    params = calculateDistance(params);
    params = calculateChannels(params,newset);
    params = judgeLoSRS(params);
    params = getBeamScan(params,newset);

    userSchedulingMethod = @randomUserScheduling;
    otherparamsUS = [params.infra.UE.number];
    params = userScheduling(userSchedulingMethod, params, otherparamsUS);
    resourceAllocationMethod = @randomResourceAllocation;
    RApattern = {[params.infra.UE.number]};
    otherParamsRA = {RApattern,"random"};
    params = resourceAllocation(resourceAllocationMethod, params, otherParamsRA);
    save("Matlab/data/params.mat",'params');

    user_pos = params.map.cartesianCoordinate.UE;
    rs_pos = params.map.cartesianCoordinate.RS;
    matrix = params.map.LoSRSMatrix;
    rs_num = params.infra.RS.number;
    ue_num = params.infra.UE.number; 

    %show(params.infra.BS.txsite)
    show(params.infra.RS.txsite)
    show(params.infra.UE.rxsite)
    %disp(matrix)
    close(viewer)
end