function SpotSpotDistance(aImarisApplicationID, vDirectory)

% connect to Imaris interface
if ~isa(aImarisApplicationID, 'Imaris.IApplicationPrxHelper')
  javaaddpath ImarisLib.jar
  vImarisLib = ImarisLib;
  if ischar(aImarisApplicationID)
    aImarisApplicationID = round(str2double(aImarisApplicationID));
  end
  vImarisApplication = vImarisLib.GetApplication(aImarisApplicationID);
else
  vImarisApplication = aImarisApplicationID;
end

% the user has to create a scene with some spots
vSurpassScene = vImarisApplication.GetSurpassScene;
if isequal(vSurpassScene, [])
    msgbox('Please create some Spots in the Surpass scene!');
    return;
end

% get all spots objects in the scene
vSpotsObjects = {};
for vChildIndex = 1:vSurpassScene.GetNumberOfChildren
    vDataItem = vSurpassScene.GetChild(vChildIndex - 1);
    if vImarisApplication.GetFactory.IsSpots(vDataItem)
        vSpotsObjects{end+1} = vImarisApplication.GetFactory.ToSpots(vDataItem);
    end
end

% check if there are at least two spots objects
if numel(vSpotsObjects) < 2
    msgbox('Please create at least two Spots objects!');
    return;
end

% get the name of the .ims file
vFileName = char(vImarisApplication.GetCurrentFileName);
[~, vFileName, ~] = fileparts(vFileName);

% define output directory
%vDirectory = 'C:\Program Files\Bitplane\Imaris 10.2.0\Batch XTension';

% prepare CSV file
vCSVFilePath = fullfile(vDirectory, [vFileName, '_SpotsDistances.csv']);
vCSVFile = fopen(vCSVFilePath, 'w');
fprintf(vCSVFile, 'Object1,Object2,SpotIndex1,ClosestSpotIndex2,MinDistance,MeanDistance,MaxDistance\n');

% iterate over all pairs of spots objects
for i = 1:numel(vSpotsObjects)-1
    for j = i+1:numel(vSpotsObjects)
        vSpots1 = vSpotsObjects{i};
        vSpots2 = vSpotsObjects{j};
        
        % get the spots coordinates and IDs
        vSpots1XYZ = vSpots1.GetPositionsXYZ;
        vSpots2XYZ = vSpots2.GetPositionsXYZ;
        vSpots1IDs = vSpots1.GetIds;
        vSpots2IDs = vSpots2.GetIds;
        
        % iterate over each spot in vSpots1
        for k = 1:size(vSpots1XYZ, 1)
            vSpot1XYZ = vSpots1XYZ(k, :);
            vSpot1ID = vSpots1IDs(k);
            
            % calculate distances to all spots in vSpots2
            vDistances = sqrt(sum((vSpots2XYZ - vSpot1XYZ).^2, 2));
            
            % find the minimum distance and corresponding spot in vSpots2
            [vMinDist, vMinIndex] = min(vDistances);
            vMeanDist = mean(vDistances);
            vMaxDist = max(vDistances);
            vClosestSpotID = vSpots2IDs(vMinIndex);
            
            % save to CSV
            fprintf(vCSVFile, '%s,%s,%d,%d,%.3f,%.3f,%.3f\n', char(vSpots1.GetName), char(vSpots2.GetName), vSpot1ID, vClosestSpotID, vMinDist, vMeanDist, vMaxDist);
            
            % add statistics to Imaris
            vUnits = {char(vImarisApplication.GetDataSet.GetUnit)};
            vFactors = {'Spot'};
            vFactorNames = {'Category'};
            vNames = {sprintf('DistMin (%s vs %s)', char(vSpots1.GetName), char(vSpots2.GetName))};
            vSpots1.AddStatistics(vNames, vMinDist, vUnits, vFactors, vFactorNames, vSpot1ID); % unique ID
            vNames = {sprintf('DistMean (%s vs %s)', char(vSpots1.GetName), char(vSpots2.GetName))};
            vSpots1.AddStatistics(vNames, vMeanDist, vUnits, vFactors, vFactorNames, vSpot1ID); % unique ID
            vNames = {sprintf('DistMax (%s vs %s)', char(vSpots1.GetName), char(vSpots2.GetName))};
            vSpots1.AddStatistics(vNames, vMaxDist, vUnits, vFactors, vFactorNames, vSpot1ID); % unique ID
        end
    end
end

% close CSV file
fclose(vCSVFile);

msgbox(['Distances between Spots objects have been calculated and saved to ', vCSVFilePath]);
end