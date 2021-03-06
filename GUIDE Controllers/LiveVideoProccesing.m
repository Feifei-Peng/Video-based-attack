function varargout = LiveVideoProccesing(varargin)
% LIVEVIDEOPROCCESING MATLAB code for LiveVideoProccesing.fig
%      LIVEVIDEOPROCCESING, by itself, creates a new LIVEVIDEOPROCCESING or raises the existing
%      singleton*.
%
%      H = LIVEVIDEOPROCCESING returns the handle to a new LIVEVIDEOPROCCESING or the handle to
%      the existing singleton*.
%
%      LIVEVIDEOPROCCESING('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in LIVEVIDEOPROCCESING.M with the given input arguments.
%
%      LIVEVIDEOPROCCESING('Property','Value',...) creates a new LIVEVIDEOPROCCESING or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before LiveVideoProccesing_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to LiveVideoProccesing_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help LiveVideoProccesing

% Last Modified by GUIDE v2.5 11-Jun-2017 21:32:50

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @LiveVideoProccesing_OpeningFcn, ...
                   'gui_OutputFcn',  @LiveVideoProccesing_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before LiveVideoProccesing is made visible.
function LiveVideoProccesing_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to LiveVideoProccesing (see VARARGIN)

% Choose default command line output for LiveVideoProccesing
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes LiveVideoProccesing wait for user response (see UIRESUME)
% uiwait(handles.figure1);
setImageBG('C:\V-B-A-Github\Images\GUI Backgruonds\video.jpg');
set(gcf, 'units','normalized','outerposition',[0 0 1 1]);

set(handles.vidAxis,'visible', 'off');

% --- Outputs from this function are returned to the command line.
function varargout = LiveVideoProccesing_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in faceCornerDetBtn.
function faceCornerDetBtn_Callback(hObject, eventdata, handles)
% hObject    handle to faceCornerDetBtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Create the face detector object.
faceDetector = vision.CascadeObjectDetector();

% Create the point tracker object.
pointTracker = vision.PointTracker('MaxBidirectionalError', 2);

% Create the webcam object.
cam = webcam();

% Capture one frame to get its size.
videoFrame = snapshot(cam);
frameSize = size(videoFrame);

% Create the video player object.
videoPlayer = vision.VideoPlayer('Position', [100 100 [frameSize(2), frameSize(1)]+30]);


runLoop = true;
numPts = 0;
frameCount = 0;
recognizedFrameCount = 0;
twoConsecutiveFrames=[];
maxNumOfFrames = 20;

while runLoop && frameCount < maxNumOfFrames

    % Get the next frame.
    videoFrame = snapshot(cam); %take a video snapshot
    videoFrameGray = rgb2gray(videoFrame); % convert the frame to gray scale image frame 
    frameCount = frameCount + 1;
    


    if numPts < 10 %if numPts smaller then 10 so we didn't recognize the face well and we want to detect it again or for the first time
        

        %if i doesn't recognize a face i will reset the twoConsecutiveFrames array and reset the counter. 
        twoConsecutiveFrames{1,1}=0;
        twoConsecutiveFrames{1,2}=0;
        recognizedFrameCount=0;
        
        % Detection mode.
        bbox = faceDetector.step(videoFrameGray); %detect faces
        hold on
        eyesDetect = vision.CascadeObjectDetector('EyePairBig'); %detect eyes area 
        step(eyesDetect,videoFrameGray); %set the eye detection on the videoFrameGray
        

        if (~isempty(bbox)) % if we recognized at least one face
                
            % Find corner points inside the detected face region (ROI).
            points = detectMinEigenFeatures(videoFrameGray, 'ROI', bbox(1, :));

            % Re-initialize the point tracker.
            xyPoints = points.Location; %get the x and y coords that build the face rectangle.
            numPts = size(xyPoints,1); % numPts get the num of points are located in the face
            release(pointTracker);
            initialize(pointTracker, xyPoints, videoFrameGray);

            % Save a copy of the points.
            oldPoints = xyPoints;

            % Convert the rectangle represented as [x, y, w, h] into an
            % M-by-2 matrix of [x,y] coordinates of the four corners. This
            % is needed to be able to transform the bounding box to display
            % the orientation of the face.
            bboxPoints = bbox2points(bbox(1, :)); %bboxPoints contain the four corners of the rectangle

            % Convert the box corners into the [x1 y1 x2 y2 x3 y3 x4 y4]
            % format required by insertShape.
            bboxPolygon = reshape(bboxPoints', 1, []);

            % Display a bounding box around the detected face.
            videoFrame = insertShape(videoFrame, 'Polygon', bboxPolygon, 'LineWidth', 3);
            
            hold on
            eyesDetect = vision.CascadeObjectDetector('EyePairBig');
            step(eyesDetect,videoFrameGray);

            % Display detected corners on the original snapshot.
            videoFrame = insertMarker(videoFrame, xyPoints, '+', 'Color', 'white');
        end

    else %numPts is bigger then 10 so we sure that we recognize the face and we want to start tracking on it. 
        % Tracking mode.
        

        
        [xyPoints, isFound] = step(pointTracker, videoFrameGray);
        visiblePoints = xyPoints(isFound, :);
        oldInliers = oldPoints(isFound, :);

        numPts = size(visiblePoints, 1);

        if numPts >= 10
            

            % Estimate the geometric transformation between the old points
            % and the new points.
            [xform, oldInliers, visiblePoints] = estimateGeometricTransform(...
                oldInliers, visiblePoints, 'similarity', 'MaxDistance', 4);

            % Apply the transformation to the bounding box.
            bboxPoints = transformPointsForward(xform, bboxPoints);

            % Convert the box corners into the [x1 y1 x2 y2 x3 y3 x4 y4]
            % format required by insertShape.
            bboxPolygon = reshape(bboxPoints', 1, []);

            % Display a bounding box around the face being tracked.
            videoFrame = insertShape(videoFrame, 'Polygon', bboxPolygon, 'LineWidth', 3);

            % Display tracked points.
            videoFrame = insertMarker(videoFrame, visiblePoints, '+', 'Color', 'white');

            % Reset the points.
            oldPoints = visiblePoints;
            setPoints(pointTracker, oldPoints);
            
  
            %I always want to compare between two consecutive frames and i saved it
            %I always override the past frame to save memory space.  
            
            bboxes = step(faceDetector, videoFrameGray);
            hold on
            eyesDetect = vision.CascadeObjectDetector('EyePairBig');
            step(eyesDetect,videoFrameGray);
            modulo = mod(recognizedFrameCount,2); 
            if modulo ==0
                twoConsecutiveFrames{1,1}=videoFrameGray;
                twoConsecutiveFrames{2,1}=bboxes;
                %axes(handles.axes1);
                %imshow(faceImage);
            else
                twoConsecutiveFrames{1,2}=videoFrameGray;
                twoConsecutiveFrames{2,2}=bboxes;

                %axes(handles.axes2);
                %imshow(faceImage);
            end

            
            recognizedFrameCount =recognizedFrameCount+1;
        
 
        end

    end

    % Display the annotated video frame using the video player object.
    step(videoPlayer, videoFrame);
    hold on
    EyeDetect = vision.CascadeObjectDetector('EyePairBig');
    step(EyeDetect,videoFrame);
    

    % Check whether the video player window has been closed.
    runLoop = isOpen(videoPlayer);
end


% Clean up.

clear cam;
release(videoPlayer);
release(pointTracker);
release(faceDetector);




function accDetectorBtn_Callback(hObject, eventdata, handles)
lastDir = pwd;
newDir = strcat(pwd,'\matlab_version');
cd(newDir);
main;

 
cd(lastDir); %come back to the last direction

function gridBtn_Callback(hObject, eventdata, handles)



function loadVideoBtn_Callback(hObject, eventdata, handles)

    lastDir = pwd;
    newDir = strcat(pwd,'\matlab_version');
    cd(newDir);
    %clear all
    clc
    addpath('PDM_helpers');
    addpath('fitting');
    addpath('models');
    addpath('face_detection');
    %% loading the patch experts
    [clmParams, pdm] = Load_CLM_params_vid();
    [patches] = Load_Patch_Experts( 'models/general/', 'svr_patches_*_general.mat', [], [], clmParams);
    % [patches] = Load_Patch_Experts( 'models/general/', 'ccnf_patches_*_general.mat', [], [], clmParams);
    clmParams.multi_modal_types  = patches(1).multi_modal_types;
    % load the face validator and add its dependency
    load('face_validation/trained/face_check_cnn_68.mat', 'face_check_cnns');
    [file, path] = uigetfile({'*.avi';'*.mpg'},'Select video file');
     vr = VideoReader(fullfile(path, file));
     vr.CurrentTime = 2.5; 
     assignin('base','vr',vr); %pass image to base workspace for data sharing between functions.

     currAxes1 = axes;
     currAxes1.Position=[0 0 0.7750 0.7150]; % axes position
     addpath('mexopencv-master\')
     detector = cv.CascadeClassifier('haarcascade_frontalface_alt2.xml');
     
     maxNumOfFrames = 60;
     frameCounter = 0 ;
     
     while hasFrame(vr) && frameCounter < maxNumOfFrames  %while the video is running
        frame = readFrame(vr); % read frame
        frameCounter =frameCounter+1;
        imshow(frame); %#####
        currAxes1.Visible = 'off';    
        im = cv.cvtColor(frame, 'RGB2GRAY'); %pars the image to gray scale
        im = cv.equalizeHist(im);
        boxes = detector.detect(im, 'ScaleFactor',1.3,'MinNeighbors',2, 'MinSize', [30,30]);   
        if isempty(boxes)          
            drawnow;
            continue;
        end
        
        if(size(boxes,2)>1)
            boxes = getMostDominanteFace(boxes);
        end
        
        % First attempt to use the Matlab one (fastest but not as accurate, if not present use yu et al.)   
        det_shapes = [];
        if(~isempty(boxes))
            boxes = cell2mat(boxes');
            % Convert to the right format
            bboxs = boxes';                
            % Correct the bounding box to be around face outline
            % horizontally and from brows to chin vertically
            % The scalings were learned using the Face Detections on LFPW, Helen, AFW and iBUG datasets
            % using ground truth and detections from openCV
            % Correct the widths
            bboxs(3,:) = bboxs(3,:) * 0.8534;
            bboxs(4,:) = bboxs(4,:) * 0.8972;                
            % Correct the location
            bboxs(1,:) = bboxs(1,:) + boxes(:,3)'*0.0266;
            bboxs(2,:) = bboxs(2,:) + boxes(:,4)'*0.1884;
            bboxs(3,:) = bboxs(1,:) + bboxs(3,:);
            bboxs(4,:) = bboxs(2,:) + bboxs(4,:);
        end
        for i=1:size(bboxs,2)
            % Convert from the initial detected shape to CLM model parameters,
            % if shape is available
            bbox = bboxs(:,i);
            num_points = numel(pdm.M) / 3;
            M = reshape(pdm.M, num_points, 3);
            width_model = max(M(:,1)) - min(M(:,1));
            height_model = max(M(:,2)) - min(M(:,2));
            a = (((bbox(3) - bbox(1)) / width_model) + ((bbox(4) - bbox(2))/ height_model)) / 2;
            tx = (bbox(3) + bbox(1))/2;
            ty = (bbox(4) + bbox(2))/2;
            % correct it so that the bounding box is just around the minimum
            % and maximum point in the initialised face
            tx = tx - a*(min(M(:,1)) + max(M(:,1)))/2;
            ty = ty + a*(min(M(:,2)) + max(M(:,2)))/2;
            % visualisation
            g_param = [a, 0, 0, 0, tx, ty]';
            l_param = zeros(size(pdm.E));
            [shape,~,~,lhood,lmark_lhood,view_used] = Fitting_from_bb(im, [], bbox, pdm, patches, clmParams, 'gparam', g_param, 'lparam', l_param);    
            % shape correction for matlab format
            shape = shape + 1;
            try    
                hold on;                  
                plot(shape(:,1), shape(:,2),'+m','MarkerSize',3);   
                drawnow expose;
                hold off;
            catch warn
                fprintf('%s', warn.message);
            end
        end
     end


    delete(vr);
    delete(gca);
    %cla(handles.vidAxis,'reset'); % clear the current image from the axis
    %set(handles.vidAxis,'visible', 'off');
    cd(lastDir);    





function axisClicked(hObject, eventdata, handles)



