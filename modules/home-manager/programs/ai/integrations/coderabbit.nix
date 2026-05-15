{
  lib,
  cfg,
  isAttrs,
}: 
with lib; {
  commands = {
    coderabbit-review = ../commands/coderabbit/review.md;
  };

  agents = {
    code-reviewer = ../agents/coderabbit/code-reviewer.md;
  };

  skills = {
    autofix = ../skills/coderabbit/autofix/SKILL.md;
    code-review = ../skills/coderabbit/code-review/SKILL.md;
  };

  options = {
    coderabbit = {
      enable = mkEnableOption (mdDoc "CodeRabbit commands, skills, and agent for shared ai tooling");
    };
  };

  warnings =
    optional (cfg.coderabbit.enable && !(isAttrs cfg.skills))
    "`modules.programs.ai.coderabbit.enable` adds default CodeRabbit skills only when `modules.programs.ai.skills` is an attribute set.";
}
