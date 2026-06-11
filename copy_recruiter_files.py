import os
import sys
import shutil
import argparse
from pathlib import Path

"""
Recruiter Files Copy Tool
=========================
This script copies migrated recruiter files from the standalone recruiter repository 
to the unified Hirematrix application.

Usage:
  # Run with default sibling path assumptions:
  # Assumes 'Hirematrix_recruiter' and 'Hirematrix_Android_app' are siblings in the same directory.
  python copy_recruiter_files.py

  # Run with custom source and target paths:
  python copy_recruiter_files.py --source /path/to/Hirematrix_recruiter --target /path/to/Hirematrix_Android_app
"""

def main():
    # 1. Determine script directory to use as fallback target path
    script_dir = Path(__file__).resolve().parent
    default_sibling_source = script_dir.parent / "Hirematrix_recruiter"

    # 2. Setup argument parser
    parser = argparse.ArgumentParser(
        description="Copy migrated recruiter files from standalone recruiter project to unified project."
    )
    parser.add_argument(
        "-s", "--source",
        type=str,
        default=str(default_sibling_source),
        help=f"Path to the source Hirematrix_recruiter project (default: {default_sibling_source})"
    )
    parser.add_argument(
        "-t", "--target",
        type=str,
        default=str(script_dir),
        help=f"Path to the target Hirematrix_Android_app project (default: {script_dir})"
    )

    args = parser.parse_args()
    
    source_base = os.path.abspath(args.source)
    target_base = os.path.abspath(args.target)

    print(f"Source project: {source_base}")
    print(f"Target project: {target_base}")

    # 3. Path validations
    if not os.path.isdir(source_base):
        print(f"ERROR: Source directory does not exist: {source_base}", file=sys.stderr)
        print("Please specify a valid path using the --source option.", file=sys.stderr)
        sys.exit(1)

    if not os.path.isdir(target_base):
        print(f"ERROR: Target directory does not exist: {target_base}", file=sys.stderr)
        print("Please specify a valid path using the --target option.", file=sys.stderr)
        sys.exit(1)

    files_to_copy = [
        # (Source path relative to source_base, Target path relative to target_base)
        # Models
        ("lib/models/application.dart", "lib/controllers/recruiter_controller/models/application.dart"),
        ("lib/models/job.dart", "lib/controllers/recruiter_controller/models/job.dart"),
        ("lib/models/recruiter.dart", "lib/controllers/recruiter_controller/models/recruiter.dart"),
        ("lib/models/saved_account.dart", "lib/controllers/recruiter_controller/models/saved_account.dart"),
        # Services
        ("lib/services/api_service.dart", "lib/controllers/recruiter_controller/services/api_service.dart"),
        # Utils / constants
        ("lib/utils/api_constants.dart", "lib/controllers/recruiter_controller/utils/api_constants.dart"),
        ("lib/utils/app_constants.dart", "lib/views/screens/recruiter/utils/app_constants.dart"),
        ("lib/utils/responsive_helper.dart", "lib/views/screens/recruiter/utils/responsive_helper.dart"),
        ("lib/utils/app_theme.dart", "lib/views/screens/recruiter/utils/app_theme.dart"),
        # Widgets
        ("lib/widgets/hirematrix_logo.dart", "lib/views/screens/recruiter/widgets/hirematrix_logo.dart"),
        ("lib/widgets/main_drawer.dart", "lib/views/screens/recruiter/widgets/main_drawer.dart"),
        # Views / Screens
        ("lib/views/main_screen.dart", "lib/views/screens/recruiter/main_screen.dart"),
        # Auth Controller (ChangeNotifier-based for recruiter dashboard)
        ("lib/controllers/auth_controller.dart", "lib/controllers/recruiter_controller/auth_controller.dart"),
    ]

    copied_count = 0
    error_count = 0

    for src_rel, tgt_rel in files_to_copy:
        src_path = os.path.join(source_base, src_rel.replace("/", os.sep))
        tgt_path = os.path.join(target_base, tgt_rel.replace("/", os.sep))
        
        # Ensure target directory exists
        os.makedirs(os.path.dirname(tgt_path), exist_ok=True)
        
        # Copy file
        if os.path.exists(src_path):
            shutil.copy2(src_path, tgt_path)
            print(f"Copied: {src_rel} -> {tgt_rel}")
            copied_count += 1
        else:
            print(f"ERROR: Source file does not exist: {src_path}", file=sys.stderr)
            error_count += 1

    print(f"\nMigration completed. Copied: {copied_count}, Errors: {error_count}")
    if error_count > 0:
        sys.exit(1)

if __name__ == "__main__":
    main()
