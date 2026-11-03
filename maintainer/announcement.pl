#!/usr/bin/env perl
# Generate Automake's complete release announcement for make announcement.
# Copyright (C) 2026 Free Software Foundation, Inc.
# Written by Kamila Szewczyk <szewczyk@cs.uni-saarland.de, k@iczelia.net>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

use strict;
use warnings;
use Digest::SHA;
use File::Spec;
use File::Temp qw(tempfile);

sub setting {
  my ($name) = @_;
  return $ENV{"AM_ANNOUNCE_$name"} // '';
}

sub read_file {
  my ($name) = @_;
  open my $file, '<', $name or die "announcement: cannot read $name: $!\n";
  local $/;
  return <$file>;
}

# List-form execution keeps paths, key IDs and revision names out of a shell.
sub capture {
  my @command = @_;
  open my $pipe, '-|', @command
    or die "announcement: cannot run $command[0]: $!\n";
  local $/;
  my $output = <$pipe> // '';
  close $pipe or die "announcement: $command[0] failed (status $?)\n";
  $output =~ s/\s+\z//;
  return $output;
}

my $version = setting('VERSION');
my $previous = setting('PREVIOUS');
for my $entry (['VERSION', $version], ($previous ne '' ? (['PREVIOUS_VERSION', $previous]) : ())) {
  $entry->[1] =~ /\A[0-9]+(?:\.[0-9]+)+\z/
    or die "announcement: supply a numeric $entry->[0]\n";
}
$previous ne $version or die "announcement: previous and current versions are equal\n";
my $key = uc setting('KEY');
$key eq '' || $key =~ /\A(?:[0-9A-F]{40}|[0-9A-F]{64})\z/
  or die "announcement: supply GPG_KEY_ID as a full public-key fingerprint\n";
my $host = setting('HOST');
$host =~ /\A(?:ftp|alpha)\z/ or die "announcement: invalid download host\n";
my $type = setting('TYPE');
$type =~ /\A(?:major release|minor release|maintenance release|test release|development snapshot)\z/
  or die "announcement: invalid release type\n";
my $srcdir = setting('SRCDIR') || '.';
my @archives = split /\s+/, setting('ARCHIVES');
@archives or die "announcement: no DIST_ARCHIVES configured\n";
my %seen;
for my $archive (@archives) {
  $archive =~ /\Aautomake-\Q$version\E\.(?:tar\.(?:gz|xz|bz2|lz|zst|Z)|zip)\z/
    or die "announcement: unexpected archive name: $archive\n";
  !$seen{$archive}++ or die "announcement: duplicate archive: $archive\n";
  -f $archive && -s $archive
    or die "announcement: missing or empty $archive; build the release archives first\n";
}

my $news = read_file(File::Spec->catfile($srcdir, 'NEWS'));
# Pretests may still use the heading for the upcoming stable release.
$news =~ /\A(.*?^New in [^\n]+\n.*?)(?=^~{3,}|\z)/ms
  or die "announcement: no release section found in NEWS\n";
$news = $1;
$news =~ s/\s+\z//;
my $intro = setting('INTRO') ? read_file(setting('INTRO')) : '';
$intro =~ s/\s+\z//;

my $git = setting('GIT') || 'git';
my @git = ($git, '-C', $srcdir);
my $tag = "v$version";
my @tags = split /\n/, capture(@git, 'tag', '--list', 'v[0-9]*');
my $tagged = scalar grep { $_ eq $tag } @tags;
my $revision = $tagged ? "refs/tags/$tag" : 'HEAD';
my $commit = capture(@git, 'rev-parse', '--verify', "${revision}^{commit}");
$commit =~ /\A[0-9a-f]{40}(?:[0-9a-f]{24})?\z/
  or die "announcement: invalid commit for $revision\n";
my $identity = $tagged
  ? capture(@git, 'for-each-ref', '--format=%(taggername)%00%(taggeremail)',
            "refs/tags/$tag")
  : '';
# Lightweight tags have no tagger; untagged drafts have no tag object.
if ($identity eq '' || $identity eq "\0") {
  $identity = capture(@git, 'show', '-s', '--format=%an%x00%ae', $commit);
}
my ($author_name, $author_email) = split /\0/, $identity, -1;
defined $author_email && $author_name =~ /\A[^\r\n]+\z/
  or die "announcement: cannot determine release author\n";
