%Convert Surface center of homogeneous mass into Spot object

%Written by Matthew J. Gastinger, Bitplane Advanced Application Scientist.  
%March 2014.
%<CustomTools>
%      <Menu>
%       <Submenu name="Surfaces Functions">
%        <Item name="Center of Mass to Spots" icon="Matlab">
%          <Command>MatlabXT::XT_MJG_SurfacePositionFinal(%i)</Command>
%        </Item>
%       </Submenu>
%      </Menu>
%      <SurpassTab>
%        <SurpassComponent name="bpSurfaces">
%          <Item name="Center of Mass to Spots" icon="Matlab">
%            <Command>MatlabXT::XT_MJG_SurfacePositionFinal(%i)</Command>
%          </Item>
%        </SurpassComponent>
%      </SurpassTab>
%    </CustomTools>
% 
%Description
%
%This XTension will collect the XYZ position of the surface based on the
%center of homogeneous mass, and plot those positions as a Spots object.  It will do
%this in all time points, for all or a selected group of surfaces. 
%
%% 
% Modified by Noushin Ahmadpour
% Live Cell Imaging Facility, University of Manitoba
% September 2024
%
% This script has been adapted for use with the XTBatchProcess XTension
% to enable batch processing of the "Center of Mass to Spots" function.
%
% In this modified version, manual surface selection in the Imaris scene
% is not required. If no surfaces are selected, the script automatically
% identifies all available surfaces.
%
% The script updates each .ims file by adding new center of mass spots
% and saves the modified file in its original directory.

%% 


function CenterOfMassToSpots2(aImarisApplicationID)
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
vSurpassScene = vImarisApplication.GetSurpassScene;
if isequal(vSurpassScene, [])
  %msgbox('Please create some Surfaces in the Surpass scene!');
  return;
end

% Get the Surfaces
vSurfaces = vImarisApplication.GetFactory.ToSurfaces(vImarisApplication.GetSurpassSelection);

% Search the surfaces if not previously selected
if ~vImarisApplication.GetFactory.IsSurfaces(vSurfaces)        
    for vChildIndex = 1:vSurpassScene.GetNumberOfChildren
        vDataItemSurface = vSurpassScene.GetChild(vChildIndex - 1);
        if vImarisApplication.GetFactory.IsSurfaces(vDataItemSurface)
            vSurfaces = vImarisApplication.GetFactory.ToSurfaces(vDataItemSurface);
            % Create spot for center of mass
            createSpotForCenterOfMass(vImarisApplication, vSurfaces);
        end
    end
end

if isempty(vSurfaces)
   vDataItemSurface = 1618; 
end

function createSpotForCenterOfMass(vImarisApplication, vSurfaces)
    vNumberOfSurfaces = vSurfaces.GetNumberOfSurfaces;
    vPositionFinal = [];
    vTimeIndexFinal = [];
    vIds = [];

    for c = 0:vNumberOfSurfaces-1
        vPositionXYZ = vSurfaces.GetCenterOfMass(c);
        vPositionFinal = [vPositionFinal; vPositionXYZ];
        vTimeIndex = vSurfaces.GetTimeIndex(c);
        vTimeIndexFinal = [vTimeIndexFinal; vTimeIndex];
        vIds = [vIds; c]; % Store the surface ID
    end
    
    if max(vTimeIndexFinal) > 0
        vSpotsTime = vTimeIndexFinal;
    else
        vSpotsTime = zeros(vNumberOfSurfaces, 1);
    end
    
    % Dialog to select new Spot size
    % vQuestion = {sprintf(['Please enter new Spot Radius (um):'])};
    % vAnswer = inputdlg(vQuestion, 'Resize Spots', 1, {'1'});
    % if isempty(vAnswer), return, end
    % newRadius = str2double(vAnswer{1});
    % vSpotsRadius = ones(vNumberOfSurfaces, 1) * newRadius;
   
    % Instead Set the spot radius to 1 µm
    newRadius = 1;
    vSpotsRadius = ones(vNumberOfSurfaces, 1) * newRadius;

    % Create the new Spots generated from the center of Mass
    vRGBA = vSurfaces.GetColorRGBA;
    vNewSpots = vImarisApplication.GetFactory.CreateSpots;
    vNewSpots.Set(vPositionFinal, vSpotsTime, vSpotsRadius);
    vNewSpots.SetColorRGBA(vRGBA);
    vNewSpots.SetName([char(vSurfaces.GetName), ' Center of Mass']);
    vNewSpots.SetTrackEdges(vSurfaces.GetTrackEdges);
    vNewSpots.SetIds(vIds); % Set the IDs to match the surface IDs
    vSurfaces.SetVisible(0);
    vSurfaces.GetParent.AddChild(vNewSpots, -1);
end
% The following MATLAB code returns the name of the dataset opened in 
% Imaris and saves file as IMS (Imaris5) format% 
vFileNameString = vImarisApplication.GetCurrentFileName; % returns ‘C:/Imaris/Images/retina.ims’
vFileName = char(vFileNameString);
[vOldFolder, vName, vExt] = fileparts(vFileName); % returns [‘C:/Imaris/Images/’, ‘retina’, ‘.ims’]
vNewFileName = fullfile('E:\ADMIN\Rebecca\BatchXTension example', [vName, vExt]); % returns ‘c:/BitplaneBatchOutput/retina.ims’
vImarisApplication.FileSave(vNewFileName, '');
end