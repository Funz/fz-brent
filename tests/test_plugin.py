#!/usr/bin/env python3
"""
Test suite for fz-brent plugin.

These tests verify:
1. Algorithm R file structure and metadata
2. Algorithm loading via rpy2 / fz plugin system
3. Algorithm execution (initial design, next design, analysis)
4. Integration with fzd (if fz + model are available)

Requirements:
    - R must be installed on the system
    - rpy2 Python package: pip install rpy2
    - fz framework: pip install git+https://github.com/Funz/fz.git
"""

import os
import sys
import re


def test_algorithm_file_exists():
    """Test that the algorithm R file exists in .fz/algorithms/."""
    print("Testing algorithm file exists...")

    algo_file = ".fz/algorithms/brent.R"
    print(f"  Checking {algo_file}...", end=" ")
    assert os.path.exists(algo_file), f"File not found: {algo_file}"
    print("✓")

    print("  Algorithm file present!\n")


def test_algorithm_metadata():
    """Test that the algorithm R file has valid metadata headers."""
    print("Testing algorithm metadata...")

    algo_file = ".fz/algorithms/brent.R"

    with open(algo_file, "r") as f:
        content = f.read()

    # Check for required metadata headers
    required_headers = ["#title:", "#type:"]
    optional_headers = ["#author:", "#options:", "#require:"]

    for header in required_headers:
        print(f"  Checking {header}...", end=" ")
        assert header in content, f"Missing required header '{header}' in {algo_file}"
        print("✓")

    for header in optional_headers:
        print(f"  Checking {header}...", end=" ")
        if header in content:
            print("✓")
        else:
            print("(optional, not present)")

    # Verify specific metadata values for Brent
    print("  Checking algorithm type is root_finding...", end=" ")
    assert "#type: root_finding" in content, "Expected #type: root_finding"
    print("✓")

    # Verify options include expected parameters
    print("  Checking options include key parameters...", end=" ")
    for param in ["ytarget", "ytol", "xtol", "max_iterations"]:
        assert param in content, f"Missing option '{param}' in metadata"
    print("✓")

    print("  Metadata valid!\n")


def test_algorithm_r_structure():
    """Test that the R algorithm file has the required S3 class and methods."""
    print("Testing R algorithm structure...")

    algo_file = ".fz/algorithms/brent.R"

    with open(algo_file, "r") as f:
        content = f.read()

    # Check for S3 constructor function
    print("  Checking for S3 constructor...", end=" ")
    constructor_pattern = r'(\w+)\s*<-\s*function\s*\('
    constructors = re.findall(constructor_pattern, content)
    class_constructors = [
        c for c in constructors
        if c[0].isupper() and '.' not in c
        and c not in ('UseMethod', 'TRUE', 'FALSE', 'NULL')
    ]
    assert len(class_constructors) >= 1, \
        f"No S3 constructor found. Expected a function like Brent <- function(...)"
    constructor_name = class_constructors[0]
    assert constructor_name == "Brent", \
        f"Expected constructor 'Brent', got '{constructor_name}'"
    print(f"✓ (found: {constructor_name})")

    # Check for class assignment
    print("  Checking for class() assignment...", end=" ")
    assert f'class(obj) <- "{constructor_name}"' in content or \
           f"class(obj) <- '{constructor_name}'" in content, \
        f"Missing class assignment: class(obj) <- \"{constructor_name}\""
    print("✓")

    # Check for required S3 methods
    required_methods = ["get_initial_design", "get_next_design", "get_analysis"]
    for method in required_methods:
        method_name = f"{method}.{constructor_name}"
        print(f"  Checking method {method_name}()...", end=" ")
        assert method_name in content, f"Missing required S3 method '{method_name}'"
        print("✓")

    # Check for optional method
    optional_method = f"get_analysis_tmp.{constructor_name}"
    print(f"  Checking method {optional_method}()...", end=" ")
    if optional_method in content:
        print("✓")
    else:
        print("(optional, not present)")

    # Check for helper functions specific to Brent
    helpers = ["from01", "to01"]
    for helper in helpers:
        print(f"  Checking helper {helper}()...", end=" ")
        assert helper in content, f"Missing helper function '{helper}'"
        print("✓")

    print("  R structure valid!\n")


