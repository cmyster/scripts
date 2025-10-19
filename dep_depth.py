#!/usr/bin/env python3
import portage
from portage.dep import Atom, use_reduce, paren_reduce
from portage.exception import InvalidAtom
import concurrent.futures
from collections import deque
import time

EXCLUDE_FLAGS = {"selinux", "test"}
SKIP_CATEGORIES = {"acct-group", "acct-user", "virtual"}

class DependencyAnalyzer:
    def __init__(self):
        self.portdb = portage.db[portage.root]["porttree"].dbapi
        self.settings = portage.config(clone=portage.settings)
        
    def get_all_packages(self):
        """Get all installable packages"""
        packages = []
        for cp in self.portdb.cp_all():
            category = cp.split('/')[0]
            if category not in SKIP_CATEGORIES:
                packages.append(cp)
        return packages
    
    def get_package_use_flags(self, cp):
        """Get all USE flags for a package"""
        try:
            versions = self.portdb.cp_list(cp)
            if not versions:
                return set()
            
            cpv = versions[-1]  # Latest version
            iuse = self.portdb.aux_get(cpv, ["IUSE"])[0]
            flags = {f.lstrip("+-") for f in iuse.split()}
            return flags - EXCLUDE_FLAGS
        except (KeyError, IndexError):
            return set()
    
    def get_cpv_use_flags(self, cpv):
        """Get all USE flags for a specific CPV"""
        try:
            iuse = self.portdb.aux_get(cpv, ["IUSE"])[0]
            flags = {f.lstrip("+-") for f in iuse.split()}
            return flags - EXCLUDE_FLAGS
        except (KeyError, IndexError):
            return set()
    
    def parse_dep_string(self, dep_str, use_flags):
        """Parse a dependency string with USE flags enabled"""
        if not dep_str or not dep_str.strip():
            return set()
        
        try:
            # Create a custom settings object with USE flags
            mysettings = portage.config(clone=self.settings)
            mysettings["USE"] = " ".join(use_flags)
            
            # Use portage's use_reduce to handle USE conditionals
            reduced = use_reduce(
                dep_str,
                uselist=use_flags,
                is_valid_flag=lambda x: True,
                token_class=Atom
            )
            
            # Extract atoms from the reduced dependency tree
            atoms = set()
            
            def extract_atoms(dep_list):
                if isinstance(dep_list, list):
                    for item in dep_list:
                        if isinstance(item, Atom):
                            atoms.add(item.cp)
                        elif isinstance(item, str) and not item.startswith('!'):
                            try:
                                atom = Atom(item)
                                atoms.add(atom.cp)
                            except InvalidAtom:
                                pass
                        elif isinstance(item, list):
                            extract_atoms(item)
            
            extract_atoms(reduced)
            return atoms
            
        except Exception as e:
            return set()
    
    def build_dependency_tree(self, cp, all_use_flags):
        """Build complete dependency tree with all USE flags enabled"""
        try:
            versions = self.portdb.cp_list(cp)
            if not versions:
                return None, 0, 0
            
            cpv = versions[-1]
            
            # Track visited packages and depths
            visited = set()
            depths = {}
            to_process = deque([(cp, 0)])
            
            while to_process:
                current_cp, depth = to_process.popleft()
                
                if current_cp in visited:
                    continue
                
                visited.add(current_cp)
                depths[current_cp] = max(depths.get(current_cp, 0), depth)
                
                # Get the latest version
                try:
                    curr_versions = self.portdb.cp_list(current_cp)
                    if not curr_versions:
                        continue
                    
                    curr_cpv = curr_versions[-1]
                    
                    # Get dependencies
                    depend = self.portdb.aux_get(curr_cpv, ["DEPEND"])[0]
                    rdepend = self.portdb.aux_get(curr_cpv, ["RDEPEND"])[0]
                    pdepend = self.portdb.aux_get(curr_cpv, ["PDEPEND"])[0]
                    bdepend = self.portdb.aux_get(curr_cpv, ["BDEPEND"])[0]
                    
                    # Combine all dependencies
                    all_deps = f"{depend} {rdepend} {pdepend} {bdepend}"
                    
                    # Parse dependencies with all USE flags
                    dep_packages = self.parse_dep_string(all_deps, all_use_flags)
                    
                    # Add to processing queue
                    for dep_cp in dep_packages:
                        if dep_cp and dep_cp not in visited:
                            to_process.append((dep_cp, depth + 1))
                
                except (KeyError, IndexError):
                    continue
            
            total_deps = len(visited)
            max_depth = max(depths.values()) if depths else 0
            
            return list(visited), total_deps, max_depth
            
        except Exception as e:
            return None, 0, 0
    
    def analyze_package(self, cp):
        """Analyze a single package with maximum USE flags"""
        start_time = time.perf_counter()
        
        try:
            # Step 1: Get all USE flags for the main package
            main_flags = self.get_package_use_flags(cp)
            
            # Step 2: Do initial dependency discovery
            initial_deps, _, _ = self.build_dependency_tree(cp, main_flags)
            
            if initial_deps is None:
                elapsed = (time.perf_counter() - start_time) * 1_000_000  # microseconds
                return (cp, 0, 0, set(), elapsed, "failed_discovery")
            
            # Step 3: Collect USE flags from all discovered packages
            all_flags = set(main_flags)
            use_by_package = {cp: main_flags}
            
            for dep_cp in initial_deps:
                dep_flags = self.get_package_use_flags(dep_cp)
                use_by_package[dep_cp] = dep_flags
                all_flags.update(dep_flags)
            
            # Step 4: Rebuild tree with all USE flags
            final_deps, total, depth = self.build_dependency_tree(cp, all_flags)
            
            if final_deps is None:
                elapsed = (time.perf_counter() - start_time) * 1_000_000
                return (cp, 0, 0, all_flags, elapsed, "failed_final")
            
            elapsed = (time.perf_counter() - start_time) * 1_000_000
            return (cp, total, depth, all_flags, use_by_package, elapsed, "ok")
            
        except Exception as e:
            elapsed = (time.perf_counter() - start_time) * 1_000_000
            return (cp, 0, 0, set(), elapsed, f"error: {str(e)[:50]}")

