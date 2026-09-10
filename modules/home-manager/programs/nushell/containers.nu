# podman/docker pad every column to a fixed width, so `ps` runs 118 columns wide.
# Emit tab-separated fields instead and let nushell render: the table fits the
# window and stays queryable (`podman ps | where status =~ Up`). Each wrapper
# calls its own binary, so neither needs the other engine installed.
# `^podman ps`, with the caret, bypasses these and runs the raw command.
const ps_fields = "{{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.Image}}"
const images_fields = "{{.Repository}}\t{{.Tag}}\t{{.ID}}\t{{.Size}}"

# --no-infer, or a tag of `8.4` is read as a float and rendered `8.40`.
def ctr-table [columns: list<string>] { $in | from tsv --noheaders --no-infer | rename ...$columns }

def --wrapped "podman ps" [...rest] { ^podman ps --format $ps_fields ...$rest | ctr-table [name status ports image] }
def --wrapped "docker ps" [...rest] { ^docker ps --format $ps_fields ...$rest | ctr-table [name status ports image] }

def --wrapped "podman images" [...rest] { ^podman images --format $images_fields ...$rest | ctr-table [repository tag id size] }
def --wrapped "docker images" [...rest] { ^docker images --format $images_fields ...$rest | ctr-table [repository tag id size] }

# stats streams by default and nushell cannot render a live stream as a table,
# so it keeps a padded Go template. `.PIDs` (docker) vs `.PIDS` (podman) is why
# it carries no PID column.
const stats_format = "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"

def --wrapped "podman stats" [...rest] { ^podman stats --format $stats_format ...$rest }
def --wrapped "docker stats" [...rest] { ^docker stats --format $stats_format ...$rest }
