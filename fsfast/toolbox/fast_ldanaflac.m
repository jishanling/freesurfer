function flac = fast_ldanaflac(anadir)
% flac = fast_ldanaflac(anadir)
%
% $Id: fast_ldanaflac.m,v 1.5 2006/08/18 22:40:58 greve Exp $

if(nargin ~= 1)
  fprintf('flac = fast_ldanaflac(anadir)\n');
  flac = [];
  return;
end

flac = fast_ldflac; % creates empty struct

flac.name = basename(anadir);

flac.mask = 'brain';
flac.con = [];
% format is handled diff than in fast_ldflac.m
flac.format = getenv('FSF_OUTPUT_FORMAT');
if(isempty(flac.format)) flac.format = 'nii'; end
flac.formatext = sprintf('.%s',flac.format);
%flac.ev = []; % Leave commented?


%----------- Read in the analysis.info -------------------
info = sprintf('%s/analysis.info',anadir);
designtype = 'event-related';
nconditions = 0;
fp = fopen(info,'r');
if(fp == -1)
  fprintf('ERROR: could not open %s\n',info);
  flac = [];
  return;
end
nthline = 1;
while(1)
  % scroll through any blank lines or comments
  while(1)
    tline = fgetl(fp);
    if(~isempty(tline) & tline(1) ~= '#') break; end
  end
  if(tline(1) == -1) break; end

  key = sscanf(tline,'%s',1);
  %fprintf('key = %s\n',key);
  
  switch(key)
   %case 'analysis',    flac.name = sscanf(tline,'%*s %s',1);
   case 'TR',          flac.TR          = sscanf(tline,'%*s %f',1);
   case 'fsd',         flac.fsd         = sscanf(tline,'%*s %s',1);
   case 'funcstem',    flac.funcstem    = sscanf(tline,'%*s %s',1);
   case 'maskstem',    flac.mask        = sscanf(tline,'%*s %s',1);
   case 'inorm',       flac.inorm       = sscanf(tline,'%*s %f',1);
   case 'runlistfile', flac.runlistfile = sscanf(tline,'%*s %s',1);
   case 'tpexclude',   flac.tpexcfile   = sscanf(tline,'%*s %s',1);
   case 'parname',     flac.parfile     = sscanf(tline,'%*s %s',1);
   case 'designtype',  designtype       = sscanf(tline,'%*s %s',1);
   case 'nconditions', nconditions      = sscanf(tline,'%*s %d',1);
   otherwise
    fprintf('INFO: key %s unrecognized, line %d, skipping\n',key,nthline);
  end
  nthline = nthline + 1;
end % while (1)
fclose(fp);

%----------- Read in the analysis.cfg -------------------
TER = flac.TR;
PolyOrder = 0;
gamexp = 2;
extreg = [];
nextreg = 0;
nskip = 0;
ncycles = 0;
delay = 0;
nspmhrfderiv = -1;
spmhrffit = 0;
cfg  = sprintf('%s/analysis.cfg',anadir);
fp = fopen(cfg,'r');
if(fp == -1)
  fprintf('ERROR: could not open %s\n',info);
  flac = [];
  return;
end
nthline = 1;
while(1)
  % scroll through any blank lines or comments
  while(1)
    tline = fgetl(fp);
    if(~isempty(tline) & tline(1) ~= '#') break; end
  end
  if(tline(1) == -1) break; end

  key = sscanf(tline,'%s',1);
  %fprintf('key = %s\n',key);
  
  switch(key)
   case '-gammafit',   
    gammafit = 1;
    gamdelay = sscanf(tline,'%*s %f',1);
    gamtau   = sscanf(tline,'%*s %*f %f',1);
   case '-gammaexp',   gamexp       = sscanf(tline,'%*s %f',1);
   case '-spmhrf',     
    nspmhrfderiv = sscanf(tline,'%*s %d',1);
    spmhrffit = 1;
    gammafit = 0;
   case '-polyfit',    PolyOrder   = sscanf(tline,'%*s %f',1);
   case '-TER',        TER         = sscanf(tline,'%*s %f',1);
   case '-autowhiten', flac.whiten = 1;
   case '-extreg',     extreg      = sscanf(tline,'%*s %s',1);
   case '-nextreg',    nextreg     = sscanf(tline,'%*s %d',1);
   case '-rescale',    flac.inorm  = sscanf(tline,'%*s %f',1);
   case '-nskip',      nskip       = sscanf(tline,'%*s %d',1);
   case '-prestim',    prestim     = sscanf(tline,'%*s %d',1);
   case '-timewindow', timewindow  = sscanf(tline,'%*s %d',1);
   case '-ncycles',    ncycles     = sscanf(tline,'%*s %d',1);
   case '-delay',      delay       = sscanf(tline,'%*s %f',1);
   case '-fwhm',       sscanf(tline,'%*s %f',1); % dont worry about it
   otherwise
    fprintf('INFO: key %s unrecognized, line %d, skipping\n',key,nthline);
  end
  nthline = nthline + 1;
