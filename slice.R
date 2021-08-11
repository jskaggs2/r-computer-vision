## Process FLIR video
## Convert format, merge, and slice
## Jon Skaggs
## 2021-08-03


## This script calls the program ffmpeg from the command prompt
## To use ffmpeg, it must be saved to your computer and added as a PATH variable
## See install guide for windows here:
## https://video.stackexchange.com/questions/20495/how-do-i-set-up-and-use-ffmpeg-in-windows


library(chron)


# User settings -----------------------------------------------------------


# Sampling event
date <- "20210719"

# Start time
t0 <- chron::times("20:16:02")

# Set +/- temporal window of interest around timestamp
window <- chron::times("00:00:30")


# Load --------------------------------------------------------------------


# Set wd
path <- paste0(getwd(), "/", date)

# Get video files from a data collection event
avis <- list.files(path = path, pattern = ".avi", full.names = TRUE)

# Get datasheet of timestamps from a data collection event
path_times <- list.files(path = path, pattern = ".csv", full.names = TRUE)
times <- read.csv(path_times)
times$id <- 1:nrow(times)


# Convert videos ----------------------------------------------------------


# Set new names
mp4s <- sub(x = avis, pattern = ".avi", replacement = ".mp4")

# Define command to convert videos from avi to mp4
cmd_c <- sprintf("ffmpeg -i %s %s", avis, mp4s)

# Convert
lapply(cmd_c, system)


# Merge videos ------------------------------------------------------------


# Save temporary file with names of videos to merge
write.table(
  x = paste0("file ", "'", mp4s, "'"),
  file = paste(date,"temp.txt", sep = "/"),
  col.names = FALSE, row.names = FALSE, quote = FALSE)

# Set merged video output name
name_m <- paste0(path, "/merged", ".mp4")

# Define command to merge all videos into one
cmd_m <- sprintf("ffmpeg -f concat -safe 0 -i %s/temp.txt -c copy %s",
                 path, name_m)

# Merge
system(cmd_m)


# Slice at timestamp ------------------------------------------------------


# Define slice parameters
mid <- times$Det.FLIR.Time - t0
start <- mid - window
end <- mid + window
output <- paste0(date, "/", times$id, ".mp4")

# Define commands to slice at each timestamp
cmd_s <- sprintf("ffmpeg -i %s -ss %s -to %s -c copy %s",
                 name_m, start, end, output) 

# Slice
lapply(cmd_s, system)