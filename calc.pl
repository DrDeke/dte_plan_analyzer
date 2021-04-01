#!/usr/bin/perl -w

use DateTime;


# Debug booleans
my $general_debug0 = 0;
my $d1debug = 0;
my $d1_2debug = 0;
my $d1_8debug = 0;
my $ss_debug = 0; # unknown what the rate card name is


# Constants

my $weekday_peak_first_hr = 11; # 11am
my $weekday_peak_last_hr = 18; # The 6pm-o'clock hour. Off-peak starts at 7pm-o'clock

my $summer_first_mo = 6;  # June
my $summer_last_mo = 10;  # October, Winter starts in October (10) for both rates

# Time of Day Rates D1.2
my $winter_peak_rate = 20.213;
my $winter_offpeak_rate = 11.82;
my $summer_peak_rate = 22.713;
my $summer_offpeak_rate = 12.032;

# New Pilot Shift & Save
my $ss_winter_peak_rate = 15.4;
my $ss_winter_offpeak_rate = 14.9;
my $ss_summer_peak_rate = 16.6;
my $ss_summer_offpeak_rate = 14.9;

my $ss_weekday_peak_first_hr = 15; # 3pm
my $ss_weekday_peak_last_hr = 18; # The 6pm-o'clock hour. Off-peak starts at 7pm-o'clock

# Standard Rate D1
my $standard_rate_tier1 = 15.287;
my $standard_rate_tier2 = 17.271;


# Regular vars

my $std_kwh_today = 0;

my $file = $ARGV[0];

# Standard Rate D1
my $std_tier1_kwh = 0;
my $std_tier2_kwh = 0;

# Time of Day Rate D1.2
my $winter_peak_kwh = 0;
my $winter_offpeak_kwh = 0;
my $summer_peak_kwh = 0;
my $summer_offpeak_kwh = 0;

# Pilot Shift & Save
my $ss_winter_peak_kwh = 0;
my $ss_winter_offpeak_kwh = 0;
my $ss_summer_peak_kwh = 0;
my $ss_summer_offpeak_kwh = 0;


my ($date, $year, $time, $hour, $ampm, $month, $day, $usage, $dayofweek);

# Note: dayofweek 1=Monday, 7=Sunday


sub usage 
{
	print <<EOF;
Usage: $0 <input.csv>

A quick and very dirty script to examine a year's worth of your DTE Energy electric usage and calculate your cost on the D1 standard service plan vs the D1.2 time-of-day service plan.
EOF
}





if(@ARGV != 1) {
	usage;
	exit 1;
}

open (my $data, '<', $file) or die "Could not open input file $file.\n";

