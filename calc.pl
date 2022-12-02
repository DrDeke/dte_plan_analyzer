#!/usr/bin/perl -w

use DateTime;
use Scalar::Util qw(looks_like_number);



# Debug booleans
my $general_debug0 = 0;
my $d1debug = 0;
my $d1_2debug = 0;
my $d1_11debug = 0;






# Constants for D1 (U-20836) rates
my $d1_rate_tier1 = 15.229;
my $d1_rate_tier2 = 17.171;

# Constants for D1.2 Enhanced TOU (U-20836) rates
my $d1_2_weekday_peak_first_hr = 11;
my $d1_2_weekday_peak_last_hr = 18; #The 6pm-o'clock hour. Off-peak starts at 7pm-o'clock
my $d1_2_summer_first_mo = 6;
my $d1_2_summer_last_mo = 10;

my $d1_2_winter_peak_rate = 19.666;
my $d1_2_winter_offpeak_rate = 11.776;
my $d1_2_summer_peak_rate = 22.017;
my $d1_2_summer_offpeak_rate = 11.975;

# Constants for D1.11 Standard TOU (U-20836) rates
my $d1_11_weekday_peak_first_hr = 15;
my $d1_11_weekday_peak_last_hr = 18; #The 6pm-o'clock Hour. Off-peak starts at 7pm-o'clock
my $d1_11_summer_first_mo = 6;
my $d1_11_summer_last_mo = 9;

my $d1_11_winter_peak_rate = 16.752;
my $d1_11_winter_offpeak_rate = 15.453;
my $d1_11_summer_peak_rate = 20.98;
my $d1_11_summer_offpeak_rate = 15.453;



# Regular vars

my $missing_data = 0;

my $d1_kwh_today = 0;

my $file = $ARGV[0];

my $d1_tier1_kwh = 0;
my $d1_tier2_kwh = 0;

my $d1_2_winter_peak_kwh = 0;
my $d1_2_winter_offpeak_kwh = 0;
my $d1_2_summer_peak_kwh = 0;
my $d1_2_summer_offpeak_kwh = 0;

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

* D1 standard residential service (U-20836)
* D1.2 enhanced time-of-use residential service (U-20836)
* D1.11 standard time-of-day residential service (U-20836)

EOF
}





if(@ARGV != 1) {
	usage;
	exit 1;
}

# Check whether multiple meter numbers are present in the input
# and abort if there are.

my $num_meters = `cat $file | grep -v 'Meter Number' | sed 's/"//g' | awk -F',' '{ print \$2  }' | sort -n | uniq | wc -l`;
chomp($num_meters);

if ($num_meters > 1)
{
	print "ERROR: Multiple electric meters ($num_meters meters) found in input file. This script only works with input files containing data from a single electric meter. Exiting.\n";
	exit 1;
}


open (my $data, '<', $file) or die "Could not open input file $file.\n";




