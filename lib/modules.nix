{ lib }:

{
  # Auto-discover and import all default.nix files in a directory
  # Returns an attribute set mapping directory names to their default.nix imports
  # Uses pure builtins - no nixpkgs lib dependency
  autoImportModules = path:
    let
      entries = builtins.readDir path;
      
      # Get all directories
      dirs = builtins.filter 
        (name: entries.${name} == "directory") 
        (builtins.attrNames entries);
      
      # Import each module if it has a default.nix
      importModule = name:
        let modulePath = path + "/${name}/default.nix";
        in {
          name = name;
          value = if builtins.pathExists modulePath 
                  then import modulePath 
                  else null;
        };
      
      # Create attribute set from imports
      modules = builtins.listToAttrs (map importModule dirs);
      
      # Filter out null values (directories without default.nix)
      validModules = builtins.removeAttrs modules 
        (builtins.filter (name: modules.${name} == null) (builtins.attrNames modules));
    in
      validModules;

  # Recursively discover modules across multiple categories
  # Usage: autoImportCategories ./modules/nixos ["programs" "hardware" "desktop"]
  autoImportCategories = basePath: categories:
    builtins.listToAttrs (map
      (category:
        let
          categoryPath = basePath + "/${category}";
          modulesHelper = import ./modules.nix { inherit lib; };
        in
          {
            name = category;
            value = if builtins.pathExists categoryPath
                    then modulesHelper.autoImportModules categoryPath
                    else {};
          }
      )
      categories
    );

  # Fully recursive auto-import with support for nested modules
  # Automatically discovers all categories and supports unlimited nesting depth
  # Excludes: hidden files/dirs (.), special dirs (_), documentation files, etc.
  # 
  # IMPORTANT: For hybrid directories (with both default.nix AND subdirectories):
  # - The default.nix is imported as the main module
  # - Subdirectories are NOT merged (modules are functions, not attr sets)
  # - To access nested modules, they must be separate categories
  autoImportRecursive = path:
    let
      # Check if a name should be excluded from auto-import
      shouldExclude = name:
        let
          # Starts with dot (hidden files/dirs)
          startsWithDot = builtins.substring 0 1 name == ".";
          
          # Starts with underscore (special dirs like _shared)
          startsWithUnderscore = builtins.substring 0 1 name == "_";
          
          # Special files/dirs to exclude
          specialNames = ["all.nix" "default.nix"];
          isSpecial = builtins.elem name specialNames;
          
          # Documentation and other file extensions to exclude
          hasExcludedExt = 
            builtins.match ".*\\.(md|txt|org|rst)$" name != null;
        in
          startsWithDot || startsWithUnderscore || isSpecial || hasExcludedExt;
      
      # Check if a directory has subdirectories
      hasSubdirectories = dirPath:
        let
          entries = builtins.readDir dirPath;
          dirs = builtins.filter
            (name: entries.${name} == "directory" && !(shouldExclude name))
            (builtins.attrNames entries);
        in
          (builtins.length dirs) > 0;
      
      # Main recursive import logic
      entries = builtins.readDir path;
      
      # Get all directories (excluding files)
      allDirs = builtins.filter 
        (name: entries.${name} == "directory") 
        (builtins.attrNames entries);
      
      # Filter out excluded directories
      dirs = builtins.filter (name: !(shouldExclude name)) allDirs;
      
      # Process each directory
      processDir = name:
        let
          dirPath = path + "/${name}";
          defaultNixPath = dirPath + "/default.nix";
          hasDefault = builtins.pathExists defaultNixPath;
          hasSubdirs = hasSubdirectories dirPath;
          
          # Get the module helper for recursion
          modulesHelper = import ./modules.nix { inherit lib; };
        in
          {
            name = name;
            value = 
              if hasDefault then
                # Directory has default.nix: import it (even if it has subdirs)
                # We prioritize the default.nix since modules are functions, not mergeable
                import defaultNixPath
              else if hasSubdirs then
                # Category directory: no default.nix, but has nested modules
                # Recursively import subdirectories
                modulesHelper.autoImportRecursive dirPath
              else
                # Empty directory or no modules: skip
                null;
          };
      
      # Create attribute set from all processed directories
      modules = builtins.listToAttrs (map processDir dirs);
      
      # Filter out null values (empty directories)
      validModules = builtins.removeAttrs modules 
        (builtins.filter (name: modules.${name} == null) (builtins.attrNames modules));
    in
      validModules;
}
