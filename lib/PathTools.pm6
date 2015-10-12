unit module PathTools;

sub ls(Str(Cool) $path, Bool :$f = True, Bool :$d = True, Bool :$r = False, *%_) is export {
    return () if !$path.IO.e || (%_<test> && $path ~~ %_<test>);
    return (?$f ?? $path !! ()) if $path.IO.f;
    my $cwd-paths = $path.IO.dir(|%_).cache;
    my $files     = $cwd-paths.grep(*.IO.f);
    my $dirs      = $cwd-paths.grep(*.IO.d);
    my $rec-paths = $cwd-paths.grep(*.IO.d)>>.&ls(:$f, :$d, :!r, |%_);
    (($files.Slip if ?$f), ($dirs.Slip if ?$d), ($rec-paths.Slip if ?$r)).flat>>.Str;
}

sub rm(*@paths, Bool :$f = True, Bool :$d = True, Bool :$r, *%_) is export {
    my @ls        = flat (@paths>>.&ls(:$f, :$d, :$r, |%_)>>.Slip)>>.Slip;
    my @delete-us = (@paths.Slip, @ls.Slip).sort({-.chars});
    my @deleted   = ~$_ for @delete-us.grep(*.IO.e).grep: {try { $_.IO.d ?? $_.IO.rmdir !! $_.IO.unlink}}
}

sub mkdirs($path, *%_) is export {
    my $path-copy = $path;
    my @mkdirs = eager gather { loop {
        last if ($path-copy.IO.e && $path-copy.IO.d);
        take $path-copy;
        last unless $path-copy := $path-copy.IO.dirname;
    } }
    @mkdirs ?? @mkdirs.reverse.map({ ~mkdir($_, |%_) }).[*-1] !! ();
}

sub mktemp($path = &tmpdir(), Bool :$f = False, *%_) is export {
    die "Cannot call mktemp with a path that already exists" if $path.IO.e;
    state @dirs; state @files;
    END { rm(|@files, :!r, :f, :!d); rm(|@dirs, :r, :f, :d) }
    ?$f ?? (do { $path.IO.open(:w).close; @files.append($path); return ~$path.IO.absolute  }  )
        !! (do { with mkdirs($path, |%_) -> $p { @dirs.append(~$p); return ~$p.IO.absolute } })
}

sub tmpdir(Str(Cool) $base where *.chars = $*TMPDIR) is export {
    state $lock = Lock.new;
    state $id   = 0;
    state @cache; # So we don't return the same path in 2 different calls when user has not created the tmpdir yet
    $lock.protect({
        for ^100 { # retry a max number of times
            my $gen-path = $base.IO.child("p6mktemp").child("{time}_{++$id}").IO;
            if !$gen-path.e && $gen-path !~~ @cache {
                @cache.append(~$gen-path);
                return ~$gen-path;
            }
        }
    });
}
