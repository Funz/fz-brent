#title: Brent method for 1D root finding
#author: Miguel Munoz Zuniga
#type: root_finding
#options: ytarget=0.0;ytol=0.1;xtol=0.01;max_iterations=100
#require: base64enc

# Constructor for Brent S3 class
Brent <- function(...) {
  # Get options from ... arguments
  opts <- list(...)

  # Create object with initial state
  # Use an environment for mutable state (idiomatic S3 pattern)
  state <- new.env(parent = emptyenv())
  state$i <- 0
  state$exit <- -1  # Reason end of algo
  state$input <- list()
  state$xtol01 <- NULL
  state$d <- NULL
  state$e <- NULL

  obj <- list(
    options = list(
      ytarget = as.numeric(
        ifelse(is.null(opts$ytarget), 0.0, opts$ytarget)
      ),
      ytol = as.numeric(
        ifelse(is.null(opts$ytol), 0.1, opts$ytol)
      ),
      xtol = as.numeric(
        ifelse(is.null(opts$xtol), 0.01, opts$xtol)
      ),
      max_iterations = as.integer(
        ifelse(is.null(opts$max_iterations), 100, opts$max_iterations)
      )
    ),
    state = state  # Environment for mutable state
  )

  # Set S3 class
  class(obj) <- "Brent"

  return(obj)
}

# Generic function definitions (if not already defined)
if (!exists("get_initial_design")) {
  get_initial_design <- function(obj, ...) UseMethod("get_initial_design")
}

if (!exists("get_next_design")) {
  get_next_design <- function(obj, ...) UseMethod("get_next_design")
}

if (!exists("get_analysis")) {
  get_analysis <- function(obj, ...) UseMethod("get_analysis")
}

if (!exists("get_analysis_tmp")) {
  get_analysis_tmp <- function(obj, ...) UseMethod("get_analysis_tmp")
}

# Method: get_initial_design
get_initial_design.Brent <- function(obj, input_variables, output_variables) {
  if (length(input_variables) != 1) {
    stop("Cannot find root of more than 1D function")
  }

  # Store variable bounds in mutable state
  # input_variables is a named list: list(var1 = c(min, max))
  var_name <- names(input_variables)[1]
  bounds <- input_variables[[var_name]]
  
  if (!is.numeric(bounds) || length(bounds) != 2) {
    stop(paste("Input variable", var_name, "must have c(min, max) bounds"))
  }
  
  obj$state$input[[var_name]] <- list(min = bounds[1], max = bounds[2])

  # Rescale xtol in [0,1]
  xminptol <- obj$state$input[[var_name]]$min + obj$options$xtol
  xminptol_matrix <- matrix(c(xminptol), ncol = 1)
  colnames(xminptol_matrix) <- var_name
  obj$state$xtol01 <- to01(xminptol_matrix, obj$state$input)[1, 1] # Rescale xtol

  obj$state$i <- 0
  obj$state$exit <- -1

  # Return initial design: 3 points at 0, 1, 1 (in [0,1] space)
  x_01 <- matrix(c(0, 1, 1), ncol = 1)
  colnames(x_01) <- var_name
  x_real <- from01(x_01, obj$state$input)

  # Convert matrix to list of named lists
  design <- list()
  for (i in 1:nrow(x_real)) {
    design[[i]] <- list()
    design[[i]][[var_name]] <- x_real[i, 1]
  }

  return(design)
}

