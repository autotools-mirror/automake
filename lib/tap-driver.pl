#! /usr/bin/env perl
# Temporary/experimental TAP test driver for Automake.
# TODO: should be rewritten portably (e.g., in awk or shell).

# ---------------------------------- #
#  Imports, static data, and setup.  #
# ---------------------------------- #

use warnings FATAL => 'all';
use strict;
use Getopt::Long ();
use TAP::Parser;

my $ME = "tap-driver.pl";

my $USAGE = <<'END';
Usage:
  tap-driver --test-name=NAME --log-file=PATH --trs-file=PATH
             [--expect-failure={yes|no}] [--color-tests={yes|no}]
             [--enable-hard-errors={yes|no}] [--ignore-exit]
             [--diagnostic-string=STRING] [--merge|--no-merge]
             [--comments|--no-comments] [--] TEST-COMMAND
The `--test-name', `--log-file' and `--trs-file' options are mandatory.
END

my $HELP = "$ME: TAP-aware test driver for Automake testsuite harness." .
           "\n" . $USAGE;

my $VERSION = '(experimental version)';

# Keep this in sync with `lib/am/check.am:$(am__tty_colors)'.
my %COLOR = (
  red => "\e[0;31m",
  grn => "\e[0;32m",
  lgn => "\e[1;32m",
  blu => "\e[1;34m",
  mgn => "\e[0;35m",
  brg => "\e[1m",
  std => "\e[m",
);

# It's important that NO_PLAN evaluates "false" as a boolean.
use constant NO_PLAN => 0;
use constant EARLY_PLAN => 1;
use constant LATE_PLAN => 2;

# ------------------- #
#  Global variables.  #
# ------------------- #

my $testno = 0;     # Number of test results seen so far.
my $bailed_out = 0; # Whether a "Bail out!" directive has been seen.
my $parser;         # TAP parser object (will be initialized later).

# Whether the TAP plan has been seen or not, and if yes, which kind
# it is ("early" is seen before any test result, "late" otherwise).
my $plan_seen = NO_PLAN;

# ----------------- #
#  Option parsing.  #
# ----------------- #

my %cfg = (
  "color-tests" => 0,
  "expect-failure" => 0,
  "merge" => 0,
  "comments" => 0,
  "ignore-exit" => 0,
);

my $test_script_name = undef;
my $log_file = undef;
my $trs_file = undef;
my $diag_string = "#";

Getopt::Long::GetOptions (
    'help' => sub { print $HELP; exit 0; },
    'version' => sub { print "$ME $VERSION\n"; exit 0; },
    'test-name=s' => \$test_script_name,
    'log-file=s' => \$log_file,
    'trs-file=s' => \$trs_file,
    'color-tests=s'  => \&bool_opt,
    'expect-failure=s'  => \&bool_opt,
    'enable-hard-errors=s' => sub {}, # No-op.
    'diagnostic-string=s' => \$diag_string,
    'comments' => sub { $cfg{"comments"} = 1; },
    'no-comments' => sub { $cfg{"comments"} = 0; },
    'merge' => sub { $cfg{"merge"} = 1; },
    'no-merge' => sub { $cfg{"merge"} = 0; },
    'ignore-exit' => sub { $cfg{"ignore-exit"} = 1; },
  ) or exit 1;

# ------------- #
#  Prototypes.  #
# ------------- #

sub add_test_result ($);
sub bool_opt ($$);
sub colored ($$);
sub copy_in_global_log ();
sub decorate_result ($);
sub extract_tap_comment ($);
sub get_global_test_result ();
sub get_test_exit_message ();
sub get_test_results ();
sub handle_tap_bailout ($);
sub handle_tap_plan ($);
sub handle_tap_test ($);
sub main (@);
sub must_recheck ();
sub report ($;$);
sub start (@);
sub stringify_test_result ($);
sub testsuite_error ($);
sub write_test_results ();
sub yn ($);

# -------------- #
#  Subroutines.  #
# -------------- #

sub bool_opt ($$)
{
  my ($opt, $val) = @_;
  if ($val =~ /^(?:y|yes)\z/i)
    {
      $cfg{$opt} = 1;
    }
  elsif ($val =~ /^(?:n|no)\z/i)
    {
      $cfg{$opt} = 0;
    }
  else
    {
      die "invalid argument '$val' for option '$opt'\n";
    }
}

# Convert a boolean to a "yes"/"no" string.
sub yn ($)
{
  my $bool = shift;
  return $bool ? "yes" : "no";
}

