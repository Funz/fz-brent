# Test script for Brent root finding algorithm
# This script tests the new fz framework implementation

# Source the Brent algorithm
source("../.fz/algorithms/brent.R")

# Test 1: cos(pi*x) root finding
# Root should be at x = 0.5
test_cos_pi <- function() {
  cat("Test 1: Finding root of cos(pi*x)\n")
  
  # Define the function
  f <- function(x) {
    cos(pi * x)
  }
  
  # Create Brent object with default options
  brent <- Brent(ytarget = 0.0, ytol = 0.01, xtol = 0.01, max_iterations = 100)
  
  # Get initial design
  input_vars <- list(x = c(0, 1))
  output_vars <- "y"
  
  X <- get_initial_design(brent, input_vars, output_vars)
  
  # Evaluate initial design
  Y <- lapply(X, function(point) f(point$x))
  
  # Iterate until convergence
  all_X <- X
  all_Y <- Y
  
  max_iter <- 100
  iter <- 0
  while (iter < max_iter) {
    iter <- iter + 1
    
    # Get next design
    X_next <- get_next_design(brent, all_X, all_Y)
    
    # Check if finished
    if (length(X_next) == 0) {
      cat("  Algorithm finished after", iter, "iterations\n")
      break
    }
    
    # Evaluate new points
    Y_next <- lapply(X_next, function(point) f(point$x))
    
    # Append to all results
    all_X <- c(all_X, X_next)
    all_Y <- c(all_Y, Y_next)
  }
  
  # Get final analysis
  analysis <- get_analysis(brent, all_X, all_Y)
  
  cat("  Root found:", analysis$data$root, "\n")
  cat("  Value at root:", analysis$data$value, "\n")
  cat("  Expected root: 0.5\n")
  cat("  Converged:", analysis$data$converged, "\n")
  
  # Check result
  if (abs(analysis$data$root - 0.5) < 0.01) {
    cat("  ✓ Test PASSED\n\n")
    return(TRUE)
  } else {
    cat("  ✗ Test FAILED\n\n")
    return(FALSE)
  }
}

# Test 2: Cubic polynomial ((x-0.75)/3)^3 root finding
# Root should be at x = 0.75
test_poly3 <- function() {
  cat("Test 2: Finding root of ((x-0.75)/3)^3\n")
  
  # Define the function
  f <- function(x) {
    ((x - 0.75) / 3)^3
  }
  
  # Create Brent object
  brent <- Brent(ytarget = 0.0, ytol = 0.01, xtol = 0.01, max_iterations = 100)
  
  # Get initial design
  input_vars <- list(x = c(0, 1))
  output_vars <- "y"
  
  X <- get_initial_design(brent, input_vars, output_vars)
  
  # Evaluate initial design
  Y <- lapply(X, function(point) f(point$x))
  
  # Iterate until convergence
  all_X <- X
  all_Y <- Y
  
  max_iter <- 100
  iter <- 0
  while (iter < max_iter) {
    iter <- iter + 1
    
    # Get next design
    X_next <- get_next_design(brent, all_X, all_Y)
    
    # Check if finished
    if (length(X_next) == 0) {
      cat("  Algorithm finished after", iter, "iterations\n")
      break
    }
    
    # Evaluate new points
    Y_next <- lapply(X_next, function(point) f(point$x))
    
    # Append to all results
    all_X <- c(all_X, X_next)
    all_Y <- c(all_Y, Y_next)
  }
  
  # Get final analysis
  analysis <- get_analysis(brent, all_X, all_Y)
  
  cat("  Root found:", analysis$data$root, "\n")
  cat("  Value at root:", analysis$data$value, "\n")
  cat("  Expected root: 0.75\n")
  cat("  Converged:", analysis$data$converged, "\n")
  
  # Check result
  if (abs(analysis$data$root - 0.75) < 0.01) {
    cat("  ✓ Test PASSED\n\n")
    return(TRUE)
  } else {
    cat("  ✗ Test FAILED\n\n")
    return(FALSE)
  }
}

# Test 3: Test with non-zero target
test_nonzero_target <- function() {
  cat("Test 3: Finding where cos(pi*x) = 0.5\n")
  
  # Define the function
  f <- function(x) {
    cos(pi * x)
  }
  
  # Create Brent object with ytarget = 0.5
  brent <- Brent(ytarget = 0.5, ytol = 0.01, xtol = 0.01, max_iterations = 100)
  
  # Get initial design
  input_vars <- list(x = c(0, 1))
  output_vars <- "y"
  
  X <- get_initial_design(brent, input_vars, output_vars)
  
  # Evaluate initial design
  Y <- lapply(X, function(point) f(point$x))
  
  # Iterate until convergence
  all_X <- X
  all_Y <- Y
  
  max_iter <- 100
  iter <- 0
  while (iter < max_iter) {
    iter <- iter + 1
    
    # Get next design
    X_next <- get_next_design(brent, all_X, all_Y)
    
    # Check if finished
    if (length(X_next) == 0) {
      cat("  Algorithm finished after", iter, "iterations\n")
      break
    }
    
    # Evaluate new points
    Y_next <- lapply(X_next, function(point) f(point$x))
    
    # Append to all results
    all_X <- c(all_X, X_next)
    all_Y <- c(all_Y, Y_next)
  }
  
  # Get final analysis
  analysis <- get_analysis(brent, all_X, all_Y)
  
  cat("  Root found:", analysis$data$root, "\n")
  cat("  Value at root:", analysis$data$value, "\n")
  cat("  Expected root: 1/3 ≈ 0.333\n")
  cat("  Converged:", analysis$data$converged, "\n")
  
  # cos(pi*x) = 0.5 when pi*x = pi/3, so x = 1/3
  expected_root <- 1/3
  if (abs(analysis$data$root - expected_root) < 0.01) {
    cat("  ✓ Test PASSED\n\n")
    return(TRUE)
  } else {
    cat("  ✗ Test FAILED\n\n")
    return(FALSE)
  }
}

# Run all tests
cat(paste(rep("=", 60), collapse=""), "\n")
cat("Running Brent Algorithm Tests\n")
cat(paste(rep("=", 60), collapse=""), "\n\n")

results <- c(
  test_cos_pi(),
  test_poly3(),
  test_nonzero_target()
)

cat(paste(rep("=", 60), collapse=""), "\n")
cat("Test Summary:\n")
cat("  Total tests:", length(results), "\n")
cat("  Passed:", sum(results), "\n")
cat("  Failed:", sum(!results), "\n")
cat(paste(rep("=", 60), collapse=""), "\n")

# Exit with appropriate code
if (all(results)) {
  cat("\nAll tests passed! ✓\n")
  quit(status = 0)
} else {
  cat("\nSome tests failed! ✗\n")
  quit(status = 1)
}