# Method: get_next_design
get_next_design.Brent <- function(obj, X, Y) {
  # Convert X (list of named lists) to matrix for internal processing
  var_name <- names(obj$state$input)[1]
  
  X_matrix <- matrix(sapply(X, function(x) x[[var_name]]), ncol = 1)
  colnames(X_matrix) <- var_name
  
  # Convert Y (list of values) to matrix
  Y_matrix <- matrix(unlist(Y), ncol = 1)
  
  # Transform to [0,1] space
  X_01 <- to01(X_matrix, obj$state$input)
  Y_adj <- Y_matrix - obj$options$ytarget

  if (obj$state$i >= obj$options$max_iterations) {
    obj$state$exit <- 2
    return(list())  # Empty list signals finished
  }

  obj$state$i <- obj$state$i + 1

  n <- nrow(X_01)
  a <- as.numeric(X_01[n - 2, 1])
  b <- as.numeric(X_01[n - 1, 1])
  c <- as.numeric(X_01[n, 1])
  fa <- as.numeric(Y_adj[n - 2, 1])
  fb <- as.numeric(Y_adj[n - 1, 1])
  fc <- as.numeric(Y_adj[n, 1])

  if ((obj$state$i == 1) && (fa * fb > 0)) {
    # root must be bracketed for Brent
    obj$state$exit <- 1
    return(list())
  }

  if (fb * fc > 0) {
    # Rename a, b, c and adjust bounding interval d
    c <- a
    fc <- fa
    obj$state$d <- b - a
    obj$state$e <- obj$state$d
  }

  if (abs(fc) < abs(fb)) {
    # b stands for the best approx of the root which will lie between b and c
    a <- b
    b <- c
    c <- a
    fa <- fb
    fb <- fc
    fc <- fa
  }

  tol1 <- 0.5 * obj$state$xtol01  # Convergence check tolerance
  xm <- 0.5 * (c - b)

  if ((abs(xm) <= tol1) || (fb == 0)) {
    # stop if fb = 0 return root b or tolerance reached
    obj$state$exit <- 0
    return(list())
  }

  if ((abs(obj$state$e) >= tol1) && (abs(fa) > abs(fb))) {
    s <- fb / fa
    if (a == c) {
      # Attempt linear interpolation
      p <- 2.0 * xm * s
      q <- 1.0 - s
    } else {
      # Attempt inverse quadratic interpolation
      q <- fa / fc
      r <- fb / fc
      p <- s * (2.0 * xm * q * (q - r) - (b - a) * (r - 1.0))
      q <- (q - 1.0) * (r - 1.0) * (s - 1.0)
    }

    if (p > 0) {
      q <- -q  # Check whether in bounds
    }
    p <- abs(p)
    if (2.0 * p < min(3.0 * xm * q - abs(tol1 * q), abs(obj$state$e * q))) {
      obj$state$e <- obj$state$d  # Accept interpolation
      obj$state$d <- p / q
    } else {
      obj$state$d <- xm  # Interpolation failed, use bisection
      obj$state$e <- obj$state$d
    }
  } else {
    # Bounds decreasing too slowly, use bisection
    obj$state$d <- xm
    obj$state$e <- obj$state$d
  }

  a <- b  # Move last best guess to a
  fa <- fb
  if (abs(obj$state$d) > tol1) {
    # Evaluate new trial root
    b <- b + obj$state$d
  } else {
    b <- b + sign(xm) * tol1
  }

  # Return next design: 3 points
  Xnext_01 <- matrix(c(a, b, c), ncol = 1)
  colnames(Xnext_01) <- var_name
  Xnext_real <- from01(Xnext_01, obj$state$input)

  # Convert matrix to list of named lists
  design <- list()
  for (i in 1:nrow(Xnext_real)) {
    design[[i]] <- list()
    design[[i]][[var_name]] <- Xnext_real[i, 1]
  }

  return(design)
}

