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

# FIX: need fountain / queue on a per-tree basis.
our @bf-queue; # for bfs-level
our $ID_FOUNTAIN = 0;

has Int     $!id;
has Int     $!depth = 0;

has Str     $.name is rw;
has Bool    $.left is rw = False;

has @.kids;

multi method new ( Str:D $name, |args ) {
    self.bless( :name($name), |args );
}

submethod TWEAK ( |args ) {
    $!id    = $ID_FOUNTAIN++;
    $!depth = args<depth> // 0;
}

method id { $!id }
method depth { $!depth }

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
    @!kids.append( self.WHAT.new( :depth($!depth+1), |args ) );
    @!kids.tail;
}

method del-kid ( Int $index ) {
    @!kids.splice( $index, 1);
}

method count-nodes ( --> Int ) {
    return self.dfs-preorder.map({1}).sum;
}

method leader-width ( Bool :$plain = False ) {
    $plain
        ??  self.dfs-preorder.map({$_.name.chars + $_.depth * 2}).max
        !!  self.dfs-preorder.map({$_.name.chars + $_.depth * 2 + $_.id.chars + 2 }).max
}


#| specialise this for prettier dump descriptions
method descr ( --> Str ) { '' }

# dfs-preorder makes a nice easy dump
method dump (
    Str $prefix is copy = '',
    Bool :$plain = False,   #= display ID
    Int  :$pad is copy,     #= :0pad means no padding.
    ) {

    # Have to determine the prefix for the next round of kids in parent,
    # because that's where we know if there are more kids

    # Unicode box-draw chars - keep for reference
    #   │  ├─ └─ ╰─

    #| use :0pad to disable name padding.
    unless $pad.defined {
        $pad = min( self.leader-width(:$plain), 40 );
    }

    my $lead  = $plain ?? '' !! ( $!id, ($!left ?? '← ' !! '→ ' )).join;
    my $more  = '├─';
    my $last  = '└─';

    my $format = $pad ?? '%-' ~ max( 0, ( $pad - $lead.chars - $prefix.chars )) ~ 's' !! '%s';


    say $prefix, $lead, $format.sprintf($!name), ' ', self.descr;

    # calc leader for kids
    $prefix.=subst(/\─$/, ' ');         # remove this nodes leader
    $prefix.=subst(/\└\s/, '  ', :g);   # prior last-kid hangover
    $prefix.=subst(/\├\s/, '│ ',:g);    # prior inter-kid hangover

    .dump( $prefix ~ ($_.id == @!kids.tail.id ?? $last !! $more), :$plain, :$pad ) for @!kids;

}

method gist {
    my $kids = self.count-nodes - 1;
    self.name
        ~ ($!depth ?? " at depth $!depth" !! "")
        ~ ($kids > 0 ?? " with $kids nodes" !!'');
}

method dfs-preorder {
    my @nodes;
    @nodes.append( $_.dfs-preorder ) for @!kids;
    @nodes.prepend(self);
    @nodes;
}

method dfs-inorder {
    # for inorder in n-ary trees - kids must be classified as left or right.
    my @nodes;
    for @.kids -> $kid {
        @nodes.append( $kid.dfs-inorder ) if $kid.left;
    }
    @nodes.append( self );
    for @.kids -> $kid {
        @nodes.append( $kid.dfs-inorder ) unless $kid.left;
    }
    @nodes;
}

method dfs-postorder {
    my @nodes;
    @nodes.append( $_.dfs-postorder ) for @!kids;
    @nodes.append(self);
    @nodes;
}

method bfs-level {
    my @nodes;
    @bf-queue.append( @!kids ); # add our kids to the queue
    @nodes.append(self);
    while @bf-queue.shift -> $node {
        @nodes.append( $node.bfs-level );
    }
    @nodes;
}


#===============================================================================
