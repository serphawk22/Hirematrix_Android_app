import os
import sys
import re
import argparse
from pathlib import Path

"""
Recruiter Imports Fix Tool
==========================
This script replaces local packages and relative paths in the migrated recruiter screens 
and controllers with the correct imports in the unified Hirematrix application.

Usage:
  # Run on target directory (default: directory containing the script)
  python fix_recruiter_imports.py

  # Run on a custom target directory
  python fix_recruiter_imports.py --target /path/to/Hirematrix_Android_app
"""

def replace_in_file(file_path, replacements, target_base):
    try:
        with open(file_path, "r", encoding="utf-8") as f:
            content = f.read()
    except Exception as e:
        print(f"ERROR: Failed to read {file_path}: {e}", file=sys.stderr)
        return
    
    original = content
    for pattern, repl in replacements:
        content = re.sub(pattern, repl, content)
            
    if content != original:
        try:
            with open(file_path, "w", encoding="utf-8") as f:
                f.write(content)
            print(f"Fixed imports in: {os.path.relpath(file_path, target_base)}")
        except Exception as e:
            print(f"ERROR: Failed to write {file_path}: {e}", file=sys.stderr)

def main():
    # 1. Determine script directory to use as fallback target path
    script_dir = Path(__file__).resolve().parent

    # 2. Setup argument parser
    parser = argparse.ArgumentParser(
        description="Fix import paths in migrated recruiter files inside the unified project."
    )
    parser.add_argument(
        "-t", "--target",
        type=str,
        default=str(script_dir),
        help=f"Path to the target Hirematrix_Android_app project (default: {script_dir})"
    )

    args = parser.parse_args()
    target_base = os.path.abspath(args.target)

    print(f"Target project: {target_base}")

    if not os.path.isdir(target_base):
        print(f"ERROR: Target directory does not exist: {target_base}", file=sys.stderr)
        sys.exit(1)

    # 1. Replacements for controllers under recruiter_controller
    controller_replacements = [
        # relative imports of services/models in parent folder
        (r"import\s+['\"].\./services/api_service\.dart['\"];", "import 'services/api_service.dart';"),
        (r"import\s+['\"].\./models/recruiter\.dart['\"];", "import 'models/recruiter.dart';"),
        (r"import\s+['\"].\./models/saved_account\.dart['\"];", "import 'models/saved_account.dart';"),
        (r"import\s+['\"].\./models/job\.dart['\"];", "import 'models/job.dart';"),
        (r"import\s+['\"].\./models/application\.dart['\"];", "import 'models/application.dart';"),
        (r"import\s+['\"].\./core/constants/api_constants\.dart['\"];", "import 'utils/api_constants.dart';"),
        (r"import\s+['\"].\./main\.dart['\"];", "import 'package:hirematrix/main.dart';"),
        # push notification service removal
        (r"import\s+['\"].\./services/push_notification_service\.dart['\"];", "// PushNotificationService removed"),
        (r"PushNotificationService\(\)\.sendTokenToServer\([^)]*\);", "// FCM token sync bypassed"),
    ]

    # 2. Replacements for views/screens/recruiter
    view_replacements = [
        # package:hirematrix_recruiter package imports
        (r"package:hirematrix_recruiter/controllers/", "package:hirematrix/controllers/recruiter_controller/"),
        (r"package:hirematrix_recruiter/models/", "package:hirematrix/controllers/recruiter_controller/models/"),
        (r"package:hirematrix_recruiter/services/api_service\.dart", "package:hirematrix/controllers/recruiter_controller/services/api_service.dart"),
        (r"package:hirematrix_recruiter/utils/api_constants\.dart", "package:hirematrix/controllers/recruiter_controller/utils/api_constants.dart"),
        (r"package:hirematrix_recruiter/utils/app_constants\.dart", "package:hirematrix/views/screens/recruiter/utils/app_constants.dart"),
        (r"package:hirematrix_recruiter/utils/responsive_helper\.dart", "package:hirematrix/views/screens/recruiter/utils/responsive_helper.dart"),
        (r"package:hirematrix_recruiter/utils/app_theme\.dart", "package:hirematrix/views/screens/recruiter/utils/app_theme.dart"),
        (r"package:hirematrix_recruiter/widgets/hirematrix_logo\.dart", "package:hirematrix/views/screens/recruiter/widgets/hirematrix_logo.dart"),
        (r"package:hirematrix_recruiter/widgets/main_drawer\.dart", "package:hirematrix/views/screens/recruiter/widgets/main_drawer.dart"),
        (r"package:hirematrix_recruiter/views/main_screen\.dart", "package:hirematrix/views/screens/recruiter/main_screen.dart"),
        (r"package:hirematrix_recruiter/main\.dart", "package:hirematrix/main.dart"),

        # relative imports of utils/widgets/controllers
        # going up multiple levels from views subfolders
        (r"import\s+['\"].\./\.\./utils/app_constants\.dart['\"];", "import 'package:hirematrix/views/screens/recruiter/utils/app_constants.dart';"),
        (r"import\s+['\"].\./\.\./utils/responsive_helper\.dart['\"];", "import 'package:hirematrix/views/screens/recruiter/utils/responsive_helper.dart';"),
        (r"import\s+['\"].\./\.\./utils/app_theme\.dart['\"];", "import 'package:hirematrix/views/screens/recruiter/utils/app_theme.dart';"),
        (r"import\s+['\"].\./\.\./widgets/main_drawer\.dart['\"];", "import 'package:hirematrix/views/screens/recruiter/widgets/main_drawer.dart';"),
        (r"import\s+['\"].\./\.\./widgets/hirematrix_logo\.dart['\"];", "import 'package:hirematrix/views/screens/recruiter/widgets/hirematrix_logo.dart';"),
        (r"import\s+['\"].\./\.\./controllers/auth_controller\.dart['\"];", "import 'package:hirematrix/controllers/recruiter_controller/auth_controller.dart';"),
        (r"import\s+['\"].\./\.\./controllers/jobs_controller\.dart['\"];", "import 'package:hirematrix/controllers/recruiter_controller/jobs_controller.dart';"),
        (r"import\s+['\"].\./\.\./controllers/dashboard_controller\.dart['\"];", "import 'package:hirematrix/controllers/recruiter_controller/dashboard_controller.dart';"),
        (r"import\s+['\"].\./\.\./controllers/applications_controller\.dart['\"];", "import 'package:hirematrix/controllers/recruiter_controller/applications_controller.dart';"),
        (r"import\s+['\"].\./\.\./controllers/language_controller\.dart['\"];", "import 'package:hirematrix/controllers/recruiter_controller/language_controller.dart';"),
        (r"import\s+['\"].\./\.\./controllers/recruiter_support_controller\.dart['\"];", "import 'package:hirematrix/controllers/recruiter_controller/recruiter_support_controller.dart';"),
        (r"import\s+['\"].\./\.\./models/saved_account\.dart['\"];", "import 'package:hirematrix/controllers/recruiter_controller/models/saved_account.dart';"),
        (r"import\s+['\"].\./\.\./models/recruiter\.dart['\"];", "import 'package:hirematrix/controllers/recruiter_controller/models/recruiter.dart';"),
        (r"import\s+['\"].\./\.\./models/job\.dart['\"];", "import 'package:hirematrix/controllers/recruiter_controller/models/job.dart';"),
        (r"import\s+['\"].\./\.\./models/application\.dart['\"];", "import 'package:hirematrix/controllers/recruiter_controller/models/application.dart';"),
        (r"import\s+['\"].\./\.\./services/api_service\.dart['\"];", "import 'package:hirematrix/controllers/recruiter_controller/services/api_service.dart';"),
        
        # 1 level up relative imports
        (r"import\s+['\"].\./utils/app_constants\.dart['\"];", "import 'package:hirematrix/views/screens/recruiter/utils/app_constants.dart';"),
        (r"import\s+['\"].\./utils/responsive_helper\.dart['\"];", "import 'package:hirematrix/views/screens/recruiter/utils/responsive_helper.dart';"),
        (r"import\s+['\"].\./utils/app_theme\.dart['\"];", "import 'package:hirematrix/views/screens/recruiter/utils/app_theme.dart';"),
        (r"import\s+['\"].\./widgets/main_drawer\.dart['\"];", "import 'package:hirematrix/views/screens/recruiter/widgets/main_drawer.dart';"),
        (r"import\s+['\"].\./widgets/hirematrix_logo\.dart['\"];", "import 'package:hirematrix/views/screens/recruiter/widgets/hirematrix_logo.dart';"),
        (r"import\s+['\"].\./controllers/auth_controller\.dart['\"];", "import 'package:hirematrix/controllers/recruiter_controller/auth_controller.dart';"),
        (r"import\s+['\"].\./controllers/jobs_controller\.dart['\"];", "import 'package:hirematrix/controllers/recruiter_controller/jobs_controller.dart';"),
        (r"import\s+['\"].\./controllers/dashboard_controller\.dart['\"];", "import 'package:hirematrix/controllers/recruiter_controller/dashboard_controller.dart';"),
        (r"import\s+['\"].\./controllers/applications_controller\.dart['\"];", "import 'package:hirematrix/controllers/recruiter_controller/applications_controller.dart';"),
        (r"import\s+['\"].\./controllers/language_controller\.dart['\"];", "import 'package:hirematrix/controllers/recruiter_controller/language_controller.dart';"),
        (r"import\s+['\"].\./controllers/recruiter_support_controller\.dart['\"];", "import 'package:hirematrix/controllers/recruiter_controller/recruiter_support_controller.dart';"),
        (r"import\s+['\"].\./models/saved_account\.dart['\"];", "import 'package:hirematrix/controllers/recruiter_controller/models/saved_account.dart';"),
        (r"import\s+['\"].\./models/recruiter\.dart['\"];", "import 'package:hirematrix/controllers/recruiter_controller/models/recruiter.dart';"),
        (r"import\s+['\"].\./models/job\.dart['\"];", "import 'package:hirematrix/controllers/recruiter_controller/models/job.dart';"),
        (r"import\s+['\"].\./models/application\.dart['\"];", "import 'package:hirematrix/controllers/recruiter_controller/models/application.dart';"),
        (r"import\s+['\"].\./services/api_service\.dart['\"];", "import 'package:hirematrix/controllers/recruiter_controller/services/api_service.dart';"),
        (r"import\s+['\"].\./main_screen\.dart['\"];", "import 'package:hirematrix/views/screens/recruiter/main_screen.dart';"),

        # relative imports from recruiter widgets
        (r"import\s+['\"].\./utils/api_constants\.dart['\"];", "import 'package:hirematrix/controllers/recruiter_controller/utils/api_constants.dart';"),
    ]

    # Walk controllers
    controller_dir = os.path.join(target_base, "lib", "controllers", "recruiter_controller")
    if os.path.isdir(controller_dir):
        for root, dirs, files in os.walk(controller_dir):
            for file in files:
                if file.endswith(".dart"):
                    replace_in_file(os.path.join(root, file), controller_replacements, target_base)
    else:
        print(f"Warning: Controller directory not found at {controller_dir}")

    # Walk views
    view_dir = os.path.join(target_base, "lib", "views", "screens", "recruiter")
    if os.path.isdir(view_dir):
        for root, dirs, files in os.walk(view_dir):
            for file in files:
                if file.endswith(".dart"):
                    replace_in_file(os.path.join(root, file), view_replacements, target_base)
    else:
        print(f"Warning: View directory not found at {view_dir}")

    print("Imports fix completed.")

if __name__ == "__main__":
    main()