end % while (1)
fclose(fp);

if(isempty(flac.fsd)) flac.fsd = 'bold'; end 
if(isempty(flac.funcstem)) 
  fprintf('ERROR: no funcstem specified in %s\n',flacfile);
  flac = [];
end

if(isempty(flac.acfsegstem)) flac.acfsegstem = 'acfseg'; end 

nthev = 1;
tline = sprintf('EV Baseline baseline nuis');
flac.ev(nthev) = flac_ev_parse(tline);
nthev = nthev+1;

if(strcmp(designtype,'event-related') | strcmp(designtype,'blocked'))
  for n=1:nconditions
    if(gammafit)
      tline = sprintf('EV Condition%02d gamma task %d %g %g %g 0 %g',...
		      n,n,gamdelay,gamtau,gamexp,TER);
    elseif(spmhrffit)
      tline = sprintf('EV Condition%02d spmhrf task %d %d %g',...
		      n,n,nspmhrfderiv,TER);
    else
      tline = sprintf('EV Condition%02d fir task %d %g %g %g %g',...
		      n,n,prestim,timewindow-prestim,TER);
      
    end
    flac.ev(nthev) = flac_ev_parse(tline);
    nthev = nthev+1;
  end
end

if(strcmp(designtype,'abblocked') | strcmp(designtype,'retinotopy'))
  % par file will have:
  %   stimtype  eccen (retinotopy)
  %   direction neg
  % rtopy output will go in ananame/{eccen,polar}
  % Need to add nuis on either side of fund and harm to be
  % compatible with selfreqavg
  period = ncycles * flac.TR;
  nharmonics = 1;
  tline = sprintf('EV Fourier fourier task %g %g %g',...
		  period,nharmonics,delay);
  flac.ev(nthev) = flac_ev_parse(tline);
  nthev = nthev+1;
end

if(PolyOrder > 0)
  tline = sprintf('EV Poly polynomial nuis %d',PolyOrder);
  flac.ev(nthev) = flac_ev_parse(tline);
  nthev = nthev+1;
end

if(~isempty(extreg))
  tline = sprintf('EV %s nonpar nuis %s %d',extreg,extreg,nextreg);
  flac.ev(nthev) = flac_ev_parse(tline);
  nthev = nthev+1;
end

%-------------- contrasts --------------------------
if(strcmp(designtype,'event-related') | strcmp(designtype,'blocked'))
  nthcon = 1;
  flac.con(nthcon).name = 'omnibus';
  flac.con(nthcon).sumev    = 0;
  flac.con(nthcon).sumevreg = 0;
  flac.con(nthcon).evrw     = [];
  flac.con(nthcon).varsm    = 0;
  for n=1:nconditions
    flac.con(nthcon).ev(n).name = sprintf('Condition%02d',n);
    flac.con(nthcon).ev(n).evw  = 1;
    flac.con(nthcon).ev(n).evrw = [];
  end
  nthcon = nthcon+1;
  flac.con(nthcon).name = 'allvfix';
  flac.con(nthcon).sumev    = 1;
  flac.con(nthcon).sumevreg = 1;
  flac.con(nthcon).evrw     = [];
  flac.con(nthcon).varsm    = 0;
  for n=1:nconditions
    flac.con(nthcon).ev(n).name = sprintf('Condition%02d',n);
    flac.con(nthcon).ev(n).evw  = 1;
    flac.con(nthcon).ev(n).evrw = [];
  end
  ncontrasts = nthcon;
end

% Check each contrast
for nthcon = 1:ncontrasts

  % Make sure that each EV in the contrast is an EV in the FLAC
  for nthev = 1:length(flac.con(nthcon).ev)
    evindex = flac_evindex(flac,flac.con(nthcon).ev(nthev).name);
    if(isempty(evindex))
      fprintf('Contrast EV %s is not in the model\n',...
	      flac.con(nthcon).ev(nthev).name);
      flac = [];
      return;
    end
  end
  
  % Compute the contrast matrices
  % May want to defer this until customize to account for EVs with
  % a variable number of regressors
  flactmp = flac_conmat(flac,nthcon);
  if(isempty(flactmp))
    fprintf('ERROR: with contrast %s in %s\n',...
	    flac.con(nthcon).name,flacfile);
    flac = [];
    return;
  end
  flac = flactmp;
end

return;
