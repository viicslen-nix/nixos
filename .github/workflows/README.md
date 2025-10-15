# GitHub Workflows

This directory contains GitHub Actions workflows for the NixOS configuration repository.

## Workflow Structure

### Main Workflow: Build ISO Images (`build-iso.yml`)

A manually triggered workflow that orchestrates building of ISO installation images for different target systems.

#### Reusable Components:

- **Composite Action**: `.github/actions/setup-nix-build/action.yml`
  - Sets up Nix with flakes support
  - Configures Cachix for faster builds
  - Frees up disk space to accommodate large builds
  - Reusable across different build jobs

- **Reusable Workflow**: `.github/workflows/build-single-iso.yml`
  - Builds a single ISO package based on `iso-type` input
  - Automatically derives package names, display names, and artifact names
  - Handles artifact upload and release note generation
  - Called by the main workflow for each ISO type

### Usage

#### Manual Trigger:
1. Go to the "Actions" tab in the GitHub repository
2. Select "Build ISO Images" workflow
3. Click "Run workflow"
4. Choose which ISO(s) to build:
   - `both`: Build both steam-handheld and common ISOs
   - `steam-handheld`: Build only the Steam Handheld ISO
   - `common`: Build only the common ISO
5. Click "Run workflow" to start the build

#### ISO Types:

**Steam Handheld ISO** (`iso.steam-handheld`):
- Package: `iso.steam-handheld`
- Optimized for gaming handhelds (Steam Deck, etc.)
- Includes Jovian NixOS modules for Steam Deck compatibility
- Uses CachyOS kernel for better gaming performance
- AMD GPU support enabled

**Common ISO** (`iso.common`):
- Package: `iso.common`
- General-purpose installation ISO
- GNOME desktop environment
- Standard development tools included
- Suitable for most desktop/laptop installations

### Architecture Benefits

1. **DRY Principle**: Eliminates code duplication between ISO build jobs
2. **Maintainability**: Changes to build logic only need to be made in one place
3. **Reusability**: The reusable workflow can be easily extended for new ISO types
4. **Modularity**: Setup logic is separated from build logic
5. **Scalability**: Easy to add new ISO packages by calling the reusable workflow

### Adding New ISO Types

To add a new ISO type, simply add a new job to `build-iso.yml`:

```yaml
build-new-iso:
  if: ${{ github.event.inputs.build_target == 'both' || github.event.inputs.build_target == 'new-iso' }}
  uses: ./.github/workflows/build-single-iso.yml
  with:
    iso-type: new-iso
  secrets:
    CACHIX_AUTH_TOKEN: ${{ secrets.CACHIX_AUTH_TOKEN }}
```

The reusable workflow will automatically:
- Build the package `iso.{iso-type}`
- Generate appropriate display names for known types (steam-handheld → "Steam Handheld ISO")
- Create artifacts named `iso.{iso-type}-iso` and `iso.{iso-type}-release-notes`

And update the input options in the `workflow_dispatch` section.

### Requirements

- **Repository**: Access to the repository (no special permissions needed for manual trigger)
- **Secrets** (optional):
  - `CACHIX_AUTH_TOKEN`: For faster builds with Cachix caching

### Artifacts

After a successful build, the following artifacts will be available for download:
- `{package-name}-iso`: The built ISO file
- `{package-name}-release-notes`: Build metadata and information
- `build-summary`: Combined build notes with workflow metadata

### Performance Optimizations

- **Disk Space Management**: Automatically removes unnecessary packages and directories
- **Cachix Integration**: Uses binary caches for faster builds
- **Parallel Builds**: ISOs are built in parallel when both are selected
- **Artifact Compression**: Disabled for ISOs since they're already compressed