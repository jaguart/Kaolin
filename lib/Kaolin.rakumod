use v6;

unit class Kaolin;

# [![Version](https://raku.land/zef:jaguart/Grok/badges/version)](https://raku.land/zef:jaguart)

=begin pod

[![Actions Status](https://github.com/jaguart/Kaolin/actions/workflows/test.yml/badge.svg)](https://github.com/jaguart/Kaolin/actions)


=head1 NAME

Kaolin - reusable components for Raku

=head1 SYNOPSIS

=begin code :lang<raku>

use Kaolin::File;
my $dir = '.'.IO but Kaolin::File::Finder;
.Str.say for $dir.find(:recursive);

my $dir = '.'.IO but (Kaolin::File::Finder, Kaolin::File::Namer);
.Str.say for $dir.find(:recursive).grep({$_.basename ne $_.basename-clean});
.fix-basename.Str.say for $dir.find.grep({$_.basename ne $_.basename-clean});


=end code

=head1 DESCRIPTION

Kaolin is a collection of reusable components.

=head2 Kaolin

B<Kaolin> - A fine white clay used in the manufacture of porcelain.

Origin: 1720–30; ←French ←Chinese (Wade-Giles) Kao1ling3, (pinyin). Gāolǐng mountain in Jiangxi
province that yielded the first kaolin sent to Europe (gāo high + lǐng hill)


=head1 AUTHOR

Jeff Armstrong <jeff@jaguart.tech>

Source can be found at: https://github.com/jaguart/Kaolin

Issues, Comments and Pull Requests are welcome.


=head1 COPYRIGHT AND LICENSE

Copyright 2023 Jeff Armstrong

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
