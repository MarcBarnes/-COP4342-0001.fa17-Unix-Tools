#!/usr/bin/perl

use strict;

# variable to store ASCII image
my $file_content;

# width of the image read in (not known ahead of time)
my $ascii_image_width;
# obtain image width for interpolation in regexp 
my $first_line=<STDIN>;
# complain if input isn't as expected
if (length $first_line > 0 or die "Input invalid.")
{
	$ascii_image_width =length $first_line;
}

# the given pattern is 5 characters wide
my $pattern_width=5;
# calculate wrap around distance of the image
# (add one for newline character)
my $wraparound_distance=$ascii_image_width-$pattern_width;

# append line to stored file content
$file_content=$file_content.$first_line;
while(<>) # read from stdin
{
	$file_content=$file_content.$_;
}

# match pattern all at once, including characters in between
$file_content =~ m!(.*)(/\\_/\\)(.{$wraparound_distance})(\\\^x\^/)(.{$wraparound_distance})(/m m\\)(.*)!gs;

my $color_index=0; 
# loop over colors forever
while(1)
{
	# wrap around 9 ANSI color codes using modulus
	$color_index%=9;

	# specify background color
	my $BG_COLOR="\033[0;30m";
	# specify foreground color dynamically
	my $FG_COLOR="\033[0;3".$color_index."m";
	my $colorized_result="$BG_COLOR$1$FG_COLOR$2$BG_COLOR$3$FG_COLOR$4$BG_COLOR$5$FG_COLOR$6$BG_COLOR$7$BG_COLOR";
	
	# write the output to an image, replacing the contents
	open ASCII_IMAGE_FILE, ">output_colorized.asciiimg";
	# output the colorized image ot the file
	print ASCII_IMAGE_FILE $colorized_result;
	# close the file and flush the buffer
	close ASCII_IMAGE_FILE;

	# don't update the file for .2 seconds
	`sleep .2`;

	# update for the next iteration
	$color_index+=1;
}
