# CONTEXT

## Commit signing without the approval prompt

`op-ssh-sign` asks the 1Password GUI to approve each signature, on the
machine's own screen. Over SSH no one can click it, so agents' commits hung.
The desktop preset therefore sets `gitSignKeyFile` to an agenix copy of the
same signing key (`secrets/github/signing-key.age`, the private half of
`flakes/home/modules/profile/git-signing-key.pub`), and git/jujutsu sign with
plain `ssh-keygen` from that file. GitHub sees the same key, so commits stay
"Verified" and nothing changes on the GitHub side.

Only signing moves off 1Password. SSH authentication (push, pull, remote
hosts) still goes through the 1Password agent with its own keys, so a push
over SSH still needs an approval.

The cost: anything running as the user can sign as them without asking.
Leaving `gitSignKeyFile` null restores the prompt.

The file must be in OpenSSH format, or `ssh-keygen -Y sign` rejects it.