TEST_RESULTS :
{
  my (@test_results, %test_results);

  sub add_test_result ($)
  {
    my $res = shift;
    push @test_results, $res;
    $test_results{$res} = 1;
  }

  sub get_test_results ()
  {
    return @test_results;
  }

  # Whether the test script should be re-run by "make recheck".
  sub must_recheck ()
  {
    return grep { !/^(?:XFAIL|PASS|SKIP)$/ } (keys %test_results);
  }

  # Whether the content of the log file associated to this test should
  # be copied into the "global" test-suite.log.
  sub copy_in_global_log ()
  {
    return grep { not $_ eq "PASS" } (keys %test_results);
  }

  # FIXME: this can certainly be improved ...
  sub get_global_test_result ()
  {
    my @results = keys %test_results;
    return "ERROR" if exists $test_results{"ERROR"};
    return "SKIP" if @results == 1 && $results[0] eq "SKIP";
    return "FAIL" if exists $test_results{"FAIL"};
    return "FAIL" if exists $test_results{"XPASS"};
    return "PASS";
  }

}

sub write_test_results ()
{
  open RES, ">", $trs_file or die "opening $trs_file: $!\n";
  print RES ":global-test-result: " . get_global_test_result . "\n";
  print RES ":recheck: " . yn (must_recheck) . "\n";
  print RES ":copy-in-global-log: " . yn (copy_in_global_log) . "\n";
  foreach my $result (get_test_results)
    {
      print RES ":test-result: $result\n";
    }
  close RES or die "closing $trs_file: $!\n";
}

sub start (@)
{
  # Redirect stderr and stdout to a temporary log file.  Save the
  # original stdout stream, since we need it to print testsuite
  # progress output.
  open LOG, ">", $log_file or die "opening $log_file: $!\n";
  open OLDOUT, ">&STDOUT" or die "duplicating stdout: $!\n";
  open STDOUT, ">&LOG" or die "redirecting stdout: $!\n";
  open STDERR, ">&LOG" or die "redirecting stderr: $!\n";
  $parser = TAP::Parser->new ({ exec => \@_, merge => $cfg{merge} });
  $parser->ignore_exit(1) if $cfg{"ignore-exit"};
}

sub get_test_exit_message ()
{
  my $wstatus = $parser->wait;
  # Watch out for possible internal errors.
  die "couldn't get the exit ststus of the TAP producer"
    unless defined $wstatus;
  # Return an undefined value if the producer exited with success.
  return unless $wstatus;
  # Otherwise, determine whether it exited with error or was terminated
  # by a signal.
  use POSIX qw (WIFEXITED WEXITSTATUS WIFSIGNALED WTERMSIG);
  if (WIFEXITED ($wstatus))
	{
      return sprintf "exited with status %d", WEXITSTATUS ($wstatus);
	}
  elsif (WIFSIGNALED ($wstatus))
	{
      return sprintf "terminated by signal %d", WTERMSIG ($wstatus);
	}
  else
	{
	  return "terminated abnormally";
	}
}

sub stringify_test_result ($)
{
  my $result = shift;
  my $PASS = $cfg{"expect-failure"} ? "XPASS": "PASS";
  my $FAIL = $cfg{"expect-failure"} ? "XFAIL": "FAIL";
  if ($result->is_unplanned
       || $result->number != $testno
       || $plan_seen == LATE_PLAN)
    {
      return "ERROR";
    }
  elsif (!$result->directive)
    {
      return $result->is_ok ? $PASS: $FAIL;
    }
  elsif ($result->has_todo)
    {
      return $result->is_actual_ok ? "XPASS" : "XFAIL";
    }
  elsif ($result->has_skip)
    {
      return $result->is_ok ? "SKIP" : $FAIL;
    }
  die "INTERNAL ERROR"; # NOTREACHED
}

sub colored ($$)
{
  my ($color_name, $text) = @_;
  return  $COLOR{$color_name} . $text . $COLOR{'std'};
}

sub decorate_result ($)
{
  my $result = shift;
  return $result unless $cfg{"color-tests"};
  my %color_for_result =
    (
      "ERROR" => 'mgn',
      "PASS"  => 'grn',
      "XPASS" => 'red',
      "FAIL"  => 'red',
      "XFAIL" => 'lgn',
      "SKIP"  => 'blu',
    );
  if (my $color = $color_for_result{$result})
    {
      return colored ($color, $result);
    }
  else
    {
      return $result; # Don't colorize unknown stuff.
    }
}