def format_time(microseconds):
    """Format microseconds into human-readable string"""
    if microseconds < 1000:
        return f"{microseconds:.0f}μs"
    elif microseconds < 1_000_000:
        return f"{microseconds/1000:.2f}ms"
    else:
        return f"{microseconds/1_000_000:.2f}s"

def main(jobs=4, out_file="deepest_deps_maxuse.txt", limit=None):
    analyzer = DependencyAnalyzer()
    packages = analyzer.get_all_packages()
    
    if limit:
        packages = packages[:limit]
        print(f"Limited to first {limit} packages for testing")
    
    print(f"Found {len(packages)} installable packages")
    print(f"Using Portage API for dependency analysis")
    print(f"Analyzing with {jobs} parallel jobs...\n")
    
    overall_start = time.perf_counter()
    results = []
    errors = []
    
    with concurrent.futures.ThreadPoolExecutor(max_workers=jobs) as ex:
        futures = {ex.submit(analyzer.analyze_package, cp): cp for cp in packages}
        
        for i, fut in enumerate(concurrent.futures.as_completed(futures), 1):
            cp = futures[fut]
            try:
                result = fut.result()
                
                if len(result) >= 6 and result[-1] == "ok":
                    pkg, total, depth, all_flags, use_by_package, elapsed, status = result
                    print(f"[{i}/{len(packages)}] ✓ {pkg}: deps={total}, depth={depth}, flags={len(all_flags)}, time={format_time(elapsed)}")
                    results.append((pkg, total, depth, all_flags, use_by_package, elapsed))
                else:
                    pkg = result[0]
                    elapsed = result[-2]
                    status = result[-1]
                    print(f"[{i}/{len(packages)}] ✗ {pkg}: {status}, time={format_time(elapsed)}")
                    errors.append((pkg, status, elapsed))
                    
            except Exception as e:
                print(f"[{i}/{len(packages)}] ✗ {cp}: {str(e)[:50]}")
                errors.append((cp, str(e), 0))
    
    overall_elapsed = (time.perf_counter() - overall_start) * 1_000_000
    
    # Sort by depth descending, then total deps descending
    results.sort(key=lambda x: (x[2], x[1]), reverse=True)
    
    # Write results
    with open(out_file, "w") as f:
        f.write("=" * 70 + "\n")
        f.write("PACKAGES WITH MAXIMUM USE FLAGS (Portage API)\n")
        f.write(f"Total analysis time: {format_time(overall_elapsed)}\n")
        f.write("=" * 70 + "\n\n")
        
        for i, (pkg, total, depth, all_flags, use_by_package, elapsed) in enumerate(results, 1):
            f.write(f"#{i}: {pkg}\n")
            f.write(f"     Total dependencies: {total}\n")
            f.write(f"     Maximum depth: {depth}\n")
            f.write(f"     Total USE flags enabled: {len(all_flags)}\n")
            f.write(f"     Analysis time: {elapsed:.0f} μs ({format_time(elapsed)})\n")
            f.write(f"\n")
            
            # Write the main package USE flags
            main_flags = use_by_package.get(pkg, set())
            if main_flags:
                f.write(f"     Main package USE flags ({len(main_flags)}):\n")
                # Format flags in columns, 6 per line
                sorted_flags = sorted(main_flags)
                for j in range(0, len(sorted_flags), 6):
                    line_flags = sorted_flags[j:j+6]
                    f.write(f"       {' '.join(line_flags)}\n")
            
            f.write(f"\n")
            f.write(f"     Complete USE flag set for emerge:\n")
            f.write(f"       USE=\"")
            
            # Write all flags, wrapped at 60 chars
            sorted_all_flags = sorted(all_flags)
            line = ""
            for flag in sorted_all_flags:
                if len(line) + len(flag) + 1 > 60:
                    f.write(line + "\n            ")
                    line = flag
                else:
                    if line:
                        line += " " + flag
                    else:
                        line = flag
            f.write(line + "\" emerge " + pkg + "\n")
            
            f.write(f"\n")
            f.write("=" * 70 + "\n\n")
        
        if errors:
            f.write("\n" + "=" * 70 + "\n")
            f.write(f"ERRORS ({len(errors)} packages)\n")
            f.write("=" * 70 + "\n\n")
            error_counts = {}
            for pkg, status, elapsed in errors:
                error_type = status.split(':')[0] if ':' in status else status
                error_counts[error_type] = error_counts.get(error_type, 0) + 1
            
            for error_type, count in sorted(error_counts.items(), key=lambda x: -x[1]):
                f.write(f"{error_type}: {count} packages\n")
            
            f.write("\n")
            f.write("Detailed errors:\n")
            for pkg, status, elapsed in errors:
                f.write(f"  {pkg}: {status} (time: {format_time(elapsed)})\n")
    
    print(f"\n{'='*70}")
    print(f"Results written to {out_file}")
    print(f"Successfully analyzed: {len(results)}")
    print(f"Errors/timeouts: {len(errors)}")
    print(f"Total time: {format_time(overall_elapsed)}")
    
    if results:
        print(f"\nTop 10 deepest dependency trees:")
        for i, (pkg, total, depth, _, _, elapsed) in enumerate(results[:10], 1):
            print(f"  {i}. {pkg:<50} depth={depth:3d} deps={total:4d} time={format_time(elapsed)}")
        
        # Show timing statistics
        times = [r[5] for r in results]
        avg_time = sum(times) / len(times)
        min_time = min(times)
        max_time = max(times)
        
        print(f"\nTiming statistics:")
        print(f"  Average: {format_time(avg_time)}")
        print(f"  Minimum: {format_time(min_time)}")
        print(f"  Maximum: {format_time(max_time)}")

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(
        description="Find Gentoo packages with deepest dependency trees using Portage API"
    )
    parser.add_argument("-j", type=int, default=4, help="Parallel jobs")
    parser.add_argument("-o", type=str, default="deepest_deps_maxuse.txt")
    parser.add_argument("--limit", type=int, help="Limit packages for testing")
    
    args = parser.parse_args()
    main(jobs=args.j, out_file=args.o, limit=args.limit)
