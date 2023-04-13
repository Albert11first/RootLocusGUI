function varargout = AlbertRoot(varargin)
feature('DefaultCharacterSet','UTF-8');

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @AlbertRoot_OpeningFcn, ...
                   'gui_OutputFcn',  @AlbertRoot_OutputFcn, ...
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





function varargout = AlbertRoot_OutputFcn(hObject, eventdata, handles) 

%varargout{1} = handles.output;

%% Initialization Code
function AlbertRoot_OpeningFcn(hObject, eventdata, handles, varargin)



%guidata(hObject, handles);

hWait=waitbar(0.1,'Please wait while GUI initializes.');
nargin=length(varargin);
if (nargin==0)
    Sys=tf(1,[1 5 4 0]);
else
    if ( (nargin~=1) || (~isa(varargin{1},'tf')) && (~isa(varargin{1},'zpk')))
        disp(' ');
        disp('Root Locus Plotter - proper usage is ''AlbertRootGui(Sys)'',')
        disp('  where ''Sys'' is a transfer function object.');
        disp(' '); disp(' ');
        close(handles.AlbertRootFig);
        close(hWait);
        return
    end
    if (isa(varargin{1},'zpk'))
        varargin{1} = tf(varargin{1});% Turn zpk into tf
    end
    Sys=varargin{1};            % Get system
    [n,d,tfOK]=testTF(Sys);     % Check it
    Sys=tf(n,d);
    if (tfOK==0)
        close(handles.AlbertRootFig);
        close(hWait);
        return
    end
end
handles.Sys=Sys;    %The variable Sys is the transfer function.
handles.mag=1;      %xxx magnification.
set(handles.rbInfo,'Value',1);   %Choose first radio button.
set(handles.cbRLocGrid,'Value',0)

handles.output = hObject;

set(handles.popupSystems,'Value',1);
handles.ColorOrder=get(gca,'ColorOrder');  %Save color order;
handles.HighlightColor=[1 0.75 0.75];      %Color for highlights (pink).
waitbar(0.25);
guidata(hObject, handles);      % Save changes to handle.

waitbar(0.75);
loadSystems(handles);           % Load systems in workspace.
handles=guidata(hObject);       % Reload handles (changed in loadSystems)

%At this point basic GUI information is  set, the rest is system specific
% so make it a separate function so we can change systems later.
waitbar(0.75);
makeLocus(handles);
waitbar(1.0); pause(0.1);
close(hWait);


%% Make Root Locus

function makeLocus(handles)
RFig=handles.AlbertRootFig;
getSysInfo(handles);         % Get useful information about Xfer func.
handles=guidata(RFig);       % Reload handles (changed in getSysInfo)

InitRlocus(handles);
    set(handles.axRules,'Visible','off');  %Hide second plot.
    set(handles.txtKval,'Visible','off');  %Hide text on plot.
    set(handles.sldKIndex,'visible','off');%Hide slider.
   %set(handles.txtKStat,'visible','off');
    set(handles.txtKEdit,'visible','off');
    %set(handles.txtKeq0,'visible','off');  %Hide "K=0" text for slider.
    %set(handles.txtKeqInf,'visible','off');%Hide "K=Inf" text for slider.
    set(handles.cbInteract,'visible','off');%Hide Checkbox.
set(handles.PanelChooseRule,'SelectedObject',handles.rbInfo)
set(handles.lbRuleDescr,'String',RuleInfo(handles));


handles.interactive=0;
handles.kInd=0;   %Index into array of gain (K) values.

RLocusDispTF(handles);      % Disp Xfer function
guidata(RFig, handles);  % Update handles structure




%% set up console


function [n1,d1,tfOK]=testTF(mySys, ~)
tfOK=1;
if (~isa(mySys,'tf'))
    disp(' ');
    disp('Root Locus Plotter - transfer function systems only')
    disp(mySys)
    disp(' ');
    tfOK=0;
    beep;
    s{1}='System has improper transfer function.';
    s{2}='See command window for details.';
    waitfor(warndlg(s));
    return
end

minSys=minreal(mySys);
[n1,d1]=tfdata(minSys,'v');
o_num=length(roots(n1));  %Order of numerator
o_den=length(roots(d1));

[n2,~]=tfdata(mySys,'v');

if (length(n1)~=length(n2))
    disp(' ');
    disp('***************************Warning*****************************');
    disp('Original transfer function was:');
    disp(mySys);
    disp('Some poles and zeros were equal.  After cancellation:');
    disp(minSys)
    disp('The simplified transfer function is the one that will be used.');
    disp('**************************************************************');
    disp(' ');
    beep;
    s{1}='System has poles and zeros that cancel.';
    s{2}='See command window for details.';
    waitfor(warndlg(s));
end
if ~isequal(size(mySys.num), [1 1])  % Check for SISO
    disp(' ');
    disp('Root Locus Plotter - error.  SISO (Single Input Single Output)')
    disp('  systems only.');
    disp(mySys)
    disp(' ');
    tfOK=0;
    beep;
    s{1}='SISO systems only.';
    s{2}='See command window for details.';
    waitfor(warndlg(s));
    return
end

if (o_num>o_den)  %Check for proper transfer function
    disp(' ');
    disp('Root Locus Plotter - proper transfer functions only')
    disp('  (order of numerator <= order of denominator).');
    disp(mySys);
    disp(' ');
    tfOK=0;
    beep;
    s{1}='System has improper transfer function.';
    s{2}='See command window for details.';
    waitfor(warndlg(s));
    return
end

%Check sign of highest order terms
if ( sign(n1(end-o_num)) ~= sign(d1(end-o_den)) )
    disp(' ');
    disp('Root Locus Plotter - error.  Highest order term in numerator')
    disp('  and denominator must have same sign.');
    disp(mySys);
    disp(' ');
    tfOK=0;
    beep;
    s{1}='Signs of coefficients in transfer function incorrect.';
    s{2}='See command window for details.';
    waitfor(warndlg(s));
    return
end

%__________________________________________________________________________

function RLocusDispTF(handles)
% This function displays a tranfer function that is a helper function.
% It takes the transfer function of the and splits it
% into three lines so that it can be displayed nicely.  For example:
% "            s + 1"
% "H(s) = ---------------"
% "        s^2 + 2 s + 1"
% The numerator string is in the variable nStr,
% the second line is in divStr,
% and the denominator string is in dStr.

% Get numerator and denominator.
[n,d]=tfdata(handles.Sys,'v');
% Get string representations of numerator and denominator
nStr=poly2str(n,'s');  
dStr=poly2str(d,'s');
% Find length of strings.
LnStr=length(nStr);  LdStr=length(dStr);

if LnStr>LdStr
    %the numerator is longer than denominator string, so pad denominator.
    n=LnStr;                  %n is the length of the longer string.
    nStr=['        ' nStr];   %add spaces for characters at start of divStr.
    dStr=['        ' blanks(floor((LnStr-LdStr)/n)) dStr]; %pad denominator.
else
    %the demoninator is longer than numerator, pad numerator.
    n=LdStr;
    nStr=['        ' blanks(floor((LdStr-LnStr)/n)) nStr];
    dStr=['        ' dStr];
end

divStr='G(s)H(s)= ';
% for i=1:n,  divStr=[divStr '-']; end
divStr=[divStr repmat('-', 1, n)];
set(handles.txtXfer,'String',{nStr,divStr,dStr});
%Change type font and size.
set(handles.txtXfer,'FontName','Courier New')
set(handles.txtXfer,'FontSize',8)

guidata(handles.AlbertRootFig, handles);  %save changes to handles.
% ------------------End of function RLocusDispTF -------------------------


% ------This function gets all of the information from transfer function.-
function getSysInfo(handles)
sys=handles.Sys;
[num,den]=tfdata(sys,'v'); %Get (and save) numerator and denominator.
handles.Num=num; handles.Den=den;
[z,p]=zpkdata(sys,'v');  %Get zeros and poles (to accuracy of 0.01)
z=round(real(z)*100)/100+1i*round(imag(z)*100)/100;
p=round(real(p)*100)/100+1i*round(imag(p)*100)/100;
realZIndex=find(abs(imag(z))<1E-3); %Determine which are real (i.e., on
realPIndex=find(abs(imag(p))<1E-3); % the real axis)...
z(realZIndex)=real(z(realZIndex));  % and set imag part to zerp.
p(realPIndex)=real(p(realPIndex));
handles.Z=z; handles.P=p;  %Store zeros and poles.

