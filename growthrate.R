
growthrateR <- function(platefile, platemap, timepoints=5, window=1, time.min=-Inf, time.max=Inf, plate.clean=FALSE){
  df <- platefile
  
  if (plate.clean){
    df$`T° 600` <- NULL # delete temperature column
    names(df)[1] <- "time" # Rename "Time" to "time"
    df <- transform(df, time = time / 60) # Change from mins to hours
  }
  
  run <- df %>%
    gather(., Well, od, -time) %>%
    mutate(ln_od = log(od),
           log10_od = log10(od))
  
  # Subset data
  subset <- subset(run, time > time.min & time < time.max)

  # Create rolling regression function
  roll_regress <- function(x){
    temp <- data.frame(x)
    mod <- lm(temp)
    temp <- data.frame(slope = coef(mod)[[2]],
                       slope_lwr = confint(mod)[2, ][[1]],
                       slope_upr = confint(mod)[2, ][[2]],
                       intercept = coef(mod)[[1]],
                       rsq = summary(mod)$r.squared, stringsAsFactors = FALSE)
    return(temp)
  }
    
  # Define window
  num_points = ceiling(window*60/(60*(timepoints/60)))
  
  # Make model
  models <- run %>%
    group_by(Well) %>%
    do(cbind(model = select(., ln_od, time) %>% 
               zoo::rollapplyr(width = num_points, roll_regress, by.column = FALSE, fill = NA, align = 'center'),
             time = select(., time),
             ln_od = select(., ln_od))) %>%
    rename_all(., gsub, pattern = 'model.', replacement = '')
  
  # Calculate GR
  growth_rates <- models %>%
    filter(slope == max(slope, na.rm = TRUE)) %>%
    ungroup()
  
  # Merge with platemap
  growth_rates.annot <- inner_join(growth_rates, platemap, by="Well")

  return(growth_rates.annot)
  
}

growthrateR_single <- function(platefile, timepoints=5, window=1, time.min=-Inf, time.max=Inf, plate.clean=FALSE, well){
  df <- platefile
  
  if (plate.clean){
    df$`T° 600` <- NULL # delete temperature column
    names(df)[1] <- "time" # Rename "Time" to "time"
    df <- transform(df, time = time / 60) # Change from mins to hours
  }
  
  run <- df %>%
    gather(., Well, od, -time) %>%
    mutate(ln_od = log(od),
           log10_od = log10(od))
  
  # Filter for single well
  d_well <- filter(run, Well == well)
  
  # Subset data
  subset <- subset(run, time > time.min & time < time.max)
  
  # Create rolling regression function
  roll_regress <- function(x){
    temp <- data.frame(x)
    mod <- lm(temp)
    temp <- data.frame(slope = coef(mod)[[2]],
                       slope_lwr = confint(mod)[2, ][[1]],
                       slope_upr = confint(mod)[2, ][[2]],
                       intercept = coef(mod)[[1]],
                       rsq = summary(mod)$r.squared, stringsAsFactors = FALSE)
    return(temp)
  }
  
  # Define window
  num_points = ceiling(window*60/(60*(timepoints/60)))
  
  # Make model
  models <- d_well %>%
    do(cbind(model = select(., ln_od, time) %>% 
               zoo::rollapplyr(width = num_points, roll_regress, by.column = FALSE, fill = NA, align = 'center'),
             time = select(., time),
             ln_od = select(., ln_od))) %>%
    rename_all(., gsub, pattern = 'model.', replacement = '')
  
  # create predictions
  preds <- models %>%
    filter(., !is.na(slope)) %>%
    group_by(time) %>%
    do(data.frame(time2 = c(.$time - 2, .$time + 2))) %>%
    left_join(., models) %>%
    mutate(pred = (slope*time2) + intercept)
  
  # Calculate GR
  growth_rate <- models %>%
    filter(slope == max(slope, na.rm = TRUE))
  
  # Plot rolling regression
  plot <- ggplot(d_well, aes(time, ln_od)) +
          geom_point() +
          geom_line(aes(time2, pred, group = time), col = 'red', preds, alpha = 0.5) +
          theme_bw(base_size = 16) +
          geom_segment(aes(x = time, y = -3, xend = time, yend = ln_od), growth_rate) +
          geom_segment(aes(x = 0, y = ln_od, xend = time, yend = ln_od), growth_rate) +
          annotate(geom = 'text', x = 0, y = -1, label = paste('µ = ', round(growth_rate$slope, 2), ' hr-1\n95%CI:(',round(growth_rate$slope_lwr, 2), '-', round(growth_rate$slope_upr, 2), ')', sep = ''), hjust = 0, size = 4) +
          labs(x = 'time (hours)',
               y = 'OD')
  
  return(plot)
  
}