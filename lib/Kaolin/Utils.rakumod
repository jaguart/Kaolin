use v6.d+;

use nqp;

unit module Kaolin::Utils;

#------------------------------------------------------------------------------
#| Convert an nqp BOOTContext into Raku-land Hash - for CompUnit.handle.unit
our sub BOOTContext-to-Hash(Mu \context --> Hash )
    is export(:BOOTContext-to-hash) {
    my $hash := nqp::hash;
    my \iterator := nqp::iterator(context);
    nqp::while(
      iterator,
      nqp::bindkey(
        $hash,
        nqp::iterkey_s(nqp::shift(iterator)),
        nqp::iterval(iterator)
      )
    );
    #note context.^name ~ '(' ~ nqp::substr(nqp::hllize($hash).raku.chop,1) ~ ')';
    #$hash;
    #say context.^name;
    nqp::hllize($hash)
}

#------------------------------------------------------------------------------
our sub CompUnit-from-file ( IO::Path:D $file --> CompUnit )
    is export(:CompUnit-from-file)
    {

    # irc: <nine> $*REPO might be better
    # Jeff 08-Jan-2023 and hoorah, no global name clash :)
    # ...because... it returns THE EXISTING UNIT IF ALREADY LOADED :)
    #
    # rakudo/src/core.c/Process.pm6 70
    # rakudo/src/core.c/CompUnit/RepositoryRegistry.pm6 125 -
    #   $next-repo := CompUnit::Repository::AbsolutePath.new(
    #       :next-repo(CompUnit::Repository::NQP.new(
    #           :next-repo(CompUnit::Repository::Perl5.new(
    #   #?if jvm
    #           :next-repo(CompUnit::Repository::JavaRuntime.new)
    # rakudo/src/core.c/CompUnit/Repository/FileSystem.pm6 150 <--
    #BOOTContext( $*REPO.load( $file.IO ).unit );   # CompUnit::Handle
    $*REPO.load( $file.IO );  # CompUnit
}

#sub is-type-class ( Mu $o --> Bool ) is export(:is-type-class) {
#  return False if $o.DEFINITE;
#  return True if $o.HOW.^name.contains('ClassHOW');
#  return False;
#}

sub is-core-class ( Mu $o is raw --> Bool ) is export(:is-core-class) {

    my $cwn = cleanup-which-name($o);
    #say $cwn.raku, ' ', $o.WHICH, $o.WHICH.gist, $o.WHAT, $o.WHERE, $o.raku.substr(0,80);

    # Jeff 01-Jan-2023 Grammar has a .WHICH.Str of Str|NQPMatchRole

    return True if $cwn.starts-with('NQP');
    return True if $cwn.starts-with('Per;6::');

    # Jeff 01-Jan-2023 Grammar and Match have an issue with this
    return True if CORE::{$cwn}:exists;
    #say $cwn.raku, ' not in CORE::';

    return False;
}

sub is-package ( Mu $o is raw --> Bool ) is export(:is-package) {
    ($o.HOW.^name ~~ / ModulesHOW | PackageHOW /).so;
}

sub is-class ( Mu $o is raw --> Bool ) is export(:is-class) {
    ($o.HOW.^name ~~ / ClassHOW /).so;
}

sub is-role ( Mu $o is raw --> Bool ) is export(:is-role) {
    ($o.HOW.^name ~~ / Role /).so;
}

sub cleanup-mop-name ( Str $name is copy --> Str ) is export(:cleanup-mop-name) {
    $name  = $name.split('+')[0];
    $name  .=subst('Perl6::Metamodel::', '');
    $name  .=subst('ClassHOW', 'Class');
    $name  .=chop(3) if $name.ends-with('HOW');
    $name   = 'Role' if $name eq 'ParametricRoleGroup';
    return $name;
}

sub cleanup-which-name ( Mu $o --> Str ) is export(:cleanup-which-name) {

    #my $name = $o ~~ Str:D ?? $o.Str !! $o.?WHICH.gist // '';
    my $name = $o.?WHICH.gist // '';
    return '' if $name eq 'Nil';  # e.g. no .WHICH for KnowHOW

    # e.g. Method+{<anon|1>}+{Kaolin::Moppet::Identified[Str],Kaolin::Moppet::Subtyped[Str]}
    $name = $name.subst('Kaolin::Moppet::Subtyped[Str]','');
    $name = $name.subst('Kaolin::Moppet::Identified[Str]','');
    $name = $name.subst('+{,}|','|');

    #return $name.split(/ \| U ? <digit> + $ /)[0];
    return $name.split('|')[0];
}

#| Pad left and right, but only for content, otherwise empty string.
#| :l(' ') - left padding
#| :r(' ') - right padding
sub pad-lr ( Str $what, :$l=' ', :$r=' ' --> Str ) is export(:pad-lr) {
    $what.so ?? $l ~ $what ~ $r !! ''
}

#| Header line with embedded description, fixed width
#| $description
#| :w(80) - width
sub header-line ( Str $descr = '', :$w=80 --> Str ) is export(:header-line) {
    ('--' ~ pad-lr($descr) ~ '-' x 78).substr(0,$w)
}