def test_algorithm_r_loading():
    """Test loading the R algorithm via rpy2."""
    print("Testing R algorithm loading via rpy2...")

    try:
        from rpy2 import robjects
    except ImportError:
        print("  rpy2 not installed - skipping R loading tests")
        print("  (Install with: pip install rpy2)")
        print("  (R must also be installed on your system)\n")
        return

    algo_file = ".fz/algorithms/brent.R"

    # Source the R file
    print("  Sourcing R file...", end=" ")
    try:
        robjects.r.source(algo_file)
        print("✓")
    except Exception as e:
        assert False, f"Failed to source R file: {e}"

    # Check that the constructor is available
    print("  Checking constructor function...", end=" ")
    r_globals = robjects.globalenv
    constructor_name = "Brent"
    assert constructor_name in r_globals, f"Constructor '{constructor_name}' not found in R environment"
    print("✓")

    # Instantiate with default options
    print("  Instantiating with defaults...", end=" ")
    r_instance = robjects.r[constructor_name]()
    assert r_instance is not None
    r_class = robjects.r['class'](r_instance)[0]
    assert r_class == constructor_name, f"Expected class '{constructor_name}', got '{r_class}'"
    print(f"✓ (class: {r_class})")

    # Check default option values
    print("  Checking default options...", end=" ")
    r_opts = r_instance.rx2('options')
    assert r_opts.rx2('ytarget')[0] == 0.0, "Default ytarget should be 0.0"
    assert r_opts.rx2('max_iterations')[0] == 100, "Default max_iterations should be 100"
    print("✓")

    # Instantiate with custom options
    print("  Instantiating with custom options...", end=" ")
    r_instance = robjects.r[constructor_name](
        ytarget=0.5,
        ytol=0.001,
        xtol=0.001,
        max_iterations=50
    )
    assert r_instance is not None
    r_opts = r_instance.rx2('options')
    assert r_opts.rx2('ytarget')[0] == 0.5, "Custom ytarget should be 0.5"
    assert r_opts.rx2('max_iterations')[0] == 50, "Custom max_iterations should be 50"
    print("✓")

    print("  R algorithm loading works!\n")


