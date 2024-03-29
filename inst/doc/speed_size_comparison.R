## ----setup, include=FALSE-----------------------------------------------------
knitr::opts_chunk$set(echo = TRUE, eval=FALSE)
options(rmarkdown.html_vignette.check_title = FALSE)
data.table::setDTthreads(2)

## -----------------------------------------------------------------------------
#  library(RaMS)
#  library(tidyverse)
#  library(microbenchmark)
#  library(MSnbase)
#  library(Spectra)
#  library(DBI)
#  library(arrow)
#  library(rvest)
#  library(xml2)
#  
#  BiocParallel::register(BiocParallel::SerialParam(stop.on.error = FALSE, progressbar = TRUE))

## ----file download------------------------------------------------------------
#  set.seed(123)
#  
#  n_ms_files <- 10
#  base_url <- "ftp://massive.ucsd.edu/v01/MSV000080030/peak/" %>%
#    paste0("Forensic_study_80_volunteers/Forensic_Hands_mzXML/") %>%
#    paste0("Forensic_Hands_plate_1_mzXML/Sample/")
#  file_list <- base_url %>%
#    read_html %>%
#    xml_text() %>%
#    strsplit("\\\n") %>%
#    pluck(1) %>%
#    str_remove(".*2016 ") %>%
#    str_remove("\\\r")
#  chosen_file_list <- sample(file_list, n_ms_files)
#  
#  dir.create("vignettes/figures/ssc_vignette_renders/Sample/")
#  for(i in chosen_file_list){
#    new_file_path <- paste0("vignettes/figures/ssc_vignette_renders/Sample/", i)
#    download.file(paste0(base_url, i), destfile = new_file_path, mode = "wb")
#  }
#  
#  ms_files <- list.files("vignettes/figures/ssc_vignette_renders/Sample/", full.names = TRUE)

## ----MSnExp-------------------------------------------------------------------
#  msnexp_obj <- readMSData(ms_files, mode="inMemory", msLevel. = 1)
#  plot(chromatogram(msnexp_obj, mz=pmppm(432.2810, ppm = 20)))

## ----onDiskMSnExp-------------------------------------------------------------
#  ondisk_obj <- readMSData(ms_files, mode="onDisk", msLevel. = 1)
#  plot(chromatogram(ondisk_obj, mz=pmppm(432.2810, ppm = 20)))

## ----Spectra------------------------------------------------------------------
#  getIntensities <- function(x, ...) {
#    if (nrow(x)) {
#      cbind(mz = NA_real_, intensity = x[, "intensity"])
#    } else cbind(mz = NA_real_, intensity = NA_real_)
#  }
#  
#  sfs_filtered <- Spectra(ms_files, source=MsBackendMzR()) %>%
#    filterMsLevel(1) %>%
#    filterMzRange(pmppm(432.2810, ppm = 20))
#  sfs_agg <- addProcessing(sfs_filtered, getIntensities)
#  eic <- cbind(rt=rtime(sfs_agg), int=unlist(intensity(sfs_agg), use.names = FALSE))
#  plot(eic[,"rt"], eic[,"int"], type="l")

## ----RaMS---------------------------------------------------------------------
#  rams_obj <- grabMSdata(ms_files, grab_what="MS1")
#  rams_chrom_data <- rams_obj$MS1[mz%between%pmppm(432.2810, ppm = 20)]
#  plot(rams_chrom_data$rt, rams_chrom_data$int, type="l")

## ----tmzML--------------------------------------------------------------------
#  tmzml_names <- paste0(dirname(dirname(ms_files)), "/tmzMLs/", gsub("mzXML", "tmzML", basename(ms_files)))
#  dir.create("vignettes/figures/ssc_vignette_renders/tmzMLs")
#  bpmapply(tmzmlMaker, ms_files, tmzml_names, BPPARAM = SnowParam(workers = 3, progressbar = TRUE, tasks=length(tmzml_names)))
#  tmzml_obj <- grabMSdata(tmzml_names)
#  tmzml_chrom_data <- tmzml_obj$MS1[mz%between%pmppm(432.2810, ppm = 20)]
#  plot(tmzml_chrom_data$rt, tmzml_chrom_data$int, type="l")