sub report ($;$)
{
  my ($msg, $result, $explanation) = (undef, @_);
  if ($result =~ /^(?:X?(?:PASS|FAIL)|SKIP|ERROR)/)
    {
      $msg = ": $test_script_name";
      add_test_result $result;
    }
  elsif ($result eq "#")
    {
      $msg = " $test_script_name:";
    }
  else
    {
      die "INTERNAL ERROR"; # NOTREACHED
    }
  $msg .= " $explanation" if defined $explanation;
  $msg .= "\n";
  # Output on console might be colorized.
  print OLDOUT decorate_result ($result) . $msg;
  # Log the result in the log file too, to help debugging (this is
  # especially true when said result is a TAP error or "Bail out!").
  print $result . $msg;
}

sub testsuite_error ($)
{
  report "ERROR", "- $_[0]";
}

sub handle_tap_test ($)
{
  $testno++;
  my $test = shift;

  my $test_result = stringify_test_result $test;
  my $string = $test->number;
  
  if (my $description = $test->description)
    {
      $string .= " $description";
    }

  if ($plan_seen == LATE_PLAN)
    {
      $string .= " # AFTER LATE PLAN";
    }
  elsif ($test->is_unplanned)
    {
      $string .= " # UNPLANNED";
    }
  elsif ($test->number != $testno)
    {
      $string .= " # OUT-OF-ORDER (expecting $testno)";
    }
  elsif (my $directive = $test->directive)
    {
      $string .= " # $directive";
      if (my $explanation = $test->explanation)
        {
          $string .= " $explanation";
        }
    }

  report $test_result, $string;
}

sub handle_tap_plan ($)
{
  my $plan = shift;
  if ($plan_seen)
    {
      # Error, only one plan per stream is acceptable.
      testsuite_error "multiple test plans";
      return;
    }
  # The TAP plan can come before or after *all* the TAP results; we speak
  # respectively of an "early" or a "late" plan.  If we see the plan line
  # after at least one TAP result has been seen, assume we have a late
  # plan; in this case, any further test result seen after the plan will
  # be flagged as an error.
  $plan_seen = ($testno >= 1 ? LATE_PLAN : EARLY_PLAN);
  # If $testno > 0, we have an error ("too many tests run") that will be
  # automatically dealt with later, so don't worry about it here.  If
  # $plan_seen is true, we have an error due to a repeated plan, and that
  # has already been dealt with above.  Otherwise, we have a valid "plan
  # with SKIP" specification, and should report it as a particular kind
  # of SKIP result.
  if ($plan->directive && $testno == 0)
    {
      my $explanation = $plan->explanation ?
                        "- " . $plan->explanation : undef;
      report "SKIP", $explanation;
    }
}

sub handle_tap_bailout ($)
{
  my ($bailout, $msg) = ($_[0], "Bail out!");
  $bailed_out = 1;
  $msg .= " " . $bailout->explanation if $bailout->explanation;
  testsuite_error $msg;
}

sub extract_tap_comment ($)
{
  local $_ = shift;
  if (/^\Q$diag_string\E(.*)$/o)
    {
      (my $comment = $1) =~ s/(?:^\s*|\s*$)//g;
      return $comment;
    }
  return "";
}

sub main (@)
{
  start @_;

  while (defined (my $cur = $parser->next))
    {
      # Verbatim copy any input line into the log file.
      print $cur->raw . "\n";
      # Parsing of TAP input should stop after a "Bail out!" directive.
      next if $bailed_out;

      if ($cur->is_plan)
        {
          handle_tap_plan ($cur);
        }
      elsif ($cur->is_test)
        {
          handle_tap_test ($cur);
        }
      elsif ($cur->is_bailout)
        {
          handle_tap_bailout ($cur);
        }
      elsif ($cfg{comments})
        {
          my $comment = extract_tap_comment ($cur->raw);
          report "#", "$comment" if length $comment;
       }
    }
  # A "Bail out!" directive should cause us to ignore any following TAP
  # error, as well as a non-zero exit status from the TAP producer.
  if (!$bailed_out)
    {
      if (!$plan_seen)
      {
        testsuite_error "missing test plan";
      }
    elsif ($parser->tests_planned != $parser->tests_run)
      {
        my ($planned, $run) = ($parser->tests_planned, $parser->tests_run);
        my $bad_amount = $run > $planned ? "many" : "few";
        testsuite_error (sprintf "too %s tests run (expected %d, got %d)",
                                 $bad_amount, $planned, $run);
      }
    }
  if (!$cfg{"ignore-exit"} && !$bailed_out)
  {
    my $msg = get_test_exit_message ();
    testsuite_error $msg if $msg;
  }
  write_test_results;
  close LOG or die "closing $log_file: $!\n";
  exit 0;
}

# ----------- #
#  Main code. #
# ----------- #

main @ARGV;

# vim: ft=perl ts=4 sw=4 et
