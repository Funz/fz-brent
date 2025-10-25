# Additional edge case tests for Brent algorithm

# Source the Brent algorithm
source("../.fz/algorithms/brent.R")

# Helper function for separator line
print_separator <- function() {
  cat(paste(rep("=", 60), collapse=""), "\n")
}

# Test 4: Test with root not bracketed initially
test_not_bracketed <- function() {
  cat("Test 4: Root not bracketed (should fail gracefully)\n")
  
  # Define a function that's positive in [0,1]
  f <- function(x) {
    x^2 + 1  # Always positive
  }
  
  # Create Brent object
  brent <- Brent(ytarget = 0.0, ytol = 0.01, xtol = 0.01, max_iterations = 100)
  
  # Get initial design
  input_vars <- list(x = c(0, 1))
  output_vars <- "y"
  
  X <- get_initial_design(brent, input_vars, output_vars)
  Y <- lapply(X, function(point) f(point$x))
  
  all_X <- X
  all_Y <- Y
  
  # Try to iterate
  iter <- 0
  while (iter < brent$options$max_iterations) {
    iter <- iter + 1
    X_next <- get_next_design(brent, all_X, all_Y)
    
    if (length(X_next) == 0) {
      cat("  Algorithm stopped after", iter, "iterations\n")
      break
    }
    
    Y_next <- lapply(X_next, function(point) f(point$x))
    all_X <- c(all_X, X_next)
    all_Y <- c(all_Y, Y_next)
  }
  
  # Get analysis
  analysis <- get_analysis(brent, all_X, all_Y)
  
  cat("  Exit code:", analysis$data$exit_code, "\n")
  cat("  Converged:", analysis$data$converged, "\n")
  
  # Should exit with code 1 (root not bracketed)
  if (analysis$data$exit_code == 1) {
    cat("  ✓ Test PASSED (correctly detected root not bracketed)\n\n")
    return(TRUE)
  } else {
    cat("  ✗ Test FAILED (expected exit code 1)\n\n")
    return(FALSE)
  }
}

# Test 5: Test with very tight tolerance
test_tight_tolerance <- function() {
  cat("Test 5: Very tight tolerance\n")
  
  # Define the function
  f <- function(x) {
    cos(pi * x)
  }
  
  # Create Brent object with very tight tolerance
  brent <- Brent(ytarget = 0.0, ytol = 1e-6, xtol = 1e-6, max_iterations = 100)
  
  # Get initial design
  input_vars <- list(x = c(0, 1))
  output_vars <- "y"
  
  X <- get_initial_design(brent, input_vars, output_vars)
  Y <- lapply(X, function(point) f(point$x))
  
  all_X <- X
  all_Y <- Y
  
  iter <- 0
  while (iter < brent$options$max_iterations) {
    iter <- iter + 1
    X_next <- get_next_design(brent, all_X, all_Y)
    
    if (length(X_next) == 0) {
      cat("  Algorithm finished after", iter, "iterations\n")
      break
    }
    
    Y_next <- lapply(X_next, function(point) f(point$x))
    all_X <- c(all_X, X_next)
    all_Y <- c(all_Y, Y_next)
  }
  
  # Get analysis
  analysis <- get_analysis(brent, all_X, all_Y)
  
  cat("  Root found:", analysis$data$root, "\n")
  cat("  Value at root:", analysis$data$value, "\n")
  cat("  Converged:", analysis$data$converged, "\n")
  
  # Check that it converged and is close to 0.5
  if (analysis$data$converged && abs(analysis$data$root - 0.5) < 1e-4) {
    cat("  ✓ Test PASSED\n\n")
    return(TRUE)
  } else {
    cat("  ✗ Test FAILED\n\n")
    return(FALSE)
  }
}

# Test 6: Test with different variable name
test_different_varname <- function() {
  cat("Test 6: Different variable name (theta instead of x)\n")
  
  # Define the function
  f <- function(theta) {
    theta^3 - 0.5
  }
  
  # Create Brent object
  brent <- Brent(ytarget = 0.0, ytol = 0.01, xtol = 0.01, max_iterations = 100)
  
  # Get initial design with variable named 'theta'
  input_vars <- list(theta = c(0, 1))
  output_vars <- "y"
  
  X <- get_initial_design(brent, input_vars, output_vars)
  Y <- lapply(X, function(point) f(point$theta))
  
  all_X <- X
  all_Y <- Y
  
  iter <- 0
  while (iter < brent$options$max_iterations) {
    iter <- iter + 1
    X_next <- get_next_design(brent, all_X, all_Y)
    
    if (length(X_next) == 0) {
      cat("  Algorithm finished after", iter, "iterations\n")
      break
    }
    
    Y_next <- lapply(X_next, function(point) f(point$theta))
    all_X <- c(all_X, X_next)
    all_Y <- c(all_Y, Y_next)
  }
  
  # Get analysis
  analysis <- get_analysis(brent, all_X, all_Y)
  
  cat("  Root found:", analysis$data$root, "\n")
  cat("  Value at root:", analysis$data$value, "\n")
  
  # theta^3 = 0.5, so theta = 0.5^(1/3) ≈ 0.7937
  expected_root <- 0.5^(1/3)
  if (abs(analysis$data$root - expected_root) < 0.01) {
    cat("  ✓ Test PASSED\n\n")
    return(TRUE)
  } else {
    cat("  ✗ Test FAILED\n\n")
    return(FALSE)
  }
}

# Run all edge case tests
print_separator()
cat("Running Brent Algorithm Edge Case Tests\n")
print_separator()
cat("\n")

results <- c(
  test_not_bracketed(),
  test_tight_tolerance(),
  test_different_varname()
)

print_separator()
cat("Edge Case Test Summary:\n")
cat("  Total tests:", length(results), "\n")
cat("  Passed:", sum(results), "\n")
cat("  Failed:", sum(!results), "\n")
print_separator()

# Exit with appropriate code
if (all(results)) {
  cat("\nAll edge case tests passed! ✓\n")
  quit(status = 0)
} else {
  cat("\nSome edge case tests failed! ✗\n")
  quit(status = 1)
}
