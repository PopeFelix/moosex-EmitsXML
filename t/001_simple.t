use strict;
use warnings;

package Product;

use Moose;
use MooseX::EmitsXML;
use namespace::autoclean;
#with 'MooseX::Role::EmitsXML';

has_xml 'description' =>
    ( 'is' => 'ro', 'isa' => 'Str', 'xml_path' => '/Product/DescriptiveInformation/ProductDescription' );
has_xml 'item_number'    => ( 'is' => 'ro', 'isa' => 'Str', 'xml_path' => '/Product/Identifiers/ItemNumber' );
has_xml 'catalog_number' => ( 'is' => 'ro', 'isa' => 'Str', 'xml_path' => '/Product/Identifiers/CatalogNumber' );
has_xml 'upc'            => ( 'is' => 'ro', 'isa' => 'Int', 'xml_path' => '/Product/Identifiers/UPC' );
has_xml 'color'          => ( 'is' => 'ro', 'isa' => 'Str', 'xml_path' => '/Product/DescriptiveInformation/Color' );
has 'that_je_ne_sais_quoi' => ( 'is' => 'ro', 'isa' => 'Str' );

1;

package main;

use Test::Most;
use XML::LibXML;

my %product_args = (
    color                => 'periwinkle',
    upc                  => 1234567890123,
    item_number          => 'THX-1138',
    catalog_number       => 'KP-1652051819',
    description          => q{Oh, yes. It's very nice!},
    that_je_ne_sais_quoi => q{Something French. Or maybe Swahili.},
);
ok my $p = Product->new(%product_args), 'Created instance of class using role';

ok my $xml = $p->to_xml, 'Output XML';

ok my $doc = XML::LibXML->load_xml(string => $xml), 'XML is valid (or at least parseable)';

for my $key (keys %product_args) {
    my $attr = $p->meta->get_attribute($key);
    if ($key ne 'that_je_ne_sais_quoi') {
        ok $attr->can('has_xml_path'), qq{Predicate 'has_xml_path' present for "$key"};
        ok my $path = $attr->xml_path, qq{Got an XML path for "$key"};
        is $doc->findvalue($path), $product_args{$key}, qq{Value of "$key" OK};
    }
}

done_testing;
