# Cauvery Delta + adjoining coast: climate variability around Aadi Pattam
# Reproducible R workflow. One script. No API/network calls. Requires ggplot2.
# Copyright: your analysis code; weather data from Open-Meteo/ECMWF.

# Locate the script even when RStudio has another working directory.
.frame_paths <- lapply(sys.frames(), function(z) z$ofile)
.frame_paths <- Filter(function(x) is.character(x) && length(x) == 1L && nzchar(x), .frame_paths)
if (!length(.frame_paths)) {
  stop('Run via source("/FULL/PATH/Cauvery_Delta_R_Upgrade/analysis.R").')
}
.root <- dirname(normalizePath(tail(.frame_paths, 1L)[[1L]], mustWork = TRUE))
.output <- file.path(.root, 'outputs')
if (!dir.exists(.output)) dir.create(.output, recursive = TRUE)

if (!requireNamespace('ggplot2', quietly = TRUE)) {
  stop('One-time installation in RStudio: install.packages("ggplot2"); then click Source again.')
}

read_openmeteo <- function(path) {
  lines <- readLines(path, warn = FALSE)
  h <- grep('^location_id,time,', lines)
  if (length(h) != 1L) stop('Input is not the expected multi-location Open-Meteo CSV: ', basename(path))
  # Original metadata are above the blank row before the daily header.
  meta <- tryCatch(read.csv(path, skip = 1L, nrows = 8L, check.names = FALSE),
                   error = function(e) NULL)
  tab <- read.csv(path, skip = h - 1L, check.names = FALSE,
                  na.strings = c('NaN', 'NA', 'null', ''))
  field <- function(prefix, required = TRUE) {
    ix <- which(startsWith(names(tab), prefix))
    if (length(ix) != 1L) {
      if (!required) return(rep(NA_real_, nrow(tab)))
      stop('Missing or duplicated column ', prefix, ' in ', basename(path))
    }
    suppressWarnings(as.numeric(tab[[ix]]))
  }
  d <- data.frame(
    location_id = suppressWarnings(as.integer(tab[['location_id']])),
    date = as.Date(tab[['time']]),
    tmean = field('temperature_2m_mean'),
    rh = field('relative_humidity_2m_mean'),
    rain = field('precipitation_sum'),
    et0 = field('et0_fao_evapotranspiration'),
    tmax = field('temperature_2m_max', FALSE),
    vpd_max = field('vapour_pressure_deficit_max', FALSE)
  )
  list(data = d, meta = meta)
}

# Use the expanded file first, then fill any missing days from the VALIDATED
# July-2023--October-2026 file. Never manufacture weather values.
file_core <- file.path(.root, 'data', 'validated_jul2023_oct2026.csv')
file_full <- file.path(.root, 'data', 'full_apr2023_oct2026.csv')
if (!file.exists(file_core) && !file.exists(file_full)) {
  stop('No weather CSV found in data/. Keep at least one of the documented files.')
}
files <- c(if (file.exists(file_full)) file_full,
           if (file.exists(file_core)) file_core)
parts <- lapply(files, function(f) {
  cat('INPUT | Reading ', basename(f), '\n', sep = '')
  read_openmeteo(f)$data
})
d <- do.call(rbind, parts)
# New expanded data take priority when the two files overlap.
key <- paste(d$location_id, d$date)
d <- d[!duplicated(key), , drop=FALSE]
site_names <- c('Thanjavur','Kumbakonam','Tiruvarur','Mannargudi',
                'Mayiladuthurai','Sirkazhi','Nagapattinam','Karaikal')
