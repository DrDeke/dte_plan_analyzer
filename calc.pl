#!/usr/bin/perl -w

use DateTime;
use Scalar::Util qw(looks_like_number);

# Debug booleans
my $general_debug0 = 0;
my $d1debug = 0;
my $d1_2debug = 0;
my $d1_8debug = 0;
my $d1_11debug = 0;

# Constants

my $weekday_peak_first_hr = 11;
my $weekday_peak_last_hr = 18; #The 6pm-o'clock hour. Off-peak starts at 7pm-o'clock

my $summer_first_mo = 6;
my $summer_last_mo = 10;

my $winter_peak_rate = 20.213;
my $winter_offpeak_rate = 11.82;
my $summer_peak_rate = 22.713;
my $summer_offpeak_rate = 12.032;

my $standard_rate_tier1 = 15.287;
my $standard_rate_tier2 = 17.271;

# Proposed D1.11 rates
my $d1_11_weekday_peak_first_hr = 15;
my $d1_11_weekday_peak_last_hr = 19;
my $d1_11_summer_first_mo = 6;
my $d1_11_summer_last_mo = 9;

my $d1_11_energy_cap_rate = 4.458;

my $d1_11_winter_peak_noncap_rate = 5.157;
my $d1_11_winter_offpeak_noncap_rate = 4.740;
my $d1_11_summer_peak_noncap_rate = 6.432;
my $d1_11_summer_offpeak_noncap_rate = 4.740;

my $d1_11_distrib_rate = 8.194;





# Regular vars

my $std_kwh_today = 0;

my $file = $ARGV[0];

my $std_tier1_kwh = 0;
my $std_tier2_kwh = 0;

my $winter_peak_kwh = 0;
my $winter_offpeak_kwh = 0;
my $summer_peak_kwh = 0;
my $summer_offpeak_kwh = 0;

my $d1_11_winter_offpeak_kwh = 0;
my $d1_11_summer_offpeak_kwh = 0;
my $d1_11_winter_peak_kwh = 0;
my $d1_11_summer_peak_kwh = 0;


my ($date, $year, $time, $hour, $ampm, $month, $day, $usage, $dayofweek);

# Note: dayofweek 1=Monday, 7=Sunday


sub usage 
{
	print <<EOF;
Usage: $0 <input.csv>

A quick and somewhat dirty script to examine a year's worth of your DTE Energy electric usage and calculate your cost on various residential service plans, including:

* D1 standard residential service
* D1.2 time-of-day residential service
* D1.11 proposed time-of-day residential service (U-20836)

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
			if (!(looks_like_number($usage)))
			{
				$usage = 0;
				print "NOTICE: No (or invalid) data recorded for this hour: $year-$month-$day $hour\n";
			}
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
			if (!(looks_like_number($usage)))
			{
				$usage = 0;
				print "NOTICE: No (or invalid) data recorded for this hour: $year-$month-$day $hour\n";
			}
			$std_tier1_kwh = $std_tier1_kwh + $usage;
			$std_kwh_today = $std_kwh_today + $usage;
			if ($d1debug == 1)
			{
                        	print "DEBUG: Adding $usage kWh to std_tier1\n";
			}
		}
		else
		{
			if (!(looks_like_number($usage)))
			{
				$usage = 0;
				print "NOTICE: No (or invalid) data recorded for this hour $year-$month-$day $hour\n";
			}
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

	#Accumulate D1.11 (proposed) usage
	if (($month < $d1_11_summer_first_mo) || ($month > $d1_11_summer_last_mo)) #It's winter
	{
		if ($d1_11debug == 1)
		{
			print "DEBUG_D1_11: Rate: Winter    ";
		}
		if (($dayofweek == 6) || ($dayofweek == 7)) #It's a weekend
		{
			if ($d1_11debug == 1)
			{
				print "DEBUG_D1_11: Adding $usage kWh to winter off-peak (weekend)\n";
			}
			$d1_11_winter_offpeak_kwh = $d1_11_winter_offpeak_kwh + $usage;
		}
		else
		{
			if (($hour < $d1_11_weekday_peak_first_hr) || ($hour > $d1_11_weekday_peak_last_hr))
			{
				if ($d1_11debug == 1)
				{
					print "DEBUG_D1_11: Adding $usage kWh to winter off-peak (weekday)\n";
				}
				$d1_11_winter_offpeak_kwh = $d1_11_winter_offpeak_kwh + $usage;
			}
			else
			{
				if ($d1_11debug == 1)
				{
					print "DEBUG_D1_11: Adding $usage kWh to winter on-peak\n";
				}
				$d1_11_winter_peak_kwh = $d1_11_winter_peak_kwh + $usage;
			}
		}
	}
	else #It's summer
	{
		if ($d1_11debug == 1)
		{
			print "DEBUG_D1_11: Rate: Summer    ";
		}
		if (($dayofweek == 6) || ($dayofweek == 7)) #It's a weekend
		{
			if ($d1_11debug == 1)
			{
				print "DEBUG_D1_11: Adding $usage kWh to summer off-peak (weekend)\n";
			}
			$d1_11_summer_offpeak_kwh = $d1_11_summer_offpeak_kwh + $usage;
		}
		else
		{
			if (($hour < $d1_11_weekday_peak_first_hr) || ($hour > $d1_11_weekday_peak_last_hr))
			{
				if ($d1_11debug == 1)
				{
					print "DEBUG_D1_11: Adding $usage kWh to summer off-peak (weekday)\n";
				}
				$d1_11_summer_offpeak_kwh = $d1_11_summer_offpeak_kwh + $usage;
			}
			else
			{
				if ($d1_11debug == 1)
				{
					print "DEBUG_D1_11: Adding $usage kWh to summer on-peak (weekday)\n";
				}
				$d1_11_summer_peak_kwh = $d1_11_summer_peak_kwh + $usage;
			}
		}
	}

}

