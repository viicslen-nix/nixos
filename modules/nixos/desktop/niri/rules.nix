{
  programs.niri.settings = {
    window-rules = [
      {
        geometry-corner-radius = let
          r = 8.0;
        in {
          top-left = r;
          top-right = r;
          bottom-left = r;
          bottom-right = r;
        };
        clip-to-geometry = true;
        draw-border-with-background = false;
      }
    ];

    layer-rules = [
      {
        matches = [{namespace = "^swaync-notification-window$";}];
        block-out-from = "screencast";
      }
    ];
  };
}