## ----arrow--------------------------------------------------------------------
#  write_dataset(rams_obj$MS1, path = "vignettes/figures/ssc_vignette_renders/pqds")
#  arrow_data <- open_dataset("vignettes/figures/ssc_vignette_renders/pqds") %>%
#    filter(mz%between%pmppm(432.2810, ppm = 20)) %>%
#    dplyr::collect()
#  plot(arrow_data$rt, arrow_data$int, type="l")

## ----sqlite database----------------------------------------------------------
#  MSdb <- dbConnect(RSQLite::SQLite(), "vignettes/figures/ssc_vignette_renders/MSdata.sqlite")
#  dbWriteTable(MSdb, "MS1", rams_obj$MS1, overwrite=TRUE)
#  EIC_query <- 'SELECT * FROM MS1 WHERE mz BETWEEN :lower_bound AND :upper_bound'
#  query_params <- as.list(pmppm(432.2810, ppm = 20))
#  names(query_params) <- c("lower_bound", "upper_bound")
#  sql_data <- dbGetQuery(MSdb, EIC_query, params = query_params)
#  plot(sql_data$rt, sql_data$int, type="l")
#  
#  rs <- dbSendQuery(MSdb, "CREATE INDEX mz ON MS1 (mz)")
#  dbClearResult(rs)
#  sql_data <- dbGetQuery(MSdb, EIC_query, params = query_params)
#  sql_data <- sql_data[order(sql_data$filename, sql_data$rt),]
#  plot(sql_data$rt, sql_data$int, type="l")
#  dbDisconnect(MSdb)

## ----time2make----------------------------------------------------------------
#  msnexp_make_fun <- function(){
#    readMSData(ms_files, mode="inMemory", msLevel. = 1)
#  }
#  ondisk_make_fun <- function(){
#    readMSData(ms_files, mode="onDisk", msLevel. = 1)
#  }
#  spectra_make_fun <- function(){
#    Spectra(ms_files, source=MsBackendMzR()) %>% filterMsLevel(1)
#  }
#  rams_make_fun <- function(){
#    grabMSdata(ms_files, grab_what="MS1")
#  }
#  tmzml_make_fun <- function(){
#    tmzml_names <- paste0(dirname(dirname(ms_files)), "/tmzMLs/",
#                          gsub("mzXML", "tmzML", basename(ms_files)))
#    dir.create("vignettes/figures/ssc_vignette_renders/tmzMLs")
#    mapply(tmzmlMaker, ms_files, tmzml_names)
#    unlink("vignettes/figures/ssc_vignette_renders/tmzMLs", recursive = TRUE)
#  }
#  arrow_make_fun <- function(){
#    msdata <- grabMSdata(ms_files, grab_what="MS1")
#    write_dataset(msdata$MS1, path = "vignettes/figures/ssc_vignette_renders/pqds")
#    unlink("vignettes/figures/ssc_vignette_renders/pqds", recursive = TRUE)
#  }
#  sql_make_fun <- function(){
#    msdata <- grabMSdata(ms_files, grab_what="MS1")
#    MSdb <- dbConnect(RSQLite::SQLite(), "vignettes/figures/ssc_vignette_renders/MSdata.sqlite")
#    dbWriteTable(MSdb, "MS1", msdata$MS1, overwrite=TRUE)
#    dbDisconnect(MSdb)
#    unlink("vignettes/figures/ssc_vignette_renders/MSdata.sqlite")
#  }
#  sqlidx_make_fun <- function(){
#    msdata <- grabMSdata(ms_files, grab_what="MS1")
#    MSdb_idx <- dbConnect(RSQLite::SQLite(), "vignettes/figures/ssc_vignette_renders/MSdata_idx.sqlite")
#    dbWriteTable(MSdb_idx, "MS1", msdata$MS1, overwrite=TRUE)
#    rs <- dbSendQuery(MSdb_idx, "CREATE INDEX mz ON MS1 (mz)")
#    dbClearResult(rs)
#    dbDisconnect(MSdb_idx)
#    unlink("vignettes/figures/ssc_vignette_renders/MSdata_idx.sqlite")
#  }
#  
#  make_timings <- microbenchmark(
#    msnexp_make_fun(), ondisk_make_fun(), spectra_make_fun(), rams_make_fun(),
#    tmzml_make_fun(), arrow_make_fun(), sql_make_fun(), sqlidx_make_fun(),
#    times = 10)
#  saveRDS(make_timings, "vignettes/figures/ssc_vignette_renders/make_timings.rds")

