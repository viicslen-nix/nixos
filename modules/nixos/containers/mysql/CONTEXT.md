# mysql

## jemalloc

After 12 days of uptime, mysqld held 5.7G of RSS plus swap. Its own
accounting (`sys.memory_global_total`) came to only 1.45G: a 128M buffer pool,
about 380M of InnoDB internals and about 300M of performance_schema. The
remaining ~4G was memory that glibc malloc had freed but never returned to the
OS, spread across its per-thread arenas. Many short-lived connections from the
worktree apps (peak 164) produce exactly this fragmentation pattern.

The Percona image ships `/usr/lib64/libjemalloc.so.2` for this reason, and
`LD_PRELOAD` turns it on. The path is tied to the image (`:latest`). If a
future image moves the library, the dynamic loader only prints a warning and
mysqld falls back to glibc malloc. Check `cat /proc/$(pgrep -f
'mysqld --disable')/maps | grep jemalloc` after an image bump.