def test_algorithm_r_execution():
    """Test running the R algorithm through its full lifecycle via rpy2."""
    print("Testing R algorithm execution via rpy2...")

    try:
        from rpy2 import robjects
        from rpy2.robjects import vectors
    except ImportError:
        print("  rpy2 not installed - skipping R execution tests")
        print("  (Install with: pip install rpy2)\n")
        return

    algo_file = ".fz/algorithms/brent.R"
    robjects.r.source(algo_file)
    r_globals = robjects.globalenv

    # Instantiate for root finding: find where cos(pi*x) = 0
    r_instance = robjects.r["Brent"](
        ytarget=0.0,
        ytol=0.01,
        xtol=0.01,
        max_iterations=100
    )

    # Brent is 1D only
    r_input_vars = robjects.r('list(x = c(0.0, 1.0))')
    r_output_vars = robjects.StrVector(["y"])

    # Test get_initial_design
    print("  Testing get_initial_design()...", end=" ")
    r_design = r_globals['get_initial_design'](r_instance, r_input_vars, r_output_vars)
    assert r_design is not None
    n_points = len(r_design)
    # Brent returns 3 initial points: at 0, 1, 1 (in [0,1] space)
    assert n_points == 3, f"Expected 3 initial points, got {n_points}"
    print(f"✓ ({n_points} points)")

    # Convert R design to Python for evaluation
    import math

    def cos_pi(x):
        return math.cos(math.pi * x)

    design = []
    for i in range(n_points):
        point = {}
        r_point = r_design[i]
        for name in r_point.names:
            point[name] = r_point.rx2(name)[0]
        design.append(point)

    outputs = [cos_pi(p["x"]) for p in design]

    # Build R lists for X and Y
    all_X = r_design
    all_Y = robjects.FloatVector(outputs)

    # Test get_next_design (iterative loop)
    print("  Testing get_next_design() iterations...", end=" ")
    iterations = 0
    for _ in range(100):
        r_next = r_globals['get_next_design'](r_instance, all_X, all_Y)
        if len(r_next) == 0:
            break

        # Convert and evaluate new points
        new_points = []
        for i in range(len(r_next)):
            point = {}
            r_point = r_next[i]
            for name in r_point.names:
                point[name] = r_point.rx2(name)[0]
            new_points.append(point)

        new_outputs = [cos_pi(p["x"]) for p in new_points]

        # Accumulate: append to R lists
        for i in range(len(r_next)):
            all_X = robjects.r('c')(all_X, robjects.r('list')(r_next[i]))
        all_Y = robjects.FloatVector(list(all_Y) + new_outputs)
        design.extend(new_points)
        outputs.extend(new_outputs)
        iterations += 1

    print(f"✓ ({iterations} iterations, {len(outputs)} total evaluations)")

    # Test get_analysis
    print("  Testing get_analysis()...", end=" ")
    r_analysis = r_globals['get_analysis'](r_instance, all_X, all_Y)
    assert r_analysis is not None

    analysis_names = list(r_analysis.names) if r_analysis.names else []
    assert "text" in analysis_names or "data" in analysis_names, \
        "get_analysis must return a list with 'text' or 'data'"
    print("✓")

    if "text" in analysis_names:
        text = r_analysis.rx2("text")[0]
        print(f"    Analysis: {text.strip()[:100]}...")

    if "data" in analysis_names:
        r_data = r_analysis.rx2("data")
        data_names = list(r_data.names)
        assert "root" in data_names, "Analysis data should contain 'root'"
        assert "converged" in data_names, "Analysis data should contain 'converged'"
        root = r_data.rx2("root")[0]
        converged = r_data.rx2("converged")[0]
        print(f"    Root: {root:.6f}, Converged: {converged}")
        # cos(pi*x) = 0 at x = 0.5
        assert abs(root - 0.5) < 0.02, f"Expected root near 0.5, got {root}"

    # Test get_analysis_tmp
    print("  Testing get_analysis_tmp()...", end=" ")
    r_tmp = r_globals['get_analysis_tmp'](r_instance, all_X, all_Y)
    assert r_tmp is not None
    tmp_names = list(r_tmp.names) if r_tmp.names else []
    assert "text" in tmp_names, "get_analysis_tmp must return a list with 'text'"
    print("✓")

    # Test with NA values in outputs (simulating failed evaluations)
    print("  Testing with failed evaluations (NA in outputs)...", end=" ")
    outputs_with_na = list(all_Y)
    if len(outputs_with_na) > 1:
        outputs_with_na[0] = None
    r_Y_na = robjects.r('c')(
        *[robjects.NA_Real if v is None else v for v in outputs_with_na]
    )
    r_analysis_na = r_globals['get_analysis'](r_instance, all_X, r_Y_na)
    assert r_analysis_na is not None
    print("✓")

    print("  R algorithm execution works!\n")