if (!identical(sort(unique(d$location_id)), 0:7)) {
  stop('Expected 8 location_id values (0-7); inspect CSV metadata before analysis.')
}
d$site <- site_names[d$location_id + 1L]
d <- d[order(d$site,d$date), ,drop=FALSE]
if (anyNA(d[,c('location_id','date','tmean','rh','rain','et0')])) {
  stop('Required daily values are missing; inspect the CSV before publication.')
}
if (any(d$rain < 0 | d$et0 < 0 | d$rh < 0 | d$rh > 100)) {
  stop('Precipitation, ET0 or relative humidity outside an acceptable range.')
}
if (anyDuplicated(d[,c('location_id','date')])) stop('Duplicate location-date rows.')
# A missing date in e.g. January must NOT prevent an April--October analysis.
# Write an explicit QC table; analyze dates represented by all eight points.
all_dates <- seq(min(d$date), max(d$date), by='day')
qc <- expand.grid(location_id = 0:7, date = all_dates)
qc$has_record <- paste(qc$location_id, qc$date) %in% paste(d$location_id, d$date)
missing_dates <- qc[!qc$has_record, c('location_id','date')]
write.csv(missing_dates,file.path(.output,'QC_MISSING_SITE_DATES.csv'), row.names=FALSE)
if (nrow(missing_dates)) {
  cat('QC | Missing site-days:',nrow(missing_dates),
      '| first:',as.character(missing_dates$date[1]), '\n')
}
counts <- table(d$date)
complete_dates <- as.Date(names(counts[counts==8L]))
dropped_dates <- as.Date(names(counts[counts!=8L]))
if (length(dropped_dates)) {
  cat('QC | Excluding', length(dropped_dates), 'partly sampled dates (not filling weather).\n')
  d <- d[d$date %in% complete_dates,,drop=FALSE]
}
# Source record for all retained dates; no synthetic or substituted readings.
input_file <- if (file.exists(file_full)) file_full else file_core
# VPD from daily mean T and daily mean RH is a PROXY, not daily mean/max observed VPD.
es_kpa <- 0.6108 * exp(17.27 * d$tmean / (d$tmean + 237.3))
d$vpd_proxy <- es_kpa * (1 - d$rh/100)
d$year <- as.integer(format(d$date, '%Y'))
d$month <- as.integer(format(d$date, '%m'))

# Detect repeated GRIDDed rainfall series. Site values are NOT independent gauges.
rain_arrays <- split(d$rain, d$location_id)
rain_signatures <- vapply(rain_arrays, function(v) paste(sprintf('%.5f',v),collapse='|'), character(1))
unique_rain_ids <- as.integer(names(rain_signatures)[!duplicated(rain_signatures)])
cat('RUNNING | Sites:', paste(site_names, collapse=', '),'\n')
cat('RAIN | Independent-looking grid series:', length(unique_rain_ids), 'of 8 sampled sites\n')
cat('DATA |',format(min(d$date)),'through', format(max(d$date)), '\n')

# All-site daily sample means for weather. Rain averages only distinct grid series.
weather <- aggregate(d[,c('tmean','rh','et0','vpd_proxy')],
                     by=list(date=d$date), FUN=mean)
rain_rows <- d[d$location_id %in% unique_rain_ids,]
rain_daily <- aggregate(rain_rows$rain, by=list(date=rain_rows$date), FUN=mean)
weather$rain <- rain_daily$x[match(weather$date,rain_daily$date)]
weather$year <- as.integer(format(weather$date,'%Y'))
weather$month <- as.integer(format(weather$date,'%m'))
weather$day <- as.integer(format(weather$date,'%d'))
weather$tmax <- NA_real_
weather$vpd_max <- NA_real_
if (all(is.finite(d$tmax))) {
  mx <- aggregate(d$tmax, by=list(date=d$date), FUN=mean)
  weather$tmax <- mx$x[match(weather$date,mx$date)]
}
if (all(is.finite(d$vpd_max))) {
  vv <- aggregate(d$vpd_max, by=list(date=d$date), FUN=mean)
  weather$vpd_max <- vv$x[match(weather$date,vv$date)]
}
write.csv(d,file.path(.output,'daily_by_site.csv'),row.names=FALSE)
write.csv(weather,file.path(.output,'daily_sample_means.csv'),row.names=FALSE)