## ----plot time2make-----------------------------------------------------------
#  make_timings <- readRDS("vignettes/figures/ssc_vignette_renders/make_timings.rds")
#  make_timings %>%
#    as.data.frame() %>%
#    arrange(expr) %>%
#    mutate(expr=str_remove(expr, "_make_fun\\(\\)")) %>%
#    mutate(rep_type=case_when(
#      expr%in%c("msnexp", "ondisk", "spectra", "rams")~"Every R session",
#      TRUE~"Single-time only"
#    )) %>%
#    mutate(expr=factor(expr, levels=c("msnexp", "ondisk", "spectra", "rams",
#                                      "tmzml", "arrow", "sql", "sqlidx"),
#                       labels=c("MSnExp", "OnDiskMSnExp", "Spectra", "RaMS",
#                                "tmzMLs", "Arrow", "SQL", "SQL (indexed)"))) %>%
#    ggplot() +
#    geom_boxplot(aes(x=expr, y=time/1e9)) +
#    geom_hline(yintercept = 0) +
#    facet_wrap(~rep_type, nrow = 1, scales="free_x") +
#    labs(y="Seconds", x=NULL) +
#    theme(axis.text.x = element_text(angle=90, hjust=1, vjust=0.5))
#  ggsave("vignettes/figures/ssc_vignette_renders/make_time_gp.png", width = 6.5, height = 4, units = "in", device = "png", dpi = 144)

## ----parallel_proc------------------------------------------------------------
#  unpar_rams <- function(){
#    print("Unpar RaMS")
#    lapply(ms_files, grabMSdata)
#  }
#  unpar_tmzml <- function(){
#    print("Unpar tmzML")
#    tmzml_names <- paste0(dirname(dirname(ms_files)), "/tmzMLs/",
#                          gsub("mzXML", "tmzML", basename(ms_files)))
#    dir.create("vignettes/figures/ssc_vignette_renders/tmzMLs")
#    pbapply::pbmapply(tmzmlMaker, ms_files, tmzml_names)
#    unlink("vignettes/figures/ssc_vignette_renders/tmzMLs", recursive = TRUE)
#  }
#  
#  library(BiocParallel)
#  par_param <- SnowParam(workers = 5, progressbar = TRUE)
#  par_rams <- function(){
#    print("Par RaMS")
#    bplapply(ms_files, grabMSdata, BPPARAM = par_param)
#  }
#  par_tmzml <- function(){
#    print("Par tmzML")
#    tmzml_names <- paste0(dirname(dirname(ms_files)), "/tmzMLs/",
#                          gsub("mzXML", "tmzML", basename(ms_files)))
#    dir.create("vignettes/figures/ssc_vignette_renders/tmzMLs")
#    bpmapply(tmzmlMaker, ms_files, tmzml_names, BPPARAM = par_param)
#    unlink("vignettes/figures/ssc_vignette_renders/tmzMLs", recursive = TRUE)
#  }
#  
#  par_timings <- microbenchmark(par_rams(), unpar_rams(), par_tmzml(), unpar_tmzml(), times = 5)
#  saveRDS(par_timings, "vignettes/figures/ssc_vignette_renders/par_timings.rds")

## ----parallel proc plot-------------------------------------------------------
#  par_timings <- readRDS("vignettes/figures/ssc_vignette_renders/par_timings.rds")
#  par_timings %>%
#    as.data.frame() %>%
#    separate(expr, into = c("sub_type", "par_type"), sep = "_") %>%
#    mutate(par_type=str_remove(par_type, "\\(\\)")) %>%
#    mutate(sub_type=factor(sub_type, levels=c("unpar", "par"),
#                           labels=c("Sequential", "Parallel"))) %>%
#    mutate(par_type=factor(par_type, levels=c("rams", "tmzml"),
#                           labels=c("RaMS", "tmzMLs"))) %>%
#    ggplot() +
#    geom_boxplot(aes(x=par_type, y=time/1e9)) +
#    geom_hline(yintercept = 0) +
#    facet_wrap(~sub_type, nrow = 1) +
#    labs(y="Seconds", x=NULL) +
#    theme(axis.text.x = element_text(angle=90, hjust=1, vjust=0.5))
#  ggsave("vignettes/figures/ssc_vignette_renders/par_time_gp.png", width = 6.5, height = 3, units = "in", device = "png", dpi = 144)

