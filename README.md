## PathTools

General purpose file system utility routines

## Exports

#### FLAGS

Definitions of the argument flags that can be passed to `PathTools` routines:

    :f - list files
    :d - list directories
    :r - recursively visit directories

    :!f - exclude files
    :!d - exclude directories
    :!r - only in the immediate path

#### `ls($path, Bool :$f = True, Bool :$d = True, Bool :$r --> Str @paths)`

    use PathTools;

    # all paths using directory recursion
    my @all   = ls($path, :r, :d, :f);

    # only *file* paths, found using directory recursion
    my @files = ls($path, :r, :!d, :f);

    # only directories in the current level (no directory recursion)
    my @dirs  = ls($path, :d, :!r);

Like the built-in `dir` but with optional recursion. Any undocumented 
additional named arguments passed in will be passed along to the internal 
`mkdir` and `dir` calls used. For instance, one may wish to pass `:$test` 
which internally defaults to `none('.','..')` and is documented further 
here: [dir](https://docs.raku.org/routine/dir)

    > .say for ls('t');
    /home/user/Raku-PathTools/t/01-basic.rakumod
    /home/user/Raku-PathTools/t/00-sanity.rakumod

To search for files, just grep the results of `ls`:

    > my @files     = ls($path, :r, :!d, :f);
    > my @p6modules = @files.grep(*.IO.extension ~~ 'pm6')

#### `rm(*@paths, :Bool $f = True, Bool :$d = True, Bool :$r --> Str @deleted-paths)`

    # rm -rf tmp/foo
    my @deleted-files = rm("tmp/foo"), :r, :f, :d);

Passes its arguments to `ls` and subsequently unlinks the files and/or deletes folders, 
possibly recursively.

    > .say for rm('t');
    /home/user/Raku-PathTools/t/01-basic.rakumod
    /home/user/Raku-PathTools/t/00-sanity.rakumod

#### `mkdirs($paths --> Str $created-path)`

    # generate a multi level temporary path name
    my $created-path = mkdirs(".work/{$new-month}/{$new-day}")

VM/OS independent folder creation. Identical to the built-in `mkdir` except the path 
parts are created folder by folder. This usually isn't needed, but in some edge cases 
the built-in `mkdir` fails when creating a multi level folder.

    > say mkdirs('newDir/newSubdir');
    /home/user/newDir/newSubdir

#### `mktemp($path?, Bool :$f = False --> Str $tmppath)`

    # create a temporary folder and clean it up after program exit
    my $cleanup-path = mkdirs("/tmp/.worker{$id}/{time}")

If argument C<:$f> is `True` it will create a new file to be deleted at `END { }`.
Otherwise, by default, creates a new folder, `$path`, and will attempt to recursively
cleanup its contents at `END { }`.

If `$path` is not supplied, a path name will be generated automatically with `tmppath`

    # a random directory
    > say mktemp();
    /tmp/tmppath/1444251805_1

    # a random file
    > say mktemp(:f);
    /tmp/tmppath/1444251805_1

    # a file (or directory) name of your choosing
    > say mktemp(".cache", :f);
    /home/user/Raku-PathTools/.cache


#### `tmppath($base? = $*TMPDIR --> Str $pathname)`

    my $pathname = tmppath(".work")

Generate a (hopefully) unique timestamp based path name that is prefixed by C<$base>.
This does not actually create the path; Use `mkdirs` or [mkdir](https://docs.raku.org/routine/mkdir)
on the result.

    > say tmppath();
    /tmp/tmppath/1444251805_1

    > say tmppath(".work");
    .work/tmppath/1444255482_1

    > say tmppath("/con/con")'
    /con/con/tmppath/1444268295_1

    > say tmppath.IO.e;
    False

    > say mkdirs(tmppath).IO.e
    True