# Monthly aggregate. Rain/ET0 are TOTALS; T/RH/VPD are daily MEANS.
month_keys <- unique(weather[,c('year','month')])
monthly <- do.call(rbind, lapply(seq_len(nrow(month_keys)), function(k) {
  y <- month_keys$year[k]; m <- month_keys$month[k]
  x <- weather[weather$year==y & weather$month==m,]
  next_month <- if (m==12) as.Date(sprintf('%04d-01-01',y+1L)) else as.Date(sprintf('%04d-%02d-01',y,m+1L))
  days_in_month <- as.integer(next_month - as.Date(sprintf('%04d-%02d-01',y,m)))
  data.frame(year=y, month=m, days=nrow(x), complete_month=nrow(x)==days_in_month,
             rainfall_mm=sum(x$rain), et0_mm=sum(x$et0),
             temperature_C=mean(x$tmean), rh_percent=mean(x$rh),
             vpd_proxy_kPa=mean(x$vpd_proxy), tmax_C=if(all(is.finite(x$tmax))) mean(x$tmax) else NA_real_)
}))
monthly <- monthly[order(monthly$year,monthly$month),]
write.csv(monthly,file.path(.output,'monthly_comparison.csv'),row.names=FALSE)

# July–August establishment window: all 4 years are complete.
aadi <- do.call(rbind,lapply(2023:2026,function(y) {
  x <- weather[weather$year==y & weather$month %in% c(7,8),]
  if (nrow(x)!=62L) stop('July-August ',y,' has ',nrow(x),' of 62 days. Check QC_MISSING_SITE_DATES.csv; no values invented.')
  data.frame(year=y, rainfall_mm=sum(x$rain),et0_mm=sum(x$et0),
             temp_C=mean(x$tmean),rh_percent=mean(x$rh),vpd_proxy_kPa=mean(x$vpd_proxy),
             days_rain_below_1mm=sum(x$rain<1),
             days_above_35C=if(all(is.finite(x$tmax))) sum(x$tmax>35) else NA_integer_)
}))
write.csv(aadi,file.path(.output,'aadi_jul_aug_summary.csv'),row.names=FALSE)

# April–June leading conditions. Never create these estimates unless the CSV covers them.
has_summer <- all(vapply(2023:2026,function(y) {
  sum(weather$year==y & weather$month %in% 4:6)==91L
},logical(1)))
if (has_summer) {
  pre_aadi <- do.call(rbind,lapply(2023:2026,function(y) {
    x <- weather[weather$year==y & weather$month %in% 4:6,]
    data.frame(year=y, rainfall_mm=sum(x$rain),et0_mm=sum(x$et0),
               temp_C=mean(x$tmean),rh_percent=mean(x$rh),
               vpd_proxy_kPa=mean(x$vpd_proxy),days_rain_below_1mm=sum(x$rain<1))
  }))
  write.csv(pre_aadi,file.path(.output,'pre_aadi_apr_jun_summary.csv'),row.names=FALSE)
} else {
  cat('SUMMER | April-June data unavailable: pre-Aadi comparison NOT calculated.\n')
}

# Jul 1 through the same latest 2026 day, for all 4 years.
end_2026 <- max(weather$date[weather$year==2026])
monthday <- format(end_2026,'%m-%d')
matched <- do.call(rbind,lapply(2023:2026,function(y) {
  first <- as.Date(sprintf('%04d-07-01',y))
  last <- as.Date(sprintf('%04d-%s',y,monthday))
  x <- weather[weather$date >= first & weather$date <= last,]
  if(nrow(x) != as.integer(last-first+1)) stop('Year-matched period ',y,' has ',nrow(x),' days instead of ',as.integer(last-first+1),'. Check QC_MISSING_SITE_DATES.csv.')
  data.frame(year=y, days=nrow(x), rainfall_mm=sum(x$rain),et0_mm=sum(x$et0),
             temperature_C=mean(x$tmean),rh_percent=mean(x$rh),
             vpd_proxy_kPa=mean(x$vpd_proxy))
}))
write.csv(matched,file.path(.output,'matched_jul_to_current_cutoff.csv'),row.names=FALSE)