## ----time2query---------------------------------------------------------------
#  msnexp_obj <- readMSData(ms_files, mode="inMemory", msLevel. = 1)
#  ondisk_obj <- readMSData(ms_files, mode="onDisk", msLevel. = 1)
#  spectra_obj <- Spectra(ms_files, source=MsBackendMzR()) %>% filterMsLevel(1)
#  rams_obj <- grabMSdata(ms_files, grab_what="MS1")
#  
#  tmzml_names <- paste0(dirname(dirname(ms_files)), "/tmzMLs/",
#                        gsub("mzXML", "tmzML", basename(ms_files)))
#  dir.create("vignettes/figures/ssc_vignette_renders/tmzMLs")
#  mapply(tmzmlMaker, ms_files, tmzml_names)
#  
#  write_dataset(rams_obj$MS1, path = "vignettes/figures/ssc_vignette_renders/pqds")
#  
#  MSdb <- dbConnect(RSQLite::SQLite(), "vignettes/figures/ssc_vignette_renders/MSdata.sqlite")
#  dbWriteTable(MSdb, "MS1", rams_obj$MS1, overwrite=TRUE)
#  dbDisconnect(MSdb)
#  
#  MSdb_idx <- dbConnect(RSQLite::SQLite(), "vignettes/figures/ssc_vignette_renders/MSdata_idx.sqlite")
#  dbWriteTable(MSdb_idx, "MS1", rams_obj$MS1, overwrite=TRUE)
#  rs <- dbSendQuery(MSdb_idx, "CREATE INDEX mz ON MS1 (mz)")
#  dbClearResult(rs)
#  dbDisconnect(MSdb_idx)
#  
#  msnexp_query_fun <- function(){
#    plot(chromatogram(msnexp_obj, mz=pmppm(432.2810, ppm = 20)))
#  }
#  ondisk_query_fun <- function(){
#    plot(chromatogram(ondisk_obj, mz=pmppm(432.2810, ppm = 20)))
#  }
#  spectra_query_fun <- function(){
#    sfs_filtered <- spectra_obj %>% filterMzRange(pmppm(432.2810, ppm = 20))
#    getIntensities <- function(x, ...) {
#      if (nrow(x)) {
#        cbind(mz = NA_real_, intensity = x[, "intensity"])
#      } else cbind(mz = NA_real_, intensity = NA_real_)
#    }
#    sfs_agg <- addProcessing(sfs_filtered, getIntensities)
#    eic <- cbind(rt=rtime(sfs_agg), int=unlist(intensity(sfs_agg), use.names = FALSE))
#    plot(eic[,"rt"], eic[,"int"], type="l")
#  }
#  rams_query_fun <- function(){
#    rams_chrom_data <- rams_obj$MS1[mz%between%pmppm(432.2810, ppm = 20)]
#    plot(rams_chrom_data$rt, rams_chrom_data$int, type="l")
#  }
#  tmzml_query_fun <- function(){
#    tmzml_names <- list.files("vignettes/figures/ssc_vignette_renders/tmzMLs", full.names = TRUE)
#    tmzml_obj <- grabMSdata(tmzml_names)
#    tmzml_chrom_data <- tmzml_obj$MS1[mz%between%pmppm(432.2810, ppm = 20)]
#    plot(tmzml_chrom_data$rt, tmzml_chrom_data$int, type="l")
#  }
#  arrow_query_fun <- function(){
#    arrow_data <- open_dataset("vignettes/figures/ssc_vignette_renders/pqds") %>%
#      filter(mz%between%pmppm(432.2810, ppm = 20)) %>%
#      dplyr::collect()
#    plot(arrow_data$rt, arrow_data$int, type="l")
#  }
#  sql_query_fun <- function(){
#    MSdb <- dbConnect(RSQLite::SQLite(), "vignettes/figures/ssc_vignette_renders/MSdata.sqlite")
#    EIC_query <- 'SELECT * FROM MS1 WHERE mz BETWEEN :lower_bound AND :upper_bound'
#    query_params <- as.list(pmppm(432.2810, ppm = 20))
#    names(query_params) <- c("lower_bound", "upper_bound")
#    sql_data <- dbGetQuery(MSdb, EIC_query, params = query_params)
#    plot(sql_data$rt, sql_data$int, type="l")
#  }
#  sqlidx_query_fun <- function(){
#    MSdb_idx <- dbConnect(RSQLite::SQLite(), "vignettes/figures/ssc_vignette_renders/MSdata_idx.sqlite")
#    EIC_query <- 'SELECT * FROM MS1 WHERE mz BETWEEN :lower_bound AND :upper_bound'
#    query_params <- as.list(pmppm(432.2810, ppm = 20))
#    names(query_params) <- c("lower_bound", "upper_bound")
#    sql_data <- dbGetQuery(MSdb_idx, EIC_query, params = query_params)
#    sql_data <- sql_data[order(sql_data$filename, sql_data$rt),]
#    plot(sql_data$rt, sql_data$int, type="l")
#  }
#  
#  query_timings <- microbenchmark(
#    msnexp_query_fun(), ondisk_query_fun(), spectra_query_fun(), rams_query_fun(),
#    tmzml_query_fun(), arrow_query_fun(), sql_query_fun(), sqlidx_query_fun(),
#    times = 10
#  )
#  query_timings
#  saveRDS(query_timings, "vignettes/figures/ssc_vignette_renders/query_timings.rds")