m=length(z); n=length(p);  %Length of numerator and denominator.
q=n-m;                     %Number of zeros at infinity.
handles.M=m; handles.N=n; handles.Q=q; %Store values.

[~,k1]=rlocus(sys);  % Let Matlab calculate appropriate range for k
for i=1:(length(k1)-1) %Generate intermediate points (smoother plots)
    k(2*(i-1)+1)=k1(i);  %Take value of k, but also...
    k(2*i)=(k1(i)+k1(i+1))/2;   %generate new point between consecutive k's
end
%k(end)=1000*k(end-1);
[r,k]=rlocus(sys,k);       %Recalculate with finer sampling of k.
handles.R=r; handles.K=k;  %Save.

% Slider for "k" has stops at each value of "k."
set(handles.sldKIndex,'Max',length(k));
set(handles.sldKIndex,'Min',1);
set(handles.sldKIndex,'SliderStep',[1/length(k) 2/length(k)]);
set(handles.sldKIndex,'Value',1);
set(handles.txtKEdit,'String',sprintf('%5.3g',k(1)));


scale=1.5;
if ~isempty(z)
    rlPzMin=min(min(real(p)),min(real(z)))*scale;
    rlPzMax=max(max(real(p)),max(real(z)))*scale;
    imPzMax=max(max(imag(p)),max(imag(z)))*scale;
else %special case if there are no zeros.
    rlPzMin=min(real(p))*scale;
    rlPzMax=max(real(p))*scale;
    imPzMax=max(imag(p))*scale;
end

if q~=0 %if the locus goes to infinity, make plot "scale" times bigger.
    xmax=ceil(scale*rlPzMax); xmin=floor(scale*rlPzMin);
else % just a little bigger.
    xmax=ceil(rlPzMax+0.1); xmin=floor(rlPzMin-0.1);
end
handles.Xmax=max(xmax,1);  %Max is at least 1.
handles.Xmin=min(-1,xmin); %Min is less than -1.
handles.Ymax=max([ceil(1.5*imPzMax) 0.75*abs([xmax xmin]) 1]);

handles.Xmax=handles.Xmax/handles.mag;  %divide by magnification
handles.Xmin=handles.Xmin/handles.mag;
handles.Ymax=handles.Ymax/handles.mag;

% find all complex poles and zeros (for angles of departure...)
handles.cmplxZero=[]; handles.cmplxPole=[];
for i=1:length(z)
    if imag(z(i))>0, handles.cmplxZero(end+1)=z(i); end
end
for i=1:length(p)
    if imag(p(i))>0, handles.cmplxPole(end+1)=p(i); end
end

guidata(handles.AlbertRootFig, handles);  %save changes to handles.
%-------------------------------------------------------------------------


%------Draw locus on left-hand set of axes (unchanged thereafter)----------
function InitRlocus(handles)
axes(handles.axStatic); 
cla;
drawRLocus(handles,handles.axStatic,1.5,length(handles.K),...
    'Complete Root Locus');
%--------------------------------------------------------------------------






%% Utility funcitons and GUI control
% ____________________________________________________________________________________________________
% --- Executes on button press in Exit.
function pushbutton1_Callback(~, ~, handles)
disp(' ');
disp('Albert Root Locus GUI tool closed');
disp(' ');
disp(' ');
close(handles.AlbertRootFig);

% _________________________________________________________________________


% --- Executes on button press in Grid.
function cbRLocGrid_Callback(~, ~, handles)
if get(handles.cbRLocGrid,'Value') 
    axes(handles.axStatic);
    sgrid(0.1:0.2:0.9,1:1:2*sqrt((handles.Ymax)^2));
else
    InitRlocus(handles);
end

% _________________________________________________________________________


function PanelChooseRule_SelectionChangedFcn(hObject, eventdata, handles)
s = ' ';
set(handles.axRules,'Visible','on');   %Second axes visible.
set(handles.txtKval,'Visible','off');  %Text invisible.
set(handles.sldKIndex,'visible','off');%Slider invisible.
%set(handles.txtKStat,'visible','off');
set(handles.txtKEdit,'visible','off');

%set(handles.txtKeq0,'visible','off');
%set(handles.txtKeqInf,'visible','off');
set(handles.lbRuleDescr,'Value',1);     %Display starting at line 1.
set(handles.cbInteract,'visible','off');%Interaction option not visible.
set(handles.cbInteract,'Value',0);      %Interaction option is off.
handles.interactive=0;                  %Save interaction info.
guidata(handles.AlbertRootFig, handles); %save changes to handles.


switch get(handles.PanelChooseRule,'SelectedObject') 
    case handles.rbInfo,       
        s=RuleInfo(handles);
    case handles.rbSym,        
        s=RuleSymmetry(handles);
    case handles.rbNumBranch,  
        s=RuleNumBranch(handles);
    case handles.rbStartEnd,   
        s=RuleStartEnd(handles);
    case handles.rbRealAxis,   
        s=RuleRealAxis(handles);
    case handles.rbAsymptotes, 
        s=RuleAsymptotes(handles);
    case handles.rbBreakOutIn, 
        s=RuleBreakOutIn(handles);
    case handles.rbDepart,     
        s=RuleDepart(handles);
    case handles.rbArrive,     
        s=RuleArrive(handles);
    case handles.rbCrossImag,  
        s=RuleCrossImag(handles);
    case handles.rbFindGain
        s=RuleFindGain(handles);
        set(handles.cbInteract,'visible','on');
        set(handles.cbInteract,'string','Specify another pole location?');
    case handles.rbLocPos
        s=RuleLocPos(handles);
        set(handles.cbInteract,'visible','on');
        set(handles.cbInteract,'string','Change K and find roots?');
    otherwise
        beep
end

set(handles.lbRuleDescr,'String',s);  %Display string in window.
guidata(hObject, handles);  %save changes to handles.


% __________________________when there is a slider movement_______________________________________________

function sldKIndex_Callback(hObject, ~, handles)
kInd = round(get(hObject,'Value'));
set(hObject,'Value',kInd);
k=handles.K; r=handles.R; ColOrd=handles.ColorOrder;
axes(handles.axRules); 
cla;
if handles.interactive %If GUI is in interactive mode,
    handles.kInd=kInd;   %Get value;
    guidata(hObject, handles);  % Update handles structure
    s=RuleLocPos(handles);  %Get explantory string,
    set(handles.lbRuleDescr,'String',s); %...and display it.
end


set(handles.txtKval,'string',sprintf('K = %5.3g  ',k(kInd)));
set(handles.txtKEdit,'string',sprintf('%5.3g',k(kInd)));

drawRLocus(handles,handles.axRules,1.5,length(handles.K),...
    get(handles.txtKval,'string'));
for c=1:size(r,1)
    plot(real(r(c,kInd)),imag(r(c,kInd)),'o','MarkerSize',4,...
        'MarkerEdgeColor',ColOrd(mod(c,7)+1,:),...
        'MarkerFaceColor',ColOrd(mod(c,7)+1,:));
end


% _________________________________________________________________________
function cbInteract_Callback(hObject, ~, handles)
if get(handles.cbInteract,'Value')
    handles.interactive = 1;
    guidata(hObject,handles);
    switch get(handles.PanelChooseRule,'SelectedObject')
        case handles.rbFindGain
            s = RuleFindGain(handles);
            set(handles.lbRuleDescr,'String',s);
            set(handles.cbInteract,'Value',0);
        case handles.rbLocPos        %If "Find Locus Location"
            s=RuleLocPos(handles);     %... get string and display.
            set(handles.lbRuleDescr,'String',s);
        otherwise
            beep;
    end
else
    handles.interactive=0;
    guidata(hObject, handles);  % Update handles structure
    switch get(handles.panelChooseRule,'SelectedObject')
        case handles.rbFindGain
            s=RuleFindGain(handles);
            set(handles.lbRuleDescr,'String',s);
        case handles.rbLocPos
            s=RuleLocPos(handles);
            set(handles.lbRuleDescr,'String',s);
        otherwise
            beep;
    end
end
guidata(hObject, handles); 




