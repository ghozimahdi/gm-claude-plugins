#!/bin/bash
# UFIL — Scaffold modular Flutter project
# Usage: ./init-modular.sh <project_name> [package_name]
# Example: ./init-modular.sh my_app com.example.myapp
# Default package_name: com.example.app
#
# Prerequisites: FVM must be installed (dart pub global activate fvm)
# Strategy: copy template tree under scripts/templates/modular/ verbatim,
# then substitute __PROJECT_NAME__, __PACKAGE_NAME__, __SDK_CONSTRAINT__,
# __FLUTTER_VERSION__ placeholders. Source files come from a real reference
# project so they match exactly (including .gitignore + analysis_options.yaml
# in every module).

set -e

PROJECT_NAME="${1:?Usage: init-modular.sh <project_name> [package_name]}"
PACKAGE_NAME="${2:-com.example.app}"
PROJECT_DIR="$(pwd)/$PROJECT_NAME"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/templates/modular"

# ========================================
# PREREQUISITES
# ========================================
if ! command -v fvm &> /dev/null; then
  echo "❌ FVM is required. Install: dart pub global activate fvm"
  exit 1
fi

FVM_FLUTTER_VERSION=$(fvm flutter --version 2>/dev/null | head -1 | awk '{print $2}')
if [ -z "$FVM_FLUTTER_VERSION" ]; then
  echo "❌ Could not detect Flutter version from FVM. Run: fvm install <version> && fvm global <version>"
  exit 1
fi

DART_SDK_FULL=$(fvm dart --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
DART_SDK_MAJOR_MINOR=$(echo "$DART_SDK_FULL" | cut -d'.' -f1,2)
SDK_CONSTRAINT="^${DART_SDK_MAJOR_MINOR}.0"

echo "🏗️ Creating modular Flutter project: $PROJECT_NAME ($PACKAGE_NAME)"
echo "   Flutter: $FVM_FLUTTER_VERSION | Dart SDK: $DART_SDK_FULL (constraint: $SDK_CONSTRAINT)"

if [ ! -d "$TEMPLATE_DIR/packages" ] || [ ! -d "$TEMPLATE_DIR/app" ] || [ ! -d "$TEMPLATE_DIR/root" ]; then
  echo "❌ Missing template tree at $TEMPLATE_DIR (expect packages/, app/, root/)"
  exit 1
fi

# ========================================
# COPY TEMPLATE TREE
# ========================================
mkdir -p "$PROJECT_DIR"

echo "📦 Copying packages/ ..."
mkdir -p "$PROJECT_DIR/packages"
cp -R "$TEMPLATE_DIR/packages/." "$PROJECT_DIR/packages/"

echo "📱 Copying app/ ..."
mkdir -p "$PROJECT_DIR/app"
cp -R "$TEMPLATE_DIR/app/." "$PROJECT_DIR/app/"

echo "📄 Copying root files ..."
cp -R "$TEMPLATE_DIR/root/." "$PROJECT_DIR/"

# ========================================
# PLACEHOLDER SUBSTITUTION
# ========================================
echo "🔧 Substituting placeholders ..."

# macOS sed needs '' after -i; this works on macOS bash.
substitute() {
  local file="$1"
  [ -f "$file" ] || return 0
  sed -i '' \
    -e "s|__PROJECT_NAME__|$PROJECT_NAME|g" \
    -e "s|__PACKAGE_NAME__|$PACKAGE_NAME|g" \
    -e "s|__SDK_CONSTRAINT__|$SDK_CONSTRAINT|g" \
    -e "s|__FLUTTER_VERSION__|$FVM_FLUTTER_VERSION|g" \
    "$file"
}

# Apply substitutions to every pubspec.yaml + known top-level files
substitute "$PROJECT_DIR/.fvmrc"
substitute "$PROJECT_DIR/app/flavorizr.yaml"
while IFS= read -r f; do
  substitute "$f"
done < <(find "$PROJECT_DIR" -name "pubspec.yaml" -not -path "*/.dart_tool/*")

# ========================================
# REFRESH DEPENDENCY VERSIONS (any -> latest caret)
# ========================================
# Templates ship with `dep: any` placeholders. We rewrite each pubspec.yaml so
# that every `dep: any` line is replaced by `dep: ^<latest>` from pub.dev via
# `dart pub add`. Path deps and `sdk: flutter` deps are left untouched.
echo "📡 Resolving latest dependency versions from pub.dev ..."

refresh_versions() {
  local pkg_dir="$1"
  local pubspec="$pkg_dir/pubspec.yaml"
  [ -f "$pubspec" ] || return 0

  # Collect dep names that are `: any` per section.
  local regular=""
  local dev=""
  local section=""
  while IFS= read -r line; do
    case "$line" in
      "dependencies:")     section="reg" ;;
      "dev_dependencies:") section="dev" ;;
      *)
        if [[ "$line" =~ ^[[:space:]]+([a-z_][a-z0-9_]*):[[:space:]]*any[[:space:]]*$ ]]; then
          local name="${BASH_REMATCH[1]}"
          if [ "$section" = "reg" ]; then
            regular="$regular $name"
          elif [ "$section" = "dev" ]; then
            dev="$dev $name"
          fi
        fi
        ;;
    esac
  done < "$pubspec"

  # Strip every `: any` line; pub add will re-add them with caret constraints.
  sed -i '' -E '/^[[:space:]]+[a-z_][a-z0-9_]*:[[:space:]]*any[[:space:]]*$/d' "$pubspec"

  if [ -n "$regular" ]; then
    (cd "$pkg_dir" && fvm dart pub add $regular >/dev/null 2>&1) \
      || echo "  ⚠️  pub add failed in $pkg_dir for: $regular"
  fi
  if [ -n "$dev" ]; then
    (cd "$pkg_dir" && fvm dart pub add --dev $dev >/dev/null 2>&1) \
      || echo "  ⚠️  pub add --dev failed in $pkg_dir for: $dev"
  fi
}