$author_email =~ s/\A<(.*)>\z/$1/;
$author_email =~ /\A[^\s<>]+\@[^\s<>]+\z/
  or die "announcement: invalid release author email\n";
if ($previous eq '') {
  # Compare against the preceding stable release, not an earlier pretest.
  # Match the stable version convention shared with the release make rules.
  my @stable = grep {
    $_ ne $tag && /^v[1-9][0-9]*\.[0-9]{1,2}(?:\.(?:[0-9]|[0-8][0-9]+))?$/
  } @tags;
  @stable or die "announcement: no stable release tags found; set PREVIOUS_VERSION\n";
  my $found = capture(@git, 'describe', '--tags', '--abbrev=0',
                      (map { ('--match', $_) } @stable), $commit);
  $found =~ /\Av([0-9]+(?:\.[0-9]+)+)\z/
    or die "announcement: no previous release found; set PREVIOUS_VERSION\n";
  $previous = $1;
}
my $oldtag = "v$previous";
my $oldcommit = capture(@git, 'rev-parse', '--verify', "refs/tags/$oldtag^{commit}");
$oldcommit =~ /\A[0-9a-f]{40}(?:[0-9a-f]{24})?\z/
  or die "announcement: invalid commit for $oldtag\n";
my $range = "$oldcommit..$commit";
my @dates = map { capture(@git, 'show', '-s', '--format=%ct', $_) }
  ($oldcommit, $commit);
for my $date (@dates) {
  $date =~ /\A[0-9]+\z/ or die "announcement: invalid release timestamp\n";
}
$dates[1] >= $dates[0] or die "announcement: release predates previous version\n";
my $days = int(($dates[1] - $dates[0]) / 86400);
my $count = capture(@git, 'rev-list', '--count', $range);
$count =~ /\A[0-9]+\z/ or die "announcement: invalid commit count\n";
my @contributors = split /\n/, capture(@git, 'shortlog', '-sn', $range);
my $contributors = '';
for my $line (@contributors) {
  $line =~ /^\s*(\d+)\s+(.+)$/ or die "announcement: invalid contributor entry\n";
  $contributors .= "  $2 ($1)\n";
}
my $people = scalar @contributors;
my $key_instructions = '';
my $gpg = setting('GPG') || 'gpg';
# Use the actual archive signer, rather than guessing from the tagger or
# from GPG's default key configuration. Verify each available signature.
for my $archive (@archives) {
  next unless -f "$archive.sig";
  my $status = capture($gpg, '--batch', '--no-auto-key-retrieve',
                       '--status-fd', '1', '--verify', "$archive.sig", $archive);
  my @valid = $status =~ /^\[GNUPG:\] VALIDSIG (.+)$/mg;
  @valid == 1 or die "announcement: expected one valid signature for $archive\n";
  my @fields = split /\s+/, $valid[0];
  # VALIDSIG's optional final field identifies the primary key when the
  # archive was signed by a subkey. Otherwise use the signing fingerprint.
  my $signer = @fields == 10 ? $fields[9] : $fields[0];
  (@fields == 9 || @fields == 10)
    && $signer =~ /\A(?:[0-9A-F]{40}|[0-9A-F]{64})\z/
    or die "announcement: invalid signing fingerprint for $archive\n";
  $key eq '' || $key eq $signer
    or die "announcement: signing key for $archive differs from the other archives or GPG_KEY_ID\n";
  $key = $signer;
}
if (length $key) {
  my $keys = capture($gpg, '--batch', '--with-colons', '--fingerprint', '--list-keys', $key);
  my ($fingerprint) = $keys =~ /^fpr:[^\n]*?:([0-9A-F]{40}|[0-9A-F]{64}):\s*$/m;
  defined $fingerprint && $fingerprint eq $key
    or die "announcement: GPG did not return the requested primary fingerprint\n";
  my $description = capture($gpg, '--batch', '--fingerprint', '--list-keys', $key);
  $description =~ s/^/  /mg;
  $key_instructions = <<EOF_KEY;
The signature should match the fingerprint of the following key:

$description

If that command fails because you don't have the required public key,
or that public key has expired, try the following command to retrieve
or refresh it, and then rerun the 'gpg --verify' command.

  gpg --recv-keys $key

EOF_KEY
}

my $base = "https://$host.gnu.org/gnu/automake";
my $history_end = $tagged ? $tag : $commit;
my $release_commit = $tagged
  ? "Commit $commit is tagged as $tag."
  : "This draft is based on commit $commit (HEAD).\n"
    . "The release tag $tag does not exist yet; regenerate after tagging\n"
    . "and finalizing the release archives.";