# --- Publication graphics: written by R, not externally generated. ---
palette <- c('2023'='#64748b','2024'='#0891b2','2025'='#2563eb','2026'='#c2410c')
theme_pub <- function() ggplot2::theme_minimal(base_size=13) +
  ggplot2::theme(plot.title=ggplot2::element_text(face='bold',size=16),
                 strip.text=ggplot2::element_text(face='bold'),
                 panel.grid.minor=ggplot2::element_blank(),
                 legend.position='bottom')
save_png <- function(name,p,width=12,height=7) {
  ggplot2::ggsave(file.path(.output,name),plot=p,width=width,height=height,dpi=220,bg='white')
  cat('FIGURE |',name,'\n')
}

# Figure 1: month-by-month view; incomplete 2026 October is visibly identified.
fields <- c(rainfall_mm='Rainfall total (mm)',et0_mm='FAO-56 ET0 total (mm)',
            temperature_C='Mean temperature (°C)',rh_percent='Mean humidity (%)',
            vpd_proxy_kPa='VPD proxy from T/RH (kPa)')
plot_monthly <- do.call(rbind,lapply(names(fields),function(k) {
  data.frame(year=factor(monthly$year),month=monthly$month,
             metric=fields[[k]],value=monthly[[k]],complete=monthly$complete_month)
}))
plot_monthly$metric <- factor(plot_monthly$metric,levels=unname(fields))
plot_monthly$month_name <- factor(month.abb[plot_monthly$month],levels=month.abb[4:12])
plot_monthly <- subset(plot_monthly, month %in% 4:12)
p1 <- ggplot2::ggplot(plot_monthly,ggplot2::aes(month_name,value,group=year,color=year)) +
  ggplot2::geom_line(linewidth=.85, na.rm=TRUE) +
  ggplot2::geom_point(ggplot2::aes(shape=complete),size=2.4,na.rm=TRUE) +
  ggplot2::scale_shape_manual(values=c('TRUE'=16,'FALSE'=1),name='Complete month') +
  ggplot2::scale_color_manual(values=palette,name='Year') +
  ggplot2::facet_wrap(~metric,scales='free_y',ncol=2) +
  ggplot2::labs(title='Monthly climate patterns | Cauvery Delta sampled locations',
       subtitle='Open symbols indicate incomplete months; rainfall excludes duplicate grid series',
       x=NULL,y=NULL,caption='Open-Meteo / ECMWF reanalysis. Eight sample points, not a spatial CDZ average.') +
  theme_pub()
save_png('01_month_by_month_2023_2026.png',p1,12,10)

# Figure 2: the four-year Aadi window in one reproducible figure.
aadi_l <- do.call(rbind,lapply(c('rainfall_mm','et0_mm','temp_C','vpd_proxy_kPa'),function(k) {
  data.frame(year=factor(aadi$year),metric=k,value=aadi[[k]])
}))
aadi_l$metric <- factor(aadi_l$metric,
  levels=c('rainfall_mm','et0_mm','temp_C','vpd_proxy_kPa'),
  labels=c('July-Aug rainfall (mm)','July-Aug reference ET0 (mm)',
           'Mean temperature (°C)','Mean VPD proxy (kPa)'))