# Refresh root first (workspace-level deps like melos), then each member.
echo "  → root workspace ..."
refresh_versions "$PROJECT_DIR"
for d in "$PROJECT_DIR/packages"/*/*/ "$PROJECT_DIR/app"/; do
  d="${d%/}"
  echo "  → $(basename "$(dirname "$d")")/$(basename "$d")"
  refresh_versions "$d"
done

# ========================================
# VSCODE CONFIGURATION
# ========================================
echo "📁 Creating .vscode configuration..."
mkdir -p "$PROJECT_DIR/.vscode"

cat > "$PROJECT_DIR/.vscode/launch.json" << 'EOF'
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "dev",
            "request": "launch",
            "type": "dart",
            "program": "app/lib/main_dev.dart",
            "args": ["--flavor", "dev"]
        },
        {
            "name": "staging",
            "request": "launch",
            "type": "dart",
            "program": "app/lib/main_staging.dart",
            "args": ["--flavor", "staging"]
        },
        {
            "name": "prod",
            "request": "launch",
            "type": "dart",
            "program": "app/lib/main_prod.dart",
            "args": ["--flavor", "prod"]
        },
        {
            "name": "dev (release)",
            "request": "launch",
            "type": "dart",
            "program": "app/lib/main_dev.dart",
            "args": ["--flavor", "dev", "--release"]
        },
        {
            "name": "staging (release)",
            "request": "launch",
            "type": "dart",
            "program": "app/lib/main_staging.dart",
            "args": ["--flavor", "staging", "--release"]
        },
        {
            "name": "prod (release)",
            "request": "launch",
            "type": "dart",
            "program": "app/lib/main_prod.dart",
            "args": ["--flavor", "prod", "--release"]
        }
    ]
}
EOF

