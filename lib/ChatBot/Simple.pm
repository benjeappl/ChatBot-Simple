package ChatBot::Simple;

use strict;
use warnings;

our $VERSION = '0.01';

require Exporter;

our @ISA = qw/Exporter/;

our @EXPORT = qw/pattern respond transform %mem/;

my %mem;

my (@patterns, @transforms);

sub pattern {
  my ($input, @rest) = @_;

  my $code = ref $rest[0] eq 'CODE' ? shift @rest : undef;

  push @patterns, {
    input  => $input,
    output => [ @rest ],
    code   => $code,
  };
}

# "respond" is just an alias to "pattern"
*respond = \&pattern;

sub transform {
  my (@expr) = @_;

  my $transform_to = pop @expr;

  my $code = ref $expr[-1] eq 'CODE' ? pop @expr : undef;

  for my $exp (@expr) {
    push @transforms, {
      input  => $exp,
      output => $transform_to,
      code   => $code,
    };
  }
}

sub match {
  my ($str, $pattern) = @_;

  my @named_vars = $pattern =~ m{(:\S+)}g;

  # make ":var" match '(\S+)'
  $pattern =~ s{:\S+}{'(\S+)'}ge;

  if ($str =~ m/$pattern/) {
    return {
      $named_vars[0] => $1,
    };
  }

  return;
}

sub replace_vars {
  my ($pattern, $named_vars) = @_;
  for my $var (keys %$named_vars) {
    $pattern =~ s{$var}{$named_vars->{$var}}g;
  }
  return $pattern;
}

sub process_transform {
  my $str = shift;

  for my $tr (@transforms) {
    next unless match($str, $tr->{input});
    warn "Transform code not implemented\n" if $tr->{code};
    return process_transform( $tr->{output} );
  }

  # No transformations found...
  return $str;
}

sub process_pattern {
  my $str = shift;

  for my $pt (@patterns) {
    my $match = match($str, $pt->{input});
    return if !$match;
    warn "Pattern code not implemented\n" if $pt->{code};
    my $response = $pt->{output}->[0]; # TODO: deal with multiple possible responses

    my $response_interpolated = replace_vars($response, $match);

    return $response_interpolated;
  }

  warn "Couldn't find a match for '$str'";
  return;
}

sub process {
  my $str = shift;
  $DB::single=1;
  my $tr  = process_transform($str);
  my $res = process_pattern($tr);
  return $res;
}

sub patterns {
  return \@patterns;
}

sub transforms {
  return \@transforms;
}

1;

__END__

=head1 NAME

ChatBot::Simple - new and flexible chatbot engine in Perl

=head1 SYNOPSIS

  use ChatBot::Simple;

  respond 'hello' => 'hi!';

  respond "what is your name" => "my name is ChatBot::Simple, and yours?";

  respond "my name is :name" => "nice to meet you, :name";

  transform "what's" => "what is";

=head1 DESCRIPTION

ChatBot::Simple is a new and flexible chatbot engine in Perl.

Instead of specifying the chatbot knowledge base in xml, we are
going to use the powerfult text manipulation capabilities of Perl.

=head1 METHODS

=head2 respond

respond is used to register response patterns:

  respond 'hello' => 'hi!';

Multiple (successive) responses:

  respond 'hello' => [ 'hi!', 'I already said hi!' ];

=head2 transform

transform is used to register text normalizations:

  transform "what's" => "what is";
  respond "what is your name" => "my name is ChatBot::Simple";

=head2 process

process will read a sentence, apply all the possible transforms and
patterns, and return a response.

=head1 TODO

There are some powerful features that I'm planning, that will make
ChatBot::Simple much more powerful than any engine I know of.

Named variables:

  respond "my name is :name" => "hello, :name!";

Code execution:

  my %mem;

  respond "my name is :name" => sub {
    # save name for later use
    $mem{name} = param('name');
  } => "nice to meet you, :name!";

  respond "I am :age years old" => sub {
    # save name for later use
    $mem{age} = param('age');
  } => "cool!";

=head1 METHODS

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2013 Nelson Ferraz

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
