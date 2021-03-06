%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Bone Mesh Female Toolkit
% Copyright (c) 2017 <Manish Sreenivasa, Daniel Gonzalez Alvarado> 
% manish.sreenivasa@ziti.uni-heidelberg.de, Heidelberg University, Germany
%
% Licensed under the zlib license. See LICENSE for more details.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clf;
clear;
clc;

% Iso2Mesh(http://iso2mesh.sourceforge.net) is required for mesh resampling
% You may use the included distribution (v1.8 linux) or provide the local 
% path to your iso2mesh distribution 
pathToIso2Mesh = './externalDependencies/iso2mesh/';

load ./data/model_Original.mat
addpath ('./externalDependencies/WOBJ_toolbox_Version2b/');
addpath (genpath('./core/'));

% Test Iso2mesh dependency
if ~isempty (pathToIso2Mesh)
    addpath(pathToIso2Mesh);
    testRes = fnc_testIso2MeshDist (model_Original);
    if testRes == 1
        disp (' - Not able to run test code for Iso2Mesh distribution.');
        disp ('   -- Mesh resampling has been disabled.');    
        bResampling = 0;
    else
        bResampling = 1;
    end
else
    disp (' - Iso2Mesh distribution not provided.');
    disp ('   -- Mesh resampling has been disabled.')
    bResampling = 0;
end

% Shared user data
UserData.model_orig       = model_Original;         
UserData.model_undo       = model_Original;      
UserData.model_current    = model_Original;
UserData.model_resampled  = model_Original;
UserData.inputHeight      = [0,0];
UserData.currPath         = cd;  
UserData.pathToMeshes     = 'meshes/obj/'; 
UserData.bPlot_jointAxes  = 0;
UserData.bPlot_landmarks  = 0;
UserData.bPlot_markers    = 0;

% Define the main Figure where everything occurs
mainFig             = figure(1);
mainFig.Name        = 'Bone Mesh Female Toolkit';
mainFig.NumberTitle = 'off';
mainFig.UserData    = UserData;

tmp_ChangesScale    = 0;
tmp_ChangesResample = 0;
nMeshes             = length(model_Original);
boneNames           = {model_Original(:).BoneName};
boneNames        = {'Lower Body Skeleton', 'Composite Foot', boneNames{:}};

% Define GUI Controls
panel_background = uicontrol('Style', 'text',...
    'Parent', mainFig,...
    'BackgroundColor', [0.8 0.8 0.8],...
    'String', 'Bone Mesh Female Toolkit - v1.0',...
    'FontWeight','bold',...
    'FontSize', 15,...
    'Units', 'normalized',...
    'Position', [0.02,0.6,0.95,.4]);

subpanelPlot_background = uicontrol('Style', 'text',...
    'BackgroundColor', [0.7 0.7 0.7],...
    'FontSize', 13,...
    'String', 'Plotting Options',...
    'FontWeight','bold',...
    'Units', 'normalized',...
    'Position', [0.03,0.61,0.41,.35]);

subpanelModify_background = uicontrol('Style', 'text',...
    'BackgroundColor', [0.6 0.6 0.6],...
    'FontWeight','bold',...
    'FontSize', 13,...    
    'String', 'Model Adjustments',...
    'Units', 'normalized',...
    'Position', [0.45,0.78,0.34,.18]);

subpanelExport_background = uicontrol('Style', 'text',...
    'BackgroundColor', [0.9 0.9 0.9],...
    'FontWeight','bold',...
    'FontSize', 13,...
    'String', 'Export Options',...
    'Units', 'normalized',...
    'Position', [0.45,0.61,0.34,.15]);

popup_menuBones = uicontrol('Style', 'popup',...
    'Parent', mainFig,...
    'String', boneNames,...
    'Tag', 'popup_menuBones',...
    'Units', 'normalized',...
    'Position', [.03,.83,.23,.1],...
    'Callback', @call_updatePlots);

checkBox_jointAxes = uicontrol('Style', 'checkbox',...
    'Tag', 'checkBox_jointAxes',...
    'Parent', mainFig,...
    'HorizontalAlignment', 'left',...
    'String', 'Show joint axes',...
    'FontWeight', 'bold',...
    'Value', 0, ...
    'Units', 'normalized',...
    'Position', [0.26,0.90,0.17,0.02],...
    'Callback', @call_updatePlots);

checkBox_landmarks = uicontrol('Style', 'checkbox',...
    'Tag', 'checkBox_landmarks',...
    'Parent', mainFig,...
    'HorizontalAlignment', 'left',...
    'String', 'Show landmarks',...
    'FontWeight', 'bold',...
    'Value', 0, ...
    'Units', 'normalized',...
    'Position', [0.26,0.87,0.17,0.02],...
    'Callback', @call_updatePlots);

checkBox_markers = uicontrol('Style', 'checkbox',...
    'Tag', 'checkBox_markers',...
    'Parent', mainFig,...
    'HorizontalAlignment', 'left',...
    'String', 'Show markers',...
    'FontWeight', 'bold',...
    'Value', 0, ...
    'Units', 'normalized',...
    'Position', [0.26,0.84,0.17,0.02],...
    'Callback', @call_updatePlots);

text_actionHistory = uicontrol('Style', 'text',...
    'String', 'Command history',...
    'FontWeight','bold',...
    'FontSize', 13,...
    'HorizontalAlignment', 'left',...
    'Units', 'normalized',...
    'Position', [0.04,0.82,0.2,0.02]);

listbox_actionHistory = uicontrol('Style', 'listbox',...
    'Tag', 'listbox_actionHistory',...
    'FontWeight','normal',...
    'Units', 'normalized',...
    'Position', [0.04,0.62,0.38,0.2]);

slider_resample = uicontrol('Style', 'slider',...
    'Parent', mainFig,...
    'Tag', 'slider_resample',...
    'Units', 'normalized',...
    'Min',0.1,'Max',1.0,...
    'Position', [0.46 0.90 0.1 0.02],...
    'Value', 1,...
    'Callback', @call_sliderResample);

edit_resample = uicontrol('Style', 'edit',...
    'Parent', mainFig,...
    'Tag', 'edit_resample',...
    'Units', 'normalized',...
    'Position', [0.57 0.90 0.04 0.02],...
    'String', '1',...
    'FontWeight','bold',...
    'Callback', @call_editResample);

if bResampling
    enableTxt = 'on';
else
    enableTxt = 'off';
end
pushbutton_resample = uicontrol('Style', 'pushbutton',...
    'Parent', mainFig,...
    'String', 'Resample',...
    'FontWeight','bold',...
    'Units', 'normalized',...
    'Enable', enableTxt,...
    'Position', [0.62 0.89 0.15 0.04],...
    'Callback', @call_resampleMeshes);

text_scaleHeight = uicontrol('Style', 'text',...
    'Parent', mainFig,...
    'String', 'Subject height (m)',...
    'HorizontalAlignment', 'left',...
    'FontWeight', 'bold',...
    'Units', 'normalized',...
    'Position', [0.46 0.84 0.15 0.04]);

input_scaleHeight = uicontrol('Style', 'edit',...
    'Tag', 'input_scaleHeight',...
    'String', '',...
    'FontWeight','bold',...
    'Units', 'normalized',...
    'Position', [0.46 0.84 0.075 0.02]);

pushbutton_scale = uicontrol('Style', 'pushbutton',...
    'Tag', 'push_scale',...
    'String', 'Scale model',...
    'FontWeight','bold',...
    'Units', 'normalized',...
    'Position', [0.62 0.84 0.15 0.04],...
    'Callback', @call_pushScale);
 
pushbutton_Undo = uicontrol('Style', 'pushbutton',...
    'String', 'Undo last action',...
    'Tag', 'pushbutton_Undo',...
    'FontWeight','bold',...
    'Units', 'normalized',...
    'Position', [0.46 0.78 0.15 0.05],...
    'Enable', 'off',...
    'Callback', @call_pushUndo);

pushbutton_Reset = uicontrol('Style', 'pushbutton',...
    'Parent', mainFig,...
    'String', 'Reset to original',...
    'Tag', 'pushbutton_Reset', ...
    'FontWeight','bold',...
    'Units', 'normalized',...
    'Enable', 'off',...
    'Position', [0.62 0.78 0.15 0.05],...
    'Callback', @call_pushReset);
 
pushbutton_exportLua = uicontrol('Style', 'pushbutton',...
    'String', 'Export lua model and .obj meshes',...
    'Tag', 'pushbutton_exportLua', ...
    'FontWeight','bold',...
    'Units', 'normalized',...
    'Enable', 'on',...
    'FontSize', 12,...
    'Position', [0.52 0.69 0.2 0.04],...
    'Callback', @call_pushExportLua);

pushbutton_exportObj = uicontrol('Style', 'pushbutton',...
    'String', 'Export .obj meshes',...
    'FontWeight','bold',...
    'FontSize', 12,...
    'Units', 'normalized',...
    'Position', [0.52 0.65 0.2 0.04],...
    'Callback', @call_pushExportObj);

pushbutton_exportStl = uicontrol('Style', 'pushbutton',...
    'String', 'Export .stl meshes',...
    'FontWeight','bold',...
    'FontSize', 12,...
    'Units', 'normalized',...
    'Position', [0.52 0.61 0.2 0.04],...
    'Callback', @call_pushExportStl);

% Plot Meshes
h1 = subplot('position',[0.04 0.02 0.4 0.55]);
title ('Original');
fnc_plotModel (UserData.model_orig, 1, UserData.bPlot_jointAxes, ...
    UserData.bPlot_landmarks, UserData.bPlot_markers);

h2 = subplot('position',[0.5 0.02 0.4 0.55]);
title('Current');
fnc_plotModel (UserData.model_current, 1, UserData.bPlot_jointAxes, ...
    UserData.bPlot_landmarks, UserData.bPlot_markers);
