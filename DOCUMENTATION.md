# Brent Algorithm Documentation

## Overview

Brent's method is a root-finding algorithm that combines the reliability of the bisection method with the speed of the secant method and inverse quadratic interpolation. It is guaranteed to converge when the root is properly bracketed and typically requires fewer function evaluations than bisection alone.

## Algorithm Description

The algorithm maintains a bracketing interval [a, c] that contains the root, with b being the current best approximation. At each iteration, it:

1. Checks if the root is properly bracketed (f(a) and f(b) have opposite signs)
2. Attempts inverse quadratic interpolation if three distinct points are available
3. Falls back to linear interpolation (secant method) if only two points are available
4. Uses bisection if interpolation would be unreliable or too slow
5. Updates the bracketing interval and best approximation

The algorithm terminates when:
- The tolerance is met (|f(b)| < ytol or |b - c| < xtol)
- Maximum iterations are reached
- The root is not properly bracketed

## Implementation Details

### S3 Class Structure

The implementation follows the new fz framework using R's S3 object system:

```r
Brent <- function(...) {
  # Constructor that creates a Brent object with:
  # - options: ytarget, ytol, xtol, max_iterations
  # - state: mutable environment for iteration state
  class(obj) <- "Brent"
  return(obj)
}
```

### Methods

#### `get_initial_design(obj, input_variables, output_variables)`

Creates the initial design of experiment with 3 points:
- Point at x = min (left boundary)
- Two points at x = max (right boundary)

The algorithm requires that the root be bracketed between these points, meaning f(min) and f(max) must have opposite signs when adjusted by ytarget.

**Parameters:**
- `input_variables`: Named list with one variable, e.g., `list(x = c(min, max))`
- `output_variables`: Name of output variable (for documentation)

**Returns:** List of named lists representing initial points to evaluate

#### `get_next_design(obj, X, Y)`

Computes the next design points based on current evaluations.

**Parameters:**
- `X`: List of all evaluated input points (named lists)
- `Y`: List of all corresponding output values

**Returns:** 
- List of 3 new points to evaluate (next iteration)
- Empty list if algorithm has converged or failed

**Internal Logic:**
1. Transforms inputs to [0,1] space for numerical stability
2. Adjusts outputs by subtracting ytarget
3. Checks bracketing condition
4. Attempts interpolation (inverse quadratic or linear)
5. Falls back to bisection if needed
6. Returns new bracketing triple (a, b, c)

#### `get_analysis(obj, X, Y)`

Produces final analysis of the root-finding process.

**Returns:** Dictionary with:
- `text`: Human-readable summary
- `data`: Structured results (root, value, iterations, converged, exit_code)
- `html`: (optional) HTML visualization with embedded plot

#### `get_analysis_tmp(obj, X, Y)`

Provides intermediate progress updates during iteration.

**Returns:** Dictionary with:
- `text`: Brief progress message
- `data`: Current iteration state

### Helper Functions

#### `from01(X, inp)` and `to01(X, inp)`

Coordinate transformation functions that map between:
- Real space: [min, max]
- Unit space: [0, 1]

These ensure numerical stability and make the tolerance specifications more intuitive.

## Convergence Criteria

The algorithm converges when one of the following conditions is met:

1. **Root found**: |f(b) - ytarget| ≈ 0 (within ytol)
2. **Interval collapsed**: |b - c| < xtol
3. **Maximum iterations**: Iteration count reaches max_iterations

## Exit Codes

- `0`: Algorithm converged successfully
- `1`: Root not bracketed (f(min) and f(max) have same sign)
- `2`: Maximum iterations reached without convergence
- Other: Unexpected error

## Usage Examples

### Basic Root Finding

Find where f(x) = 0:

```r
source(".fz/algorithms/brent.R")

# Define function
f <- function(x) cos(pi * x)

# Create algorithm object
brent <- Brent(ytarget = 0.0, ytol = 0.01, xtol = 0.01)

# Get initial design
X <- get_initial_design(brent, list(x = c(0, 1)), "y")
Y <- lapply(X, function(p) f(p$x))

# Iterate
all_X <- X; all_Y <- Y
repeat {
  X_next <- get_next_design(brent, all_X, all_Y)
  if (length(X_next) == 0) break
  
  Y_next <- lapply(X_next, function(p) f(p$x))
  all_X <- c(all_X, X_next)
  all_Y <- c(all_Y, Y_next)
}

# Get result
result <- get_analysis(brent, all_X, all_Y)
print(result$data$root)
```

### Finding Non-Zero Target

Find where f(x) = target:

```r
# Find where cos(pi*x) = 0.5
brent <- Brent(ytarget = 0.5, ytol = 0.001, xtol = 0.001)
# ... (same iteration pattern)
```

### Different Variable Names

The algorithm works with any variable name:

```r
# Use 'theta' instead of 'x'
X <- get_initial_design(brent, list(theta = c(0, 1)), "y")
Y <- lapply(X, function(p) f(p$theta))
```

## Performance Characteristics

- **Best case**: O(log n) convergence (superlinear)
- **Worst case**: O(n) convergence (linear, same as bisection)
- **Typical case**: 5-15 iterations for engineering tolerances
- **Function evaluations**: 3 + 3*iterations (3 per iteration)

## Limitations

1. **1D only**: Cannot solve multidimensional root-finding problems
2. **Bracketing required**: Initial interval must bracket the root
3. **Single root**: Finds only one root even if multiple exist in interval
4. **Continuous functions**: Best suited for continuous, smooth functions

## Comparison with Other Methods

| Method | Convergence | Robustness | Speed |
|--------|-------------|------------|-------|
| Bisection | Linear | Very high | Slow |
| Newton | Quadratic | Low | Very fast |
| Secant | Superlinear | Medium | Fast |
| **Brent** | Superlinear | High | Fast |

Brent's method provides the best balance between speed and robustness.

## References

1. Brent, R. P. (1973). *Algorithms for Minimization without Derivatives*. Prentice-Hall.
2. Wikipedia: [Brent's method](https://en.wikipedia.org/wiki/Brent%27s_method)
3. Press, W. H., et al. (2007). *Numerical Recipes: The Art of Scientific Computing*.

## Testing

The implementation includes comprehensive tests:

```bash
cd tests
Rscript test_brent.R       # Basic functionality tests
Rscript test_edge_cases.R  # Edge case and robustness tests
```

All tests should pass with "✓ Test PASSED" messages.