# Read and parse hourly usage data from the input file
while (my $line = <$data>)
{
	$line =~ s/\"//g;

	if ($general_debug0 == 1)
	{
		print "$line\n";
	}
	next if $. == 1; # skip first line

	my @fields = split "," , $line;
	$date = $fields[2];
	$time = $fields[3];
	$usage = $fields[4];

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
		if ($d1_kwh_today < 17)
		{
			if (!(looks_like_number($usage)))
			{
				$usage = 0;
				print "NOTICE: No (or invalid) data recorded for this hour: $year-$month-$day $hour\n";
				$missing_data = 1;
			}
			$d1_tier1_kwh = $d1_tier1_kwh + $usage;
			$d1_kwh_today = 0;
			if ($d1debug == 1)
			{
				print "DEBUG: Adding $usage kWh to d1_tier1\n";
				print "DEBUG: Resetting daily accumulation\n";
			}
		}
		else
		{
			$d1_tier2_kwh = $d1_tier2_kwh + $usage;
			$d1_kwh_today = 0;
			if ($d1debug == 1)
			{
				print "DEBUG: Adding $usage kWh to d1_tier2\n";
				print "DEBUG: Resetting daily accumulation\n";
			}
		}
	}
	else
	{
		if ($d1_kwh_today < 17)
		{
			if (!(looks_like_number($usage)))
			{
				$usage = 0;
				print "NOTICE: No (or invalid) data recorded for this hour: $year-$month-$day $hour\n";
				$missing_data = 1;
			}
			$d1_tier1_kwh = $d1_tier1_kwh + $usage;
			$d1_kwh_today = $d1_kwh_today + $usage;
			if ($d1debug == 1)
			{
                        	print "DEBUG: Adding $usage kWh to d1_tier1\n";
			}
		}
		else
		{
			if (!(looks_like_number($usage)))
			{
				$usage = 0;
				print "NOTICE: No (or invalid) data recorded for this hour $year-$month-$day $hour\n";
				$missing_data = 1;
			}
			$d1_tier2_kwh = $d1_tier2_kwh + $usage;
			$d1_kwh_today = $d1_kwh_today + $usage; #unnecessary
			if ($d1debug == 1)
			{
				print "DEBUG: Adding $usage kWh to d1_tier2\n";
			}
		}
	}

	#Accumulate enhanced TOU (D1.2) usage
	if (($month < $d1_2_summer_first_mo) || ($month > $d1_2_summer_last_mo)) #It's winter
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
			$d1_2_winter_offpeak_kwh = $d1_2_winter_offpeak_kwh + $usage;
		}
		else
		{
			if (($hour < $d1_2_weekday_peak_first_hr) || ($hour > $d1_2_weekday_peak_last_hr))
			{
				if ($d1_2debug == 1)
				{
					print "Adding $usage kWh to off-peak (weekday)\n";
				}
				$d1_2_winter_offpeak_kwh = $d1_2_winter_offpeak_kwh + $usage;
			}
			else
			{
				if ($d1_2debug == 1)
				{
					print "Adding $usage kWh to on-peak\n";
				}
				$d1_2_winter_peak_kwh = $d1_2_winter_peak_kwh + $usage;
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
                        $d1_2_summer_offpeak_kwh = $d1_2_summer_offpeak_kwh + $usage;
                }
                else
                {
                        if (($hour < $d1_2_weekday_peak_first_hr) || ($hour > $d1_2_weekday_peak_last_hr))
                        {
				if ($d1_2debug == 1)
				{
                                	print "Adding $usage kWh to off-peak (weekday)\n";
				}
                                $d1_2_summer_offpeak_kwh = $d1_2_summer_offpeak_kwh + $usage;
                        }
                        else
                        {
				if ($d1_2debug == 1)
				{
                                	print "Adding $usage kWh to on-peak\n";
				}
                                $d1_2_summer_peak_kwh = $d1_2_summer_peak_kwh + $usage;
                        }
                }
	}

	#Accumulate D1.11 usage
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

if ($missing_data == 1)
{
	print "Note: It is normal to have \"no \(or invalid\) data\" for hours during which the power to your meter was out.\n";
}



my $d1_total_kwh = int($d1_tier1_kwh + $d1_tier2_kwh);
my $d1_tier1_dollars = int(($d1_tier1_kwh * $d1_rate_tier1) / 100);
my $d1_tier2_dollars = int(($d1_tier2_kwh * $d1_rate_tier2) / 100);
my $d1_total_dollars = int($d1_tier1_dollars + $d1_tier2_dollars);
$d1_tier1_kwh = int($d1_tier1_kwh);
$d1_tier2_kwh = int($d1_tier2_kwh);



my $d1_2_summer_peak_dollars = int(($d1_2_summer_peak_kwh * $d1_2_summer_peak_rate) / 100);
my $d1_2_winter_peak_dollars = int(($d1_2_winter_peak_kwh * $d1_2_winter_peak_rate) / 100);
my $d1_2_summer_offpeak_dollars = int(($d1_2_summer_offpeak_kwh * $d1_2_summer_offpeak_rate) / 100);
my $d1_2_winter_offpeak_dollars = int(($d1_2_winter_offpeak_kwh * $d1_2_winter_offpeak_rate) / 100);
my $d1_2_total_kwh = int($d1_2_summer_peak_kwh + $d1_2_summer_offpeak_kwh + $d1_2_winter_peak_kwh + $d1_2_winter_offpeak_kwh);
my $d1_2_total_dollars = int($d1_2_summer_peak_dollars + $d1_2_summer_offpeak_dollars + $d1_2_winter_peak_dollars + $d1_2_winter_offpeak_dollars);
$d1_2_summer_peak_kwh = int($d1_2_summer_peak_kwh);
$d1_2_summer_offpeak_kwh = int($d1_2_summer_offpeak_kwh);
$d1_2_winter_peak_kwh = int($d1_2_winter_peak_kwh);
$d1_2_winter_offpeak_kwh = int($d1_2_winter_offpeak_kwh);

