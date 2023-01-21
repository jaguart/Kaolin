use v6.d+;

#------------------------------------------------------------------------------
#| A prettier .gist from MOP for almost anything.
#| .gist   from .ident .whom .what .where .why
#| .detail from .ident .whom .what .where .whence .wax .why
#| .mop is accessible - possible anti-pattern - deprecate or delegate?
#------------------------------------------------------------------------------
unit class Kaolin::Wisp is export(:Wisp);

use Kaolin::Moppet :Moppet;


has Mu              $.thing is built(:bind);
has Kaolin::Moppet  $.mop;
has Str             $.hide;

has Bool            $.notwhom   = False;   #= trunctate the .gist?

has Str             $.ident   = '';   #= Identity
has Str             $!whom    = '';   #= Whom           $myvar
has                 $!worth       ;   #= Worth          4
has Str             $!what    = '';   #= What           Int
has Str             $!where   = '';   #= Where          Int
has Str             $!whence  = '';   #= Whence         SETTING::src/core.c/Int.pm6 57
has Str             $!wax     = '';   #= Wax            manual
has Str             $!why     = '';   #= Why            POD

#------------------------------------------------------------------------------
submethod TWEAK {

    $!mop = Moppet.new( :thing($!thing ) ) unless $!mop;

    $!whom =    $!ident             ||
                $!mop.ident         ||    # sometimes we have an external identity
                $!mop.var-name      ||    # sometimes we are a var
                #$!mop.descr         ||    # .DEFINITE and .VAR <- var-value??
                $!mop.name          ||    # sometimes we have a name
                $!mop.type          ||    # sometimes we are a Type
                $!thing.Str               # hmmm, we always need a $!whom
                ;

    $!worth     = $!mop.var-value;

    #dd $!thing if $!worth;

    #say '$!ident        ', $!ident        .raku;
    #say '$!mop.ident    ', $!mop.ident    .raku;    # sometimes we have an external identity
    #say '$!mop.var-name ', $!mop.var-name .raku;    # sometimes we are a var
    #say '$!mop.descr    ', $!mop.descr    .raku;    # .DEFINITE and .VAR
    #say '$!mop.name     ', $!mop.name     .raku;    # sometimes we have a name
    #say '$!mop.type     ', $!mop.type     .raku;    # sometimes we are a Type
    #say '$!thing.Str    ', $!thing.Str    .raku;    # hmmm, we always need a $!whom
    #say 'whom: ', $!whom.raku;


    #say '^name:     ', $!mop.thing.^name.raku;
    #say 'subtype:   ', $!mop.subtype.raku; # proto multi private etc
    #say 'type:      ', $!mop.type.raku;    # just the base type
    #say 'which:     ', $!mop.which.raku;   # includes any mixins
    #say 'supertype: ', $!mop.supertype.raku;
    #say 'is-core:   ', $!mop.is-core;
    #say 'is-class:  ', $!mop.is-class;
    #dd $!thing;
    #say '';

    # Jeff 05-Jan-2023 note that the !$mop.which includes the +{is_hidden_from_backtrace} etc.
    # I may remove that in future and put it into detail.

    my  $type = ( $!mop.type, $!mop.which, '' ).grep({$_ ne ( $!ident//'' | $!whom | $!worth ) }).first;
    #say 'type: ', $type.raku, 'from ', $!mop.which.raku, ' ', $!mop.type.raku;


    #my  $type = $!whom ne $!mop.type ?? $!mop.which || $!mop.type || '' !! '';
        $type = '' if $!mop.subtype and $!mop.type eq 'Attribute';
        #$type = '' if $type eq 'Str';
        #say 'type', $type.raku;

    my  $supertype  =  $!mop.supertype;
        $supertype  = '' if $supertype eq 'Class'; # noise vs signal?

    my  $name       = $!mop.name;
        $name       = '' if $name eq ( $!whom | '<anon>' | $type | $!whom.substr(1) );

                #say '$name,          ', $name.raku               ;
                #say '$!mop.signature ', $!mop.signature.raku     ;
                #say '$!mop.subtype   ', $!mop.subtype.raku       ;
                #say '$type           ', $type.raku               ;
                #say '$supertype      ', $supertype.raku          ;

    $!what  = (
                $name,
                $!mop.signature // '',
                $!mop.subtype //'',
                $type,
                $supertype,
              )
              .grep(*.chars)
              .grep({$_ ne ( $!whom | $!worth ) })
              .join(' ');

    #say ': name      ', ($!mop.name ne $!whom and $!mop.name ne '<anon>') ?? $!mop.name !! '',     ;
    #say ': signiture ', $!mop.signature // '',                                                     ;
    #say ': subtype   ', $!mop.subtype //'',                                                        ;
    #say ': type      ', $type,                                                                     ;
    #say ': mop-type  ', $!mop.type,                                                               ;
    #say ': descr     ', $!mop.descr,                                                               ;
    #say ': supertype ', $supertype,                                                                ;

    $!what ||= $!mop.supertype unless $!mop.type eq 'Str';

    #say 'whom:    ', $!whom;
    #say 'what:    ', $!what;
    #say 'type:    ', $type;
    #say 'package: ', $!mop.package;

    # Add Parents and Roles for Classes
    if $!what eq $!mop.supertype {
        $!what ~= ' is: ('   ~ $!mop.parent-names.join(' ') ~ ')' if $!mop.parent-names.elems;
        $!what ~= ' does: (' ~ $!mop.role-names.join(' ') ~ ')'   if $!mop.role-names.elems;
    }
    $!what ~= ' enums: ' ~ $!mop.enum-names.join(' ') if $!mop.enum-names.elems;

    $!where = $!mop.package;

    $!whence = (
                $!mop.file,
               ).grep(*.chars).unique.join(' ');

    # POD or Exception Message - with NL subst
    $!why = S:g/\n/\c[SYMBOL FOR NEWLINE]/ given ( $!mop.why || $!mop.message );

    # Jeff 07-Jan-2023 this is used to hide scry artifacts
    if $!hide {
        $!ident.=subst($!hide,'',:g);
        $!whom.=subst($!hide,'',:g);;
        $!what.=subst($!hide,'',:g);;
        $!where.=subst($!hide,'',:g);;
        $!whence.=subst($!hide,'',:g);;
        $!wax.=subst($!hide,'',:g);;
        $!why.=subst($!hide,'',:g);;
    }


}

#------------------------------------------------------------------------------

# $notware can be:
#   False -> no $where is displayed,
#   Str   -> $!where is not displayed if it is the same as the Str value
method gist ( :$format="%s", :$detail = False, :$notwhere = False, :$notwhom = $!notwhom, --> Str ) {

    #say 'ident:  ', $!ident;
    #say 'whom:   ', $!whom;
    #say 'what:   ', $!what;
    #say 'where:  ', $!where;
    #say 'whence: ', $!whence;
    #say 'wax:    ', $!wax;
    #say 'why:    ', $!why;

    # Note that $detail forces inclusion of $!where $!whence $!wax and overrides $notwhere
    my  $where = $!where ?? 'in '~$!where !! '';
        $where = '' if $!where eq ( $!whom | $!worth | $!what );

    if not $detail {
        given $notwhere {
            when Str  { $where = '' if $notwhere and $where.contains($notwhere) }
            when Bool { $where = '' if $notwhere.so }
        }
    }

    my @whom = ( $format.sprintf($!whom), '-', );
    given $notwhom {
        when Bool:D {
            @whom = () if $notwhom
        }
        when Str:D  {
            # $notwhom subnames start with &
            @whom = () if @whom and @whom[0] eq $notwhom;
            @whom = () if @whom and @whom[0] eq $notwhom.substr(1);
        }
    }

    (
      @whom.Slip,
      $!worth,
      $!what,
      $where,
      ( $detail     ?? $!whence   !! '' ),
      ( $detail     ?? $!wax      !! '' ),
      ( $!why ?? ('#', $!why )    !! () ),
    )
    .grep( *.chars )
    .join(' ');

}

method detail ( |args ) {
    self.gist( |args, :detail );
}

method ident  ( --> Str ) { $!ident   } #= identity - external
method whom   ( --> Str ) { $!whom    } #= who I am - name
method worth  ( --> Str ) { $!worth   } #= what I am worth
method what   ( --> Str ) { $!what    } #= what I am - subtype, type, supertype
method where  ( --> Str ) { $!where   } #= where I am - namespace
method whence ( --> Str ) { $!whence  } #= whence I came from - file/line
method wax    ( --> Str ) { $!wax     } #= additional wax - extended detail
method why    ( --> Str ) { $!why     } #= Pod declarator content. RAKUDO_POD_DECL_BLOCK_USER_FORMAT=1

method dump () {
    say (
            'ident:'  , $!ident.raku   ,  #= External identity
            'whom:'   , $!whom.raku    ,  #= Who I think I am
            'worth:'  , $!worth.raku   ,  #= Worth aka value
            'what:'   , $!what.raku    ,  #= What am I
            'where:'  , $!where.raku   ,  #= Where am I
            'whence:' , $!whence.raku  ,  #= Whence I came from - File/Line
            'wax:'    , $!wax.raku     ,  #= Wax - detail I only reveal when asked
            'why:'    , $!why.raku     ,  #= Why I am
        ).join(' ');
}


# TODO: rejig this detail