def test_algorithm_r_root_finding():
    """Test the algorithm correctly finds roots of different functions."""
    print("Testing R algorithm root finding...")

    try:
        from rpy2 import robjects
    except ImportError:
        print("  rpy2 not installed - skipping root finding test")
        print("  (Install with: pip install rpy2)\n")
        return

    import math

    algo_file = ".fz/algorithms/brent.R"
    robjects.r.source(algo_file)
    r_globals = robjects.globalenv

    # Test 1: cos(pi*x) = 0, root at x = 0.5
    print("  Test: cos(pi*x) = 0, expected root at 0.5...", end=" ")
    r_instance = robjects.r["Brent"](ytarget=0.0, ytol=0.01, xtol=0.01, max_iterations=100)
    r_input_vars = robjects.r('list(x = c(0.0, 1.0))')
    r_output_vars = robjects.StrVector(["y"])

    r_design = r_globals['get_initial_design'](r_instance, r_input_vars, r_output_vars)

    design = []
    for i in range(len(r_design)):
        point = {}
        r_point = r_design[i]
        for name in r_point.names:
            point[name] = r_point.rx2(name)[0]
        design.append(point)

    outputs = [math.cos(math.pi * p["x"]) for p in design]
    all_X = r_design
    all_Y = robjects.FloatVector(outputs)

    for _ in range(100):
        r_next = r_globals['get_next_design'](r_instance, all_X, all_Y)
        if len(r_next) == 0:
            break
        new_points = []
        for i in range(len(r_next)):
            point = {}
            r_point = r_next[i]
            for name in r_point.names:
                point[name] = r_point.rx2(name)[0]
            new_points.append(point)
        new_outputs = [math.cos(math.pi * p["x"]) for p in new_points]
        for i in range(len(r_next)):
            all_X = robjects.r('c')(all_X, robjects.r('list')(r_next[i]))
        all_Y = robjects.FloatVector(list(all_Y) + new_outputs)

    r_analysis = r_globals['get_analysis'](r_instance, all_X, all_Y)
    root = r_analysis.rx2("data").rx2("root")[0]
    assert abs(root - 0.5) < 0.02, f"Expected root near 0.5, got {root}"
    print(f"✓ (root={root:.6f})")

    # Test 2: ((x-0.75)/3)^3 = 0, root at x = 0.75
    print("  Test: ((x-0.75)/3)^3 = 0, expected root at 0.75...", end=" ")
    r_instance2 = robjects.r["Brent"](ytarget=0.0, ytol=0.01, xtol=0.01, max_iterations=100)
    r_design2 = r_globals['get_initial_design'](r_instance2, r_input_vars, r_output_vars)

    design2 = []
    for i in range(len(r_design2)):
        point = {}
        r_point = r_design2[i]
        for name in r_point.names:
            point[name] = r_point.rx2(name)[0]
        design2.append(point)

    outputs2 = [((p["x"] - 0.75) / 3) ** 3 for p in design2]
    all_X2 = r_design2
    all_Y2 = robjects.FloatVector(outputs2)

    for _ in range(100):
        r_next2 = r_globals['get_next_design'](r_instance2, all_X2, all_Y2)
        if len(r_next2) == 0:
            break
        new_points2 = []
        for i in range(len(r_next2)):
            point = {}
            r_point = r_next2[i]
            for name in r_point.names:
                point[name] = r_point.rx2(name)[0]
            new_points2.append(point)
        new_outputs2 = [((p["x"] - 0.75) / 3) ** 3 for p in new_points2]
        for i in range(len(r_next2)):
            all_X2 = robjects.r('c')(all_X2, robjects.r('list')(r_next2[i]))
        all_Y2 = robjects.FloatVector(list(all_Y2) + new_outputs2)

    r_analysis2 = r_globals['get_analysis'](r_instance2, all_X2, all_Y2)
    root2 = r_analysis2.rx2("data").rx2("root")[0]
    assert abs(root2 - 0.75) < 0.02, f"Expected root near 0.75, got {root2}"
    print(f"✓ (root={root2:.6f})")

    # Test 3: Non-zero target: cos(pi*x) = 0.5, root at x = 1/3
    print("  Test: cos(pi*x) = 0.5, expected root at 1/3...", end=" ")
    r_instance3 = robjects.r["Brent"](ytarget=0.5, ytol=0.01, xtol=0.01, max_iterations=100)
    r_design3 = r_globals['get_initial_design'](r_instance3, r_input_vars, r_output_vars)

    design3 = []
    for i in range(len(r_design3)):
        point = {}
        r_point = r_design3[i]
        for name in r_point.names:
            point[name] = r_point.rx2(name)[0]
        design3.append(point)

    outputs3 = [math.cos(math.pi * p["x"]) for p in design3]
    all_X3 = r_design3
    all_Y3 = robjects.FloatVector(outputs3)

    for _ in range(100):
        r_next3 = r_globals['get_next_design'](r_instance3, all_X3, all_Y3)
        if len(r_next3) == 0:
            break
        new_points3 = []
        for i in range(len(r_next3)):
            point = {}
            r_point = r_next3[i]
            for name in r_point.names:
                point[name] = r_point.rx2(name)[0]
            new_points3.append(point)
        new_outputs3 = [math.cos(math.pi * p["x"]) for p in new_points3]
        for i in range(len(r_next3)):
            all_X3 = robjects.r('c')(all_X3, robjects.r('list')(r_next3[i]))
        all_Y3 = robjects.FloatVector(list(all_Y3) + new_outputs3)

    r_analysis3 = r_globals['get_analysis'](r_instance3, all_X3, all_Y3)
    root3 = r_analysis3.rx2("data").rx2("root")[0]
    expected3 = 1.0 / 3.0
    assert abs(root3 - expected3) < 0.02, f"Expected root near {expected3:.4f}, got {root3}"
    print(f"✓ (root={root3:.6f})")

    print("  Root finding works!\n")


