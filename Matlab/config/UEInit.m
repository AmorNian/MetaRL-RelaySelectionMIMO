% street(1).start = [35.690044,139.726381];
% street(1).end = [35.688421,139.725476];
% street(2).start = [35.689739,139.727185];
% street(2).end = [35.688049,139.726305];
% street(3).start = [35.688532,139.727562];
% street(3).end = [35.687703,139.727139];
% street(4).start = [35.689225,139.725934];
% street(4).end = [35.688532,139.727562];
% street(5).start = [35.688421,139.725476];
% street(5).end = [35.687703,139.727139];
% street(6).start = [35.690044,139.726381];
% street(6).end = [35.689739,139.727185];

startend = [40.635024,-73.992138,40.637838,-73.989192;
            40.633692,-73.989916,40.636481,-73.987008;
            40.632377,-73.987740,40.635180,-73.984833;
            40.635024,-73.992138,40.632377,-73.987740;
            40.635586,-73.991560,40.632932,-73.987155;
            40.636170,-73.990978,40.633497,-73.986581;
            40.636725,-73.990391,40.634051,-73.985997;
            40.637255,-73.989799,40.634633,-73.985416;
            40.637838,-73.989192,40.635180,-73.984833];
for i = 1:size(startend,1)
    street(i).start = startend(i,1:2);
    street(i).end = startend(i,3:4);
end
interval = 5;
[uelat, uelon] = calculateStreetPoints(street, interval);

RSFile = "RSInitNewYorkLarge.mat";
mapFile = "NewYorkLarge.osm";
load("config\RSInitNewYorkLarge.mat")
load("config\UEInitNewYorkLarge.mat")
bslat = 40.635239;
bslon = -73.988542;
% rslat = [];
% rslon = [];
viewer = siteviewer("Name","NewYork","Basemap","streets","Buildings",mapFile);
BS = txsite("AntennaHeight",3,...
        "Latitude",bslat,...
        "Longitude",bslon,...
        "TransmitterFrequency",28e9,...
        "TransmitterPower",126,...
        "Name","BaseStation");
show(BS)
uename = "UE#" + (1:length(uelat))';
UE = rxsite("AntennaHeight",1.6,...
        "Latitude",uelat,...
        "Longitude",uelon,...
        "Name",uename);


RS = txsite("AntennaHeight",2,...
        "Latitude",rslat,...
        "Longitude",rslon,...
        "TransmitterFrequency",28e9,...
        "TransmitterPower",126);
show(RS)

pm = propagationModel("raytracing");
pm.Method = 'sbr';
pm.AngularSeparation = 'high';
pm.MaxNumReflections = 2;
pm.MaxNumDiffractions = 0;
rays = raytrace(RS,UE,pm);

% for ue = 1:length(uelat)
%     flag = false;
%     for rs = 1:length(rslat)
%         if isempty(rays{rs,ue}) == false
%             if rays{rs,ue}(1).LineOfSight == true
%                 flag = true;
%             end
%         end
%     end
%     if flag == false
%         disp(ue)
%         show(UE(ue))
%     end
% end

count = zeros(1,length(uelat));
for ue = 1:length(uelat)
    flag = false;
    for rs = 1:length(rslat)
        if isempty(rays{rs,ue}) == false
            if rays{rs,ue}(1).LineOfSight == true
                count(ue) = count(ue) + 1;
            end
        end
    end
    if count(ue) <= 2
        disp(ue)
        show(UE(ue))
    end
end

