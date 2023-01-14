use v6;

unit module Kaolin::File;

#| find files lazily
our sub find  (
    $dir,
    Bool :$recursive = True,
    |opt
) is export(:find) {

    #| check find() opts once - no validation while testing files
    sub ok-opts (|opt --> Bool) {
        die "type must be: file, dir or symlink got '{ opt<type> }'"
            if opt<type> and opt<type> ne ('file' | 'dir' | 'symlink');
        True
    }

    #| check entry against filter opts - name, type, skip
    sub ok-entry (IO::Path:D $entry, |opt --> Bool) {
        with opt<skip> -> $skip {
            return False if  $entry.Str ~~ $skip;
        }
        with opt<name> -> $name {
            return False unless $entry.basename ~~ $name;
        }
        with opt<type> -> $type {
            when $type eq  'file'   { return False unless $entry.f }
            when $type eq 'dir'     { return False unless $entry.d }
            when $type eq 'symlink' { return False unless $entry.l }
        }
        return True;
    }

    ok-opts(|opt); # validate filter opts

    my @entries = $dir.IO.dir.sort;
    gather while @entries {
        my $entry = @entries.shift;
        take $entry if ok-entry($entry, |opt);
        if $recursive and $entry.IO.d {
            @entries.append: $entry.IO.dir.sort;
        }
    }

}

#| Safer rename - defaults to NO-clobber
our sub mv-file ( IO::Path:D $from, IO::Path:D $to, :$clobber = False ) is export(:mv-file) {
    die { "mv-file: from {$from.Str} does not exist" } unless $from.e;
    die { "mv-file: to {$to.Str} already exists" } if not $clobber and $to.e;
    $from.rename( $to, :createonle(not $clobber) );
}
