#!/usr/bin/perl -w

use strict;
use File::Spec;
use File::Path(qw(make_path));
use File::Basename;
my $hasReflow = eval {
    require Text::Reflow;
    Text::Reflow->import(qw(reflow_string));
    1;
};

sub printUsage {
    print STDERR "Usage: $0 <clean|smudge> <sentence|paragraph|wrap n>\n\nAvailable formats:\n    sentence: print one sentence per line\n    paragraph: print one paragraph per line\n    wrap: wrap each line at the given number of columns n\n\n";
    while (<>) { print; }
    exit;
}

my $backupfile;
my $action = shift or printUsage();
if ($action ne "clean" and $action ne "smudge" and $action ne "test") {
    printUsage();
}

my $rule = shift or printUsage();
if ($rule eq "wrap") {
    my $n = shift ;
    if (!$n) {
        print STDERR "The 'wrap' strategy needs the number of columns as the second argument.\n";
        printUsage();
    }
    if (!$hasReflow) {
        print STDERR "The 'wrap' strategy needs the perl module Text::Reflow, which is not installed on this system.\n";
        printUsage();
    }
    $Text::Reflow::optimum = int($n)-5;
    $Text::Reflow::maximum = int($n);
    print $Text::Reflow::optimum if 0; # suppresses warning
    print $Text::Reflow::maximum if 0; # suppresses warning
    #$Text::Reflow::noreflow = '(\\\\cite|\\\\mbox)';
} elsif($rule ne "sentence" and $rule ne "paragraph") {
    print STDERR "Unknown strategy " . $rule . ". Available rules are: sentence, paragraph, wrap.\n\n";
    printUsage();
}

if ($action ne "test") {
  my (undef, $path) = fileparse(File::Spec->rel2abs($0));
  make_path(File::Spec->catdir(($path, "backup")));
  open($backupfile, ">", File::Spec->catfile(($path, "backup"), sprintf("%s-%d-%04d.bak", $action, time(), int(rand(1000)))));
}

my $docollect = 0;
my $doprint = 1;
my $doformat = 0;
my $text = "";

while (<>) {
    my $line = $_;    
    print $backupfile $line if ($backupfile);
    if (m/\\begin\{document\}/ || m/\\end\{(table|equation|figure|algorithm|align|eqnarray)\}/) {
        $docollect = 1;
        $doprint = 1;
        $doformat = 0;
    } elsif (m/\\end\{document\}/ || m/\\begin\{(table|equation|figure|algorithm|align|eqnarray)\}/) {
        $docollect = 0;
        $doprint = 1;
        $doformat = 1;
    } elsif (m/%/ || m/^\s*$/ || m/^\s*\\(bibliography|label|item|make|newcommand|pagestyle|section|subsection)/ ) {
        $doprint = 1;
        $doformat = 1;
    } elsif ($docollect) {
        $doprint = 0;
        $doformat = 0;
        $line =~ s/[ \t\n\r]+$/ /g;
        $text = $text . $line;
    } else {
        $doprint = 1;
        $doformat = 0;
    }
    if ($doformat && $text ne "") {
        $text =~ s/ +/ /g;
        $text =~ s/^ //; 
        if ($rule eq "sentence") { $text =~ s/\. /.\n/g; }
        elsif ($rule eq "paragraph") {  }
        elsif ($rule eq "wrap") { $text = reflow_string($text); }
        chomp $text; 
        print $text; 
        print "\n"; 
        $text = "";
    }
    if ($doprint) {
        print $line;
    }
} 

close($backupfile) if ($backupfile);