## ----time2query plot----------------------------------------------------------
#  query_timings <- readRDS("vignettes/figures/ssc_vignette_renders/query_timings.rds")
#  query_timings %>%
#    as.data.frame() %>%
#    arrange(expr) %>%
#    mutate(expr=str_remove(expr, "_query_fun\\(\\)")) %>%
#    mutate(rep_type=case_when(
#      expr%in%c("msnexp", "ondisk", "spectra", "rams")~"Every R session",
#      TRUE~"Single-time only"
#    )) %>%
#    mutate(expr=factor(expr, levels=c("msnexp", "ondisk", "spectra", "rams",
#                                      "tmzml", "arrow", "sql", "sqlidx"),
#                       labels=c("MSnExp", "OnDiskMSnExp", "Spectra", "RaMS",
#                                "tmzMLs", "Arrow", "SQL", "SQL (indexed)"))) %>%
#    ggplot() +
#    geom_boxplot(aes(x=expr, y=time/1e9)) +
#    scale_y_log10() +
#    labs(y="Seconds", x=NULL) +
#    theme(axis.text.x = element_text(angle=90, hjust=1, vjust=0.5))
#  ggsave("vignettes/figures/ssc_vignette_renders/query_time_gp.png", width = 6.5, height = 5, units = "in", device = "png", dpi = 144)

## ----double-check sql_idx vs RaMS---------------------------------------------
#  MSdb_idx <- dbConnect(RSQLite::SQLite(), "vignettes/figures/ssc_vignette_renders/MSdata_idx.sqlite")
#  EIC_query <- 'SELECT * FROM MS1 WHERE mz BETWEEN :lower_bound AND :upper_bound'
#  query_params <- as.list(pmppm(432.2810, ppm = 20))
#  names(query_params) <- c("lower_bound", "upper_bound")
#  dbGetQuery(MSdb_idx, EIC_query, params = query_params) %>% qplotMS1data()
#  
#  rams_obj$MS1[mz%between%pmppm(432.2810, ppm = 20)] %>% qplotMS1data()

## ----make query strings-------------------------------------------------------
#  rams_obj <- grabMSdata(ms_files, grab_what="MS1")
#  grouped_ms1 <- rams_obj$MS1 %>%
#    arrange(desc(int)) %>%
#    mutate(mz_group=mz_group(mz, ppm = 10, max_groups = 10, min_group_size=20)) %>%
#    drop_na()
#  # grouped_ms1 %>%
#  #   qplotMS1data(facet_col="mz_group", facet_args = list(ncol=2))
#  mzs_to_grab <- grouped_ms1 %>%
#    group_by(mz_group) %>%
#    summarise(mean_mz=mean(mz), sd_mz=sd(mz), mean_rt=mean(rt)) %>%
#    pull(mean_mz)
#  
#  rams_arrow_call <- lapply(mzs_to_grab, function(mz_i){
#    mzrange <- pmppm(mz_i, 10)
#    call("between", as.name("mz"), mzrange[[1]], mzrange[[2]])
#  }) %>% paste(collapse = "|")
#  
#  sql_comb_call <- sapply(mzs_to_grab, function(mz_i){
#    paste("mz BETWEEN", pmppm(mz_i, 10)[1], "AND", pmppm(mz_i, 10)[2])
#  }) %>% paste(collapse = " OR ") %>% paste("SELECT * FROM MS1 WHERE", .)
#  
#  print(rams_arrow_call)
#  print(sql_comb_call)

