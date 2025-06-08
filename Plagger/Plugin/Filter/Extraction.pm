package Plagger::Plugin::Filter::Extraction;

use strict;
use warnings;
use base qw( Plagger::Plugin );

sub register {
    my ($self, $context) = @_;
    $context->register_hook(
        $self,
        'update.feed.fixup' => \&filter,
    );
}

sub init {
    my $self = shift;
    $self->SUPER::init();

    # Configuration for what to extract
    # Example: extract content based on a regex pattern
    $self->{extraction_pattern} = $self->conf->{pattern};
    $self->{extraction_field_name} = $self->conf->{field_name} || 'extracted_content';

    unless ($self->{extraction_pattern}) {
        Plagger->context->error("Extraction pattern 'pattern' is required for Filter::Extraction plugin.");
    }
    Plagger->context->log(info => "Extraction plugin initialized. Pattern: '$self->{extraction_pattern}', Field: '$self->{extraction_field_name}'");
}

sub filter {
    my ($self, $context, $args) = @_;
    my $feed = $args->{feed};

    for my $entry (@{$feed->entries}) {
        $self->process_entry($entry);
    }
}

sub process_entry {
    my ($self, $entry) = @_;
    my $body = $entry->body || '';
    my $title = $entry->title || '';
    my $text_to_search = $body . " " . $title; # Search in both body and title

    my @extracted_values;
    while ($text_to_search =~ m/$self->{extraction_pattern}/g) {
        # Assuming the pattern contains a capturing group for the desired content
        if ($1) {
            push @extracted_values, $1;
        }
    }

    if (@extracted_values) {
        # Store extracted data in the entry's meta field
        # If multiple values, store as array; if single, store as scalar
        my $current_extracted = $entry->meta->{$self->{extraction_field_name}};
        if (defined $current_extracted) {
            # If field already exists, merge (e.g. if other plugin also writes to it)
            # This basic example will just overwrite or append, depending on type
            if (ref $current_extracted eq 'ARRAY') {
                push @$current_extracted, @extracted_values;
            } else {
                # Convert to array if it was a scalar and now we have more
                $entry->meta->{$self->{extraction_field_name}} = [$current_extracted, @extracted_values];
            }
        } else {
            $entry->meta->{$self->{extraction_field_name}} = \@extracted_values;
        }
        Plagger->context->log(info => "Extracted " . scalar(@extracted_values) . " item(s) for entry: " . $entry->title . " into meta field '" . $self->{extraction_field_name} . "'");
    } else {
        Plagger->context->log(debug => "No content extracted for entry: " . $entry->title . " with pattern '" . $self->{extraction_pattern} . "'");
    }
}

1;

__END__

=head1 NAME

Plagger::Plugin::Filter::Extraction - Extracts information from feed entries.

=head1 SYNOPSIS

  plugins:
    - module: Filter::Extraction
      config:
        pattern: 'ISBN:\s*(\d{10}|\d{13})' # Example: Extract ISBN numbers
        field_name: 'isbn_numbers'

=head1 DESCRIPTION

This plugin filters feed entries and extracts specific information based on
a regular expression pattern. The extracted information is stored in the
entry's metadata under a specified field name.

=head1 CONFIGURATION

=over 4

=item pattern (required)

A Perl regular expression used to find and extract information.
It is recommended to use a capturing group in your regex to specify
what part of the match should be extracted. The content of the first
capturing group C<($1)> will be extracted.

=item field_name

The name of the metadata field where the extracted content will be stored.
Defaults to 'extracted_content'. If multiple matches are found, they will
be stored as an array.

=back

=head1 AUTHOR

Your Name

=head1 SEE ALSO

L<Plagger::Plugin>

=cut
