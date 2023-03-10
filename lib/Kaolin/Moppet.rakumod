use v6.d+;

use Kaolin::Utils :cleanup-mop-name, :is-core-class, :cleanup-which-name;

#------------------------------------------------------------------------------
#| Easier interface to the MOP - which can be tricky when you drill down.
#|  e.g. role.^methods doesn't return multi-methods etc.
#|  Note that we always use the _table_ calls when we can, see
#|  https://github.com/rakudo/rakudo/issues/4207#issuecomment-782836089
#|  for a discussion on how a Block may have an incorrect idea of it's
#|  class accessor name.
unit class Kaolin::Moppet:auth<zef:jaguart> is export(:Moppet);

# Used to adorn methods with their external name and subtype - i.e. Multi Private
role Subtyped[$t]   {  has Str $.subtype = $t }
role Identified[$i] {  has Str $.ident = $i   }

#| The Mu being introspected
has $.thing;

#| The Mu's HOW
has $!how;

# Jeff 03-Jan-2023 not sure why but different:
#   my &name = {} <- works
#   sub &name  {} <- not so well, $a^name problems?
#| Attribute sorting: required, accessible, private, DEPRECATED
my &sort-attributes = {
  $^b.required.Bool     cmp $^a.required.Bool     or
  $^a.?DEPRECATED.Bool  cmp $^b.?DEPRECATED.Bool  or
  $^b.has_accessor.Bool cmp $^a.has_accessor.Bool or
  $^a.name cmp $^b.name
};

#| Attribute sorting: just name, e.g. for grok: Metamodel::SubsetHOW
my &sort-attribute-names = {
  $^a.name cmp $^b.name
};

submethod TWEAK ( Mu :$thing is raw,  ) {
  $!thing := $thing;
  $!how    = $!thing.HOW;
}

#! EXTERNAL name - unknown to thing
method ident ( --> Str ) {
  return $!thing.ident if try $!thing.ident;
  return '';
}

#| INTERNAL name, see also: .var-name for Scalar vars
method name ( --> Str ) {
  return $!thing.name  if try $!thing.name;
  return $!thing.^name if self.not-core;
  return '';
}

method is-method ( --> Bool:D ) {
  $!thing ~~ Method
}

method is-proto-method ( --> Bool:D ) {
  self.is-method and self.var-value.starts-with('proto')
}

#| Subtype e.g. for Methods: proto private Multi
method subtype ( --> Str ) {
  return 'proto' if self.is-proto-method;

  # Jeff 31-Dec-2022 lower priority because subtype is simply assigned
  return $!thing.subtype if try $!thing.subtype;

  if $!thing ~~ Attribute and $!thing.WHICH ne Attribute.WHICH {
    return $!thing.type.^name;
  }

  return '';
}

#| Tweaked type-name, e.g. Perl6::Metamodel::ClassHOW --> Class
#| Class name || What name || Role || HOW name
method type ( --> Str ) {
  return cleanup-mop-name($!thing.^name) if try $!thing.^name;
  return $!thing.WHAT.^name if self.is-core;
  return 'Role' if self.is-role;
  return cleanup-mop-name($!how.^name);
}

#| parent type - usually Class, Role, Subtype etc.
method supertype ( --> Str ) {
  return 'Role' if self.is-role;
  return cleanup-mop-name($!how.^name);
}


method var {
  #say $!thing.WHICH, " vs ", $!thing.VAR.WHICH, ' d: ', $!thing.DEFINITE;
  $!thing.DEFINITE ?? $!thing.VAR !! Nil;
  #return $!thing.VAR.gist if $!thing.DEFINITE;
  #return $!thing.VAR if $!thing.DEFINITE;
  #return Nil;
}

method var-type-name ( --> Str ) {
  $!thing.DEFINITE ?? $!thing.VAR.^name !! '';
  #$!thing.VAR.^name
}

