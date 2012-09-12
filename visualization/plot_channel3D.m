function H= plot_channel3D(epo, clab, varargin)
%plot_channel3D - Plot the Classwise averages of one channel. Plots 3D data,
%i.e. FreqLimuency x time x amplitude.
%
%Usage:
% H= plot_channel3D(EPO, CLAB, <OPT>)
%
%Input:
% EPO  - Struct of epoched signals, see makeEpochs
% CLAB - Name (or index) of the channel to be plotted.
% OPT  - struct or property/value list of optional properties:
%  .XUnit  - unit of x axis, default 'ms'
%  .YUnit  - unit of y axis, default epo.unit if this field
%                     exists, 'Hz' otherwise
%  .YDir     - 'normal' (low FreqLimuencies at bottom) or 'reverse'
%  .FreqLim     - A vector giving lowest and highest FreqLimuency. If not specified, 
%              and epo.wave_FreqLim exists the corresponding values are taken;
%              otherwise [1 size(epo.x,1)] is taken.
%  .PlotRef  - if 1 plot Reference interval (default 0)
%  .RefYPos     - y position of Reference line 
%  .RefWhisker - length of whiskers (vertical lines)
%  .Ref*     - with * in {'LineStyle', 'LineWidth', 'Color'}
%              selects the appearance of the Reference interval.
%  .Colormap - specifies the colormap for depicting amplitude. Give either
%              a string or a x by 3 Color matrix (default 'jet')
%  .CLim   - Define the Color (=amplitude) limits. If empty (default), 
%              limits correspond to the data limits.
%  .CLimPolicy - if 'sym', Color limits are symmetric (so that 0
%              corresponds to the middle of the colormap) (default
%              'normal')
%  .XGrid, ... -  many axis properties can be used in the usual
%                 way
%  .GridOverPatches - if 1 plot grid (default 0)
%  .Title   - title of the plot to be displayed above the axis. 
%             If OPT.title equals 1, the channel label is used.
%  .Title*  - with * in {'Color', 'FontWeight', 'FontSize'}
%             selects the appearance of the title.
%  .YTitle  - if set, the title is displayed within the axis, with its 
%             Y position corresponding to Ytitle (default [])
%  .ZeroLine  - draw an axis along the y-axis at x=0
%  .ZeroLine*  - with * in {'Color','Style'} selects the
%                drawing style of the axes at x=0/y=0
%
%Output:
% H - Handle to several graphical objects.
%
%Do not call this function directly, rather use the superfunction
%plot_channel. This function is an adapted version of plot_channel2D.
%
%See also plot_channel2D, grid_plot.

% Author(s): Matthias Treder Aug 2010

props = {'AxisType',                  'box',                  'CHAR';
         'YDir',                      'normal',               'CHAR';
         'XGrid',                     'on',                   'CHAR';
         'YGrid',                     'on',                   'CHAR';
         'Box',                       'on',                   'CHAR';
         'XUnit',                     '[ms]',                 'CHAR';
         'YUnit',                     '[\muV]',               'CHAR';
         'FreqLim',                   [],                     'DOUBLE[2]';
         'PlotRef',                   0,                      'BOOL';
         'RefCol',                    0.75,                   'DOUBLE';
         'RefLineStyle',              '-',                    'CHAR';
         'RefLineWidth',              2,                      'DOUBLE';
         'RefYPos',                   [],                     'DOUBLE';
         'RefWhisker',                [],                     'DOUBLE';
         'ZeroLine',                  1,                      'DOUBLE';
         'ZeroLineColor',             0.5*[1 1 1],            'DOUBLE[3]';
         'ZeroLineStyle',             '-',                    'CHAR';
         'LineWidth',                 2,                      'DOUBLE';
         'ChannelLineStyleOrder',     {'-','--','-.',':'},    'CELL{CHAR}'
         'Title',                     1,                      'BOOL';
         'TitleColor',                'k',                    'CHAR';
         'TitleFontSize',             get(gca,'FontSize'),    'DOUBLE';
         'TitleFontWeight',           'normal',               'CHAR';
         'YTitle',                    [],                     'DOUBLE';
         'SmallSetup',                0,                      'BOOL';
         'MultichannelTitleOpts',     {},                     'STRUCT';
         'Colormap',                  'jet',                  'CHAR|DOUBLE[- 3]'
         'CLim',                      [],                     'DOUBLE[2]';
         'CLimPolicy',                'normal',               'CHAR';
         'GridOverPatches',           1,                      'BOOL';
         'OversizePlot',              1,                      'DOUBLE'};

if nargin==0,
  H= props; return
end

opt= opt_proplistToStruct(varargin{:});
[opt, isdefault]= opt_setDefaults(opt, props);
opt_checkProplist(opt, props);

if isdefault.FreqLim,
  if isfield(epo,'wave_FreqLim')
    opt.FreqLim= [epo.wave_FreqLim(1) epo.wave_FreqLim(end)];
  else
    opt.FreqLim= [1 size(epo.x,1)];
  end
end

if max(sum(epo.y,2))>1,
  epo= proc_average(epo);