p2 <- ggplot2::ggplot(aadi_l,ggplot2::aes(year,value,fill=year)) +
  ggplot2::geom_col(width=.68) + ggplot2::facet_wrap(~metric,scales='free_y',ncol=2) +
  ggplot2::scale_fill_manual(values=palette,guide='none') +
  ggplot2::labs(title='Aadi Pattam climate exposure | July–August',
       subtitle='Four comparable complete July–August periods, 2023–2026',x='Year',y=NULL,
       caption='Climate exposure indicators only; not measured seedling mortality or crop yield.') + theme_pub()
save_png('02_aadi_pattam_four_years.png',p2,11,8)

# Figure 3: cumulative July-August rainfall and smoothed VPD.
part <- subset(weather,month %in% 7:8 & year %in% 2023:2026)
part <- part[order(part$year,part$date),]
part$season_day <- as.integer(part$date-as.Date(paste0(part$year,'-07-01')))+1L
part$cum_rain <- ave(part$rain,part$year,FUN=cumsum)
part$vpd_7day <- unlist(lapply(split(part$vpd_proxy,part$year), function(v) {
   as.numeric(stats::filter(v,rep(1/7,7),sides=1))
}),use.names=FALSE)
p3 <- ggplot2::ggplot(part,ggplot2::aes(season_day,cum_rain,color=factor(year))) +
  ggplot2::geom_line(linewidth=1.1) + ggplot2::scale_color_manual(values=palette,name='Year') +
  ggplot2::labs(title='Rainfall timing through July–August',subtitle='Cumulative rainfall using six distinct modelled grid series',
      x='Day since 1 July',y='Cumulative mean-grid rainfall (mm)',
      caption='Gridded precipitation does not represent a farm rain gauge.') + theme_pub()
save_png('03_aadi_cumulative_rainfall.png',p3)
p4 <- ggplot2::ggplot(part,ggplot2::aes(season_day,vpd_7day,color=factor(year))) +
  ggplot2::geom_line(linewidth=1.1,na.rm=TRUE) + ggplot2::scale_color_manual(values=palette,name='Year') +
  ggplot2::labs(title='Atmospheric dryness during July–August',
      subtitle='Seven-day trailing mean of approximate VPD calculated from daily mean T and RH',
      x='Day since 1 July',y='VPD proxy (kPa)',
      caption='A daily-mean proxy; not directly observed maximum or leaf-to-air VPD.') + theme_pub()
save_png('04_aadi_vpd_timeline.png',p4)

# If optional daily Tmax and maximum VPD are supplied, add direct modelled hazard context.
if (all(is.finite(weather$tmax)) && all(is.finite(weather$vpd_max))) {
  heat <- subset(weather,month %in% c(7,8) & year %in% 2023:2026)
  heat$season_day <- as.integer(heat$date-as.Date(paste0(heat$year,'-07-01')))+1L
  hv <- do.call(rbind,lapply(c('tmax','vpd_max'),function(k) {
    data.frame(year=factor(heat$year),season_day=heat$season_day,
               metric=k,value=heat[[k]])
  }))
  hv$metric <- factor(hv$metric,levels=c('tmax','vpd_max'),
                      labels=c('Daily maximum temperature (°C)',
                               'Daily maximum VPD (kPa)'))
  ph <- ggplot2::ggplot(hv,ggplot2::aes(season_day,value,color=year)) +
    ggplot2::geom_line(alpha=.85,linewidth=.6) +
    ggplot2::facet_wrap(~metric,scales='free_y',ncol=1) +
    ggplot2::scale_color_manual(values=palette,name='Year') +
    ggplot2::labs(title='July–August: modelled heat and maximum atmospheric dryness',
      subtitle='Averaged across eight sampling points; not directly measured seedling injury',
      x='Day since 1 July',y=NULL) + theme_pub()
  save_png('06_daily_max_temperature_and_vpd.png',ph,11,8)
}