% _________________________________________________________________________
function s=PlurStr(x,q)
switch(x)
    case 0
        s=['0 ' q 's'];
    case 1
        s=['1 ' q];
    otherwise
        s=sprintf('%g %ss',x,q);
end


function s=ListString(s1,x,s2,punct)
if isempty(x)
    s=[s1 '0 ' s2 's' punct];
else
    s=[s1 PlurStr(length(x),s2) ' at s =' CmplxString(x)];
    s(end)=punct;
end


function s=CmplxString(z)
s='';
if isempty(z)
    s='(None exist)';
else
    i=1;
    while i<=length(z)
        if isreal(z(i))
            s=sprintf('%s %5.2g, ',s,z(i));
        else
            s=sprintf('%s %5.2g%5.2gj, ',s,real(z(i)),imag(z(i)));
            i=i+1;
        end
        i=i+1;
    end
end
s(end-1)='';






%% Draw the root locus

function drawRLocus(handles,ax,w,numPts,titleString)
% Retrieve necessary information.
ColOrd=handles.ColorOrder; p=handles.P; z=handles.Z; r=handles.R;
axes(ax);   %Select proper axes.
plot(real(p),imag(p),'xk','MarkerSize',10);  %Plot poles
hold on
plot(real(z),imag(z),'ok','MarkerSize',10);  %Plot zeros
plot([handles.Xmin handles.Xmax],[0 0],'k:');%Plot axes.
plot([0 0],[-handles.Ymax handles.Ymax],'k:');

for c=1:size(r,1)   %Plot locus
    plot(real(r(c,1:numPts)),imag(r(c,1:numPts)),...
        'LineWidth',w,'Color',ColOrd(mod(c,7)+1,:));
end
box on;
axis([handles.Xmin handles.Xmax -handles.Ymax handles.Ymax]);
title(titleString); xlabel('\sigma (real part of s)');
ylabel('j\omega (imag part of s)');


function DrawArc(s,z,c,theta,r,label)
c2=c*3/4;
x=[0 r*cos(linspace(0,theta,10)) 0];  y=[0 r*sin(linspace(0,theta,10)) 0];
patch(x+real(z),y+imag(z),c,...
    'EdgeColor',c2,...
    'FaceAlpha',0.5,...
    'LineStyle',':');
plot([real(z) real(s)],[imag(z) imag(s)],'-.','Color',c2);
plot([real(z) real(z)+2*r],[imag(z) imag(z)],'-.','Color',c2);
text(real(z)+r*cos(theta/2),imag(z)+r*sin(theta/2)...
    ,label,'Color',c2,'FontSize',9);


%% Root Locus Rules

function s = RuleInfo(handles)
axes(handles.axRules);
cla;
set(handles.axRules,'Visible','off');
m=handles.M;  
n=handles.N;  
q=handles.Q;
z=handles.Z;  
p=handles.P;

s{1}='For the open loop transfer function, G(s)H(s):';
s{end+1}=ListString('We have n=', p, 'pole','.');
s{end+1}=ListString('We have m=', z, 'finite zero','.');
s{end+1}=['So there exists q=' PlurStr(q,'zero') ' as |s| goes to infinity'];
s{end}=[s{end} sprintf('  (q = n-m = %g-%g = %g).',n,m,q)];
s{end+1}=' ';
s{end+1}='We can rewrite the open loop transfer function as';
s{end+1}='G(s)H(s)=N(s)/D(s) where N(s) is the numerator polynomial, and';
s{end+1}='D(s) is the denominator polynomial. ';
s{end+1}=['N(s)=' poly2str(handles.Num,'s') ', and'];
s{end+1}=['D(s)=' poly2str(handles.Den,'s') '.'];
s{end+1}=' ';
s{end+1}='Characteristic Equation is 1+KG(s)H(s)=0, or 1+KN(s)/D(s)=0,';
s{end+1}=['or D(s)+KN(s) = ' poly2str(handles.Den,'s') '+ K(' ...
    poly2str(handles.Num,'s') ' ) = 0'];




%-----------------Describe symmetry---------------------------------------
function s=RuleSymmetry(handles)
%Axes off
axes(handles.axRules); cla; set(handles.axRules,'Visible','off')
s{1}='As you can see, the locus is symmetric about the real axis';
%-------------------------------------------------------------------------



%-----------------Number of branches--------------------------------------
function s=RuleNumBranch(handles)
% No graph
axes(handles.axRules); cla; set(handles.axRules,'Visible','off')
n=handles.N;
s{1}='The open loop transfer function, G(s)H(s), has ';
s{1}=[s{1} sprintf('%g poles, therefore the',n)];
s{2}=sprintf('locus has %g branches.',n);
s{3}=' ';
s{4}='Each branch is displayed in a different color.';
%-------------------------------------------------------------------------


%---------------Starting and ending points (i.e., poles and zeros)---------
function s=RuleStartEnd(handles)
% function s=RuleStartEnd(handles,ax)
% The second argument is really a dummy argument - if it is there, it does
% not create a graph (this is done for web page).  If it is not there, it
% shows locus on right axis and allows for user interaction.
del=0.02;   %Delay (for animation)
%Get pertinent information.
n=handles.N;   m=handles.M;   q=handles.Q;   p=handles.P;
z=handles.Z;   k=handles.K;   r=handles.R;   ColOrd=handles.ColorOrder;
%Show axes.
axes(handles.axRules); cla;

if nargin==1  %Plot on right axis in GUI.
    plot(real(p),imag(p),'xk','MarkerSize',10);
    hold on
    plot(real(z),imag(z),'ok','MarkerSize',10);
    plot([handles.Xmin handles.Xmax],[0 0],'k:');
    plot([0 0],[-handles.Ymax handles.Ymax],'k:');
    axis([handles.Xmin handles.Xmax -handles.Ymax handles.Ymax]);

    set(handles.txtKval,'Visible','on');
    set(handles.txtKval,'String','K = 0');
end
s{1}='Root locus starts (K=0) at poles of open ';
s{1}=[s{1} 'loop transfer function, G(s)H(s).'];
s{2}='These are shown by an "x" on the diagram above';
s{3}=' ';
if nargin==1  %Plot on right axis in GUI.
    set(handles.lbRuleDescr,'String',s);
    s{end+1}='As K increases, the location of closed loop poles move, as';
    s{end+1}='shown on diagram (the value of k is in upper left corner).';
    s{end+1}=' ';
    set(handles.lbRuleDescr,'String',s);
    for k1=2:length(k) %This loop creates an animation of the movement of
        %the locus as K varies.
        drawRLocus(handles,handles.axRules,1.5,k1,'Locus start/end points');
        set(handles.txtKval,'string',sprintf('K = %5.3g  ',k(k1)));
        for c=1:size(r,1)
            plot(real(r(c,k1)),imag(r(c,k1)),'o',...
                'MarkerSize',4,...
                'MarkerEdgeColor',ColOrd(mod(c,7)+1,:),...
                'MarkerFaceColor',ColOrd(mod(c,7)+1,:));
        end
        hold off
        pause(del);
    end
end
s{end+1}='As K goes to infinity the location of closed loop poles move';
s{end+1}='to the zeros of the open loop transfer function, G(s)H(s).';
if m~=0 %There are some finite zeros.
    s{end+1}='Finite zeros are shown by a "o" on the diagram above.';
end
if q~=0 %There are some zeros at infinity.
    s{end+1}=['Don''t forget we have ' 'we also have q=n-m='];
    s{end}=[s{end} PlurStr(q,'zero') ' at infinity.'];
    s{end+1}=['(We have n=' PlurStr(n,'finite pole') ', '];
    s{end}=[s{end} 'and m=' PlurStr(m,'finite zero') ').'];
end

if nargin==1  %Show slider for user interaction.
    s{end+1}=' ';
    s{end+1}='Use slider to change K and see resulting location of roots.';
    s{end+1}=' ';
    s{end+1}='To redo animation, deselect button (at left), then reselect.';

    set(handles.sldKIndex,'visible','on');
%    set(handles.txtKStat,'visible','on');
    set(handles.txtKEdit,'visible','on');

   % set(handles.txtKeq0,'visible','on');
   % set(handles.txtKeqInf,'visible','on');
    set(handles.sldKIndex,'value',get(handles.sldKIndex,'Max'));
    set(handles.txtKEdit,'String',handles.K(end));

end
%-----------------------------------


