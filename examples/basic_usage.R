# Example usage of Brent algorithm for root finding

# Source the algorithm
source("../.fz/algorithms/brent.R")

cat(paste(rep("=", 60), collapse=""), "\n")
cat("Brent Algorithm Example\n")
cat(paste(rep("=", 60), collapse=""), "\n\n")

# Example 1: Find root of cos(pi*x) = 0
cat("Example 1: Find root of cos(pi*x) = 0\n")
cat("Expected root: x = 0.5\n\n")

# Define the function
f1 <- function(x) {
  cos(pi * x)
}

# Create Brent object
brent1 <- Brent(ytarget = 0.0, ytol = 0.001, xtol = 0.001, max_iterations = 100)

# Get initial design
X1 <- get_initial_design(brent1, 
                         input_variables = list(x = c(0, 1)), 
                         output_variables = "y")

# Evaluate initial design
Y1 <- lapply(X1, function(point) f1(point$x))

# Store all evaluations
all_X1 <- X1
all_Y1 <- Y1

# Iterate
iter <- 0
while (iter < 100) {
  iter <- iter + 1
  
  # Get temporary analysis
  tmp_analysis <- get_analysis_tmp(brent1, all_X1, all_Y1)
  cat(tmp_analysis$text, "\n")
  
  # Get next design
  X_next <- get_next_design(brent1, all_X1, all_Y1)
  
  if (length(X_next) == 0) {
    break
  }
  
  # Evaluate
  Y_next <- lapply(X_next, function(point) f1(point$x))
  
  # Append
  all_X1 <- c(all_X1, X_next)
  all_Y1 <- c(all_Y1, Y_next)
}

# Get final analysis
analysis1 <- get_analysis(brent1, all_X1, all_Y1)
cat("\n")
cat(analysis1$text)
cat("\n")

# Example 2: Find where x^2 - 2 = 0 (i.e., sqrt(2))
cat(paste(rep("=", 60), collapse=""), "\n")
cat("Example 2: Find root of x^2 - 2 = 0\n")
cat("Expected root: x = sqrt(2) ≈ 1.414\n\n")

# Define the function
f2 <- function(x) {
  x^2 - 2
}

# Create Brent object with different search interval
brent2 <- Brent(ytarget = 0.0, ytol = 0.001, xtol = 0.001, max_iterations = 100)

# Get initial design (search in [1, 2])
X2 <- get_initial_design(brent2, 
                         input_variables = list(x = c(1, 2)), 
                         output_variables = "y")

# Evaluate
Y2 <- lapply(X2, function(point) f2(point$x))

# Store all evaluations
all_X2 <- X2
all_Y2 <- Y2

# Iterate
iter <- 0
while (iter < 100) {
  iter <- iter + 1
  
  # Get temporary analysis
  tmp_analysis <- get_analysis_tmp(brent2, all_X2, all_Y2)
  cat(tmp_analysis$text, "\n")
  
  # Get next design
  X_next <- get_next_design(brent2, all_X2, all_Y2)
  
  if (length(X_next) == 0) {
    break
  }
  
  # Evaluate
  Y_next <- lapply(X_next, function(point) f2(point$x))
  
  # Append
  all_X2 <- c(all_X2, X_next)
  all_Y2 <- c(all_Y2, Y_next)
}

# Get final analysis
analysis2 <- get_analysis(brent2, all_X2, all_Y2)
cat("\n")
cat(analysis2$text)
cat("\n")

cat(paste(rep("=", 60), collapse=""), "\n")
cat("Examples completed!\n")
cat(paste(rep("=", 60), collapse=""), "\n")
