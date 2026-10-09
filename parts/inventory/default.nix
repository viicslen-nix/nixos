# `flake.inventory.<host>`: what each host installs and enables, and the file that put it there.
{
  lib,
  self,
  ...
}: let
  inherit (builtins) tryEval deepSeq;

  hosts = (import ../../hosts {}).hosts or {};
  root = "${self.outPath}/";

  source = file: let
    path = lib.head (lib.splitString ", via option " file);
    inRepo = lib.hasPrefix root path;
    storeRel = builtins.match "/nix/store/[^/]+/(.*)" path;
    rel =
      if inRepo
      then lib.removePrefix root path
      else if storeRel != null
      then lib.head storeRel
      else path;
  in {
    source = lib.removeSuffix "/default.nix" rel;
    upstream = !inRepo;
  };

  safe = fallback: v: let
    r = tryEval (deepSeq v v);
  in
    if r.success
    then r.value
    else fallback;

  pkgInfo = p:
    safe {
      name = "<eval error>";
      version = "";
    } (
      if lib.isDerivation p
      then let
        version = lib.getVersion p;
      in {
        # perlPackages bake the perl and package versions into pname.
        name = lib.removeSuffix "-${version}" (lib.getName p);
        inherit version;
      }
      else {
        name = toString p;
        version = "";
      }
    );

  # Some modules put mkIf on list elements (home-manager's nixgl.nix), which the merge never discharges.
  unwrap = p: let
    t =
      if lib.isAttrs p
      then p._type or null
      else null;
  in
    if t == "if"
    then lib.optionals (safe false p.condition == true) (unwrap p.content)
    else if t == "override" || t == "order"
    then unwrap p.content
    else [p];

  packagesFrom = defs:
    lib.unique (lib.concatMap (def: map (p: pkgInfo p // source def.file) (lib.concatMap unwrap def.value)) defs);

  isTrue = opt: let
    r = tryEval (opt.value == true);
  in
    r.success && r.value;

  kind = o: let
    r = tryEval (
      if lib.isOption o
      then "option"
      else if lib.isAttrs o
      then "set"
      else "other"
    );
  in
    if r.success
    then r.value
    else "other";

  # Hidden options are rename aliases: reading one can `abort` (uncatchable) or report its target twice.
  # Visible aliases (services.sshd → services.openssh) only repeat their target: they carry no default and no definitions.
  # Never read `description`: a module's `mdDoc` there throws an uncatchable undefined-variable error.
  isEnable = o:
    kind o
    == "option"
    && (o.visible or true) != false
    && (o ? default || safe true (o.definitionsWithLocations != []));

  # Every `<prefix>.….enable` that is true, minus sub-feature toggles of something already listed.
  # Stops at a disabled level: its sub-features often default to on (services.akkoma.initDb).
  # `modules.*` hides only direct sub-features (`ai.integrations.<x>` stays); upstream trees stop below a
  # level the repo enabled and drop nested toggles nobody in the repo set (services.zfs.trim).
  enabled = ns: walk (ns == "modules") false [ns];

  walk = ours: parentOn: prefix: opts: let
    hasEnable = opts ? enable && isEnable opts.enable;
    on = hasEnable && isTrue opts.enable;
    sources = lib.optionals on (lib.unique (map (d: source d.file) opts.enable.definitionsWithLocations));
    fromRepo = lib.any (s: !s.upstream) sources;
    show =
      on
      && (
        if ours
        then !parentOn
        else fromRepo || lib.length prefix <= 2
      );
    descend = !hasEnable || (on && (ours || !fromRepo));
  in
    lib.optional show {
      option = lib.concatStringsSep "." prefix;
      inherit sources;
    }
    ++ lib.optionals descend (lib.concatLists (lib.mapAttrsToList (
        name: o: lib.optionals (name != "enable" && kind o == "set") (walk ours on (prefix ++ [name]) o)
      )
      opts));

  # Names each file declares in an attrsOf option; a name missing from the final value was dropped by an inner mkIf.
  namesFrom = opt: final: extra:
    lib.unique (lib.concatMap (
        def: let
          s = source def.file;
        in
          map (name: {inherit name;} // extra name // s)
          (lib.filter (n: final ? ${n}) (lib.attrNames def.value))
      )
      opt.definitionsWithLocations);

  # Units the repo creates; one upstream already defines (nix-daemon, greetd) is only being tweaked.
  units = scope: opt: final: let
    defs = namesFrom opt final (_: {inherit scope;});
    upstreamNames = map (u: u.name) (lib.filter (u: u.upstream) defs);
  in
    lib.mapAttrsToList (name: us: {
      inherit name scope;
      source = lib.concatStringsSep ", " (lib.unique (map (u: u.source) us));
      upstream = false;
    })
    (lib.groupBy (u: u.name) (lib.filter (u: !u.upstream && !(lib.elem u.name upstreamNames)) defs));

  # An inline home-manager.sharedModules entry has no file of its own, so everything it defines is
  # credited to home-manager's nixos/common.nix. Re-tag each with the file that added it.
  withSharedModuleFiles = nixos: let
    opt = nixos.options.home-manager.sharedModules or null;
    tag = file: m:
      if builtins.isPath m || builtins.isString m
      then m
      else {
        _file = file;
        imports = [m];
      };
  in
    if opt == null
    then nixos
    else
      nixos.extendModules {
        modules = [
          {home-manager.sharedModules = lib.mkForce (lib.concatMap (d: map (tag d.file) d.value) opt.definitionsWithLocations);}
        ];
      };

  # nixpkgs folds every users.users.<u>.packages into systemPackages; those are listed per user instead.
  usersGroups = "nixos/modules/config/users-groups.nix";

  system = {
    options,
    config,
    ...
  }: {
    packages =
      packagesFrom (lib.filter (d: !(lib.hasSuffix usersGroups d.file))
        options.environment.systemPackages.definitionsWithLocations);
    modules = enabled "modules" (options.modules or {});
    programs = enabled "programs" options.programs;
    services = enabled "services" options.services ++ enabled "virtualisation" options.virtualisation;
    containers = let
      cs = config.virtualisation.oci-containers.containers;
    in
      namesFrom options.virtualisation.oci-containers.containers cs (n: {image = safe "" cs.${n}.image;});
    units =
      units "system" options.systemd.services config.systemd.services
      ++ units "user" options.systemd.user.services config.systemd.user.services;
  };

  user = nixos: name: hm: let
    inherit (hm) options config;
    nixosUser = nixos.options.users.users.valueMeta.attrs.${name}.configuration.options or null;
  in {
    packages =
      packagesFrom options.home.packages.definitionsWithLocations
      ++ lib.optionals (nixosUser != null) (lib.filter (p: !p.upstream)
        (packagesFrom nixosUser.packages.definitionsWithLocations));
    modules = enabled "modules" (options.modules or {});
    programs = enabled "programs" options.programs;
    services = enabled "services" options.services;
    containers = [];
    units = units "user" options.systemd.user.services config.systemd.user.services;
  };
in {
  flake.inventory =
    lib.mapAttrs (host: nixos': let
      nixos = withSharedModuleFiles nixos';
    in {
      inherit host;
      presets = hosts.${host}.presets or [];
      system = system nixos;
      users = let
        hmUsers = nixos.options.home-manager.users or null;
      in
        lib.optionalAttrs (hmUsers != null) (
          lib.mapAttrs (name: _: user nixos name hmUsers.valueMeta.attrs.${name}.configuration)
          nixos.config.home-manager.users
        );
    })
    self.nixosConfigurations;
}