## ----multichrom query timing--------------------------------------------------
#  rams_uni_fun <- function(){
#    print("RaMS unified")
#    rams_obj$MS1[eval(parse(text=rams_arrow_call))]
#  }
#  rams_loop_fun <- function(){
#    print("RaMS loop")
#    lapply(mzs_to_grab, function(mz_i){
#      rams_obj$MS1[mz%between%pmppm(mz_i, 10)]
#    }) %>% bind_rows() %>% distinct()
#  }
#  
#  arrow_ds <- open_dataset("vignettes/figures/ssc_vignette_renders/pqds")
#  arrow_uni_fun <- function(){
#    print("Arrow unified")
#    arrow_ds %>%
#      filter(eval(parse(text = rams_arrow_call))) %>%
#      collect()
#  }
#  arrow_loop_fun <- function(){
#    print("Arrow loop")
#    lapply(mzs_to_grab, function(mz_i){
#      arrow_ds %>%
#        filter(mz%between%pmppm(mz_i, 10)) %>%
#        collect()
#    }) %>% bind_rows() %>% distinct()
#  }
#  
#  MSdb_idx <- dbConnect(RSQLite::SQLite(), "vignettes/figures/ssc_vignette_renders/MSdata_idx.sqlite")
#  sql_uni_fun <- function(){
#    print("SQL unified")
#    dbGetQuery(MSdb_idx, sql_comb_call)
#  }
#  sql_query_base <- 'SELECT * FROM MS1 WHERE mz BETWEEN :lower_bound AND :upper_bound'
#  sql_loop_fun <- function(){
#    print("SQL loop")
#    lapply(mzs_to_grab, function(mz_i){
#      query_params <- as.list(pmppm(mz_i, ppm = 20))
#      names(query_params) <- c("lower_bound", "upper_bound")
#      sql_data <- dbGetQuery(MSdb_idx, sql_query_base, params = query_params)
#    }) %>% bind_rows() %>% distinct()
#  }
#  
#  multichrom_timings <- microbenchmark(
#    rams_uni_fun(), rams_loop_fun(), arrow_uni_fun(), arrow_loop_fun(),
#    sql_uni_fun(), sql_loop_fun(), times = 10
#  )
#  saveRDS(multichrom_timings, "vignettes/figures/ssc_vignette_renders/multichrom_timings.rds")
#  
#  multichrom_timings <- readRDS("vignettes/figures/ssc_vignette_renders/multichrom_timings.rds")
#  multichrom_timings %>%
#    as.data.frame() %>%
#    arrange(expr) %>%
#    mutate(expr=str_remove(expr, "_fun\\(\\)")) %>%
#    separate(expr, into = c("expr", "query_type"), sep = "_") %>%
#    mutate(expr=factor(expr, levels=c("rams", "arrow", "sql"),
#                       labels=c("RaMS", "Arrow", "SQL"))) %>%
#    mutate(query_type=factor(query_type, levels=c("uni", "loop"),
#                             labels=c("Unified query", "Query loop"))) %>%
#    ggplot() +
#    geom_boxplot(aes(x=query_type, y=time/1e9), lwd=1) +
#    facet_wrap(~expr, nrow=1) +
#    scale_y_log10() +
#    labs(y="Seconds", x=NULL, color=NULL) +
#    theme_bw()
#  ggsave("vignettes/figures/ssc_vignette_renders/multichrom_gp.png", width = 6.5, height = 4, units = "in", device = "png", dpi = 144)

