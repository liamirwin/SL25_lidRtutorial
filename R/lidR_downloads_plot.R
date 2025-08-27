# Production code to generate figure for intro slides of lidR downloads over time

# install missing packages if needed
pkgs <- c("cranlogs", "lubridate", "scales", "ggplot2", "dplyr")
installed <- rownames(installed.packages())
to_install <- setdiff(pkgs, installed)
if (length(to_install)) {
  install.packages(to_install)
}

# use cranlogs to count number of monthly and cumulative downloads of lidR package
library(cranlogs)
library(lubridate)
library(scales)
library(ggplot2)
library(dplyr)

# Dates
start_date <- "2016-10-01"
end_date <- Sys.Date()

# Download data from cranlogs
dl <- cran_downloads(packages = "lidR", from = start_date, to = end_date) %>%
  mutate(month_year = format(date, "%m-%Y"))

# Summarize by month and year - monthly/cumulative downloads
df <- dl %>%
  mutate(year = year(date), month = month(date, label = TRUE)) %>%
  group_by(year, month) %>%
  summarise(downloads = sum(count), .groups = "drop") %>%
  arrange(year, month) %>%
  mutate(
    cumulative = cumsum(downloads),
    month_year = as.Date(paste0(month, "-", year, "-01"), format = "%b-%Y-%d")
  )

# Scaling ratio for secondary axis
ratio <- max(df$cumulative) / max(df$downloads)

# Plot with unified legend
p <- ggplot(df, aes(x = month_year)) + 

  # Two series, both mapped to the same “Series” aesthetic
  geom_line(aes(y = downloads,
                colour   = "Monthly Downloads",
                linetype = "Monthly Downloads"),
            linewidth = 0.75) +
  geom_line(aes(y = cumulative / ratio,
                colour   = "Cumulative Downloads",
                linetype = "Cumulative Downloads"),
            linewidth = 0.75) +

  # Primary Y axis
  scale_y_continuous(
    name   = "Monthly Downloads",
    labels = comma,
    sec.axis = sec_axis(
      ~ . * ratio,
      name   = "Total Downloads",
      labels = comma
    )
  ) +

  # Year ticks from 2016 through 2025
  scale_x_date(
    name   = NULL,
    breaks = seq(as.Date(start_date), as.Date(end_date), by = "1 year"),
    date_labels = "%Y"
  ) +

  # Single colour scale, in the order we want
  scale_colour_manual(
    name   = NULL,
    breaks = c("Monthly Downloads", "Cumulative Downloads"),
    values = c("Monthly Downloads"    = "red",
               "Cumulative Downloads" = "blue")
  ) +

  # Single linetype scale, matching the same breaks
  scale_linetype_manual(
    name   = NULL,
    breaks = c("Monthly Downloads", "Cumulative Downloads"),
    values = c("Monthly Downloads"    = "solid",
               "Cumulative Downloads" = "dashed")
  ) +

  theme_classic() +
  theme(legend.position = "bottom") +

  labs(
    title    = "CRAN lidR Downloads"
  )

print(p)