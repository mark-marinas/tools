# Utility for writing logs/debug information, depending on the log mask
# 4 options:
# 	$Logger::LOG_MASK_INFO 
# 	$Logger::LOG_MASK_DEBUG
# 	$Logger::LOG_MASK_ERROR
# 	$Logger::LOG_MASK_WARNING
# Options can be be bit-ORed, and there is variable that BIT-OR everything.
# 	$Logger::LOG_MASK_ALL

# To instantiate:
# pass a hash ref with the following keys:
#		'filename' => log filename
#			when filename is set to 'default', the log file name is set to log.txt
#			if omitted, then the log goes to STDOUT
#			also, if the file cant be opened, the log goes to STDOUT
#		'log_mask' => BIT-ORed value of the 4 options
#			when omitted, the default value of $Logger::LOG_MASK_ERROR is used.
#			log mask can be changed after instantiation using set_log_mask and clear_log_mask
# $Logger::LOG_MASK_ERROR is always set, and can not be cleared.
# There are 4 functions to write different log type:
# 	write_info, write_error, write_warning, write_debug

# example:
# Logs All, to log3.txt
# 	my $logger = new Logger( {'log_mask' => $Logger::LOG_MASK_ALL , 'filename' => 'log3.txt' } );
# Logs All, to STDOUT
#	my $logger = new Logger( {'log_mask' => $Logger::LOG_MASK_ALL });
# Logs Only the always on ( Error ) to stdout
#	my $logger = new Logger();
# Logs only INFO (and the always ON Error) to stdout.
#	my $logger = new Logger({'log_mask' => $Logger::LOG_MASK_INFO } );

# $logger->write_info("This is an info");
# 	prints: INFO:This is an info
# $logger->write_warning("This is a warning");
# 	prints: WARNING:This is a warning
# $logger->write_error("This is an error");
# 	prints: ERROR:This is an error
# $logger->write_debug("This is a debug");
# 	prints: DEBUG:This is a debug 

package Logger;

use strict;

our $LOG_MASK_INFO = 1;
our $LOG_MASK_DEBUG= (1 << 1);
our $LOG_MASK_ERROR= (1 << 2);
our $LOG_MASK_WARNING = (1 << 3);

our $LOG_MASK_ALL = $LOG_MASK_INFO | $LOG_MASK_DEBUG | $LOG_MASK_ERROR | $LOG_MASK_WARNING;

my $default_log_filename = "log.txt";
my $NO_ERROR = 0;
my $ERROR_FAILED_TO_CREATE_FILE = 1;

sub new {
	my ($class, $args) = @_;
	my $self = {};
	bless $self;

	$self->open_log_handle($args);
	$self->init_log_mask($args);

	return $self;

}

sub is_file_writable {
	my ($self, $filename) = @_;

	my $fh;
	my $retval = 1;
	if (-e $filename) {
		if ( open($fh, ">>$filename")) {
			close($fh);
		} else {
			$retval = 0;
		}
	} else {
		if ( open($fh, ">$filename")) {
			close($fh);
			unlink($fh);
		} else {
			$retval = 0;
		}
	}


	return $retval;
}

#TODO: Only mask in decimal form. How about in hex?
sub is_valid_log_mask {
	my ($self, $mask) = @_;

	my $retval = 0;
	if ($mask =~ /[0-9]/) {
		$retval = 1;	
	}
	return $retval;
}

sub open_log_handle {
	my ($self, $args) = @_;
	my $retval = $NO_ERROR;

	my $log_fh = undef;
	if (defined($args) && defined($args->{'filename'})) {
		my $log_name = lc($args->{'filename'}); $log_name =~ s/^\s+//; $log_name =~ s/\s+$//;
		if ($log_name eq 'default') { $log_name = $default_log_filename; }

		my $mode = "write";
		if (-e $log_name) {
			$mode = "append";
		}

		if ($self->is_file_writable($log_name)) {
			my $status = 0;
			if ($mode eq 'write') {
				$status = open($log_fh, ">$log_name");
			} else {
				$status = open($log_fh, ">>$log_name");
			}
			if ($status == undef) {
				$retval = $ERROR_FAILED_TO_CREATE_FILE; 
			}
		} else {
			$retval = $ERROR_FAILED_TO_CREATE_FILE; 
		}
	} 

	if (! defined($log_fh) || $retval != $NO_ERROR) {
		open($log_fh, ">-");
	}
	$self->{'log_fh'} = $log_fh;
	return $retval;
}

sub init_log_mask {
	my ($self, $args)  = @_;

	#All Errors should be logged
	$self->{'log_mask'} = $LOG_MASK_ERROR;
	if (defined($args->{'log_mask'})) {
		$self->set_log_mask($args->{'log_mask'});
	}
}

#changes the mask, setting all values specified in the input
sub set_log_mask {
	my ($self, $mask) = @_;
	if (defined($mask) && $self->is_valid_log_mask($mask)) {
		$self->{'log_mask'} = $LOG_MASK_ERROR | int($mask);
	}
}

#clears the mask. All 1's in the input will be cleared (except ERROR)
#use the same LOG_MASK_* variables.
sub clear_log_mask {
	my ($self, $mask) = @_;

	#all ones in the mask should become 0 to clear the log_mask, except ERROR
	if (defined($mask) && $self->is_valid_log_mask($mask)) {
		$mask = (~(int($mask)) & $LOG_MASK_ALL) | $LOG_MASK_ERROR;
		$self->{'log_mask'} = $mask;
	}
}

sub get_log_mask {
	my ($self) = @_;
	return $self->{'log_mask'};
}

sub write_log {
	my ($self, $log_type, $msg) = @_;

	chomp $msg; $msg =~ s/\s+$//;

	my $fh = $self->{'log_fh'};
	if (($self->{'log_mask'} & $log_type) == $log_type) {
		print $fh ("$msg\n");
	}
}

sub write_debug {
	my ($self, $msg) = @_;

	$self->write_log($LOG_MASK_DEBUG, "DEBUG:".$msg);
}

sub write_error {
	my ($self, $msg) = @_;

	$self->write_log($LOG_MASK_ERROR, "ERROR:".$msg);
}

sub write_warning {
	my ($self, $msg) = @_;

	$self->write_log($LOG_MASK_WARNING, "WARNING:".$msg);
}

sub write_info {
	my ($self, $msg) = @_;

	$self->write_log($LOG_MASK_INFO, "INFO:".$msg);
}

1;
