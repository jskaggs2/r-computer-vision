## Use computer vision to extract text from video
## Jon Skaggs
## 2021-08-09


library(tesseract)
library(magick)


# Convert video to images -------------------------------------------------


# Set path to sampling event folder
path <- "C:/pig/sample"

# Get path for video(s) of interest
vids <- list.files(path = path, pattern = ".mp4$")

# Print video stats (including framerate)
cmd_fps <- sprintf("ffmpeg -i %s",
                   paste0(path, "/", vids))
lapply(cmd_fps, system)

# Convert video to frames, assume 30 fps
fps <- 30
cmd_frames <- sprintf("ffmpeg -i %s -r %s %s",
                      paste0(path, "/", vids), fps, paste0(path, "/", vids, "_frame_%04d.png"))
lapply(cmd_frames, system)


# Get data from images ----------------------------------------------------


t.start <- Sys.time()

# Specify expected characters and pattern in date, time, and location
engine_time <- tesseract(options = list(
  tessedit_char_whitelist = "0123456789:",
  user_patterns_file = "C:/pig/pattern_time.txt"))
  
engine_date <- tesseract(options = list(
  tessedit_char_whitelist = "0123456789/",
  user_patterns_file = "C:/pig/pattern_date.txt"))

engine_loc <- tesseract(options = list(
  tessedit_char_whitelist = "0123456789GPSWNV.,:/",
  user_patterns_file = "C:/pig/pattern_loc.txt"))

# Template to save results
dat <- data.frame(video = NA, frame = NA, date = NA, time = NA, location = NA)

# Loop over all frames
frames <- list.files(path = path, pattern = ".png$", full.names = TRUE)

for(frame in frames){
  print(frame)
  
  # Load input frame
  input <- image_read(frame)
  
  # Extract date
  date <- input %>%
    image_crop("80x13+464+50") %>%
    image_scale(300) %>%
    image_convert(type = "Bilevel") %>%
    image_negate() %>%
    image_morphology("Close", "Square:1") %>%
    image_morphology("Erode", "Octagon:2") %>%
    image_median(radius = 6) %>%
    tesseract::ocr(engine = engine_date)
  
  # Extract time
  time <- input %>%
    image_crop("65x13+551+50") %>%
    image_scale(300) %>%
    image_convert(type = "Bilevel") %>%
    image_negate() %>%
    image_morphology("Close", "Square:1") %>%
    image_morphology("Erode", "Octagon:2") %>%
    image_median(radius = 9) %>%
    tesseract::ocr(engine = engine_time)

  # Extract location
  loc <- input %>%
    image_crop("288x15+112+417") %>%
    image_scale(1000) %>%
    image_convert(type = "Grayscale") %>%
    image_negate() %>%
    image_threshold(type = "white", threshold = "30%") %>%
    image_morphology("Erode", "Square:1") %>%
    image_median(radius = 3) %>%
    image_enhance() %>%
    tesseract::ocr(engine = engine_loc)
  
  # Save results of each iteration
  v <- sub(pattern = path, replacement = "", x = frame)
  f <- substr(frame, start = nchar(frame)-7, stop = nchar(frame))
  dat <- rbind(dat, c(v, f, date, time, loc))
}

# Write results to file
write.csv(dat, "sample_framedata.csv")

print(Sys.time() - t.start)