def test_with_fz_loading():
    """Test loading the R algorithm via fz plugin system."""
    print("Testing fz plugin system integration...")

    try:
        from fz.algorithms import load_algorithm
        print("  fz.algorithms module found ✓")
    except ImportError:
        print("  fz module not installed - skipping fz integration tests")
        print("  (Install with: pip install git+https://github.com/Funz/fz.git)\n")
        return

    try:
        import rpy2
        print("  rpy2 module found ✓")
    except ImportError:
        print("  rpy2 not installed - skipping fz+R integration tests")
        print("  (Install with: pip install rpy2)\n")
        return

    # Test loading by direct path
    print("  Testing load_algorithm() with direct path...", end=" ")
    algo = load_algorithm(
        ".fz/algorithms/brent.R",
        ytarget=0.0,
        ytol=0.01,
        xtol=0.01,
        max_iterations=100
    )
    assert algo is not None
    print("✓")

    # Test basic execution through fz wrapper
    design = algo.get_initial_design(
        {"x": (0.0, 1.0)},
        ["y"]
    )
    assert len(design) == 3, f"Expected 3 initial points, got {len(design)}"
    print(f"  Algorithm returned {len(design)} initial points ✓")

    print("  fz plugin integration works!\n")


def main():
    """Run all tests."""
    print("=" * 70)
    print("fz-brent Plugin Test Suite")
    print("=" * 70)
    print()

    # Change to repository root if needed
    if not os.path.exists(".fz"):
        if os.path.exists("../fz-brent/.fz"):
            os.chdir("../fz-brent")
        else:
            print("Error: Could not find .fz directory")
            print("Please run this script from the fz-brent repository root")
            return 1

    try:
        test_algorithm_file_exists()
        test_algorithm_metadata()
        test_algorithm_r_structure()
        test_algorithm_r_loading()
        test_algorithm_r_execution()
        test_algorithm_r_root_finding()
        test_with_fz_loading()

        print("=" * 70)
        print("All tests passed! ✓")
        print("=" * 70)
        return 0

    except AssertionError as e:
        print(f"\n✗ Test failed: {e}")
        return 1
    except Exception as e:
        print(f"\n✗ Unexpected error: {e}")
        import traceback
        traceback.print_exc()
        return 1


if __name__ == "__main__":
    sys.exit(main())
