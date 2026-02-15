# fz-brent

A [Funz](https://github.com/Funz/fz) algorithm plugin implementing **Brent's method for 1D root finding**.

Brent's method is a hybrid root-finding algorithm that combines bisection, secant, and inverse quadratic interpolation methods to find a root of a function within a given interval. It provides the best balance between speed and robustness.

## Features

### Algorithm Interface (R S3 class)

The Brent algorithm implements the standard fz R algorithm interface:

- `Brent(...)`: S3 constructor accepting algorithm-specific options
- `get_initial_design.Brent(obj, input_variables, output_variables)`: Return 3 initial bracketing points
- `get_next_design.Brent(obj, X, Y)`: Return next 3 points (a, b, c) or `list()` when converged
- `get_analysis.Brent(obj, X, Y)`: Return final root-finding analysis
- `get_analysis_tmp.Brent(obj, X, Y)`: Return intermediate progress

### Algorithm Details

- **Author**: Miguel Munoz Zuniga
- **Type**: Root finding / Inversion
- **Reference**: [Brent's method - Wikipedia](https://en.wikipedia.org/wiki/Brent%27s_method)
- **1D only**: Works with a single input variable
- **Guaranteed convergence**: When the root is properly bracketed

## Algorithm Options

- `ytarget` (default: 0.0): Target output value to find
- `ytol` (default: 0.1): Convergence precision on output value
- `xtol` (default: 0.01): Convergence precision on input value
- `max_iterations` (default: 100): Maximum number of iterations

## Requirements

- **R** must be installed on your system
- **rpy2** Python package: `pip install rpy2`
- **fz** framework: `pip install git+https://github.com/Funz/fz.git`

## Installation

```bash
pip install git+https://github.com/Funz/fz.git
pip install rpy2
```

### Install the Algorithm Plugin

```python
import fz
fz.install_algorithm("Brent")
```

Or from a URL:
```python
fz.install_algorithm("https://github.com/Funz/fz-brent")
```

Or using the CLI:
```bash
fz install Brent
```

## Usage

### Without fzd (standalone algorithm testing)

You can test the Brent algorithm without any simulation code, using rpy2 directly:

```python
from rpy2 import robjects

# Source the R algorithm
robjects.r.source(".fz/algorithms/brent.R")
r_globals = robjects.globalenv

# Create an instance with custom options
r_algo = robjects.r["Brent"](ytarget=0.0, ytol=0.01, xtol=0.01, max_iterations=100)

# Define input variable range (1D only)
r_input_vars = robjects.r('list(x = c(0.0, 1.0))')
r_output_vars = robjects.StrVector(["y"])

# Get initial design (3 bracketing points)
r_design = r_globals['get_initial_design'](r_algo, r_input_vars, r_output_vars)
print(f"Initial design: {len(r_design)} points")
```

Or via fz's automatic wrapper:

```python
from fz.algorithms import load_algorithm

# Load R algorithm (fz handles rpy2 wrapping automatically)
algo = load_algorithm("Brent", ytarget=0.0, ytol=0.01, xtol=0.01)

# Same Python interface as Python algorithms
design = algo.get_initial_design({"x": (0.0, 1.0)}, ["y"])
print(f"Initial design: {len(design)} points")
```

### With fzd (coupled with a model)

Use `fz.fzd()` to run the Brent algorithm coupled with a model and calculators:

```python
import fz

# Install model and algorithm plugins
fz.install("Model")  # or your model
fz.install_algorithm("Brent")

# Run iterative root finding
analysis = fz.fzd(
    input_path="examples/Model/input.txt",
    input_variables={"x": "[0;10]"},
    model="Model",
    output_expression="result",
    algorithm="Brent",
    algorithm_options={"ytarget": 0.0, "ytol": 0.01, "xtol": 0.01},
    calculators="localhost_Model",
    analysis_dir="analysis_results"
)

print(analysis)
```

## Directory Structure

```
fz-brent/
├── .fz/
│   └── algorithms/
│       └── brent.R                # R algorithm implementation (S3 class)
├── .github/
│   └── workflows/
│       └── test.yml               # CI workflow (includes R setup)
├── tests/
│   ├── test_plugin.py             # Test suite (uses rpy2)
│   ├── test_brent.R               # Original R tests
│   └── test_edge_cases.R          # Edge case R tests
├── examples/
│   └── basic_usage.R              # R usage example
├── example_standalone.ipynb       # Notebook: algorithm without fzd
├── example_with_fzd.ipynb         # Notebook: algorithm with fzd
├── DOCUMENTATION.md               # Detailed algorithm documentation
├── LICENSE
└── README.md
```

## Running Tests

```bash
# Run all Python tests (pytest)
python -m pytest tests/test_plugin.py -v

# Or run R tests directly
cd tests && Rscript test_brent.R
cd tests && Rscript test_edge_cases.R
```

**Note:** Tests require R and rpy2. Tests that need rpy2 will be skipped automatically if it's not available.

## License

See the [original repository](https://github.com/Funz/algorithm-Brent) for license information.

## Related Links

- [Funz/fz](https://github.com/Funz/fz) - Main framework
- [Funz/fz-AlgorithmR](https://github.com/Funz/fz-AlgorithmR) - Template for R algorithm plugins
- [Funz/fz-Algorithm](https://github.com/Funz/fz-Algorithm) - Template for Python algorithm plugins
- [Funz/algorithm-Brent](https://github.com/Funz/algorithm-Brent) - Original Funz algorithm