# Figure 5 requires real April–June observations; never fill missing months with values.
if (has_summer) {
  pre_p <- data.frame(year=pre_aadi$year,stage='Chithirai + Vaikasi (Apr-Jun)',
                      rainfall_rate_mm=pre_aadi$rainfall_mm/91,
                      et0_rate_mm=pre_aadi$et0_mm/91,
                      temp_C=pre_aadi$temp_C,vpd_proxy_kPa=pre_aadi$vpd_proxy_kPa)
  aadi_p <- data.frame(year=aadi$year,stage='Aadi (Jul-Aug)',
                       rainfall_rate_mm=aadi$rainfall_mm/62,
                       et0_rate_mm=aadi$et0_mm/62,
                       temp_C=aadi$temp_C,vpd_proxy_kPa=aadi$vpd_proxy_kPa)
  groupdat <- rbind(pre_p,aadi_p)
  pairs <- do.call(rbind,lapply(c('rainfall_rate_mm','et0_rate_mm','temp_C','vpd_proxy_kPa'),function(k) {
    data.frame(year=factor(groupdat$year),stage=groupdat$stage,
               metric=k,value=groupdat[[k]])
  }))
  pairs$metric <- factor(pairs$metric,
    levels=c('rainfall_rate_mm','et0_rate_mm','temp_C','vpd_proxy_kPa'),
    labels=c('Rainfall per day (mm/day)','ET0 per day (mm/day)','Mean temperature (°C)','Mean VPD proxy (kPa)'))
  p5 <- ggplot2::ggplot(pairs,ggplot2::aes(stage,value,fill=year)) +
    ggplot2::geom_col(position=ggplot2::position_dodge(width=.8),width=.7) +
    ggplot2::facet_wrap(~metric,scales='free_y',ncol=2) +
    ggplot2::scale_fill_manual(values=palette,name='Year') +
    ggplot2::labs(title='From pre-Aadi weather to Aadi establishment conditions',
       subtitle='April–June compared with July–August for each year',
       x=NULL,y=NULL,caption='Descriptive stage comparison, not proof of crop-stage causality.') +
    theme_pub() + ggplot2::theme(axis.text.x=ggplot2::element_text(angle=12,hjust=1))
  save_png('05_apr_jun_to_jul_aug.png',p5)
}

# Optional: make month-advancing GIF with R package gifski (not required for static figures).
if (requireNamespace('gifski',quietly=TRUE)) {
  frame_stops <- c('07-31','08-31','09-30',monthday)
  frame_stops <- unique(frame_stops)
  frame_paths <- character(0)
  for (f in seq_along(frame_stops)) {
    cutoff <- frame_stops[f]
    frame_data <- do.call(rbind,lapply(2023:2026,function(y) {
      x <- weather[weather$date>=as.Date(sprintf('%04d-07-01',y)) &
                   weather$date<=as.Date(sprintf('%04d-%s',y,cutoff)),]
      data.frame(year=factor(y),cumulative_rain_mm=sum(x$rain))
    }))
    gp <- ggplot2::ggplot(frame_data,ggplot2::aes(year,cumulative_rain_mm,fill=year)) +
      ggplot2::geom_col(width=.7) + ggplot2::scale_fill_manual(values=palette,guide='none') +
      ggplot2::coord_cartesian(ylim=c(0,max(matched$rainfall_mm)*1.1)) +
      ggplot2::labs(title=paste('Rainfall since July 1 | through',cutoff),
             subtitle='Same dates, 2023–2026 | 6 distinct gridded rainfall series',
             x=NULL,y='Cumulative rainfall (mm)') + theme_pub()
    fpath <- tempfile(fileext='.png')
    ggplot2::ggsave(fpath,plot=gp,width=9,height=5,dpi=120,bg='white')
    frame_paths <- c(frame_paths,fpath)
  }
  tryCatch(gifski::gifski(frame_paths,file.path(.output,'06_year_comparison.gif'),
                         width=1080,height=600,delay=1.5,progress=FALSE),
           error=function(e) message('GIF skipped, static figures remain usable: ',conditionMessage(e)))
  unlink(frame_paths)
} else cat('OPTIONAL GIF | To create the GIF later: install.packages("gifski")\n')

