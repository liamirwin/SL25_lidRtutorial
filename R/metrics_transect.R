# --- Prerequisites ---
library(lidR, quietly = TRUE)
library(ggplot2, quietly = TRUE)
library(dplyr, quietly = TRUE)
library(tibble, quietly = TRUE)
library(purrr, quietly = TRUE)
library(lidRmetrics, quietly = TRUE)

# --- Configuration Registries ---
metric_calculation_registry <- tribble(
  ~name,          ~metric_formula,         ~required_attributes,
  "basic",        ~metrics_basic(Z),       "Z",
  "percentiles",  ~metrics_percentiles(Z), "Z",
  "cover",        ~metrics_percabove(Z),   "Z",
  "lad",          ~metrics_lad(Z),         "Z",
  "dispersion",   ~metrics_dispersion(Z),  "Z"
)

metric_viz_dict <- tribble(
  ~metric_name,    ~metric_type,   ~geom,         ~label,              ~color,  ~linetype, ~thickness, ~hjust, ~vjust, ~format_spec, ~group,
  #---------------------------------------------------------------------------------------------------------------------------------------------
  # Height metrics to be plotted as lines on the graph
  "zmax",          "height",       "hline",       "Max Height",        "black", "dashed",   0.5,        0,   0.5,    NA,           NA,
  "zmean",         "height",       "hline",       "Mean Height",       "black", "dashed",   0.5,        0,   0.5,    NA,           NA,
  "zsd",           "height",       "range_hline", "Std. Dev.",         "black", "dashed",   0.5,        0,   0.5,    NA,           NA,
  "zq50",          "height",       "hline",       "Median",            "black", "dashed",   0.5,        0,   0.5,    NA,           NA,
  "zq25",          "height",       "hline",       "ZQ25",              "black", "dashed",   0.5,        0,   0.5,    NA,           NA,
  "zq75",          "height",       "hline",       "ZQ75",              "black", "dashed",   0.5,        0,   0.5,    NA,           NA,
  # Annotation metrics for the subtitle
  "pzabovemean",   "annotation",   NA,            "Prop. Above Mean",  NA,      NA,         NA,         NA,     NA,     "%.2f%%",    "Proportions",
  "pzabove2",      "annotation",   NA,            "Prop. Above 2m",    NA,      NA,         NA,         NA,     NA,     "%.2f%%",    "Proportions",
  "pzabove5",      "annotation",   NA,            "Prop. Above 5m",    NA,      NA,         NA,         NA,     NA,     "%.2f%%",    "Proportions",
  "lad_min",       "annotation",   NA,            "LAD Min",           NA,      NA,         NA,         NA,     NA,     "%.3f",      "LAD",
  "lad_max",       "annotation",   NA,            "LAD Max",           NA,      NA,         NA,         NA,     NA,     "%.3f",      "LAD",
  "lad_mean",      "annotation",   NA,            "LAD Mean",          NA,      NA,         NA,         NA,     NA,     "%.3f",      "LAD",
  "lad_cv",        "annotation",   NA,            "LAD CV",            NA,      NA,         NA,         NA,     NA,     "%.3f",      "LAD",
  "lad_sum",       "annotation",   NA,            "LAD Sum",           NA,      NA,         NA,         NA,     NA,     "%.3f",      "LAD",
  "ziqr",          "annotation",   NA,            "IQR",               NA,      NA,         NA,         NA,     NA,     "%.3f",      "Dispersion",
  "zMADmean",      "annotation",   NA,            "MAD Mean",          NA,      NA,         NA,         NA,     NA,     "%.3f",      "Dispersion",
  "zMADmedian",    "annotation",   NA,            "MAD Median",        NA,      NA,         NA,         NA,     NA,     "%.3f",      "Dispersion",
  "CRR",           "annotation",   NA,            "CRR",               NA,      NA,         NA,         NA,     NA,     "%.3f",      "Dispersion",
  "zentropy",      "annotation",   NA,            "Entropy",           NA,      NA,         NA,         NA,     NA,     "%.3f",      "Dispersion"
)

# --- Helper Functions ---
calculate_metrics <- function(las, registry, metrics_to_run) {
  sets_to_run <- registry %>% filter(name %in% metrics_to_run)
  results_list <- purrr::pmap(sets_to_run, function(name, metric_formula, required_attributes) {
    if (all(required_attributes %in% names(las@data))) {
      cloud_metrics(las, func = metric_formula)
    } else {
      warning("Skipping '", name, "'. Missing attributes.", call. = FALSE)
      NULL
    }
  })
  bind_cols(compact(results_list))
}