close ($data);

my $std_total_kwh = int($std_tier1_kwh + $std_tier2_kwh);
my $std_tier1_dollars = int(($std_tier1_kwh * $standard_rate_tier1) / 100);
my $std_tier2_dollars = int(($std_tier2_kwh * $standard_rate_tier2) / 100);
my $std_total_dollars = int($std_tier1_dollars + $std_tier2_dollars);
$std_tier1_kwh = int($std_tier1_kwh);
$std_tier2_kwh = int($std_tier2_kwh);



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

my $d1_11_summer_peak_dollars = int((($d1_11_summer_peak_kwh * $d1_11_summer_peak_noncap_rate) + ($d1_11_summer_peak_kwh * $d1_11_energy_cap_rate) + ($d1_11_summer_peak_kwh * $d1_11_distrib_rate)) / 100);
my $d1_11_summer_offpeak_dollars = int((($d1_11_summer_offpeak_kwh * $d1_11_summer_offpeak_noncap_rate) + ($d1_11_summer_offpeak_kwh * $d1_11_energy_cap_rate) + ($d1_11_summer_offpeak_kwh * $d1_11_distrib_rate)) / 100);
my $d1_11_winter_peak_dollars = int((($d1_11_winter_peak_kwh * $d1_11_winter_peak_noncap_rate) + ($d1_11_winter_peak_kwh * $d1_11_energy_cap_rate) + ($d1_11_winter_peak_kwh * $d1_11_distrib_rate)) / 100);
my $d1_11_winter_offpeak_dollars = int((($d1_11_winter_offpeak_kwh * $d1_11_winter_offpeak_noncap_rate) + ($d1_11_winter_offpeak_kwh * $d1_11_energy_cap_rate) + ($d1_11_winter_offpeak_kwh * $d1_11_distrib_rate)) / 100);
my $d1_11_total_dollars = $d1_11_summer_peak_dollars + $d1_11_summer_offpeak_dollars + $d1_11_winter_peak_dollars + $d1_11_winter_offpeak_dollars;
my $d1_11_total_kwh = int($d1_11_summer_peak_kwh + $d1_11_summer_offpeak_kwh + $d1_11_winter_peak_kwh + $d1_11_winter_offpeak_kwh);
$d1_11_winter_offpeak_kwh = int($d1_11_winter_offpeak_kwh);
$d1_11_winter_peak_kwh = int($d1_11_winter_peak_kwh);
$d1_11_summer_offpeak_kwh = int($d1_11_summer_offpeak_kwh);
$d1_11_summer_peak_kwh = int($d1_11_summer_peak_kwh);

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
print "---Proposed Time-of-Day D1.11 Plan (U-20836)---\n";
print "Summer Peak     kWh: $d1_11_summer_peak_kwh Cost: \$$d1_11_summer_peak_dollars\n";
print "Summer Off-Peak kWh: $d1_11_summer_offpeak_kwh Cost: \$$d1_11_summer_offpeak_dollars\n";
print "Winter Peak     kWh: $d1_11_winter_peak_kwh Cost: \$$d1_11_winter_peak_dollars\n";
print "Winter Off-Peak kWh: $d1_11_winter_offpeak_kwh Cost: \$$d1_11_winter_offpeak_dollars\n";
print "Total           kWh: $d1_11_total_kwh Cost: \$$d1_11_total_dollars\n";