%--------Show locus on real axis------------------------------------------
function s=RuleRealAxis(handles,ax)
%Get pertinent information
cHiLt=handles.HighlightColor; p=handles.P; z=handles.Z;
%Determine which axes to use (GUI axes if no second argument, and a
%separate set of axes if there is a second argument - this is done for
%web page).
if nargin==1
    ax=handles.axRules;
end
axes(ax); cla; hold on;

s{1}='The root locus exists on real axis to left of an odd number of';
s{2}='poles and zeros of open loop transfer function, G(s)H(s), that are';
s{3}='on the real axis.';
s{4}='These real pole and zero locations are highlighted on diagram,';
s{5}='along with the portion of the locus that exists on the real axis.';
s{6}=' ';

% Find all poles and zero on real axis.
axisPoles=flipud(find(imag(p)==0));  %Flip to go highest->lowest.
axisZeros=flipud(find(imag(z)==0));

if ~isempty(axisPoles)      %We have poles on axis - highlight them.
    plot(p(axisPoles),0,'s',...
        'MarkerSize',12,...
        'MarkerEdgeColor',cHiLt,...
        'MarkerFaceColor',cHiLt);
end

if ~isempty(axisZeros)      %We have zeros on axis - highlight them.
    plot(z(axisZeros),0,'d',...
        'MarkerSize',12,...
        'MarkerEdgeColor',cHiLt,...
        'MarkerFaceColor',cHiLt);
end

%Put all poles and zeros that are on the axis in a single list, sorted.
lst=sort([p(axisPoles); z(axisZeros)],'descend');

if isempty(lst)  % If no elements on axis, no locus on axis.
    s{end+1}='No poles or zeros on axis, so locus does not';
    s{end+1}='exist along axis.';
else              % The locus exists between every other element on axis.
    s{end+1}='Root locus exists on real axis between:';
    for i=1:2:length(lst)
        if i==length(lst)
            s{end+1}=sprintf('   %5.2g and negative infinity',lst(i));
            plot([lst(i) handles.Xmin],[0 0],'Linewidth',6,'Color',cHiLt);
        else
            s{end+1}=sprintf('   %5.2g and %5.2g',lst(i),lst(i+1));
            plot([lst(i) lst(i+1)],[0 0],'Linewidth',6,'Color',cHiLt);
        end
    end
end

s{end+1}=' ';
s{end+1}='... because on the real axis,';
s{end+1}=ListString('  we have ', p(axisPoles), 'pole',',');
s{end+1}=ListString('  and we have ', z(axisZeros), 'zero','.');

%Draw the locus.
drawRLocus(handles,ax,1.5,length(handles.K),'Locus on Real Axis');
%-------------------------------------------------------------------------




%----------------Find (and show) asymptotes-------------------------------
function [s,doPlot]=RuleAsymptotes(handles, ax)
% Get pertinent information
q=handles.Q; n=handles.N; m=handles.M; p=handles.P; z=handles.Z;
cHiLt=handles.HighlightColor;

s{1}=' ';
s{1}='In the open loop transfer function, G(s)H(s),';
s{1}=[s{1} ' we have n=' PlurStr(n,'finite pole') ','];
s{2}=['and m=' PlurStr(m,'finite zero') ', therefore '];
s{2}=[s{2} 'we have q=n-m=' PlurStr(q,'zero') ' at infinity.'];
s{3}=' ';
if q==0  %If there are no asymptotes (q=0) we're done, make no plot.
    doPlot=0;
    axes(handles.axRules); cla; set(handles.axRules,'Visible','off')
    s{end+1}='Because q=0, there are no asymptotes.';
    return
