package MooseX::EmitsXML::Trait::HasXMLPath;

use Moose::Role;

has xml_path => (
    'is' => 'ro',
    'isa' => 'Str',
    'predicate' => 'has_xml_path',
);

has 'namespace' => (
    'is' => 'ro',
    'isa' => 'Str',
    'predicate' => 'has_namespace',
);

has 'cdata' => (
    'is' => 'ro',
    'isa' => 'Bool',
    'predicate' => 'has_cdata',
);

package MooseX::EmitsXML::Role::ToXML;

our $VERSION = '0.01';

use Moose::Role;
use namespace::autoclean;
use XML::LibXML;
use Moose::Exporter;

sub to_xml {
    my ( $self, @args ) = @_;

    my $doc = XML::LibXML::Document->new(); 
    
    for my $attr ( map { $self->meta->get_attribute($_) } $self->meta->get_attribute_list ) {
        my $reader = $attr->get_read_method;
        if ( $attr->does('MooseX::EmitsXML::Trait::HasXMLPath') && $attr->has_xml_path ) {
            my $val      = $self->$reader();
            my $path     = $attr->xml_path;
            my @elements = split /\//, $path;

            if ( $path =~ /^\// ) {    # Throw away blank
                shift @elements;
            }

            my $previous;
            while ( my $element = shift @elements ) {
                my $node;
                my $attrs = _extract_attrs($element);
                ( my $node_name = $element ) =~ s/\[.+?\]//g;

                if ( !$previous ) {
                    if ( !$doc->documentElement ) {
                        $doc->setDocumentElement( XML::LibXML::Element->new($node_name) );
                        for my $key ( keys %{$attrs} ) {
                            $doc->documentElement->setAttribute( $key, $attrs->{$key} );
                        }
                    }
                    else {
                        my $root1 = $doc->documentElement->nodeName;
                        my $root2 = $element;

                        if ( $root1 ne $root2 ) {
                            die qq{MISMATCH! Root elements do not match: "$root1" <> "$root2"};
                        }
                    }
                    $node = $doc->documentElement;
                }
                else {
                    ($node) = @{ $previous->find(qq{./$element}) };

                    if ( !$node ) {
                        $node = XML::LibXML::Element->new($node_name);
                        for my $key ( keys %{$attrs} ) {
                            $node->setAttribute( $key, $attrs->{$key} );
                        }
                        $previous->addChild($node);
                    }
                }
                $previous = $node;
            }

            # $previous has become the leaf here
            $previous->appendText($val);
        }
    }

    return "$doc";
}

sub _extract_attrs {
    my $element = shift;

    my @attr_strings = ($element =~ m/(\[.+?\])/); # Capture everything between [ and ].
    if (scalar @attr_strings > 1) {
        die q{Invalid attribute specification. Specify multiple attrs as [@attr1=val1,@attr2=val2]};
    }
    my %attrs;
    if (@attr_strings) {
        for my $string (split /,/, $attr_strings[0]) {
            my ($key, $val) = ($string =~ m/\[@?\s*(\w+)\s*=\s*"(\w+)"\s*\]/);

            if (!$key) {
                die qq{Malformed attribute specification: "$string". Should be [key="value"] (DOUBLE QUOTES MANDATORY)\n};
            }
            if (exists $attrs{$key}) {
                warn qq{Duplicate key "$key" in attrs};
            }
            $attrs{$key} = $val;
        }
    }
    return \%attrs;
}
no Moose::Role;

1;

package MooseX::EmitsXML;

use Moose::Exporter;

sub has_xml {
    my ($meta, $attr_name, %opts) = @_;
    $opts{'traits'} ||= [];
    push @{$opts{'traits'}}, 'MooseX::EmitsXML::Trait::HasXMLPath';
    $meta->add_attribute($attr_name, %opts);
}

Moose::Exporter->setup_import_methods(
    with_meta       => [qw(has_xml)],
    base_class_roles => [qw(MooseX::EmitsXML::Role::ToXML)],
);


__END__

=pod

=head1 NAME 

MooseX::EmitsXML

=head1 DESCRIPTION

A Moose extension to allow your class to easily generate an XML document with arbitrary structure.

The idea behind this class it to allow you to quickly generate arbitrarily complex XML documents 
without an XML schema and without creating an arbitrary Perl data structure that mimics the 
aforementioned XML document, and without the expectation that you will be able to parse the XML
document back into an identical instance of this object.  Think of it as a one-way map between a 
Moose object and an XML document.

=head1 SYNOPSIS

    package Product;

    use Moose;
    use MooseX::EmitsXML;
    use namespace::autoclean;

    has_xml 'description' => (
        'is'       => 'ro',
        'isa'      => 'Str',
        'xml_path' => '/Product/DescriptiveInformation/ProductDescription'
    );
    has_xml 'item_number' => (
        'is'       => 'ro',
        'isa'      => 'Str',
        'xml_path' => '/Product/Identifiers/ItemNumber'
    );
    has_xml 'catalog_number' => (
        'is'       => 'ro',
        'isa'      => 'Str',
        'xml_path' => '/Product/Identifiers/CatalogNumber'
    );
    has_xml 'upc' => (
        'is'       => 'ro',
        'isa'      => 'Int',
        'xml_path' => '/Product/Identifiers/UPC'
    );
    has_xml 'color' => (
        'is'       => 'ro',
        'isa'      => 'Str',
        'xml_path' => '/Product/DescriptiveInformation/Color'
    );
    has 'that_je_ne_sais_quoi' => (
        'is'  => 'ro',
        'isa' => 'Str'
    );

    1;

=head1 METHODS

=over 4

=item B<to_xml>

Create an XML representation of the object's state, but B<only> for those attributes that have 
'xml_path' defined. In the example above, everything but $product->that_je_ne_sais_quoi will be 
output in the XML document.

=item B<has_xml>

Use this like you would 'has' in L<Moose>.  You can add the 'xml_path' option, which allows you 
to specify the location in the output XML document for the value of that attribute.  This is (or
is meant to be) an XPath 1.0 query, so you can specify attribute names in the path using 
/Path/To[@attribute="value"]/Your/Thing.

=back

=head1 NAMESPACE SUPPORT

Coming Real Soon Now.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please or add the bug to cpan-RT
at L<https://rt.cpan.org/Dist/Display.html?Queue=MooseX-EmitsXML>.

=cut

