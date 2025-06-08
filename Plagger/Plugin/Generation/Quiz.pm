package Plagger::Plugin::Generation::Quiz;

use strict;
use warnings;
use base qw( Plagger::Plugin );

# Required for Plagger to recognize this as a plugin
sub register {
    my ($self, $context) = @_;
    # Registering for 'store.entry' to generate quiz after entry is processed
    # and stored. Another option could be 'update.feed.format' if quiz
    # should be part of the feed item itself before storage.
    $context->register_hook(
        $self,
        'store.entry' => \&generate_quiz_for_entry,
    );
}

# Initialize the plugin, load configuration
sub init {
    my $self = shift;
    $self->SUPER::init(); # Call parent's init

    # Example: Load configuration for quiz generation, e.g., number of questions
    $self->{num_questions} = $self->conf->{num_questions} || 3;
    $self->{quiz_difficulty} = $self->conf->{difficulty} || 'medium';

    Plagger->context->log(info => "Quiz plugin initialized. Number of questions: $self->{num_questions}, Difficulty: $self->{quiz_difficulty}");
}

# Generate quiz for a single entry
sub generate_quiz_for_entry {
    my ($self, $context, $args) = @_;
    my $entry = $args->{entry};
    my $feed = $args->{feed};

    my $title = $entry->title || '';
    my $body = $entry->body || '';
    # Remove HTML tags for cleaner text processing
    $body =~ s/<[^>]+>//g;
    $body = substr($body, 0, 500); # Limit body length for quiz generation

    Plagger->context->log(debug => "Generating quiz for entry: " . $title);

    # Placeholder for actual quiz generation logic
    # This would ideally involve some NLP or rule-based system to create questions
    # For now, we'll create some generic questions based on the title
    my @questions;
    for (my $i = 1; $i <= $self->{num_questions}; $i++) {
        push @questions, {
            question => "What is question $i about '$title'?",
            options => ["Option A for '$title'", "Option B for '$title'", "Option C for '$title'"],
            answer => "Option A for '$title'", # Placeholder answer
        };
    }

    if (@questions) {
        # Store quiz data in the entry's meta field
        $entry->meta->{quiz} = \@questions;
        Plagger->context->log(info => "Generated " . scalar(@questions) . " quiz questions for: " . $title);

        # Optionally, modify the entry body to include the quiz
        # my $quiz_html = "<div><h3>Quiz</h3><ul>";
        # foreach my $q (@questions) {
        #     $quiz_html .= "<li>" . $q->{question} . "</li>";
        # }
        # $quiz_html .= "</ul></div>";
        # $entry->body($entry->body . $quiz_html);
    }
}

1;

__END__

=head1 NAME

Plagger::Plugin::Generation::Quiz - Generates quizzes from feed entries.

=head1 SYNOPSIS

  plugins:
    - module: Generation::Quiz
      config:
        num_questions: 5
        difficulty: hard

=head1 DESCRIPTION

This plugin processes feed entries and generates a set of quiz questions
based on their content. The generated quiz is stored in the entry's metadata.

=head1 CONFIGURATION

=over 4

=item num_questions

The number of questions to generate for each entry. Defaults to 3.

=item difficulty

The difficulty level of the quiz. (e.g., easy, medium, hard).
This is a placeholder for future actual difficulty implementation. Defaults to 'medium'.

=back

=head1 AUTHOR

Your Name

=head1 SEE ALSO

L<Plagger::Plugin>

=cut