my $d1_11_summer_peak_dollars = int(($d1_11_summer_peak_kwh * $d1_11_summer_peak_rate) / 100);
my $d1_11_summer_offpeak_dollars = int((($d1_11_summer_offpeak_kwh * $d1_11_summer_offpeak_rate)) / 100);
my $d1_11_winter_peak_dollars = int(($d1_11_winter_peak_kwh * $d1_11_winter_peak_rate) / 100);
my $d1_11_winter_offpeak_dollars = int(($d1_11_winter_offpeak_kwh * $d1_11_winter_offpeak_rate) / 100);
my $d1_11_total_dollars = $d1_11_summer_peak_dollars + $d1_11_summer_offpeak_dollars + $d1_11_winter_peak_dollars + $d1_11_winter_offpeak_dollars;
my $d1_11_total_kwh = int($d1_11_summer_peak_kwh + $d1_11_summer_offpeak_kwh + $d1_11_winter_peak_kwh + $d1_11_winter_offpeak_kwh);
$d1_11_winter_offpeak_kwh = int($d1_11_winter_offpeak_kwh);
$d1_11_winter_peak_kwh = int($d1_11_winter_peak_kwh);
$d1_11_summer_offpeak_kwh = int($d1_11_summer_offpeak_kwh);
$d1_11_summer_peak_kwh = int($d1_11_summer_peak_kwh);



print "\n\n";
print "---Residential D1 Rate (U-20836)---\n";
print "Tier 1 kWh: $d1_tier1_kwh Cost: \$$d1_tier1_dollars\n";
print "Tier 2 kWh: $d1_tier2_kwh Cost: \$$d1_tier2_dollars\n";
print "Total  kWh: $d1_total_kwh Cost: \$$d1_total_dollars\n";

print "\n";
print "---Residential D1.2 Enhanced Time-of-Use Rate (U-20836)---\n";
print "Summer Peak     kWh: $d1_2_summer_peak_kwh Cost: \$$d1_2_summer_peak_dollars\n";
print "Summer Off-Peak kWh: $d1_2_summer_offpeak_kwh Cost: \$$d1_2_summer_offpeak_dollars\n";
print "Winter Peak     kWh: $d1_2_winter_peak_kwh Cost: \$$d1_2_winter_peak_dollars\n";
print "Winter Off-Peak kWh: $d1_2_winter_offpeak_kwh Cost: \$$d1_2_winter_offpeak_dollars\n";
print "Total           kWh: $d1_2_total_kwh Cost: \$$d1_2_total_dollars\n";

print "\n";
print "---Residential D1.11 Standard Time-of-Use Rate (U-20836)---\n";
print "Summer Peak     kWh: $d1_11_summer_peak_kwh Cost: \$$d1_11_summer_peak_dollars\n";
print "Summer Off-Peak kWh: $d1_11_summer_offpeak_kwh Cost: \$$d1_11_summer_offpeak_dollars\n";
print "Winter Peak     kWh: $d1_11_winter_peak_kwh Cost: \$$d1_11_winter_peak_dollars\n";
print "Winter Off-Peak kWh: $d1_11_winter_offpeak_kwh Cost: \$$d1_11_winter_offpeak_dollars\n";
print "Total           kWh: $d1_11_total_kwh Cost: \$$d1_11_total_dollars\n";

print "\n\n";

print "---Comparison Summary---\n";
print "D1    (U-20836)  Cost: \$$d1_total_dollars\n";
print "D1.2  (U-20836)  Cost: \$$d1_2_total_dollars\n";
print "D1.11 (U-20836)  Cost: \$$d1_11_total_dollars\n";

print "\n";