add_metric_labels <- function(p, metrics_df, viz_registry, label_size, label_alpha, label_fill,
                              hjust_label_override = NULL, vjust_label_override = NULL) {
  
  height_rules <- viz_registry %>% filter(metric_type == "height", metric_name %in% names(metrics_df))
  if (nrow(height_rules) == 0) return(p)
  
  label_data <- tibble()
  
  # Add horizontal lines
  for (i in 1:nrow(height_rules)) {
    rule <- height_rules[i, ]
    metric_val <- metrics_df[[rule$metric_name]]
    
    if (rule$geom == "hline") {
      p <- p + geom_hline(yintercept = metric_val, color = rule$color, linetype = rule$linetype, linewidth = rule$thickness)
    } else if (rule$geom == "range_hline") {
      mean_val <- metrics_df[["zmean"]]
      if (!is.null(mean_val)) {
        p <- p + geom_hline(yintercept = mean_val + metric_val, color = rule$color, linetype = rule$linetype, linewidth = rule$thickness) +
          geom_hline(yintercept = mean_val - metric_val, color = rule$color, linetype = rule$linetype, linewidth = rule$thickness)
      }
    }
  }
  
  # Build data frame for height labels
  for (i in 1:nrow(height_rules)) {
    rule <- height_rules[i, ]
    metric_val <- metrics_df[[rule$metric_name]]
    final_hjust <- if (!is.null(hjust_label_override)) hjust_label_override else rule$hjust
    final_vjust <- if (!is.null(vjust_label_override)) vjust_label_override else rule$vjust
    
    if (rule$geom == "hline") {
      label_data <- bind_rows(label_data, tibble(y = metric_val, label_text = rule$label, hjust = final_hjust, vjust = final_vjust, color = rule$color))
    } else if (rule$geom == "range_hline") {
      mean_val <- metrics_df[["zmean"]]
      if (!is.null(mean_val)) {
        vjust_lower <- if (!is.null(vjust_label_override)) -vjust_label_override + 1 else 1 - rule$vjust
        label_data <- bind_rows(label_data,
                                tibble(y = mean_val + metric_val, label_text = paste("+1", rule$label), hjust = final_hjust, vjust = final_vjust, color = rule$color),
                                tibble(y = mean_val - metric_val, label_text = paste("-1", rule$label), hjust = final_hjust, vjust = vjust_lower, color = rule$color)
        )
      }
    }
  }
  
  p <- p + geom_label(
    data = label_data,
    aes(x = Inf, y = y, label = label_text, hjust = hjust, vjust = vjust, color = color),
    size = label_size, alpha = label_alpha, fill = label_fill,
    show.legend = FALSE
  ) +
    scale_color_identity()
  
  return(p)
}

create_transect <- function(las, width = 2, length = NULL, shift = c(0, 0)) {
  # --- Calculate the shifted Y center ---
  y_center <- mean(las@data$Y) + shift[2] # Add the Y shift
  
  if (is.null(length)) {
    # --- Apply the X shift to the min and max coordinates ---
    p1 <- c(min(las@data$X) + shift[1], y_center)
    p2 <- c(max(las@data$X) + shift[1], y_center)
  } else {
    
    # --- Calculate the shifted X center and apply it ---
    x_center <- mean(range(las@data$X)) + shift[1] # Add the X shift
    p1 <- c(x_center - (length / 2), y_center)
    p2 <- c(x_center + (length / 2), y_center)
  }
  
  las_transect <- clip_transect(las, p1, p2, width = width)
  
  # --- check to handle cases where the transect is empty ---
  if (npoints(las_transect) == 0) {
    warning("Transect is empty. The shift may have moved it outside the point cloud extent.")
    return(las_transect)
  }
  
  # Normalize the X coordinates of the output to start at 0 for easier plotting
  las_transect@data$X <- las_transect@data$X - min(las_transect@data$X)
  
  return(las_transect)
}

# --- Main Function ---
plot_lidar_metrics <- function(las, metrics_to_run = "basic", point_color = "black",
                               point_size = 1.0, point_alpha = 1.0,
                               title_label = "Two-dimensional Lidar Profile with Metrics",
                               label_size = 3, label_alpha = 0.6, label_fill = "white",
                               hjust_label_override = NULL, vjust_label_override = NULL) {
  
  summary_table <- calculate_metrics(las, metric_calculation_registry, metrics_to_run)
  if (nrow(summary_table) == 0) stop("No metrics were calculated.", call. = FALSE)
  
  # Create Subtitle from Annotation Metrics
  annotation_rules <- metric_viz_dict %>%
    filter(metric_type == "annotation", metric_name %in% names(summary_table))
  
  subtitle_text <- ""
  if (nrow(annotation_rules) > 0) {
    # Ensure the order of groups is consistent
    group_order <- c("Proportions", "LAD", "Dispersion")
    annotation_rules$group <- factor(annotation_rules$group, levels = group_order)
    
    subtitle_text <- annotation_rules %>%
      arrange(group) %>% # Sort by the factor levels
      mutate(
        value_text = pmap_chr(list(format_spec, metric_name), ~sprintf(.x, summary_table[[.y]])),
        full_label = paste(label, value_text, sep = ": ")
      ) %>%
      group_by(group) %>%
      summarise(line = paste(full_label, collapse = " | "), .groups = 'drop') %>%
      pull(line) %>%
      paste(collapse = "\n")
  }
  
  
  x_label <- if (min(las@data$X) < 1000) "Distance along transect (m)" else "Easting (X)"
  
  base_plot <- ggplot(payload(las), aes(x = X, y = Z)) +
    geom_point(color = point_color, size = point_size, alpha = point_alpha) +
    coord_equal(clip = "off") +
    labs(
      title = title_label,
      subtitle = subtitle_text,
      x = x_label,
      y = "Height (Z)"
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(face = "bold", size = 14, hjust = 0.5),
      plot.subtitle = element_text(size = 9, hjust = 0.5, face = "italic", lineheight = 1.1),
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(color = "gray90", linetype = "dashed"),
      plot.margin = margin(5.5, 50, 5.5, 5.5, "pt")
    )
  
  final_plot <- add_metric_labels(
    base_plot, summary_table, metric_viz_dict,
    label_size, label_alpha, label_fill,
    hjust_label_override, vjust_label_override
  )
  
  return(list(plot = final_plot, metrics = summary_table))
}

las <- readLAS('data/zrh_norm.laz')
# Create a transect with a restricted length
las_transect <- create_transect(las, width = 20, length = 20,shift = c(28,-10))

# Run the analysis with all metric types, including "dispersion".
results <- plot_lidar_metrics(
  las_transect ,
  metrics_to_run = c("basic", "percentiles", "cover"),
  point_color = "black",
  point_size = 1.5,
  point_alpha = 0.4
)

# Print the results
print(results$plot)

