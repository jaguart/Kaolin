v6;

#-------------------------------------------------------------------------------
# Jeff 11-Jan-2023 TODO: Make iterators for these
#
#    method dfs-inorder {
#        # for inorder in n-ary trees - kids must be classified as left or right.
#        my @ids;
#        for @.kids -> $kid {
#            @ids.append( $kid.dfs-inorder ) if $kid.left;
#        }
#        @ids.push( $!id );
#        for @.kids -> $kid {
#            @ids.append( $kid.dfs-inorder ) unless $kid.left;
#        }
#        @ids;
#    }
#
#    method dfs-preorder {
#        my @ids;
#        @ids.append( $_.dfs-preorder ) for @!kids;
#        @ids.prepend($!id);
#        @ids;
#    }
#
#    method dfs-postorder {
#        my @ids;
#        @ids.append( $_.dfs-postorder ) for @!kids;
#        @ids.push($!id);
#        @ids;
#    }
#
#    method bfs-level {
#        my @ids;
#
#        @bf-queue.append( @!kids ); # add our kids to the queue
#
#        @ids.push($!id);
#        while @bf-queue.shift -> $node {
#            @ids.append( $node.bfs-level );
#        }
#
#        @ids;
#
#    }
#-------------------------------------------------------------------------------


#-------------------------------------------------------------------------------
#| basis for simple N-ary Trees - has .id .left .name - does .add-kid, .del-kid
unit class Kaolin::Node;

our $ID_FOUNTAIN = 0;

has Int $!id;

has $.name is rw;
has $.left is rw;
has @.kids;

multi method new ( $name, |args ) {
    self.bless( :name($name), |args );
}

submethod TWEAK {
    $!id = $ID_FOUNTAIN++;
}

method id { $!id }

multi method get ( Int $id ) {
    return self if $!id == $id;
    for @.kids -> $kid {
        return $kid.get($id) if $kid.get($id);
    }
    return Nil;
}

multi method get ( Str $name ) {
    return self if $!name eq $name;
    for @.kids -> $kid {
        return $kid.get($name) if $kid.get($name);
    }
    return Nil;
}

method add-kid ( |args ) {
    @!kids.append( self.WHAT.new( |args ) );
    @!kids.tail;
}

method del-kid ( Int $index ) {
    @!kids.splice( $index, 1);
}

method count-nodes ( --> Int ) {
    #(1, @!kids.map({$_.count-nodes}).flat ).sum;
    my $howmany = 1;
    $howmany += $_.count-nodes for @!kids;
    $howmany;
}

#| specialise this for prettier dump descriptions
method descr ( --> Str ) {  '' }


# dfs-preorder makes a nice easy dump
method dump ( $prefix is copy = '', :$id = True, :$nodir = False ) {

    # Have to determine the prefix for the next round of kids in parent,
    # because that's where we know if there are more kids

    # Various unicode box-draw chars - keep for reference
    #   │
    #   ├─
    #   └─
    #   ╰

    say $prefix, ($id ?? $!id !! ''), ($!left ?? '← ' !! '→ ' ), $!name, ' ', self.descr;

    # calc leader for kids
    $prefix.=subst(/\─$/, ' ');         # remove this nodes leader
    $prefix.=subst(/\└\s/, '  ', :g);   # prior last-kid hangover
    $prefix.=subst(/\├\s/, '│ ',:g);    # prior inter-kid hangover

    .dump( $prefix ~ ($_.id == @!kids.tail.id ?? '└─' !! '├─'), |%_ ) for @!kids;

}

method gist {
    self.^name ~ ' with ' ~ self.count-nodes ~ ' nodes';
}

#-------------------------------------------------------------------------------