## ----sizing info--------------------------------------------------------------
#  size_list <- list()
#  
#  size_list$mzXML <- sum(file.size(ms_files))
#  
#  msnexp_obj <- readMSData(ms_files, mode="inMemory", msLevel. = 1)
#  size_list$msnexp_obj <- pryr::object_size(msnexp_obj)
#  rm(msnexp_obj)
#  
#  ondisk_obj <- readMSData(ms_files, mode="onDisk", msLevel. = 1)
#  size_list$ondisk_obj <- pryr::object_size(ondisk_obj)
#  rm(ondisk_obj)
#  
#  sfs_filtered <- Spectra(ms_files, source=MsBackendMzR()) %>%
#    filterMsLevel(1)
#  size_list$spectra <- pryr::object_size(sfs_filtered)
#  rm(sfs_filtered)
#  
#  rams_obj <- grabMSdata(ms_files, grab_what="MS1")
#  size_list$rams <- pryr::object_size(rams_obj)
#  
#  tmzml_names <- paste0(dirname(dirname(ms_files)), "/tmzMLs/", gsub("mzXML", "tmzML", basename(ms_files)))
#  dir.create("vignettes/figures/ssc_vignette_renders/tmzMLs")
#  bpmapply(tmzmlMaker, ms_files, tmzml_names, BPPARAM = SnowParam(workers = 5, progressbar = TRUE, tasks=length(tmzml_names)))
#  size_list$tmzml <- sum(file.size(list.files("vignettes/figures/ssc_vignette_renders/tmzMLs", full.names = TRUE)))
#  unlink("vignettes/figures/ssc_vignette_renders/tmzMLs", recursive = TRUE)
#  
#  write_dataset(rams_obj$MS1, path = "vignettes/figures/ssc_vignette_renders/pqds")
#  size_list$arrow <- sum(file.size(list.files("vignettes/figures/ssc_vignette_renders/pqds", full.names = TRUE)))
#  unlink("vignettes/figures/ssc_vignette_renders/pqds", recursive = TRUE)
#  
#  MSdb <- dbConnect(RSQLite::SQLite(), "vignettes/figures/ssc_vignette_renders/MSdata.sqlite")
#  dbWriteTable(MSdb, "MS1", rams_obj$MS1, overwrite=TRUE)
#  dbDisconnect(MSdb)
#  size_list$MSdb <- file.size("vignettes/figures/ssc_vignette_renders/MSdata.sqlite")
#  
#  
#  MSdb_idx <- dbConnect(RSQLite::SQLite(), "vignettes/figures/ssc_vignette_renders/MSdata.sqlite")
#  rs <- dbSendQuery(MSdb_idx, "CREATE INDEX mz ON MS1 (mz)")
#  dbClearResult(rs)
#  dbDisconnect(MSdb_idx)
#  size_list$MSdb_idx <- file.size("vignettes/figures/ssc_vignette_renders/MSdata_idx.sqlite")
#  unlink("vignettes/figures/ssc_vignette_renders/MSdata.sqlite")
#  
#  saveRDS(size_list, "vignettes/figures/ssc_vignette_renders/size_list.rds")

## ----plot size info-----------------------------------------------------------
#  size_list <- readRDS("vignettes/figures/ssc_vignette_renders/size_list.rds")
#  size_list %>%
#    within(rm(mzXML)) %>%
#    sapply(as.numeric) %>%
#    data.frame(bytes=.) %>%
#    rownames_to_column("expr") %>%
#    mutate(expr=str_remove(expr, "_obj")) %>%
#    mutate(expr=str_replace(expr, "MSdb_?", "sql")) %>%
#    mutate(mem_type=case_when(
#      expr%in%c("msnexp", "ondisk", "spectra", "rams")~"Memory",
#      TRUE~"Disk"
#    )) %>%
#    mutate(mem_type=factor(mem_type, levels=c("Memory", "Disk"))) %>%
#    mutate(expr=factor(expr, levels=c("msnexp", "ondisk", "spectra", "rams",
#                                      "tmzml", "arrow", "sql", "sqlidx"),
#                       labels=c("MSnExp", "OnDiskMSnExp", "Spectra", "RaMS",
#                                "tmzMLs", "Arrow", "SQL", "SQL (indexed)"))) %>%
#    ggplot() +
#    geom_hline(yintercept = size_list$mzXML/(1024^3)) +
#    geom_point(aes(x=expr, y=bytes/(1024^3))) +
#    scale_y_log10(breaks=c(0.001, 0.01, 0.1, 1, 10), labels=c("1MB", "10MB", "100MB", "1GB", "10GB"),
#                  limits=c(0.001, 10)) +
#    facet_wrap(~mem_type, scales = "free_x") +
#    labs(x=NULL, y=NULL)
#  ggsave("vignettes/figures/ssc_vignette_renders/size_cons.png", width = 6.5, height = 4, units = "in", device = "png", dpi = 144)