while (my $line = <$data>)
{
	if ($general_debug0 == 1)
	{
		print "$line\n";
	}
	next if $. == 1; # skip first line

	my @fields = split "," , $line;
	$date = $fields[1];
	$time = $fields[2];
	$usage = $fields[3];

	$date =~ s/\"//g;
	$time =~ s/\"//g;
	$usage =~ s/\"//g;

	@fields = split "/", $date;
	$month = $fields[0];
	$day = $fields[1];
	$year = $fields[2];

	@fields = split ":", $time;
	$hour = $fields[0];

	@fields = split " ", $time;
	$ampm = $fields[1];

	if (($ampm eq "PM") && ($hour != 12))
	{
		$hour = $hour + 12;
	}

	if (($ampm eq "AM") && ($hour == 12))
	{
		$hour = 0;
	}

	my $dt = DateTime->new(
		year => $year,
		month => $month,
		day => $day,
	);
	
	$dayofweek = $dt->day_of_week;


	if ($general_debug0 == 1)
	{
		print ">$date< >$hour< >$usage<\n";
		print ">$month< >$day< >$year< >$time< >$hour< >$ampm< >$usage< >$dayofweek<\n";
	}


	#Accumulate standard (D1) usage
	if ($hour == 23)
	{
		if ($std_kwh_today < 17)
		{
			$std_tier1_kwh = $std_tier1_kwh + $usage;
			$std_kwh_today = 0;
			if ($d1debug == 1)
			{
				print "DEBUG: Adding $usage kWh to std_tier1\n";
				print "DEBUG: Resetting daily accumulation\n";
			}
		}
		else
		{
			$std_tier2_kwh = $std_tier2_kwh + $usage;
			$std_kwh_today = 0;
			if ($d1debug == 1)
			{
				print "DEBUG: Adding $usage kWh to std_tier2\n";
				print "DEBUG: Resetting daily accumulation\n";
			}
		}
	}
	else
	{
		if ($std_kwh_today < 17)
		{
			$std_tier1_kwh = $std_tier1_kwh + $usage;
			$std_kwh_today = $std_kwh_today + $usage;
			if ($d1debug == 1)
			{
                        	print "DEBUG: Adding $usage kWh to std_tier1\n";
			}
		}
		else
		{
			$std_tier2_kwh = $std_tier2_kwh + $usage;
			$std_kwh_today = $std_kwh_today + $usage; #unnecessary
			if ($d1debug == 1)
			{
				print "DEBUG: Adding $usage kWh to std_tier2\n";
			}
		}
	}

	#Accumulate time-of-day (D1.2) usage
	if (($month < $summer_first_mo) || ($month > $summer_last_mo)) #It's winter
	{
		if ($d1_2debug == 1)
		{
			print "DEBUG: Rate: Winter    ";
		}
		if (($dayofweek == 6) || ($dayofweek == 7)) #It's a weekend
		{
			if ($d1_2debug == 1)
			{
				print "Adding $usage kWh to off-peak (weekend)\n";
			}
			$winter_offpeak_kwh = $winter_offpeak_kwh + $usage;
		}
		else
		{
			if (($hour < $weekday_peak_first_hr) || ($hour > $weekday_peak_last_hr))
			{
				if ($d1_2debug == 1)
				{
					print "Adding $usage kWh to off-peak (weekday)\n";
				}
				$winter_offpeak_kwh = $winter_offpeak_kwh + $usage;
			}
			else
			{
				if ($d1_2debug == 1)
				{
					print "Adding $usage kWh to on-peak\n";
				}
				$winter_peak_kwh = $winter_peak_kwh + $usage;
			}
		}
	}
	else #It's summer
	{
		if ($d1_2debug == 1)
		{
                	print "DEBUG: Rate: Summer    ";
		}
                if (($dayofweek == 6) || ($dayofweek == 7)) #It's a weekend
                {
			if ($d1_2debug == 1)
			{
                        	print "Adding $usage kWh to off-peak (weekend)\n";
			}
                        $summer_offpeak_kwh = $summer_offpeak_kwh + $usage;
                }
                else
                {
                        if (($hour < $weekday_peak_first_hr) || ($hour > $weekday_peak_last_hr))
                        {
				if ($d1_2debug == 1)
				{
                                	print "Adding $usage kWh to off-peak (weekday)\n";
				}
                                $summer_offpeak_kwh = $summer_offpeak_kwh + $usage;
                        }
                        else
                        {
				if ($d1_2debug == 1)
				{
                                	print "Adding $usage kWh to on-peak\n";
				}
                                $summer_peak_kwh = $summer_peak_kwh + $usage;
                        }
                }
	}

	#Accumulate shift & save usage
	if (($month < $summer_first_mo) || ($month > $summer_last_mo)) #It's winter
	{
		if ($ss_debug == 1)
		{
			print "DEBUG: Rate: Winter    ";
		}
		if (($dayofweek == 6) || ($dayofweek == 7)) #It's a weekend
		{
			if ($ss_debug == 1)
			{
				print "Adding $usage kWh to off-peak (weekend)\n";
			}
			$ss_winter_offpeak_kwh = $ss_winter_offpeak_kwh + $usage;
		}
		else
		{
			if (($hour < $ss_weekday_peak_first_hr) || ($hour > $ss_weekday_peak_last_hr))
			{
				if ($ss_debug == 1)
				{
					print "Adding $usage kWh to off-peak (weekday)\n";
				}
				$ss_winter_offpeak_kwh = $ss_winter_offpeak_kwh + $usage;
			}
			else
			{
				if ($ss_debug == 1)
				{
					print "Adding $usage kWh to on-peak\n";
				}
				$ss_winter_peak_kwh = $ss_winter_peak_kwh + $usage;
			}
		}
	}
	else #It's summer
	{
		if ($ss_debug == 1)
		{
                	print "DEBUG: Rate: Summer    ";
		}
                if (($dayofweek == 6) || ($dayofweek == 7)) #It's a weekend
                {
			if ($ss_debug == 1)
			{
                        	print "Adding $usage kWh to off-peak (weekend)\n";
			}
                        $ss_summer_offpeak_kwh = $ss_summer_offpeak_kwh + $usage;
                }
                else
                {
                        if (($hour < $ss_weekday_peak_first_hr) || ($hour > $ss_weekday_peak_last_hr))
                        {
				if ($ss_debug == 1)
				{
                                	print "Adding $usage kWh to off-peak (weekday)\n";
				}
                                $ss_summer_offpeak_kwh = $ss_summer_offpeak_kwh + $usage;
                        }
                        else
                        {
				if ($ss_debug == 1)
				{
                                	print "Adding $usage kWh to on-peak\n";
				}
                                $ss_summer_peak_kwh = $ss_summer_peak_kwh + $usage;
                        }
                }
	}

}