# Method: get_analysis
get_analysis.Brent <- function(obj, X, Y) {
  analysis_dict <- list(text = "", data = list())

  # Determine exit status
  if (obj$state$exit == 1) {
    exit_txt <- "root not bracketed"
    converged <- FALSE
  } else if (obj$state$exit == 2) {
    exit_txt <- "maximum iteration reached"
    converged <- FALSE
  } else if (obj$state$exit == 0) {
    exit_txt <- "algorithm converged"
    converged <- TRUE
  } else {
    exit_txt <- paste("error code", obj$state$exit)
    converged <- FALSE
  }

  # Convert X and Y to matrices
  var_name <- names(obj$state$input)[1]
  X_matrix <- matrix(sapply(X, function(x) x[[var_name]]), ncol = 1)
  Y_matrix <- matrix(unlist(Y), ncol = 1)

  # The root approximation is at the second-to-last point
  root_idx <- nrow(X_matrix) - 1
  root_x <- X_matrix[root_idx, 1]
  root_y <- Y_matrix[root_idx, 1]

  # Store data
  analysis_dict$data <- list(
    root = root_x,
    value = root_y,
    iterations = obj$state$i,
    converged = converged,
    exit_code = obj$state$exit
  )

  # Create text summary
  analysis_dict$text <- sprintf(
"Brent Root Finding Results:
  Iterations: %d
  Root approximation: %.6f
  Corresponding value: %.6f
  Target value: %.6f
  Exit status: %s
",
    obj$state$i,
    root_x,
    root_y,
    obj$options$ytarget,
    exit_txt
  )

  # Try to create HTML with plot
  tryCatch({
    # Create plot
    png_file <- tempfile(fileext = ".png")
    png(png_file, width = 600, height = 600)

    plot(X_matrix[, 1], Y_matrix[, 1], 
         pch = 20,
         xlab = var_name,
         ylab = "Output",
         main = "Brent Root Finding")
    abline(h = obj$options$ytarget, lty = 2, col = "grey70")
    points(root_x, root_y, pch = 20, col = "red", cex = 2)
    grid(col = rgb(0, 0, 0, 0.3))

    dev.off()

    # Convert to base64
    if (requireNamespace("base64enc", quietly = TRUE)) {
      img_base64 <- base64enc::base64encode(png_file)

      html_output <- sprintf(
'<div>
  <p><strong>Root approximation:</strong> %.6f</p>
  <p><strong>Corresponding value:</strong> %.6f (target: %.6f)</p>
  <p><strong>Iterations:</strong> %d</p>
  <p><strong>Exit status:</strong> %s</p>
  <img src="data:image/png;base64,%s" alt="Root Finding Plot" style="max-width:600px;"/>
</div>',
        root_x,
        root_y,
        obj$options$ytarget,
        obj$state$i,
        exit_txt,
        img_base64
      )
      analysis_dict$html <- html_output
    }

    # Clean up temp file
    unlink(png_file)
  }, error = function(e) {
    # If plotting fails, just skip it
  })

  return(analysis_dict)
}

# Method: get_analysis_tmp
get_analysis_tmp.Brent <- function(obj, X, Y) {
  # Convert X and Y to matrices
  var_name <- names(obj$state$input)[1]
  X_matrix <- matrix(sapply(X, function(x) x[[var_name]]), ncol = 1)
  Y_matrix <- matrix(unlist(Y), ncol = 1)

  # The current best approximation is at the second-to-last point
  if (nrow(X_matrix) >= 2) {
    root_idx <- nrow(X_matrix) - 1
    root_x <- X_matrix[root_idx, 1]
    root_y <- Y_matrix[root_idx, 1]

    return(list(
      text = sprintf(
        "  Progress: iteration %d, root≈%.6f, value≈%.6f (target: %.6f)",
        obj$state$i,
        root_x,
        root_y,
        obj$options$ytarget
      ),
      data = list(
        iteration = obj$state$i,
        current_root = root_x,
        current_value = root_y
      )
    ))
  } else {
    return(list(
      text = sprintf("  Progress: iteration %d", obj$state$i),
      data = list(iteration = obj$state$i)
    ))
  }
}

# Helper function: from01
# Convert from [0,1] space to real space
from01 <- function(X, inp) {
  for (i in 1:ncol(X)) {
    namei <- colnames(X)[i]
    X[, i] <- X[, i] * (inp[[namei]]$max - inp[[namei]]$min) + inp[[namei]]$min
  }
  return(X)
}

# Helper function: to01
# Convert from real space to [0,1] space
to01 <- function(X, inp) {
  for (i in 1:ncol(X)) {
    namei <- colnames(X)[i]
    X[, i] <- (X[, i] - inp[[namei]]$min) / (inp[[namei]]$max - inp[[namei]]$min)
  }
  return(X)
}
