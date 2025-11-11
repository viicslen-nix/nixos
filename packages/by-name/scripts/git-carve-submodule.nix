{
  writeShellScriptBin,
  stdenv,
  git,
  git-filter-repo,
  gnugrep,
  gnused,
  coreutils,
  ...
}:
writeShellScriptBin "git-carve-submodule" ''
  #!${stdenv.shell}

  # Git Carve Submodule - Extract a subdirectory into a separate repository and add it as a submodule

  set -euo pipefail

  # Colors for output
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  BLUE='\033[0;34m'
  NC='\033[0m' # No Color

  usage() {
    cat << EOF
  Usage: git-carve-submodule [OPTIONS] <subdirectory> <new-repo-url>

  Extract a subdirectory from the current Git repository and convert it to a submodule.

  ARGUMENTS:
    subdirectory     The subdirectory to extract (relative to repo root)
    new-repo-url     The URL of the new repository where the subdirectory will be pushed

  OPTIONS:
    -h, --help       Show this help message
    -b, --branch     Target branch name (default: main)
    -n, --dry-run    Show what would be done without making changes
    --no-push        Don't push to the new repository (useful for testing)
    --backup         Create a backup branch before making changes

  EXAMPLES:
    git-carve-submodule modules/neovim https://github.com/user/neovim-config.git
    git-carve-submodule --branch develop --backup flakes/niri git@github.com:user/niri-flake.git

  REQUIREMENTS:
    - Current directory must be a Git repository
    - The subdirectory must exist and be tracked in Git
    - You must have push access to the new repository URL
    - The new repository should be empty or already set up to receive the subdirectory

  EOF
  }

  # Default values
  BRANCH="main"
  DRY_RUN=false
  NO_PUSH=false
  BACKUP=false

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
      -h|--help)
        usage
        exit 0
        ;;
      -b|--branch)
        BRANCH="$2"
        shift 2
        ;;
      -n|--dry-run)
        DRY_RUN=true
        shift
        ;;
      --no-push)
        NO_PUSH=true
        shift
        ;;
      --backup)
        BACKUP=true
        shift
        ;;
      -*)
        echo -e "''${RED}Error: Unknown option $1''${NC}" >&2
        usage
        exit 1
        ;;
      *)
        break
        ;;
    esac
  done

  # Check required arguments
  if [[ $# -ne 2 ]]; then
    echo -e "''${RED}Error: Missing required arguments''${NC}" >&2
    usage
    exit 1
  fi

  SUBDIRECTORY="$1"
  NEW_REPO_URL="$2"

  # Validation functions
  check_git_repo() {
    if ! ${git}/bin/git rev-parse --git-dir > /dev/null 2>&1; then
      echo -e "''${RED}Error: Not in a Git repository''${NC}" >&2
      exit 1
    fi
  }

  check_subdirectory() {
    if [[ ! -d "$SUBDIRECTORY" ]]; then
      echo -e "''${RED}Error: Subdirectory '$SUBDIRECTORY' does not exist''${NC}" >&2
      exit 1
    fi

    # Check if subdirectory is tracked in Git
    if ! ${git}/bin/git ls-tree HEAD "$SUBDIRECTORY" > /dev/null 2>&1; then
      echo -e "''${RED}Error: Subdirectory '$SUBDIRECTORY' is not tracked in Git''${NC}" >&2
      exit 1
    fi
  }

  check_working_directory() {
    if [[ -n "$(${git}/bin/git status --porcelain)" ]]; then
      echo -e "''${RED}Error: Working directory is not clean. Please commit or stash your changes.''${NC}" >&2
      exit 1
    fi
  }

  # Main functions
  create_backup() {
    if [[ "$BACKUP" == true ]]; then
      local backup_branch="backup-before-carve-$(${coreutils}/bin/date +%Y%m%d-%H%M%S)"
      echo -e "''${BLUE}Creating backup branch: $backup_branch''${NC}"
      if [[ "$DRY_RUN" == false ]]; then
        ${git}/bin/git branch "$backup_branch"
        echo -e "''${GREEN}Backup created: $backup_branch''${NC}"
      fi
    fi
  }

  extract_subdirectory() {
    echo -e "''${BLUE}Extracting subdirectory '$SUBDIRECTORY' with git filter-repo...''${NC}"

    # Create a temporary directory for the extracted repo
    local temp_dir="$(${coreutils}/bin/mktemp -d)"
    local original_dir="$(${coreutils}/bin/pwd)"

    # Clone the current repo to temp directory
    if [[ "$DRY_RUN" == false ]]; then
      ${git}/bin/git clone "$original_dir" "$temp_dir"
      cd "$temp_dir"

      # Use git filter-repo to extract only the subdirectory
      # Note: This requires git filter-repo to be available
      local filter_repo_success=false

      if ${git-filter-repo}/bin/git-filter-repo --help > /dev/null 2>&1; then
        echo -e "''${BLUE}Attempting to use git-filter-repo...''${NC}"

        # Try to clean up any problematic git config that might cause issues
        ${git}/bin/git config --unset-all filter.repo.clean 2>/dev/null || true
        ${git}/bin/git config --unset-all filter.repo.smudge 2>/dev/null || true

        # Try git-filter-repo with force flag and error handling
        if ${git-filter-repo}/bin/git-filter-repo --force --partial --path "$SUBDIRECTORY/" --path-rename "$SUBDIRECTORY/:" 2>/dev/null; then
          # Verify that the filtering worked
          local file_count=$(${git}/bin/git ls-tree --name-only HEAD | wc -l)
          if [[ "$file_count" -gt 0 ]]; then
            filter_repo_success=true
            echo -e "''${GREEN}Successfully extracted using git-filter-repo ($file_count items)''${NC}"
          else
            echo -e "''${YELLOW}git-filter-repo completed but no files found, trying fallback...''${NC}"
            ${git}/bin/git reset --hard HEAD 2>/dev/null || true
            ${git}/bin/git clean -fd 2>/dev/null || true
          fi
        else
          echo -e "''${YELLOW}git-filter-repo failed, trying alternative approach...''${NC}"
          # Reset any partial changes from failed filter-repo
          ${git}/bin/git reset --hard HEAD 2>/dev/null || true
          ${git}/bin/git clean -fd 2>/dev/null || true
        fi
      fi

      # Use filter-branch if filter-repo is not available or failed
      if [[ "$filter_repo_success" != "true" ]]; then
        echo -e "''${YELLOW}Using git filter-branch as fallback...''${NC}"

        # Set environment variable to suppress filter-branch warning
        export FILTER_BRANCH_SQUELCH_WARNING=1

        # Use filter-branch to keep only the subdirectory and rewrite paths
        ${git}/bin/git filter-branch --force --prune-empty \
          --subdirectory-filter "$SUBDIRECTORY" \
          --tag-name-filter cat \
          HEAD

        # Verify that the filtering worked by checking if the subdirectory contents are now at root
        if [[ ! -f "$(${git}/bin/git ls-tree --name-only HEAD | head -1)" ]] && [[ "$(${git}/bin/git rev-list --count HEAD)" -eq 0 ]]; then
          echo -e "''${RED}Error: Filter-branch failed - no files found in filtered repository''${NC}" >&2
          cd "$original_dir"
          ${coreutils}/bin/rm -rf "$temp_dir"
          exit 1
        fi

        echo -e "''${GREEN}Successfully extracted using git filter-branch''${NC}"
      fi

      # Final validation: ensure we only have the subdirectory contents
      local file_count=$(${git}/bin/git ls-tree --name-only HEAD | wc -l)
      if [[ "$file_count" -eq 0 ]]; then
        echo -e "''${RED}Error: No files found after filtering - something went wrong''${NC}" >&2
        cd "$original_dir"
        ${coreutils}/bin/rm -rf "$temp_dir"
        exit 1
      fi

      echo -e "''${BLUE}Filtered repository contains $file_count items''${NC}"

      if [[ "$NO_PUSH" == false ]]; then
        # Remove existing origin remote and add the new one
        ${git}/bin/git remote remove origin 2>/dev/null || true
        ${git}/bin/git remote add origin "$NEW_REPO_URL"

        echo -e "''${BLUE}Pushing extracted directory to new repository...''${NC}"
        ${git}/bin/git push -u origin "$BRANCH"

        cd "$original_dir"
        ${coreutils}/bin/rm -rf "$temp_dir"
      else
        # When NO_PUSH is true, save the extracted repo to a permanent location
        local extracted_repo_dir="$original_dir/''${SUBDIRECTORY//\//-}-extracted-$(${coreutils}/bin/date +%Y%m%d-%H%M%S)"
        cd "$original_dir"
        ${coreutils}/bin/mv "$temp_dir" "$extracted_repo_dir"
        echo -e "''${GREEN}Extracted repository saved to: $extracted_repo_dir''${NC}"
        echo -e "''${BLUE}You can manually push it later with:''${NC}"
        echo -e "  cd $extracted_repo_dir && git push -u origin $BRANCH"
      fi
    else
      echo -e "''${YELLOW}[DRY RUN] Would clone repo to temp directory and extract '$SUBDIRECTORY'.''${NC}"
      echo -e "''${YELLOW}[DRY RUN] Would push to '$NEW_REPO_URL' on branch '$BRANCH'.''${NC}"
    fi
  }

  replace_with_submodule() {
    echo -e "''${BLUE}Removing original subdirectory and adding as submodule...''${NC}"

    if [[ "$DRY_RUN" == false ]]; then
      # Remove the original subdirectory
      ${git}/bin/git rm -r "$SUBDIRECTORY"
      ${git}/bin/git commit -m "Remove $SUBDIRECTORY before converting to submodule"

      # Add as submodule
      ${git}/bin/git submodule add "$NEW_REPO_URL" "$SUBDIRECTORY"
      ${git}/bin/git commit -m "Add $SUBDIRECTORY as submodule"

      echo -e "''${GREEN}Successfully converted '$SUBDIRECTORY' to submodule''${NC}"
    else
      echo -e "''${YELLOW}[DRY RUN] Would remove '$SUBDIRECTORY' from current repo''${NC}"
      echo -e "''${YELLOW}[DRY RUN] Would add '$NEW_REPO_URL' as submodule at '$SUBDIRECTORY'.''${NC}"
    fi
  }

  # Main execution
  main() {
    echo -e "''${BLUE}Git Carve Submodule''${NC}"
    echo -e "''${BLUE}==================''${NC}"
    echo

    # Pre-flight checks
    check_git_repo
    check_subdirectory
    check_working_directory

    # Show what we're going to do
    echo -e "''${BLUE}Configuration:''${NC}"
    echo -e "  Subdirectory: ''${YELLOW}$SUBDIRECTORY''${NC}"
    echo -e "  New repo URL: ''${YELLOW}$NEW_REPO_URL''${NC}"
    echo -e "  Target branch: ''${YELLOW}$BRANCH''${NC}"
    echo -e "  Dry run: ''${YELLOW}$DRY_RUN''${NC}"
    echo -e "  Create backup: ''${YELLOW}$BACKUP''${NC}"
    echo

    # Confirm unless dry run
    if [[ "$DRY_RUN" == false ]]; then
      echo -e "''${YELLOW}This will permanently modify your repository. Continue? (y/N)''${NC}"
      read -r confirm
      if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo -e "''${YELLOW}Aborted by user''${NC}"
        exit 0
      fi
    fi

    # Execute the carving process
    create_backup
    extract_subdirectory
    replace_with_submodule

    echo
    echo -e "''${GREEN}Carve operation completed!''${NC}"

    if [[ "$DRY_RUN" == false ]]; then
      echo -e "''${BLUE}Next steps:''${NC}"
      echo -e "  1. Verify the submodule is working: ''${YELLOW}git submodule status''${NC}"
      echo -e "  2. Update submodule if needed: ''${YELLOW}git submodule update --remote''${NC}"
      echo -e "  3. Push changes to your main repository"
    fi
  }

  main "$@"
''