cat > "$PROJECT_DIR/.vscode/settings.json" << EOF
{
  "dart.flutterSdkPath": ".fvm/versions/${FVM_FLUTTER_VERSION}",
  "files.autoSave": "afterDelay",
  "files.autoSaveDelay": 0,
  "[dart]": {
    "editor.formatOnSave": true,
    "editor.formatOnType": true,
    "editor.codeActionsOnSave": {
      "source.fixAll": "always",
      "source.organizeImports": "always"
    }
  },
  "dart.flutterHotReloadOnSave": "never",
  "dart.lineLength": 80,
  "dart.previewFlutterUiGuides": true,
  "dart.previewFlutterUiGuidesCustomTracking": true,
  "dart.debugExternalPackageLibraries": false,
  "dart.debugSdkLibraries": false,
  "editor.rulers": [80, 120],
  "editor.tabSize": 2,
  "editor.insertSpaces": true,
  "editor.detectIndentation": false,
  "editor.bracketPairColorization.enabled": true,
  "editor.guides.bracketPairs": "active",
  "files.trimTrailingWhitespace": true,
  "files.insertFinalNewline": true,
  "files.trimFinalNewlines": true,
  "files.exclude": {
    "**/.git": true,
    "**/.DS_Store": true,
    "**/build": false,
    "**/.dart_tool": false,
    "**/.idea": true,
    "**/*.g.dart": false,
    "**/*.freezed.dart": false,
    "**/*.gr.dart": false,
    "**/*.config.dart": false,
    "**/Thumbs.db": true,
    "**/.svn": true,
    "**/.hg": true
  },
  "files.watcherExclude": {
    "**/.git/objects/**": true,
    "**/.git/subtree-cache/**": true,
    "**/build/**": true,
    "**/.dart_tool/**": true
  },
  "search.exclude": {
    "**/build": true,
    "**/.dart_tool": true,
    "**/*.g.dart": true,
    "**/*.freezed.dart": true,
    "**/*.gr.dart": true,
    "**/*.config.dart": true,
    "**/lib/gen/**": true,
    "**/.fvm": true
  },
  "explorer.fileNesting.enabled": true,
  "explorer.fileNesting.expand": false,
  "explorer.fileNesting.patterns": {
    "*.dart": "\${capture}.freezed.dart, \${capture}.g.dart, \${capture}.gr.dart, \${capture}.config.dart",
    "pubspec.yaml": "pubspec.lock, .packages, .flutter-plugins, .flutter-plugins-dependencies, .metadata",
    ".gitignore": ".gitattributes, .gitmodules"
  }
}
EOF

echo ""
echo "✅ Modular project '$PROJECT_NAME' created!"
echo "   Flutter: $FVM_FLUTTER_VERSION | Dart SDK: $SDK_CONSTRAINT"
echo "   Templates copied from scripts/templates/modular/ (3 features:"
echo "   feature_auth, feature_common, feature_dashboard with paired domain/data)."
echo "   Versions resolved live from pub.dev (caret constraints)."
echo ""
echo "Best-practice scaffold included (feature_auth + domain_auth + data_auth):"
echo "  • Domain  : UserModel, LoginParams, LoginResult (Failure-bearing), AuthRepository,"
echo "             LoginUseCase, LogoutUseCase, GetIsLoginUseCase"
echo "  • Data    : UserDto, LoginRequest, LoginResponse + separate mapper classes"
echo "             (UserModelMapper, LoginResultMapper, LoginRequestMapper)"
echo "             + AuthDataSource (returns LoginResponse) + AuthRepositoryImpl"
echo "             (with FailureHandlerMixin, query → Result, action → Failure)"
echo "  • Bloc    : LoginBloc with sub-state union (SubmitLoginState idle/loading/done/error)"
echo "             + AlertState + init event"
echo "  • Page    : LoginPage with BlocConsumer + ScreenUtil"
echo ""
echo "Next steps:"
echo "  cd $PROJECT_NAME"
echo "  # Generate native iOS/Android plumbing (will not overwrite app/lib or app/pubspec.yaml):"
echo "  fvm flutter create --platforms=android,ios --org $PACKAGE_NAME --project-name app app"
echo "  fvm dart pub get"
echo "  dart run melos bootstrap"
echo "  dart run melos generate:all"
echo ""