# Publishable data-driven finding lines; comparisons are descriptive only.
r2025 <- matched[matched$year==2025,]
r2026 <- matched[matched$year==2026,]
line <- function(x) paste0(x,'\n')
report <- c(
  '# Climate analysis: reproducible results (R-generated)', '',
  paste('Input files:',paste(basename(files),collapse=' + ')),
  paste('Daily records after quality screening:',nrow(d),'| Sample points:',length(site_names),
        '| Distinct gridded rainfall series:',length(unique_rain_ids)),
  paste('Available dates:',min(d$date),'to',max(d$date)),
  paste('Date-matched period: July 1 to',monthday,'in 2023–2026'), '',
  '## Observed reanalysis patterns (not measured agricultural outcomes)',
  sprintf('Sampled rainfall: 2025 %.1f mm vs 2026 %.1f mm.',r2025$rainfall_mm,r2026$rainfall_mm),
  sprintf('Reference ET0: 2025 %.1f mm vs 2026 %.1f mm.',r2025$et0_mm,r2026$et0_mm),
  sprintf('Daily mean T: 2025 %.2f °C vs 2026 %.2f °C.',r2025$temperature_C,r2026$temperature_C),
  sprintf('Daily mean RH: 2025 %.2f%% vs 2026 %.2f%%.',r2025$rh_percent,r2026$rh_percent),
  sprintf('VPD proxy: 2025 %.2f kPa vs 2026 %.2f kPa.',r2025$vpd_proxy_kPa,r2026$vpd_proxy_kPa), '',
  if (has_summer) 'April–June pre-Aadi comparison: available; see pre_aadi_apr_jun_summary.csv.' else
    'April–June pre-Aadi comparison: NOT AVAILABLE in the current input. No results inferred.',
  if (has_summer) sprintf('April–June 2025: rain %.1f mm, ET0 %.1f mm; April–June 2026: rain %.1f mm, ET0 %.1f mm.',
       pre_aadi$rainfall_mm[pre_aadi$year==2025],pre_aadi$et0_mm[pre_aadi$year==2025],
       pre_aadi$rainfall_mm[pre_aadi$year==2026],pre_aadi$et0_mm[pre_aadi$year==2026]) else
       'April–June climate comparisons require the optional expanded source CSV.', '',
  paste('Missing location-date records in input range:', nrow(missing_dates), '(details: QC_MISSING_SITE_DATES.csv)'), '',
  '## Scientific boundaries',
  '- Eight sampling points in and adjoining the Cauvery Delta; Karaikal is in Puducherry.',
  '- Point/grid averages are NOT area-weighted Cauvery Delta Zone observations.',
  '- Gridded rainfall is not a farm rain gauge; some locations share the same grid series.',
  '- VPD proxy uses daily mean temperature and RH; it is not a direct daily/hourly VPD product.',
  '- ET0 is well-watered grass-reference atmospheric demand, NOT actual crop ET.',
  '- Calendar Pattam windows overlap and vary by crop; applied here only as interpretive windows.',
  '- Four years describe variability; they cannot establish long-term climate change or ENSO causality.',
  '- No farmer yield losses, seedling mortality or technology savings have been estimated.', '',
  '## Attribution',
  'Contains modified Copernicus Climate Change Service information, accessed via Open-Meteo Historical Weather API.',
  'Weather data by Open-Meteo.com: https://open-meteo.com/en/docs/historical-weather-api',
  'Copernicus: https://cds.climate.copernicus.eu/',
  'Neither the European Commission nor ECMWF is responsible for uses of these adapted products.'
)
writeLines(report,file.path(.output,'RESEARCH_RESULTS_R_GENERATED.md'),useBytes=TRUE)
cat('\nCOMPLETE: R figures, analysis CSVs and report saved to ',.output,'\n',sep='')
