use v6;

#| A simple class identifying the nature of its content/descendants.
class Kaolin::Cargo is export(:Cargo) {
    has $.name      is required;
    has $.thing     ;
    has $.descr     ;   # Optional description -> ends up in @!content
    has @.values    ;   # array of pairs - hashlike, but has an order, -or- things
    has @.parts     ;   # array of things to grok

    # .descr is fine as an empty string.
    submethod TWEAK {
        $!descr //= $!thing ?? $!thing.gist !! '';
    }

    # e.g. Cargo.new( 'Methods', :values($mop.methods) )
    multi method new ( Str:D $name, |args ) {
        self.bless(:name($name),|args);
    }

    method gist { $!name ~ ( $!thing ?? ' - ' ~ $!thing.^name !! '') }

}