else
  % epo contains already averages (or single trials)
  % sort Classes
  [tmp,si]= sort([1:size(epo.y,1)]*epo.y);
  epo.y= epo.y(:,si);  % should be an identity matrix now
  epo.x= epo.x(:,:,:,si);
end

chan= chanind(epo, clab);
nChans= length(chan);
nClasses= size(epo.y, 1);

if nChans==0,
  error('channel not found'); 
elseif nChans>1,
  opt_plot= {'ZeroLine',0, 'Title',0, ...
            'GridOverPatches',0};
  tit= cell(1, nChans);
  for ic= 1:nChans,
    if ic==nChans,
      opt_plot([4 6])= {1};
    end
    ils= mod(ic-1, length(opt.ChannelLineStyleOrder))+1;
    H{ic}= plot_channel2D(epo, chan(ic), opt_rmifdefault(opt, isdefault), ...
                       opt_plot{:}, ...
                       'lineStyle',opt.ChannelLineStyleOrder{ils});
    hold on;
    tit{ic}= sprintf('%s (%s)', epo.clab{chan(ic)}, ...
                     opt.ChannelLineStyleOrder{ils});
    opt_plot{2}= 0;
  end
  hold off;
  H{1}.leg= NaN;
  H{1}.title= axis_title(tit, opt.MultichannelTitleOpts{:});
  ud= struct('type','ERP', 'chan',{epo.clab(chan)}, 'hleg',H{1}.leg);
  set(gca, 'userData', ud);
  return;
end

%% Post-process opt properties
if isequal(opt.Title, 1),
  opt.Title= epo.clab(chan);
end

if isdefault.XUnit && isfield(epo, 'XUnit'),
  opt.XUnit= ['[' epo.XUnit ']'];
end
if isdefault.YUnit && isfield(epo, 'YUnit'),
  opt.YUnit= ['[' epo.YUnit ']'];
end

if isdefault.RefYPos,
  opt.RefYPos = opt.FreqLim(1) + .9 * diff(opt.FreqLim);
end

if isdefault.RefWhisker,
  opt.RefWhisker = .05 * diff(opt.FreqLim);
end

if length(opt.RefCol)==1,
  opt.RefCol= opt.RefCol*[1 1 1];
end

%% Set missing optional fields of epo to default values
if ~isfield(epo, 't'),
  epo.t= 1:size(epo.x,2);
end

%% Plot data, zero line, ref ival, grid
H.ax= gca; cla

if ~isempty(opt.CLim)
  if strcmp(opt.CLimPolicy,'sym')  % make Color limits symmetric
    cm = abs(max(opt.CLim));
    opt.CLim = [-cm cm];
  end
  H.plot= imagesc([epo.t(1) epo.t(end)],opt.FreqLim, squeeze(epo.x(:,:,chan,:)), ...
    opt.CLim);
else
  H.plot= imagesc([epo.t(1) epo.t(end)],opt.FreqLim, squeeze(epo.x(:,:,chan,:)));

end
hold on;      

if opt.ZeroLine,
  line([0 0], get(gca,'YLim'), ...
                'Color',opt.ZeroLineColor, 'lineStyle',opt.ZeroLineStyle);
end

% Plot ref ival
if opt.PlotRef && isfield(epo, 'refIval'),
  xx = epo.refIval;
  yy = opt.RefYPos * [1 1];
  lopt = {'LineStyle',opt.RefLineStyle, 'LineWidth',opt.RefLineWidth, ...
    'Color', opt.RefCol};
  line(xx,yy,lopt{:});
  line([xx(1) xx(1)],[yy(1)-opt.RefWhisker yy(1)+opt.RefWhisker], ...
    lopt{:});
  line([xx(end) xx(end)],[yy(1)-opt.RefWhisker yy(1)+opt.RefWhisker], ...
    lopt{:});
end

if opt.GridOverPatches,
  plot_gridOverPatches(copy_struct(opt, 'XGrid','YGrid'));
end

%% More layout settings
colormap(opt.Colormap);
set(gca,'YDir',opt.YDir)
H.leg = NaN;

%% title and labels
if ~isequal(opt.Title, 0),
  if isempty(opt.Ytitle)
    H.title= title(opt.Title);
    set(H.title, 'Color',opt.TitleColor, ...
                 'fontWeight',opt.TitleFontWeight, ...
                 'FontSize',opt.TitleFontSize);
  else
    xx = sum(get(gca,'XLim'))/2; % middle
    H.title = text(xx,opt.Ytitle, opt.Title, ...
                 'Color',opt.TitleColor, ...
                 'fontWeight',opt.TitleFontWeight, ...
                 'FontSize',opt.TitleFontSize, ...
                 'HorizontalAlignment','center');
    
  end
end

H.xlabel = xlabel(opt.XUnit);
H.ylabel = ylabel(opt.YUnit);

% if ~isempty(H.hidden_objects),
%   move_objectBack(H.hidden_objects);
% % If we hide handles, those objects may pop to the front again,
% % e.g., when another object is moved to the background with moveObjetBack
% %  set(H.hidden_objects, 'handleVisibility','off');
% end
ud= struct('type','ERP', 'chan',epo.clab{chan}, 'hleg',H.leg);
set(H.ax, 'userData', ud);

if nargout==0,
  clear H,
end