method var-of {
  $!thing.DEFINITE ?? $!thing.VAR.?of !! Nil;
}

method var-name ( --> Str ) {
  try return $!thing.VAR.name;
  return '';
}

method var-value ( --> Str ) {
    return '' unless $!thing.DEFINITE;
    return '' unless $!thing.VAR;

    # Wisp driven...
    return '' if $!thing ~~ Routine;
    return '' if $!thing ~~ Sub;

    #return $!thing.raku if $!thing.^name eq 'Str'; # Quoted
    return $!thing.gist if is-core-class($!thing);

    return $!thing.raku;

}

#| aka POD declarators
#| tip: export RAKUDO_POD_DECL_BLOCK_USER_FORMAT=1 to get your declarators looking pretty.
method why ( --> Str ) {
  # Routine.WHY fails
  try return $!thing.?WHY ?? $!thing.WHY.gist !! '';
  return '';
}

# TODO: Incorporate these into grok()
#| aka OUR scoped things
method knows {
  if $!thing.WHO.?elems {
    return $!thing.WHO.sort;
  }
  return Empty;
 # say $layout.sprintf("ours"), $thing.WHO.keys.join(' ') if $thing.WHO.?elems;  # Stash names
}

# This was hard to get right... feels fragile
method exports ( :$which = 'ALL' ) {
  if try $!thing.WHO<EXPORT>.WHO<< $which >>.WHO.elems {
    return $!thing.WHO<EXPORT>.WHO<< $which >>.WHO.sort;
  }
  return Empty;
}

#| Parents of this thing - Subset is not quite there yet.
method parents () {

  if try $!how.?parents($!thing, :all) {
    return $!how.?parents($!thing, :all);
  }

  # Metamodel::SubsetHOW does not have :all
  if try $!how.?parents($!thing ) {
    return $!how.?parents($!thing );
  }

  # https://github.com/rakudo/rakudo/blob/main/src/Perl6/Metamodel/SubsetHOW.nqp
  # This is the underlying / parent type for a Subset
  if try $!thing.HOW.refinee($!thing) {
    return $!thing.HOW.refinee($!thing);
  }

  return Empty;
}

method parent-names   { self.parents.map( *.^name );  } # convenience

method roles {
  try {
    # Normal things
    if $!how.?roles($!thing) {
      return $!thing.^roles(:transitive);
    }
  }
  try {
    # Metamodel::SubsetHOW requires :local
    if $!how.?roles($!thing, :local) {
      return $!thing.^roles;
    }
  }
  return Empty;
}

method role-names     { self.roles.map( *.^name );    }

# Attributes have a log of NQP - performance maybe?
method attributes {

  # Jeff 03-Jan-2023 this is fragile...
 if try $!how.?attributes($!thing) {
    try return $!thing.^attributes.sort(&sort-attributes);
    return $!thing.^attributes.sort(&sort-attribute-names);
  }

  return Empty;
}

#| class x is rw -> are Attributes read-write by default?
method is-rw of Bool {
 my $rw = try $!thing.^rw.Bool;
 return $rw ?? True !! False;
}

#| Note that Submethods are NOT Methods -but they ARE returned by .methods( :all )
method submethods {
  my @methods;
  if $!how.?submethod_table($!thing) {
    if my %methods = $!how.submethod_table($!thing) {
      @methods.append: %methods.pairs.sort.map({
           $_.value<> but Identified[$_.key]
        })
    }
  }
  # Must be a better pattern for returning an empty list.
  # return |@a returns a NIL for empty @a
  # Have to see if we really need to do anything...
  ##return Empty unless @methods.elems;
  ##return |@methods.Slip;
  return @methods;
}