close ($data);

# standard rate cost calculation D1
my $std_total_kwh = int($std_tier1_kwh + $std_tier2_kwh);
my $std_tier1_dollars = int(($std_tier1_kwh * $standard_rate_tier1) / 100);
my $std_tier2_dollars = int(($std_tier2_kwh * $standard_rate_tier2) / 100);
my $std_total_dollars = int($std_tier1_dollars + $std_tier2_dollars);
$std_tier1_kwh = int($std_tier1_kwh);
$std_tier2_kwh = int($std_tier2_kwh);


# Time of Day cost calculation D1.2
my $summer_peak_dollars = int(($summer_peak_kwh * $summer_peak_rate) / 100);
my $winter_peak_dollars = int(($winter_peak_kwh * $winter_peak_rate) / 100);
my $summer_offpeak_dollars = int(($summer_offpeak_kwh * $summer_offpeak_rate) / 100);
my $winter_offpeak_dollars = int(($winter_offpeak_kwh * $winter_offpeak_rate) / 100);
my $total_tod_kwh = int($summer_peak_kwh + $summer_offpeak_kwh + $winter_peak_kwh + $winter_offpeak_kwh);
my $total_tod_dollars = int($summer_peak_dollars + $summer_offpeak_dollars + $winter_peak_dollars + $winter_offpeak_dollars);
$summer_peak_kwh = int($summer_peak_kwh);
$summer_offpeak_kwh = int($summer_offpeak_kwh);
$winter_peak_kwh = int($winter_peak_kwh);
$winter_offpeak_kwh = int($winter_offpeak_kwh);

# Shift & Save cost calculation
my $ss_summer_peak_dollars = int(($ss_summer_peak_kwh * $ss_summer_peak_rate) / 100);
my $ss_winter_peak_dollars = int(($ss_winter_peak_kwh * $ss_winter_peak_rate) / 100);
my $ss_summer_offpeak_dollars = int(($ss_summer_offpeak_kwh * $ss_summer_offpeak_rate) / 100);
my $ss_winter_offpeak_dollars = int(($ss_winter_offpeak_kwh * $ss_winter_offpeak_rate) / 100);
my $ss_total_tod_kwh = int($ss_summer_peak_kwh + $ss_summer_offpeak_kwh + $ss_winter_peak_kwh + $ss_winter_offpeak_kwh);
my $ss_total_tod_dollars = int($ss_summer_peak_dollars + $ss_summer_offpeak_dollars + $ss_winter_peak_dollars + $ss_winter_offpeak_dollars);
$ss_summer_peak_kwh = int($ss_summer_peak_kwh);
$ss_summer_offpeak_kwh = int($ss_summer_offpeak_kwh);
$ss_winter_peak_kwh = int($ss_winter_peak_kwh);
$ss_winter_offpeak_kwh = int($ss_winter_offpeak_kwh);


print "\n\n";
print "---Standard D1 Plan---\n";
print "Tier 1 kWh: $std_tier1_kwh Cost: \$$std_tier1_dollars\n";
print "Tier 2 kWh: $std_tier2_kwh Cost: \$$std_tier2_dollars\n";
print "Total  kWh: $std_total_kwh Cost: \$$std_total_dollars\n";

print "\n";
print "---Time-of-Day D1.2 Plan---\n";
print "Summer Peak     kWh: $summer_peak_kwh Cost: \$$summer_peak_dollars\n";
print "Summer Off-Peak kWh: $summer_offpeak_kwh Cost: \$$summer_offpeak_dollars\n";
print "Winter Peak     kWh: $winter_peak_kwh Cost: \$$winter_peak_dollars\n";
print "Winter Off-Peak kWh: $winter_offpeak_kwh Cost: \$$winter_offpeak_dollars\n";
print "Total           kWh: $total_tod_kwh Cost: \$$total_tod_dollars\n";

print "\n";
print "---Pilot Shift & Save Plan---\n";
print "Summer Peak     kWh: $ss_summer_peak_kwh Cost: \$$ss_summer_peak_dollars\n";
print "Summer Off-Peak kWh: $ss_summer_offpeak_kwh Cost: \$$ss_summer_offpeak_dollars\n";
print "Winter Peak     kWh: $ss_winter_peak_kwh Cost: \$$ss_winter_peak_dollars\n";
print "Winter Off-Peak kWh: $ss_winter_offpeak_kwh Cost: \$$ss_winter_offpeak_dollars\n";
print "Total           kWh: $ss_total_tod_kwh Cost: \$$ss_total_tod_dollars\n";

