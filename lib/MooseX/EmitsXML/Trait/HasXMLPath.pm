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

no Moose::Role;
1;

