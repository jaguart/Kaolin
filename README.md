[![Actions Status](https://github.com/jaguart/Kaolin/actions/workflows/test.yml/badge.svg)](https://github.com/jaguart/Kaolin/actions)

NAME
====

Kaolin - reusable components for Raku

SYNOPSIS
========

```raku
use Kaolin::File;
my $dir = '.'.IO but Kaolin::File::Finder;
.Str.say for $dir.find(:recursive);

my $dir = '.'.IO but (Kaolin::File::Finder, Kaolin::File::Namer);
.Str.say for $dir.find(:recursive).grep({$_.basename ne $_.basename-clean});
.fix-basename.Str.say for $dir.find.grep({$_.basename ne $_.basename-clean});
```

DESCRIPTION
===========

Kaolin is a collection of reusable components.

Kaolin
------

**Kaolin** - A fine white clay used in the manufacture of porcelain.

Origin: 1720–30; ←French ←Chinese (Wade-Giles) Kao1ling3, (pinyin). Gāolǐng mountain in Jiangxi province that yielded the first kaolin sent to Europe (gāo high + lǐng hill)

AUTHOR
======

Jeff Armstrong <jeff@jaguart.tech>

Source can be found at: https://github.com/jaguart/Kaolin

Issues, Comments and Pull Requests are welcome.

COPYRIGHT AND LICENSE
=====================

Copyright 2023 Jeff Armstrong

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