end
doPlot=1;   %Make a plot on specified axes (GUI if no second argument to
%... function.
if nargin==1
    ax=handles.axRules;
end
axes(ax); cla; hold on;

%Do calcluations.
sump=sum(p); sumz=sum(z);  %Sum of poles and zeros.
sigma=real(sump-sumz)/q;   %Intersect on real axis.
theta=180/q;               %Angle of asymptotes

s{end+1}='Angle of asymptotes at odd multiples of 180/q ';
eStr=['(i.e., ' sprintf(' %g,',(1:2:q)*180/q)];
s{end}=[s{end} eStr(1:(end-1)) ').'];   %Strip off last comma.
s{end+1}=' ';
s{end+1}=ListString('There exists ', p, ' pole',',');
s{end+1}=sprintf('      ...so sum of poles=%g.',sump);
s{end+1}=ListString('There exists ', z, ' zero',',');
s{end+1}=sprintf('      ...so sum of zeros=%g.',sumz);
s{end+1}='(Imaginary components of poles and zeros, if any, cancel when';
s{end+1}='  summed because they appear as complex conjugate pairs.)';
s{end+1}=' ';
s{end+1}='Asymptote intersect is at ( (sum of poles)-(sum of zeros) )/q';
s{end+1}=sprintf('Intersect is at ((%g)-(%g))/%g = %g/%g = %5.3g',...
    sump,sumz,q,sump-sumz,q,sigma);
s{end}=[s{end} '  (highlighted by five pointed star).'];

if q==1
    s{end+1}='Since q=1, there is a single asymptote at 180';
    s{end+1}='(on negative real axis), so  intersect of this asymptote';
    s{end+1}='on the axis s not important (but it is shown anyway).';
end

plot(sigma,0,'p',...    %Plot intersect with big start.
    'MarkerSize',16,...
    'MarkerEdgeColor',cHiLt,...
    'MarkerFaceColor',cHiLt);
radius=max(get(gca,'YLim'))*5;   %Make radius big enough to go off page.
for i=0:(q-1)
    theta_i=(2*i+1)*theta*pi/180; %Plot asymptotes.
    line([sigma sigma+radius*cos(theta_i)],...
        [0 radius*sin(theta_i)],...
        'Color',cHiLt,...
        'LineStyle','--',...
        'LineWidth',4);
end
%Draw root locus.
drawRLocus(handles,ax,1.5,length(handles.K),...
    'Asymptotes as |s| goes to infinity');
%-------------------------------------------------------------------------



%--------------Break-out and break-in.

function s=RuleBreakOutIn(handles, ax)
s{1}='';
cHiLt=handles.HighlightColor;
if nargin==1
    ax=handles.axRules;
end
axes(ax); cla; hold on;
num=handles.Num;     %N(s)
den=handles.Den;     %D(s)
np=polyder(num);     %N'(s)
dp=polyder(den);     %D'(s)
p1=conv(np,den);     %p1=N'(s)D(s)
p2=conv(dp,num);     %p2=D'(s)N(s)
np1=length(p1);      %Next lines make p1 and p2 the same order.
np2=length(p2);
if np1>np2
    p2=[zeros(1,np1-np2) p2];
elseif np2>np1
    p1=[zeros(1,np2-np1) p1];
end
pn=p2-p1;            %pn=D'(s)N(s)-N'(s)D(s)
baway=roots(pn);     %breakaway are at roots of pn.

s{1}='Break Out (or Break In) points occur where ';
s{1}=[s{1} 'N(s)D''(s)-N''(s)D(s)=0, or'];
s{end+1}=[poly2str(pn,'s') ' = 0.     (details below*) '];
s{end+1}=' ';
s{end+1}=ListString('This polynomial has ', baway, 'root','.');
s{end+1}=' ';

% In the next loop, we determine the value of K at each root of "pn".  If K
% is real and positive, the point is on the locus.  If the point is also
% real, then it is one of our points.
realK=[];      %This will hold all breakaway location that occur at real
%...values of K,
posRealK=[];   %...this holds only those for positive real K.
for i=1:length(baway)
    %Find value of K at the baway location.
    kVal=-polyval(den,baway(i))/polyval(num,baway(i));
    if isreal(kVal)
        realK=[realK baway(i)];
        if kVal>=0 %If K is real and positive, this point is on locus
            %...so plot it with a square,
            posRealK=[posRealK baway(i)];
            plot(real(baway(i)),imag(baway(i)),'s',...
                'MarkerSize',10,...
                'MarkerEdgeColor',cHiLt,...
                'MarkerFaceColor',cHiLt);
        else
            %...else, plot it with a diamond (negative value of K).
            plot(real(baway(i)),imag(baway(i)),'d',...
                'MarkerSize',10,...
                'MarkerEdgeColor',cHiLt,...
                'MarkerFaceColor',cHiLt);
        end
    end
end
%Draw the root locus plot.
drawRLocus(handles,ax,1.5,length(handles.K),...
    'Break-away and Break-in points on real axis');
s{end+1}=['From these ' PlurStr(length(baway),'root')];
s{end}=[s{end} ListString( ', there exists ',realK,'real root','.')];
s{end+1}='These are highlighted on the diagram above (with squares ';
s{end}=[s{end} 'or diamonds.)'];
s{end+1}=' ';
if length(posRealK)~=length(realK)
    if isempty(posRealK)
        s{end+1}='None of the roots are on the locus.';
    else
        s{end+1}='Not all of these roots are on the locus.  ';
        s{end}=[s{end} 'Of these ' PlurStr(length(realK),'real root') ','];
        s{end+1}=ListString( 'there exists ',posRealK,'root',' ');
        s{end}=[s{end} 'on the locus (i.e., K>0).'];
        s{end+1}='Break-away (or break-in) points on the locus are shown ';
        s{end}=[s{end} 'by squares.'];
        s{end+1}=' ';
        s{end+1}='(Real break-away (or break-in) with K less than 0 are';
        s{end}=[s{end} ' shown with diamonds).'];
    end
else
    s{end+1}='These roots are all on the locus (i.e., K>0), ';
    s{end}=[s{end} 'and are highlighted with squares.'];
end
s{end+1}=' ';
s{end+1}='*  N(s) and D(s) are numerator and denominator polynomials';
s{end+1}='of G(s)H(s), and the tick mark, '', denotes differentiation.';
s{end+1}=['N(s) =' poly2str(num,'s')];
s{end+1}=['N''(s) =' poly2str(np,'s')];
s{end+1}=['D(s)=' poly2str(den,'s')];
s{end+1}=['D''(s)=' poly2str(dp,'s')];
s{end+1}=['N(s)D''(s)=' poly2str(p2,'s')];
s{end+1}=['N''(s)D(s)=' poly2str(p1,'s')];
s{end+1}=['N(s)D''(s)-N''(s)D(s)=' poly2str(pn,'s')];

s{end+1}=' ';
s{end+1}='Here we used N(s)D''(s)-N''(s)D(s)=0, but we could multiply';
s{end+1}='by -1 and use N''(s)D(s)-N(s)D''(s)=0.';
%------------------------------------------------------------------------


%-------------------------Angle of departure-----------------------------
function [s, doPlot]=RuleDepart(handles,ax)
cmplxPole=handles.cmplxPole;  %Get all the complex poles
if isempty(cmplxPole)        %... if none, we are done.
    axes(handles.axRules); cla; set(handles.axRules,'Visible','off')
    s{1}='No complex poles in loop gain, so no angles of departure.';
    doPlot=0;
    return
end
doPlot=1;
% Get pertinent information, and clear appropriate axes
z=handles.Z; p=handles.P; k=handles.K; cHiLt=handles.HighlightColor;
if nargin==1
    ax=handles.axRules;
end
axes(ax); cla;
%Draw the root locus.
drawRLocus(handles,ax,1.5,length(k),'Angle of departure shown in gray');

s='';
if length(cmplxPole)>1  %This is laborious, do in only once.
    s{1}='Loop gain has more than one pair of complex poles.  We will do';
    s{2}='analysis for only one pair.  Others are left as an exercise.';
    s{3}=' ';
end
cP=cmplxPole(1);   %Choose the complex conjugate to analyze.
s{end+1}=['Find angle of departure from pole at ' num2str(cP)];
s{end+1}='  Note: Theta_p2 denotes angle labeled theta with subscript p2.';
s{end+1}=' ';

% To understand the following, it is best to do an example and examine the
% resulting plot.
r=(handles.Xmax-handles.Xmin)/15;  %Radius for arcs drawn on plot.
sum_zeros=0;
for i=1:length(z)   %For each zero...
    theta=angle(cP-z(i));      %...find the angle to the chosen pole,
    sum_zeros=sum_zeros+theta; %...find sum of angles,
    %...draw arc on plot to show angle.
    DrawArc(cP,z(i),cHiLt,theta,r,['\theta_{z' num2str(i) '}']);
    if i==1 %Give more detail with first one, others will be succinct.
        s{end+1}=['Theta_z' num2str(i) '=angle((Departing pole)'...
            '- (zero at ' num2str(z(i)) ') ).'];
    end
    fs=['Theta_z' num2str(i)...
        '=angle((%s) - (%s)) = angle(%s) = %s'];
    s{end+1}=sprintf(fs,num2str(cP),num2str(z(i)),...
        num2str(cP-z(i)),num2str(theta*180/pi));
end
s{end+1}=' ';

sum_poles=0;
firstLine=1;   %Again, we will be more verbose with first angle, but this
%...may not be p(1), so this variable indicates first time
%...through loop.  Otherwise this code is almost identical
%...to that above.
for i=1:length(p)
    if p(i)~=cP   %Only examine angle to poles other than the one from
        %...which we are trying to find the angle of departure.
        theta=angle(cP-p(i));
        sum_poles=sum_poles+theta;
        DrawArc(cP,p(i),cHiLt,theta,r,['\theta_{p' num2str(i) '}']);
        if firstLine==1
            s{end+1}=['Theta_p' num2str(i) '=angle((Departing pole)'...
                '- (pole at ' num2str(p(i)) ') ).'];
            firstLine=0;
        end
        fs=['Theta_p' num2str(i)...
            '=angle((%s) - (%s)) = angle(%s) = %s'];
        s{end+1}=sprintf(fs,num2str(cP),num2str(p(i)),...
            num2str(cP-p(i)),num2str(theta*180/pi));
    end
end
s{end+1}=' ';

theta_D=pi+sum_zeros-sum_poles;  %Formula for angle of departure.
theta_D1=theta_D;
while theta_D<=-pi             %...it should be more then -pi
    theta_D=theta_D+2*pi;
end
while theta_D>=pi              %...and less than pi.
    theta_D=theta_D-2*pi;
end

s{end+1}='Angle of Departure is equal to:';
s{end+1}='Theta_depart = 180 + sum(angle to zeros) - ';
s{end}=[s{end} 'sum(angle to poles).'];
s{end+1}=['Theta_depart = 180 + ' num2str(sum_zeros*180/pi)...
    '-' num2str(sum_poles*180/pi) '.'];
s{end+1}=sprintf('Theta_depart = %5.3g.',theta_D1*180/pi);
if theta_D1 ~= theta_D
    s{end+1}=sprintf('This is equivalent to %5.3g.',theta_D*180/pi);
end
s{end+1}=' ';
s{end+1}='This angle is shown in gray.';
s{end+1}='It may be hard to see if it is near zero.';

%Draw angle of departure with a larger (grey) arc.
r=2*r;
DrawArc(cP+r*exp(1i*theta_D),cP,[0.8 0.8 0.8],theta_D,r,'\theta_{depart}');
%-------------------------------------------------------------------------


%------Angle of arrival---------------------------------------------------
%This code is so similar to that for the angle of departure, that it does
%no warrant its own set of comments.
function [s, doPlot]=RuleArrive(handles,ax)
cmplxZero=handles.cmplxZero;
if isempty(cmplxZero)
    axes(handles.axRules); cla; set(handles.axRules,'Visible','off')
    s{1}='No complex zeros in loop gain, so no angles of arrival.';
    doPlot=0;
    return
end
doPlot=1;
z=handles.Z; p=handles.P; k=handles.K; cHiLt=handles.HighlightColor;
if nargin==1
    ax=handles.axRules;
end
axes(ax); cla;
drawRLocus(handles,ax,1.5,length(k),'Angle of arrival shown in gray');

s='';
if length(cmplxZero)>1
    s{1}='Loop gain has more than one pair of complex zeros.  We will do';
    s{2}='analysis for only one pair.  Others are left as an exercise.';
    s{3}=' ';
end
chosenZero=1;
cZ=cmplxZero(chosenZero);   %Choose the complex conjugate to analyze.
s{end+1}=['Find angle of arrival to pole at ' num2str(cZ)];
s{end+1}='  Note: Theta_p2 denotes angle labeled theta with subscript p2.';
s{end+1}=' ';

r=(handles.Xmax-handles.Xmin)/15;
sum_zeros=0;
FirstLine=1;
for i=1:length(z)
    if z(i)~=cZ
        theta=angle(cZ-z(i));
        sum_zeros=sum_zeros+theta;
        DrawArc(cZ,z(i),cHiLt,theta,r,['\theta_{z' num2str(i) '}']);
        if FirstLine==1
            s{end+1}=['Theta_z' num2str(i) ...
                '=angle( (Arriving zero) - (zero at ' num2str(z(i)) ') ).'];
        end
        fs=['Theta_z' num2str(i)...
            '=angle((%s) - (%s)) = angle(%s) = %s'];
        s{end+1}=sprintf(fs,num2str(cZ),num2str(z(i)),...
            num2str(cZ-z(i)),num2str(theta*180/pi));
    end
end
s{end+1}=' ';

sum_poles=0;
for i=1:length(p)
    theta=angle(cZ-p(i));
    sum_poles=sum_poles+theta;
    DrawArc(cZ,p(i),cHiLt,theta,r,['\theta_{p' num2str(i) '}']);
    if i==1
        s{end+1}=['Theta_p' num2str(i) '=angle( (Arriving zero) - '...
            '(pole at ' num2str(p(i)) ') ).'];
    end
    fs=['Theta_p' num2str(i)...
        '=angle((%s) - (%s)) = angle(%s) = %s'];
    s{end+1}=sprintf(fs,num2str(cZ),num2str(p(i)),...
        num2str(cZ-p(i)),num2str(theta*180/pi));
end
s{end+1}=' ';

theta_D=pi-sum_zeros+sum_poles;
theta_D1=theta_D;
while theta_D<=-pi
    theta_D=theta_D+2*pi;
end
while theta_D>=pi
    theta_D=theta_D-2*pi;
end

s{end+1}='Angle of arrival is equal to:';
s{end+1}='Theta_arrive = 180 - sum(angle to zeros) + ';
s{end}=[s{end} 'sum(angle to poles).'];
s{end+1}=['Theta_arrive = 180 - ' num2str(sum_zeros*180/pi)...
    '+' num2str(sum_poles*180/pi) '.'];
s{end+1}=sprintf('Theta_arrive = %5.3g.',theta_D1*180/pi);
if theta_D1 ~= theta_D
    s{end+1}=sprintf('This is equivalent to %5.3g.',theta_D*180/pi);
end
s{end+1}=' ';
s{end+1}='This angle is shown in gray.';
s{end+1}='It may be hard to see if it is near 0.';

r=2*r;
DrawArc(cZ+r*exp(1i*theta_D),cZ,[0.8 0.8 0.8],theta_D,r,'\theta_{arrive}');
drawRLocus(handles,ax,1.5,length(k),'Angle of arrival shown in gray');
%-------------------------------------------------------------------------


%--------------------Crossing the Imaginary axis-------------------------
function [s,doPlot]=RuleCrossImag(handles, ax)
% Get pertinent infofmation.
k=handles.K;  ColOrd=handles.ColorOrder; r=handles.R;
n=0;     %n counts the number of values of k that cause crossing of axis
% in top half of s-plane (including real axis).
m=0;     %m keeps track of crossings in bottom half of s-plane (not
% including real axis.
%Determine where (and if) the locus crosses the imaginary axis.
for i=1:size(r,1)
    for j=1:(length(k)-2)  %Don't include last point (often equals Inf)
        %Check to see if locus has crossed the imaginary axis.
        x1=real(r(i,j));  x2=real(r(i,j+1));
        %      if (x1<=0 && x2>0) || (x1>0 && x2<0),
        if (x1*x2)<=0  %x1=0, x2=0, or x1 and x2 have different signs.
            %Only need to check for top half of s plane (and real axis),
            %because roots appear in complex conjugate pairs.
            if imag(r(i,j))>=0
                n=n+1;
                %kcross is approximate value of k where locus crosses axis,
                kcross(n)=interp1([x1 x2],[k(j) k(j+1)],0,'linear');
                %...wcross is approsimate value of frequency (omega).
                wcross(n)=interp1([x1 x2],[imag(r(i,j)) imag(r(i,j+1))],...
                    0,'linear');
                lcross(n)=i;   %keep track of which locus (for color on plot).
            else
                m=m+1;
                kcross2(m)=interp1([x1 x2],[k(j) k(j+1)],0,'linear');
                wcross2(m)=interp1([x1 x2],[imag(r(i,j)) imag(r(i,j+1))],...
                    0,'linear');
                lcross2(m)=i;
            end
        end
    end
end

if n==0
    doPlot=0;
    axes(handles.axRules); cla; set(handles.axRules,'Visible','off')
    s{1}='Locus does not cross imaginary axis.';
else
    doPlot=1;
    if nargin==1
        ax=handles.axRules;
    end
    axes(ax); cla;
    drawRLocus(handles,ax,1.5,length(k)','Locus Crossing Axis');
    s{1}=['Locus crosses imaginary axis at ' PlurStr(n,'value') ' of K.'];
    s{2}='These values are normally determined by using Routh''s method.';
    s{3}='This program does it numerically, and so is only an estimate.';
    s{end+1}=' ';
    s{end+1}=['Locus crosses where K =' sprintf(' %5.3g,',kcross)];
    s{end+1}='corresponding to crossing imaginary axis at s=';
    for i=1:n
        if wcross(i)==0
            s{end}=[s{end} ' 0,'];
        else
            s{end}=[s{end} sprintf(' %5.3gj,',wcross(i))];
        end
    end
    if n>1
        s{end}=[s{end} ' respectively.'];
    else
        s{end}(end)='.';
    end
    s{end+1}=' ';
    s{end+1}='These crossings are shown on plot.';

    for c=1:n %Plot each crossing of axis, along with value of K.
        plot(0,wcross(c),'o',...
            'MarkerSize',8,...
            'MarkerEdgeColor',ColOrd(mod(lcross(c),7)+1,:),...
            'MarkerFaceColor',ColOrd(mod(lcross(c),7)+1,:));
        text(-0.25,wcross(c),sprintf('K=%5.3g',kcross(c)),...
            'Color',ColOrd(mod(lcross(c),7)+1,:),...
            'HorizontalAlignment','Right',...
            'VerticalAlignment','bottom');
    end
    for c=1:m
        plot(0,wcross2(c),'o',...
            'MarkerSize',8,...
            'MarkerEdgeColor',ColOrd(mod(lcross2(c),7)+1,:),...
            'MarkerFaceColor',ColOrd(mod(lcross2(c),7)+1,:));
        text(-0.25,wcross2(c),sprintf('K=%5.3g',kcross2(c)),...
            'Color',ColOrd(mod(lcross2(c),7)+1,:),...
            'HorizontalAlignment','Right',...
            'VerticalAlignment','top');
    end
end
%------------------------------------------------------------------------


%-------Find K given location of roots-----------------------------------
function s=RuleFindGain(handles, ax)
%Set up axes and get pertinent information (as in functions above)
if nargin==1
    ax=handles.axRules;
end
axes(ax); cla;
k=handles.K;  r=handles.R;  cHiLt=handles.HighlightColor;
num=handles.Num;            den=handles.Den;

if handles.interactive
    set(handles.panelChooseRule,'visible','off');
    drawRLocus(handles,ax,1.5,length(k),'Choose location for pole.');
    s{1}='Choose spot on locus (on rightmost set of axes) to place a';
    s{2}='closed loop pole with crosshairs.';
    set(handles.lbRuleDescr,'String',s);
    [x,y]=ginput(1);
    s1=complex(x,y);
    set(handles.panelChooseRule,'visible','on');
else
    %Choose a value of s to demonstrate.
    %Try to find a value of s that is complex (with zeta near 0.7) to
    %illustrate the point described above.  We will search locus for the
    %midrange values of k.
    kStart=round(length(k)/4);   %Choose value of k near the beginning.
    kEnd=round(3*length(k)/4);   %Choose value of k near the end.
    %Search locus for point near zeta=0.7.
    rKeep=0;
    bestZeta=Inf;
    for k1=kStart:kEnd
        for r1=1:size(r,1)
            z=-real(r(r1,k1))/abs(r(r1,k1));  %Definition of zeta;
            if ((abs(z-0.7)<abs(bestZeta-0.7))) &&...
                    (real(r(r1,k1))<0) &&...
                    (imag(r(r1,k1))>0)
                bestZeta=z;
                rKeep=r1;
                kKeep=k1;
            end
        end
    end
    if bestZeta>0.99   %We didn't find any complex poles, so
        rKeep=1;                   %arbitrarily choose first locus, and
        kKeep=round(length(k)/2);  %arbitrarily choose middle k value.
    end

    s0=r(rKeep,kKeep);   %Choose value of s0 on locus.
    s1=s0*1.05;          %Purposely choose value of s not quite on locus
end
if abs(imag(s1))<0.001   %If close to real, make it real.
    s1=real(s1);
end

dVal=polyval(den,s1);
nVal=polyval(num,s1);
kVal=-dVal/nVal;

s{1}='Characteristic Equation is 1+KG(s)H(s)=0, or 1+KN(s)/D(s)=0, or';
s{end+1}=['K = -D(s)/N(s) = -(' poly2str(den,'s') ' ) / ('...
    poly2str(num,'s') ' )'];
s{end+1}='We can pick a value of s on the locus, and find K=-D(s)/N(s).';
s{end+1}=' ';

if isreal(s1)
    s{end+1}=sprintf('For example if we choose s=%5.3g,',s1);
    s{end+1}=sprintf('then D(s)=%5.3g, N(s)=%5.3g,',dVal,nVal);
    s{end+1}=sprintf('and K=-D(s)/N(s)=%5.3g.',kVal);
else
    s{end+1}=sprintf('For example if we choose s=%5.2g + %5.2gj',...
        real(s1),imag(s1));
    s{end}=[s{end} ' (marked by asterisk),'];
    s{end+1}=sprintf('then D(s)=%5.3g + %5.3gj,',real(dVal),imag(dVal));
    s{end}=[s{end}...
        sprintf('   N(s)=%5.3g + %5.3gj,',real(nVal),imag(nVal))];
    s{end+1}=sprintf('and K=-D(s)/N(s)=%5.3g + %5.3gj.',...
        real(kVal),imag(kVal));
    s{end+1}='This s value is not exactly on the locus, so K is complex,';
    kVal=real(kVal);
    s{end+1}=sprintf('(see note below), pick real part of K (%5.3g)',kVal);
end
np1=length(num);
np2=length(den);
ce=den+kVal*[zeros(1,np1-np2) num];
s2=roots(ce);
drawRLocus(handles,ax,1.5,length(k)',...
    sprintf('Design for pole at s=%5.3g + %5.3g',real(s1),imag(s1)));
for i=1:length(s2)     %Plot resulting roots.
    plot(real(s2(i)),imag(s2(i)),'o','MarkerSize',8,...
        'MarkerEdgeColor',cHiLt,'MarkerFaceColor',cHiLt);
end

plot(real(s1),imag(s1),'*','MarkerSize',8,...
    'MarkerEdgeColor',cHiLt*0.67,'MarkerFaceColor',cHiLt*0.67);

s{end+1}=' ';
s{end+1}=ListString('For this K there exist ',s2,...
    'closed loop pole','.');
s{end+1}='These poles are highlighted on the diagram with dots, the value';
s{end+1}='of "s" that was originally specified is shown by an asterisk.';
if nargin==1
    s{end+1}=' ';
    s{end+1}='Check the box above if you would like to specify another';
    s{end+1}='pole location, and use it to calculate the corresonding';
    s{end+1}='value of gain, K.';
end
s{end+1}=' ';
s{end+1}='Note: it is often difficult to choose a value of s that is';
s{end+1}='precisely on the locus, but we can pick a point that is close.';
s{end+1}='If the value is not exactly on the locus, then the calculated';
s{end+1}='value of K will be complex instead of real.  Just ignore the';
s{end+1}='the imaginary part of K (which will be small).';
s{end+1}=' ';
s{end+1}='Note also that only one pole location was chosen and this';
s{end+1}='determines the value of K.  If the system has more than one';
s{end+1}='closed loop pole, the location of the other poles are';
s{end+1}='determine solely by K, and may be in undesirable locations.';
%-------------------------------------------------------------------------


%------------Given K, determine location of roots-------------------------
function s=RuleLocPos(handles, ax)
%Set appropriate axes, and get pertinent info (as in functions above)
if nargin==1
    ax=handles.axRules;
end
axes(ax); cla;

ColOrd=handles.ColorOrder; k=handles.K;  r=handles.R;
num=handles.Num;           den=handles.Den;
s{1}='Characteristic Equation is 1+KG(s)H(s)=0, or 1+KN(s)/D(s)=0,';
s{end+1}=['or D(s)+KN(s) = ' poly2str(den,'s') '+ K(' ...
    poly2str(num,'s') ' ) = 0'];
s{end+1}=' ';
s{end+1}='So, by choosing K we determine the characteristic equation';
s{end+1}='whose roots are the closed loop poles.';
s{end+1}=' ';

if handles.kInd==0
    kInd=round(length(k)/2);   %Choose value of k in  middle of the range.
else
    kInd=handles.kInd;
end
kVal=k(kInd);

s{end+1}=sprintf('For example with K=%g, then the characteristic',kVal);
s{end}=[s{end} ' equation is'];
s{end+1}=['D(s)+KN(s) = ' poly2str(den,'s') ' + ' ...
    num2str(kVal) '(' poly2str(num,'s') ' ) = 0, or'];
np1=length(num);
np2=length(den);
ce=den+kVal*[zeros(1,np1-np2) num];
s{end+1}=[poly2str(ce,'s') '= 0'];
s{end+1}=' ';
if (kVal~=Inf)  %Find roots by factoring characteristic equation
    rts=roots(ce);
else            %Some roots are at infinitiy
    rts=Inf*ones(length(ce)-1,1);   %put all roots at infinity
    if ~isempty(roots(num))
        rts(1:(length(num)-1))=roots(num);  %Replace some of the infinite roots
    end
end
s{end+1}=ListString('This equation has ', rts, 'root','.');
s{end+1}='These are shown by the large dots on the root locus plot';
drawRLocus(handles,ax,1.5,length(k)',['Roots at K=' num2str(kVal)]);
for c=1:size(r,1)
    plot(real(r(c,kInd)),imag(r(c,kInd)),'o',...
        'MarkerSize',6,...
        'MarkerEdgeColor',ColOrd(mod(c,7)+1,:),...
        'MarkerFaceColor',ColOrd(mod(c,7)+1,:));
end

if handles.interactive
    s{end+1}=' ';
    s{end+1}='Use slider to change K from this initial value and see the';
    s{end+1}='resulting location of the closed loop poles (roots of';
    s{end+1}='characteristic equation).';
    s{end+1}='   Note: this allows you to choose a large range of values';
    s{end+1}='   between 0 and infinity.  For larger values of K the roots';
    s{end+1}='   may not be visible due to scaling of axes of the graph.';

    set(handles.txtKval,'string',sprintf('K =%5.3g',kVal));
    set(handles.txtKval,'Visible','on');
    set(handles.sldKIndex,'visible','on');
    set(handles.txtKStat,'visible','on');
    set(handles.txtKEdit,'visible','on');
    set(handles.txtKeq0,'visible','on');
    set(handles.txtKeqInf,'visible','on');
    set(handles.sldKIndex,'value',kInd);
else
    if nargin==1
        s{end+1}=' ';
        s{end+1}='Check the box above if you would like to change the value';
        s{end+1}='of K and see the resulting roots.';
        set(handles.txtKval,'string',sprintf('K =%5.3g',kVal));
        set(handles.txtKEdit,'string',sprintf('%5.3g',kVal));
        set(handles.txtKval,'Visible','on');
    else
        set(handles.txtKval,'Visible','off');
        set(handles.sldKIndex,'visible','off');
        set(handles.txtKStat,'visible','off');
        set(handles.txtKEdit,'visible','off');
        set(handles.txtKeq0,'visible','off');
        set(handles.txtKeqInf,'visible','off');
    end
end
%-------------------------------------------------------------------------



function txtKEdit_Callback(hObject, eventdata, handles)

kSet=str2double(get(hObject,'String'));     %Get k value
kSet=abs(kSet);                             %Make it positive
% Insert new value of k into array and recalculate root locus
sys=handles.Sys;  k=handles.K;
klow=k(k<kSet);             %Find all values below new value;
khigh=k(k>kSet);            %Find all values above
k=[klow kSet khigh];        %Insert new value in array
[r,k]=rlocus(sys,k);        %Recalculate root locus.
handles.R=r; handles.K=k;   %Save.
set(handles.sldKIndex,'Max',length(k));         %adjust max slider val
set(handles.sldKIndex,'Value',length(klow)+1);  %adjust slider
handles.kInd=length(klow)+1;
guidata(hObject, handles);  %save changes to handles.
RuleLocPos(handles);        %Plot

% --- Executes during object creation, after setting all properties.
function txtKEdit_CreateFcn(hObject, ~, ~)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function mySys=getSISOsysGUI
%  Create and  hide the GUI as it is being constructed.
f = figure('Visible','off',...
    'MenuBar','none',...
    'Resize','off',...
    'Position',[500,360,300,120],...
    'Name','Choose System from Workspace',...
    'NumberTitle','off');
%  Construct the components.

% Find all valid transfer functions in workspace
s=evalin('base','whos(''*'')');
tfs=char(s.class);             %x=class of all variable
tfs=strcmp(cellstr(tfs),'tf');    %Convert to cell array and find tf's
s=s(tfs);                         %Get just tf's
vname=char(s.name);
% x=cell(length(s)+1,2);
j=1;
varName{j}='User Systems';
varTF{j}=[];
for i=1:length(s)
    myTF=evalin('base',vname(i,:));
    if (isequal(size(myTF.num), [1 1]))   %Check for siso
        [n,d]=tfdata(myTF,'v');
        o_num=length(roots(n));     %Order of numerator
        o_den=length(roots(d));
        if (o_num<=o_den)         %Check for proper transfer functions
            if sign(n(end-o_num)) == sign(d(end-o_den))  %Check for signs
                j=j+1;
                varName{j}=vname(i,:);
                varTF{j}=myTF;
            end
        end
    end
end
htext = uicontrol('Style','text','String','Choose System',...
    'Position',[75,100,150,15]);
hpopup = uicontrol('Style','popupmenu',...
    'String',varName,...
    'Position',[75,70,150,25],...
    'Callback',{@popup_menu_Callback});
hbutton = uicontrol('Style','pushbutton',...
    'String','Valid Systems?',...
    'Position',[75,15,150,25],...
    'Callback',@validSys_Callback);
align([htext,hpopup,hbutton],'Center','None');

% Assign the GUI a name to appear in the window title.
movegui(f,'center');
set(f,'Visible','on');
uiwait(f);
j=get(hpopup,'Value')-1;
if j==0      %no tf chosen
    mySys=[];
else
    mySys = varTF{j};
end
close(gcf)

% Resume GUI when value is chosen
function popup_menu_Callback(~,~)
uiresume

function validSys_Callback(~,~)
s{1}='Restrictions on systems:';
s{2}=' 1) SISO (Single Input Single Output);';
s{3}=' 2) Proper systems (order of num <= order of den);';
s{4}=' 3) Sxxign of highest order num and den coefficients are equal.';
s{5}=' 4) System must be a transfer function (i.e., not state space...)';
s{6}=' 5) Cannot find crossing of imag axis if locus exists only on axis.';
% disp(s);
beep
helpdlg(s,'Valid Systems');

% --- Executes on selection change in popupSystems.
function popupSystems_Callback(hObject, ~, handles)
i=get(hObject,'Value');
if  i ~= 1   %If this is not the "User Systems" choice
    if i==2  %This is the refresh choice
        loadSystems(handles);
        handles=guidata(handles.RLocusGuiFig);       % Reload handles
    else        %THis is a valid choice, pick transfer function.
        x=handles.WorkSpaceTFs(i);
        handles.Sys=x{1};
    end
end
set(hObject,'Value',1);         %Display "User Systems" messag in dropdown
set(handles.rbInfo,'Value',1);   %Choose first radio button.
guidata(hObject, handles);
makeLocus(handles);

% --- Executes on button press in pbValid.
function pbValid_Callback(~, ~, ~)
s{1}='Restrictions on systems:';
s{2}=' 1) SISO (Single Input Single Output);';
s{3}=' 2) Proper systems (order of num <= order of den);';
s{4}=' 3) Sign of highest order num and den coefficients are equal.';
s{5}=' 4) System must be a transfer function (i.e., not state space...)';
s{6}=' 5) If locus is only on imag axis, crossing of axis not found.';
helpdlg(s,'Valid Systems');

function loadSystems(handles)
[v_name, v_tf]=getBaseTFs;
set(handles.popupSystems,'String',v_name);
handles.WorkSpaceTFs=v_tf;
guidata(handles.AlbertRootFig, handles);  %save changes to handles.

function [varName, varTF]=getBaseTFs
% Find all valid transfer functions in workspace
s=evalin('base','whos(''*'')');
tfs=char(s.class);             %x=class of all variable
tfs=strcmp(cellstr(tfs),'tf');    %Convert to cell array and find tf's
s=s(tfs);                         %Get just tf's
vname=char(s.name);

varName{1}='User Systems';
varTF{1}=[];
varName{2}='Refresh Systems';
varTF{2}=[];
j=2;
for i=1:length(s)
    myTF=evalin('base',vname(i,:));
    if (isequal(size(myTF.num), [1 1]))    %Check for siso
        [n,d]=tfdata(myTF,'v');
        o_num=length(roots(n));   %Order of numerator
        o_den=length(roots(d));
        if (o_num<=o_den)        %Check for proper transfer functions
            if sign(n(end-o_num)) == sign(d(end-o_den))  %Check for signs
                j=j+1;
                varName{j}=vname(i,:);
                varTF{j}=myTF;
            end
        end
    end
end


function butZoom_Callback(hObject, eventdata, handles)
if handles.mag==1
    handles.mag=handles.mag*4;
    set(hObject,'String','Zoom Out');
else
    handles.mag=1;
    set(hObject,'String','Zoom In');
end
guidata(hObject, handles);  %save changes to handles.
makeLocus(handles);
set(handles.cbRLocGrid,'Value',0)




% _________________________________________________________________________
% --- Executes on button press in radiobutton8.
function radiobutton8_Callback(hObject, eventdata, handles)

function radiobutton9_Callback(hObject, eventdata, handles)

function radiobutton11_Callback(hObject, eventdata, handles)

function radiobutton12_Callback(hObject, eventdata, handles)

function radiobutton13_Callback(hObject, eventdata, handles)

function radiobutton13_KeyPressFcn(hObject, eventdata, handles)

function radiobutton13_ButtonDownFcn(hObject, eventdata, handles)

function rbCrossImg_Callback(hObject, eventdata, handles)


function rbFindGain_Callback(hObject, eventdata, handles)

function rbLocPos_Callback(hObject, eventdata, handles)

function rbInfo_Callback(hObject, eventdata, handles)

function PanelChooseRule_CreateFcn(hObject, eventdata, handles)

function rbSym_ButtonDownFcn(hObject, eventdata, handles)

function rbSym_Callback(hObject, eventdata, handles)

function rbNumBranch_Callback(hObject, eventdata, handles)


% --- Executes on slider movement.

% hObject    handle to KIndex (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function KIndex_CreateFcn(hObject, eventdata, handles)
% hObject    handle to KIndex (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.


function sldKIndex_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sldKIndex (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end




% hObject    handle to txtKEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtKEdit as text
%        str2double(get(hObject,'String')) returns contents of txtKEdit as a double


% --- Executes during object creation, after setting all properties.
%function txtKEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtKEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function txtKval_Callback(hObject, eventdata, handles)
% hObject    handle to txtKval (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtKval as text
%        str2double(get(hObject,'String')) returns contents of txtKval as a double


% --- Executes during object creation, after setting all properties.
function txtKval_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtKval (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in lbRuleDescr.
function lbRuleDescr_Callback(hObject, eventdata, handles)
% hObject    handle to lbRuleDescr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns lbRuleDescr contents as cell array
%        contents{get(hObject,'Value')} returns selected item from lbRuleDescr


% --- Executes during object creation, after setting all properties.
function lbRuleDescr_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lbRuleDescr (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupSystems.
%function popupSystems_Callback(hObject, eventdata, handles)
% hObject    handle to popupSystems (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupSystems contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupSystems


% --- Executes during object creation, after setting all properties.
function popupSystems_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupSystems (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in butZoom.

% hObject    handle to butZoom (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
