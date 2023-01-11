use v6;

use Kaolin::Node;

class Tree is Kaolin::Node {};

my $root = Tree.new('apple');

$root.add-kid( 'pear', :left );
$root.add-kid( 'peach' );
$root.add-kid( 'orange' );

$root.get('pear').add-kid('williams', :left).add-kid('comference');
$root.get('pear').add-kid('poached' );

$root.get('peach').add-kid('soft', :left);
$root.get('peach').add-kid('squishy');
$root.get('peach').add-kid('furry');

$root.get('orange').add-kid('blood');
$root.get('orange').add-kid('seville').add-kid('Spain').add-kid('Europe');

$root.dump;
say $root;
