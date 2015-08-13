package MooseX::EmitsXML::Role::ToXML;

our $VERSION = '0.01';

use Moose::Exporter;
use Moose::Role;
use MooseX::EmitsXML::Trait::HasXMLPath;
use namespace::autoclean;
use XML::LibXML;

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