#----------------------------------------------------------------------------
#| :all -> include meta, multi, private and submethods.
#| :local -> only those defined in the same package
method methods ( :$all = True, :$local = False ) {

  # Jeff 01-Jan-2023 keep the debug statements in this method.
  my $debug = False;
  say "methods: :all $all :local $local" if $debug;

  my @methods;

  if $!how.?method_table($!thing) {
    # hash-assignment coerces NQP-hash-types into araku hash type
    if my %methods = $!how.method_table($!thing) {
      say "methods: using ^method_table" if $debug;
      @methods.append:
         %methods.pairs.sort.map({
          try { $_.value<> but (Identified[$_.key], Subtyped[''] ) } // $_.value<>;
         });
    }
  }
  else {
    say "methods: no method_table -> using ^methods" if $debug;
    try
    # Roles - e.g. Callable does not have method_table
     @methods.append: $!thing.^methods.map({
          $_ ~~ Pair
            ??  $_.value<> but (Identified[$_.key], Subtyped[''] )
            !! $_<> ;
         });
  }

  # https://github.com/rakudo/rakudo/blob/main/src/Perl6/Metamodel/SubsetHOW.nqp
  # This is the method that enforces the constraint in the Subset.

  # Jeff 01-Jan-2023 try .^refinement is not reliable
  # Weird issue in testing where grok(Any);grok(UInt) shows no methods for UInt (a Subset)
  # but grok(UInt);grok(Any) works as expected.
  # Switching to a Subset smartmatch on .HOW seems to work better.
  {
    say "methods: have .^refinement " if $debug;
    @methods.append( $!thing.^refinement ) ;
  } if $!thing.HOW ~~ Metamodel::SubsetHOW;

  if $all {

    @methods.append:
      |self.methods-meta,
      |self.methods-multi,
      |self.methods-private,
      |self.submethods,
      ;

  }

  say "methods: total: ", @methods.elems if $debug;

  if $local {
    my $package = self.type if self.is-class || self.is-role;
    if $package {
      @methods = @methods.grep({ not ($_.?package.^name ne $package) });
    }
  }

  say "methods: after local prune: ", @methods.elems if $debug;

  # ForeignCode <anon> blocks are difficult to get anything from
  @methods = @methods.grep({
      not ( $_.?name.so and $_.name eq '<anon>' )
    });
  say "methods: after <anon> prune: ", @methods.elems if $debug;

  @methods = @methods.sort({
      # Jeff 01-Jan-2023 Grammar NQP methods have issues
      ($^a.?ident // $^a.?name // '' )  cmp  ($^b.?ident // $^b.?name // '')   or
      ($^a.?signature.gist //'' ) cmp  ($^b.?signature.gist //'' )
    });

  ## Jeff 31-Dec-2022 always an iterable, never a Nil
  #return Empty unless @methods.elems;
  #return |@methods.Slip;
  return @methods;

}

method methods-meta {
  my @methods;
  if $!how.?meta_method_table($!thing) {
    if my %methods = $!how.meta_method_table($!thing) {
      @methods.append: %methods.pairs.sort.map({
           $_.value<> but (Identified[$_.key], Subtyped['meta'] )
        });
    }
  }
  #return @methods.Slip if @methods.elems;
  #return Empty;
  return @methods;

}

#| Specifically for Roles,
#| as .^methods does NOT include multi-methods.
#| Rakudo specific - ParametricRoleGroup.candidates
method methods-multi {
  my @methods;

  if $!how ~~ Metamodel::ParametricRoleGroupHOW {
    my @multis;
    for $!how.candidates($!thing) -> $role {
      push @multis, | $role.^multi_methods_to_incorporate;
    }
    @methods.append: @multis.map({ $_.name => $_.code }).sort.map({
       $_.value<> but (Identified[$_.key], Subtyped['multi'] )
    });
  }

  #return Empty unless @methods.elems;
  #return |@methods.Slip;
  return @methods;
}

method methods-private {
  my @methods;
  if $!how.?private_method_table($!thing) {
    if my %methods = $!how.private_method_table($!thing) {
      @methods.append: %methods.pairs.sort.map({
           $_.value<> but (Identified[$_.key], Subtyped['private'] )
        });
    }
  }
  #return Empty unless @methods.elems;
  #return |@methods.Slip;
  return @methods;
}

method which ( --> Str ) {
  return cleanup-which-name($!thing);
}

method is-role ( --> Bool ) {
  return $!how.^name.contains('Role');
}

method is-core ( --> Bool ) {
  # Jeff 31-Dec-2022 just the base type, ignoring any mixin
  is-core-class( self.type )
}
method not-core ( --> Bool ) {
  return not self.is-core;
}

method is-class ( --> Bool ) {
  return $!thing.HOW ~~ Metamodel::ClassHOW;
}

method not-class ( --> Bool ) {
  return not self.is-class;
}

method is-definite ( --> Bool ) {
  return $!thing.DEFINITE;
}

method raku ( --> Str ) {
  try $!thing.raku;
}

#| Wisp.where shows this as `` 'in ' ~ package' ``
method package ( :$prefix='' --> Str ) {
  return $prefix ~ $!thing.package.^name if try $!thing.package.^name;
  return $prefix ~ self.type if self.is-class or self.is-role;
  return '';
}

method file ( :$prefix='' --> Str ) {
  return $!thing.file.split(' ')[0] ~ ' ' ~ $!thing.line if try $!thing.file;
  return '';
}

method signature ( --> Str ) {
  try { $!thing.signature.gist } // '';
}

method message ( --> Str ) {
  try { $!thing.message } // '';
}

# TODO: hard to probe subs in a module - they are 'my' scopedod module-subs () {
#  # Jeff 31-Dec-2022 not found a way to make this work yet
#
#  $GLOBAL::Foo::barb = 100;
#  say 'barb: ', $GLOBAL::Foo::barb;
#
#  say self.name, ' exports:', self.exports;
#  say self.name, ' knows:', self.knows;
#
#  my $name    = self.name;
#
#
#  &GLOBAL::Foo::get-outers = -> { .say for 'OUTER::.pairs'.EVAL };
#  &GLOBAL::Foo::get-outers();
#
#  #say 'name: ', $Foo::bar;
#  #say $::('GLOBAL::Foo::bar');
#}


|# description - a method that dispatches to multi-subs
method descr () {
  descr( $!thing ) # multi subs
}

# Jeff 01-Jan-2023 type-check multi sub return values
proto sub descr ( Mu $thing --> Str ) {*}

# We end up here if there is no specialisation, so keep the debug
multi sub descr ( Mu $thing ) {

  #my $mop = Grok::Moppet.new( :thing($thing) );
  #say '  # name:      ', $mop.name;
  #say '  # signature: ', $mop.signature;
  #say '  # subtype:   ', $mop.subtype;
  #say '  # type:      ', $mop.type;
  #say '  # supertype: ', $mop.supertype;
  #say '  # package:   ', $mop.package;
  #say '  # file:      ', $mop.file;
  #say '  # methods:   ', $mop.methods(:all);
  #say '  # var-name:  ', $mop.var-name;
  #try say '  # parents:   ', $mop.parents; # BOOTSTRAPATTR barfs here
  #try say '  # roles:     ', $mop.roles;
  #try say '  # gist:      ', $thing.gist;
  #say '  # .^name:    ', $thing.^name;

  # Jeff 01-Jan-2023 Don't know how to multi this.
  return '' if try $thing.^name eq 'BOOTSTRAPATTR';

  return $thing.VAR.raku if try $thing.DEFINITE and $thing.VAR.raku;

  return '';

}

# I think this is ignored in Wisp
multi sub descr ( Metamodel::ClassHOW:D $thing ) {
  'class-descr'
}

multi sub descr ( Pod::Block::Named:D $thing ) {
  '' ~ $thing.contents.elems ~ ' elements ' ~ $thing.config.join(' ');
}

multi sub descr ( Pod::FormattingCode:D $thing ) {
  'type: ' ~ $thing.type
}

multi sub descr ( Pod::Heading:D $thing ) {
  'level ' ~ $thing.level;
}

multi sub descr ( Pod::Block::Para:D $thing ) {
  $thing.contents.join(' ');
}

multi sub descr ( Pod::Block::Declarator:D $thing ) {
  $thing.WHEREFORE.gist;
}

multi sub descr ( Pod::Block::Code:D $thing ) {
  $thing.config<lang>;
}

# Attributes have interesting parts.
# It's a shame there is no standard way of getting traits
multi sub descr ( Attribute:D $thing ) {

  # Jeff 01-Jan-2023 note that .subtype returns the type constraint for an Attribute
  (
    ##$thing.type.^name,
    $thing.?DEPRECATED  ?? 'DEPRECATED: [' ~ $thing.DEPRECATED ~ ']' !! '',
    (
       $thing.?required ~~ Str  ?? 'required: [' ~  $thing.?required ~ ']'
    !! $thing.?required         ?? 'required'
    !! ''
    ),
    $thing.has_accessor ?? 'public'       !! 'private',
    $thing.?rw          ?? 'read-write'   !! 'read-only',
  )
  .grep( *.chars )
  .join(' ')
  ;

}

multi sub descr ( IO::Path:D $thing  ) { $thing.Str }
multi sub descr ( Str:D $thing  ) { $thing.chars ?? $thing.Str !! $thing.raku }
multi sub descr ( CompUnit:D $thing  ) { $thing.short-name }
multi sub descr ( CompUnit::Repository::Distribution:D $x ) { $x.Str }

# No interesting further detail - Wisp does the rest
multi sub descr ( Routine:D $thing      ) {  '' }
multi sub descr ( ForeignCode:D $thing  ) { 'Rakudo-specific' }


method enums {

  # Jeff 01-Jan-2023 the Enumeration class itself fails,
  # but non-DEFINITE classes like Endian do have enums.
  if $!thing ~~ Enumeration  {
    return $!thing.enums.sort({$^a.value <=> $^b.value})
      if try $!thing.enums;
  }

  return Empty;

}

method enum-names {
    return self.enums.map(*.key)
}


method ver ( --> Version ) {
    return $!thing.ver if try $!thing.ver;
    return $!thing.^ver if try $!thing.^ver;
    Nil;
}

# or a Rat?
method api( --> Str ) {
    return $!thing.api if try $!thing.api;
    return $!thing.^api if try $!thing.^api;
    if $!thing.HOW.^name ~~ / RoleGroupHOW / {
        # ParametricRoleGroupHOW is missing the api method.
        return $!thing.^candidates.first.^api if try $!thing.^candidates.first.^api;
    }
    Nil;
}

method auth ( --> Str ) {
    return $!thing.auth if try $!thing.auth;
    return $!thing.^auth if try $!thing.^auth;
    Nil;
}

method archetypes( --> List ) {
    if my $arch = try $!thing.^archetypes {
        my @a;
        @a.append('augmentable')        if $arch.augmentable     ;
        @a.append('coercive')           if $arch.coercive        ;
        @a.append('composable')         if $arch.composable      ;
        @a.append('composalizable')     if $arch.composalizable  ;
        @a.append('definite')           if $arch.definite        ;
        @a.append('generic')            if $arch.generic         ;
        @a.append('inheritable')        if $arch.inheritable     ;
        @a.append('inheritalizable')    if $arch.inheritalizable ;
        @a.append('nominal')            if $arch.nominal         ;
        @a.append('nominalizable')      if $arch.nominalizable   ;
        @a.append('parametric')         if $arch.parametric      ;
        return @a.List;
    }
    Empty;
}

# Haven't actually seen this work yet
method language-version ( --> Str ) {
    return $!thing.^language-version if try $!thing.^language-version;
    return $!thing.HOW.language-version($!thing) if try $!thing.HOW.language-version($!thing);
    Nil;
}



# done
