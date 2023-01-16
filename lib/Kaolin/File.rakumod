use v6;

unit module Kaolin::File;

#-------------------------------------------------------------------------------
#| e.g. my $dir = '.'.IO but (Kaolin::File::Finder, Kaolin::File::Namer);
role Finder {
    method find (|args) {
        Kaolin::File::find(self,|args)
    }
}

#-------------------------------------------------------------------------------
#| Cleanup and fix basenames - lowercase, alpha-numeric, hypens
role Namer {
    method basename-clean ( Bool :$lc = True, --> Str ) {
        my $basename = $lc ?? self.basename.lc !! self.basename;
        # any spooky -> hypen
        # multi-hypens -> single hypen
        # leading / trailing hypen -> removed
        $basename.=subst(/<-[A..Z a..z 0..9 . -]>+/, '-', :g);
        $basename.=subst(/'-' ** 2..*/, '-', :g);
        $basename.=subst(/(^ '-') || ('-' $)/, '', :g);
        $basename;
    }
    method fix-basename () {
        if self.basename ne self.basename-clean {
            if mv-file( self, self.sibling( self.basename-clean ) ) {
                self.sibling( self.basename-clean );
            }
        }
    }
}


#-------------------------------------------------------------------------------
#| find files lazily
our sub find  (
    $dir,
    Bool  :$recursive = False,          #= descend
    Str   :$type = 'file',              #= file dir symlink
          :$name,                       #= inclusion filter
          :$skip,                       #= exclusion filter
          :$filter = rx/ '.' .*? '/' /, #= default filter
) is export(:find) {

    #| check opts once - no validation while testing files
    sub ok-opts (Str :$type, :$name, :$skip, :$filter --> Bool) {
        die "type must be: file, dir or symlink got '$type'"
            if $type and $type ne ('file' | 'dir' | 'symlink');
        True
    }

    #| check entry against filter opts - name, type, skip
    sub ok-entry (IO::Path:D $entry, Str :$type, :$name, :$skip, :$filter --> Bool) {
        return False if $filter.defined and $entry.Str ~~ $filter;
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
        take $entry if ok-entry($entry, :$type, :$name, :$skip, :$filter);
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
    if $from.rename($to, :createonly(not $clobber)) {
        $to;
    }
}

#-------------------------------------------------------------------------------