## ----summary plot-------------------------------------------------------------
#  make_timings <- readRDS("vignettes/figures/ssc_vignette_renders/make_timings.rds")
#  query_timings <- readRDS("vignettes/figures/ssc_vignette_renders/query_timings.rds")
#  size_df <- readRDS("vignettes/figures/ssc_vignette_renders/size_list.rds") %>%
#    sapply(as.numeric) %>%
#    data.frame(size=.) %>%
#    mutate(size=size/1024^3) %>%
#    rownames_to_column("expr") %>%
#    mutate(expr=str_remove(expr, "_obj")) %>%
#    mutate(expr=str_replace(expr, "MSdb_?", "sql"))
#  
#  bind_rows(make_timings, query_timings) %>%
#    as.data.frame() %>%
#    group_by(expr) %>%
#    mutate(time=time/1e9) %>%
#    summarise(med_time=median(time), IQR_time=IQR(time)) %>%
#    mutate(expr=str_remove(expr, "_fun\\(\\)")) %>%
#    separate(expr, into = c("expr", "time_type")) %>%
#    left_join(size_df) %>%
#    mutate(rep_type=case_when(
#      expr%in%c("msnexp", "ondisk", "spectra", "rams")~"Memory",
#      TRUE~"Disk"
#    )) %>%
#    mutate(expr=factor(expr, levels=c("msnexp", "ondisk", "spectra", "rams",
#                                      "tmzml", "arrow", "sql", "sqlidx"),
#                       labels=c("MSnExp", "OnDiskMSnExp", "Spectra", "RaMS",
#                                "tmzMLs", "Arrow", "SQL", "SQL (indexed)"))) %>%
#    pivot_wider(names_from = time_type, values_from=c("med_time", "IQR_time")) %>%
#    ggplot() +
#    geom_vline(xintercept = 0) +
#    geom_linerange(aes(x=med_time_make, ymin=med_time_query-IQR_time_query*2,
#                       ymax=med_time_query+IQR_time_query*2, color=expr)) +
#    geom_linerange(aes(y=med_time_query, xmin=med_time_make-IQR_time_make*2,
#                       xmax=med_time_make+IQR_time_make*2, color=expr)) +
#    geom_point(aes(x=med_time_make, y=med_time_query, color=expr,
#                   size=size, shape=rep_type)) +
#    scale_shape_manual(values=c(16, 15)) +
#    scale_y_log10() +
#    coord_flip() +
#    guides(color = guide_legend(order = 1), shape = guide_legend(order = 2),
#           size=guide_legend(order=3)) +
#    labs(x="Time to transform (s)", y="Time to query (s)", color=NULL, size="Size (GB)",
#         shape="Storage") +
#    theme_bw()
#  ggsave("vignettes/figures/ssc_vignette_renders/sum_plot.png", width = 6.5, height = 5, units = "in", device = "png", dpi = 144)
#  
#  
#  # bind_rows(make_timings, query_timings) %>%
#  #   as.data.frame() %>%
#  #   group_by(expr) %>%
#  #   mutate(time=time/1e9) %>%
#  #   summarise(med_time=median(time)) %>%
#  #   mutate(expr=str_remove(expr, "_fun\\(\\)")) %>%
#  #   separate(expr, into = c("expr", "time_type")) %>%
#  #   pivot_wider(names_from = time_type, values_from=med_time) %>%
#  #   left_join(size_df) %>%
#  #   plotly::plot_ly(x=~make, y=~query, z=~size, hovertext=~expr,
#  #                   type="scatter3d", mode="markers")

## ----cleanup------------------------------------------------------------------
#  unlink("vignettes/figures/ssc_vignette_renders/tmzMLs", recursive = TRUE)
#  unlink("vignettes/figures/ssc_vignette_renders/pqds", recursive = TRUE)
#  unlink("vignettes/figures/ssc_vignette_renders/MSdata.sqlite")
#  unlink("vignettes/figures/ssc_vignette_renders/MSdata_idx.sqlite")
#  unlink("vignettes/figures/ssc_vignette_renders/Sample/", recursive = TRUE)