my ($downloads, $signatures, $checksums) = ('', '', '');
my $openssl = setting('OPENSSL') || 'openssl';
for my $archive (@archives) {
  open my $file, '<', $archive or die "announcement: cannot read $archive: $!\n";
  binmode $file;
  my $sha256 = Digest::SHA->new(256)->addfile($file)->hexdigest;
  close $file or die "announcement: cannot close $archive: $!\n";
  my $sha3 = capture($openssl, 'dgst', '-sha3-256', $archive);
  $sha3 =~ /\b([0-9a-fA-F]{64})\z/ or die "announcement: invalid SHA3-256 digest\n";
  $sha3 = lc $1;
  $downloads .= sprintf "  %s/%s (%s bytes)\n", $base, $archive, -s $archive;
  $signatures .= "  $base/$archive.sig\n";
  $checksums .= "  File: $archive\n  SHA256 sum: $sha256\n  SHA3-256 sum: $sha3\n\n";
}
my $recipients = 'autotools-announce@gnu.org, automake@gnu.org, ';
$recipients .= $host eq 'alpha' ? 'platform-testers@gnu.org' : 'info-gnu@gnu.org';
my $body = "To: $recipients\nSubject: automake $version [$type]\n\n";
$body .= "We are pleased to announce GNU Automake $version, a $type.\n\n[...]\n\n";
$body .= "$intro\n\n" if length $intro;
$body .= "There have been $count commits by $people contributors in the $days days\n"
       . "since $previous.\n\n";
$body .= "Thanks to everyone who contributed to this release!\n\n$contributors\n";
$body .= "$author_name ($author_email)\n" . ('=' x 66) . "\n\n";
$body .= <<EOF_BODY;
See below for the detailed list of changes since the
previous version, as summarized by the NEWS file.

Here is the GNU Automake home page:
  https://www.gnu.org/software/automake/

Here are the compressed sources:
$downloads
Here are the GPG detached signatures:
$signatures
Use a mirror for higher download bandwidth:
  https://www.gnu.org/order/ftp.html

Here are the SHA256 and SHA3-256 checksums:

${checksums}Verify SHA256 with sha256sum or 'shasum -a 256'.
Verify SHA3-256 with 'openssl dgst -sha3-256 FILE'.

Use a .sig file to verify that the corresponding file (without the
.sig suffix) is intact. First, be sure to download both the .sig file
and the corresponding tarball. Then, run a command like this:

  gpg --verify $archives[0].sig $archives[0]

${key_instructions}As a last resort to find the key, you can try the official GNU
keyring:

  wget -q https://ftp.gnu.org/gnu/gnu-keyring.gpg
  gpg --keyring ./gnu-keyring.gpg --verify $archives[0].sig $archives[0]

Please report bugs and problems to <bug-automake\@gnu.org> (instead of replying
to this mail), and send general comments and feedback to <automake\@gnu.org>,
and patches to <automake-patches\@gnu.org>.

Thanks to everyone who has reported problems, contributed
patches, and helped test Automake! 

EOF_BODY
if ($host eq 'alpha') {
  $body .= <<'EOF_TEST';
If you install this test release in its own prefix (recommended) and use
Libtool, arrange for its m4 files to be found by aclocal.  See:
https://www.gnu.org/software/automake/manual/automake.html#Libtool-library-used-but-LIBTOOL-is-undefined

EOF_TEST
}
$body .= "Changes from NEWS:\n\n$news\n\n";
$body .= <<EOF_END;
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
This release is based on the Automake Git repository, available as:

  git clone https://https.git.savannah.gnu.org/git/automake.git

$release_commit

For a summary of changes and contributors, see:
https://gitweb.git.savannah.gnu.org/gitweb/?p=automake.git;a=shortlog;h=$history_end

Or run this command from a Git checkout of Automake:

  git shortlog $oldtag..$history_end

EOF_END

# Keep an existing draft intact if any input or external command fails.
my ($output, $temporary) = tempfile('announcement.XXXXXXXX', DIR => '.', UNLINK => 1);
print {$output} $body or die "announcement: cannot write draft: $!\n";
close $output or die "announcement: cannot close draft: $!\n";
rename $temporary, 'announcement' or die "announcement: cannot replace draft: $!\n";
print "Wrote announcement\n";
