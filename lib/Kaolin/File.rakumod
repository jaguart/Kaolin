use v6;

unit module Kaolin::File;

#-------------------------------------------------------------------------------
#| find files lazily
our sub find  (
    $dir,
    Bool  :$recursive = True,
    Str   :$type,
          :$name,
          :$skip,
) is export(:find) {

    #| check opts once - no validation while testing files
    sub ok-opts (Str :$type, :$name, :$skip --> Bool) {
        die "type must be: file, dir or symlink got '$type'"
            if $type and $type ne ('file' | 'dir' | 'symlink');
        True
    }

    #| check entry against filter opts - name, type, skip
    sub ok-entry (IO::Path:D $entry, Str :$type, :$name, :$skip --> Bool) {
        return False if $skip.defined and $entry.Str ~~ $skip;
        return False if $name.defined and not $entry.basename ~~ $name;
        if $type {
            return False if $type eq 'file'    and not $entry.f;
            return False if $type eq 'dir'     and not $entry.d;
            return False if $type eq 'symlink' and not $entry.l;
        }
        return True;
    }

    # check filter opts
    ok-opts( :$type, :$name, :$skip );

    my @entries = $dir.IO.dir.sort;
    gather while @entries {
        my $entry = @entries.shift;
        take $entry if ok-entry($entry, :$type, :$name, :$skip);
        if $recursive and $entry.IO.d {
            @entries.append: $entry.IO.dir.sort;
        }
    }

}

#-------------------------------------------------------------------------------
#| Safer rename - defaults to NO-clobber, returns IO::Path destination
our sub mv-file (
    IO::Path:D $from,
    IO::Path:D $to,
    :$clobber = False
    --> IO::Path:D
) is export(:mv-file) {
    die { "mv-file: from { $from.Str } does not exist" } unless $from.e;
    die { "mv-file: to { $to.Str } already exists" } if not $clobber and $to.e;
    $from.rename($to, :createonly(not $clobber));
    $to;
}

#-------------------------------------------------------------------------------