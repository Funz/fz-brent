# fz-brent

Brent's method for 1D root finding, ported to the new fz framework.

## Description

This repository contains an implementation of Brent's method for finding roots of 1-dimensional functions. Brent's method is a hybrid root-finding algorithm that combines bisection, secant, and inverse quadratic interpolation methods to find a root of a function within a given interval.

* **Author**: Miguel Munoz Zuniga
* **Type**: Root finding / Inversion
* **Reference**: [Brent's method - Wikipedia](https://en.wikipedia.org/wiki/Brent%27s_method)

## Algorithm Options

- `ytarget` (default: 0.0): Target output value to find
- `ytol` (default: 0.1): Convergence precision on output value
- `xtol` (default: 0.01): Convergence precision on input value
- `max_iterations` (default: 100): Maximum number of iterations

## Requirements

- R (>= 3.5.0)
- base64enc package (for HTML visualization)

## Usage

The algorithm follows the new fz framework pattern using S3 classes:

```r
# Source the algorithm
source(".fz/algorithms/brent.R")

# Define a function to find the root of
f <- function(x) {
  cos(pi * x)
}

# Create Brent object with options
brent <- Brent(ytarget = 0.0, ytol = 0.01, xtol = 0.01, max_iterations = 100)

# Define input variables (single variable with min/max bounds)
input_vars <- list(x = c(0, 1))
output_vars <- "y"

# Get initial design
X <- get_initial_design(brent, input_vars, output_vars)

# Evaluate initial points
Y <- lapply(X, function(point) f(point$x))

# Store all evaluations
all_X <- X
all_Y <- Y

# Iterate until convergence
while (TRUE) {
  # Get next design
  X_next <- get_next_design(brent, all_X, all_Y)
  
  # Check if finished (empty list means done)
  if (length(X_next) == 0) {
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

# Print results
cat(analysis$text)
print(analysis$data)
```

## Input/Output Format

- **Input**: Single variable with bounds specified as `list(varname = c(min, max))`
- **Output**: Single numerical value

The algorithm will find the value of the input variable where the function output equals `ytarget`.

## Testing

Run the test suite to validate the implementation:

```bash
cd tests
Rscript test_brent.R
```

The tests include:
1. Finding the root of `cos(pi*x)` (expected: 0.5)
2. Finding the root of `((x-0.75)/3)^3` (expected: 0.75)
3. Finding where `cos(pi*x) = 0.5` (expected: 0.333)

## Migration from Old Framework

This implementation has been ported from the old Funz algorithm framework to the new fz framework. Key changes:

1. **S3 Class Pattern**: Uses standard R S3 classes instead of environment-based objects
2. **Generic Methods**: Uses `get_initial_design()`, `get_next_design()`, `get_analysis()` instead of standalone functions
3. **Data Format**: Input/output uses list of named lists instead of matrices
4. **Visualization**: Uses base64-encoded images in HTML output instead of separate files

## License

See the [original repository](https://github.com/Funz/algorithm-Brent) for license information.
