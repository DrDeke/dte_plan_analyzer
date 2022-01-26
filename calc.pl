#!/usr/bin/perl -w

use DateTime;
use Scalar::Util qw(looks_like_number);

# Debug booleans
my $general_debug0 = 0;
my $d1debug = 0;
my $d1_2debug = 0;
my $d1_8debug = 0;
my $d1_11debug = 0;
my $d1_12debug = 0;

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

# Constants for Proposed D1.11 rates
my $d1_11_weekday_peak_first_hr = 15;
my $d1_11_weekday_peak_last_hr = 18; #The 6pm-o'clock Hour. Off-peak starts at 7pm-o'clock
my $d1_11_summer_first_mo = 6;
my $d1_11_summer_last_mo = 9;

my $d1_11_energy_cap_rate = 4.458;

my $d1_11_winter_peak_noncap_rate = 5.157;
my $d1_11_winter_offpeak_noncap_rate = 4.740;
my $d1_11_summer_peak_noncap_rate = 6.432;
my $d1_11_summer_offpeak_noncap_rate = 4.740;

my $d1_11_distrib_rate = 8.194;

# Constants for Proposed D1.12 rates

my $d1_12_winter_peak_noncap_rate = 5.157;
my $d1_12_winter_offpeak_noncap_rate = 4.740;
my $d1_12_summer_peak_noncap_rate = 6.432;
my $d1_12_summer_offpeak_noncap_rate = 4.740;

my $d1_12_summer_first_mo = 6;
my $d1_12_summer_last_mo = 9;
my $d1_12_weekday_peak_first_hr = 15;
my $d1_12_weekday_peak_last_hr = 18; #The 6pm-o'clock Hour. Off-peak starts at 7pm-o'clock


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

my $d1_12_winter_offpeak_kwh = 0;
my $d1_12_winter_peak_kwh = 0;
my $d1_12_summer_offpeak_kwh = 0;
my $d1_12_summer_peak_kwh = 0;


my $d1_12_demandhr1_kwh = 0;
my $d1_12_demandhr2_kwh = 0;
my $d1_12_demandhr3_kwh = 0;

my $d1_12_demandhr1_date = "1970/01/01";
my $d1_12_demandhr2_date = "1970/01/01";
my $d1_12_demandhr3_date = "1970/01/01";

my $d1_12_demandhr1_hour = -1;
my $d1_12_demandhr2_hour = -1;
my $d1_12_demandhr3_hour = -1;

my $d1_12_demand_kw;
my $d1_12_demand_level;
my $d1_12_capacity_dollars;
my $d1_12_delivery_dollars;


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




# Get top three usage hours per proposed D1.12 rules
# (which have some complications, so look them up if needed)
# (at https://mi-psc.force.com/sfc/servlet.shepherd/version/download/0688y000001oeWBAAY )

my $d1_12_demand_rows = `cat $file | sort -g -r --field-separator=',' -k 4,4 |awk -F',' '{ if(!a[\$2]++){print} }' | head -3`;
my @d1_12_fields = split ",", $d1_12_demand_rows;

$d1_12_demandhr1_kwh = $d1_12_fields[3];
$d1_12_demandhr2_kwh = $d1_12_fields[8];
$d1_12_demandhr3_kwh = $d1_12_fields[13];

$d1_12_demandhr1_date = $d1_12_fields[1];
$d1_12_demandhr2_date = $d1_12_fields[6];
$d1_12_demandhr3_date = $d1_12_fields[11];

$d1_12_demandhr1_hour = $d1_12_fields[2];
$d1_12_demandhr2_hour = $d1_12_fields[7];
$d1_12_demandhr3_hour = $d1_12_fields[12];

$d1_12_demand_kw = ($d1_12_demandhr1_kwh + $d1_12_demandhr2_kwh + $d1_12_demandhr3_kwh) / 3;
$d1_12_demand_level = int($d1_12_demand_kw);

if ($d1_12debug == 1)
{
	#print "$d1_12_demandhr1_kwh $d1_12_demandhr2_kwh $d1_12_demandhr3_kwh\n";
	#print "$d1_12_demandhr1_date $d1_12_demandhr2_date $d1_12_demandhr3_date\n";
	#print "$d1_12_demandhr1_hour $d1_12_demandhr2_hour $d1_12_demandhr3_hour\n";

	print "DEBUG_D1_12: Demand Hour 1: $d1_12_demandhr1_date $d1_12_demandhr1_hour $d1_12_demandhr1_kwh kWh\n";
	print "DEBUG_D1_12: Demand Hour 2: $d1_12_demandhr2_date $d1_12_demandhr2_hour $d1_12_demandhr2_kwh kWh\n";
	print "DEBUG_D1_12: Demand Hour 3: $d1_12_demandhr3_date $d1_12_demandhr3_hour $d1_12_demandhr3_kwh kWh\n";
	print "DEBUG_D1_12: Demand kW: $d1_12_demand_kw\n";

}

# Compute capacity energy charge and delivery charge for D1.12
if ($d1_12_demand_kw < 1)
{
	$d1_12_capacity_dollars = 0;
}
elsif (($d1_12_demand_kw >= 1) && ($d1_12_demand_kw < 2))
{
	$d1_12_capacity_dollars = 5.85;
}
elsif (($d1_12_demand_kw >= 2) && ($d1_12_demand_kw < 3))
{
	$d1_12_capacity_dollars = 11.70;
}
elsif (($d1_12_demand_kw >= 3) && ($d1_12_demand_kw < 9))
{
	$d1_12_capacity_dollars = 17.56 + 5.85 * (int($d1_12_demand_kw) - 3);
}
else
{
	$d1_12_capacity_dollars = 52.67 + 5.85 * ($d1_12_demand_kw - 9);
}

if ($d1_12debug == 1)
{
	print "DEBUG_D1_12: Energy Capacity Dollars: $d1_12_capacity_dollars\n";
}

if ($d1_12_demand_kw < 1)
{
	$d1_12_delivery_dollars = 0;
}
elsif (($d1_12_demand_kw >= 1) && ($d1_12_demand_kw < 2))
{
	$d1_12_delivery_dollars = 10.76;
}
elsif (($d1_12_demand_kw >= 2) && ($d1_12_demand_kw < 3))
{
        $d1_12_delivery_dollars = 21.51;
}
elsif (($d1_12_demand_kw >= 3) && ($d1_12_demand_kw < 4))
{
        $d1_12_delivery_dollars = 32.27;
}
elsif (($d1_12_demand_kw >= 4) && ($d1_12_demand_kw < 5))
{
        $d1_12_delivery_dollars = 43.02;
}
elsif (($d1_12_demand_kw >= 5) && ($d1_12_demand_kw < 6))
{
        $d1_12_delivery_dollars = 53.78;
}
elsif (($d1_12_demand_kw >= 6) && ($d1_12_demand_kw < 7))
{
        $d1_12_delivery_dollars = 64.53;
}
elsif (($d1_12_demand_kw >= 7) && ($d1_12_demand_kw < 8))
{
        $d1_12_delivery_dollars = 75.29;
}
elsif (($d1_12_demand_kw >= 8) && ($d1_12_demand_kw < 9))
{
        $d1_12_delivery_dollars = 86.04;
}
else
{
	$d1_12_delivery_dollars = 96.80 + 10.76 * ($d1_12_demand_kw - 9);
}

if ($d1_12debug == 1)
{
	print "DEBUG_D1_12: Delivery Dollars: $d1_12_delivery_dollars\n";
}




# Read and parse hourly usage data from the input file
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

	#Accumulate D1.12 (proposed) non-capacity energy usage
	if (($month < $d1_12_summer_first_mo) || ($month > $d1_12_summer_last_mo)) #It's winter
	{
		if ($d1_12debug == 1)
		{
			print "DEBUG_D1_12: Rate: Winter    ";
		}
		if (($dayofweek == 6) || ($dayofweek == 7)) #It's a weekend
		{
			if ($d1_12debug == 1)
			{
				print "Adding $usage kWh to winter off-peak (weekend)\n";
			}
			$d1_12_winter_offpeak_kwh = $d1_12_winter_offpeak_kwh + $usage;
		}
		else
		{
			if (($hour < $d1_12_weekday_peak_first_hr) || ($hour > $d1_12_weekday_peak_last_hr))
			{
				if ($d1_12debug == 1)
				{
					print "Adding $usage kWh to winter off-peak (weekday)\n";
				}
				$d1_12_winter_offpeak_kwh = $d1_12_winter_offpeak_kwh + $usage;
			}
			else
			{
				if ($d1_12debug == 1)
				{
					print "Adding $usage kWh to winter on-peak\n";
				}
				$d1_12_winter_peak_kwh = $d1_12_winter_peak_kwh + $usage;
			}
		}
	}
	else #It's summer
	{
		if ($d1_12debug == 1)
		{
			print "DEBUG_D1_12: Rate: Summer    ";
		}
		if (($dayofweek == 6) || ($dayofweek == 7)) #It's a weekend
		{
			if ($d1_12debug == 1)
			{
				print "Adding $usage kWh to summer off-peak (weekend)\n";
			}
			$d1_12_summer_offpeak_kwh = $d1_12_summer_offpeak_kwh + $usage;
		}
		else
		{
			if (($hour < $d1_12_weekday_peak_first_hr) || ($hour > $d1_12_weekday_peak_last_hr))
			{
				if ($d1_12debug == 1)
				{
					print "Adding $usage kWh to summer off-peak (weekday)\n";
				}
				$d1_12_summer_offpeak_kwh = $d1_12_summer_offpeak_kwh + $usage;
			}
			else
			{
				if ($d1_12debug == 1)
				{
					print "Adding $usage kWh to summer on-peak (weekday)\n";
				}
				$d1_12_summer_peak_kwh = $d1_12_summer_peak_kwh + $usage;
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

my $d1_12_delivery_dollars_year = int($d1_12_delivery_dollars * 12);
my $d1_12_capacity_dollars_year = int($d1_12_capacity_dollars * 12);

my $d1_12_winter_peak_dollars = int(($d1_12_winter_peak_noncap_rate * $d1_12_winter_peak_kwh) / 100);
my $d1_12_winter_offpeak_dollars = int(($d1_12_winter_offpeak_noncap_rate * $d1_12_winter_offpeak_kwh) / 100);
my $d1_12_summer_peak_dollars = int(($d1_12_summer_peak_noncap_rate * $d1_12_summer_peak_kwh) / 100);
my $d1_12_summer_offpeak_dollars = int(($d1_12_summer_offpeak_noncap_rate * $d1_12_summer_offpeak_kwh) / 100);

my $d1_12_total_kwh = int($d1_12_winter_peak_kwh + $d1_12_winter_offpeak_kwh + $d1_12_summer_peak_kwh + $d1_12_summer_offpeak_kwh);
my $d1_12_total_noncap_energy_dollars = $d1_12_winter_peak_dollars + $d1_12_winter_offpeak_dollars + $d1_12_summer_peak_dollars + $d1_12_summer_offpeak_dollars;

$d1_12_winter_peak_kwh = int($d1_12_winter_peak_kwh);
$d1_12_winter_offpeak_kwh = int($d1_12_winter_offpeak_kwh);
$d1_12_summer_peak_kwh = int($d1_12_summer_peak_kwh);
$d1_12_summer_offpeak_kwh = int($d1_12_summer_offpeak_kwh);

my $d1_12_grand_total_dollars = $d1_12_delivery_dollars_year + $d1_12_capacity_dollars_year + $d1_12_winter_peak_dollars + $d1_12_winter_offpeak_dollars + $d1_12_summer_peak_dollars + $d1_12_summer_offpeak_dollars;


if ($d1_12debug == 1)
{
	print "DEBUG_D1_12: TopHour1 date=$d1_12_demandhr1_date hour=$d1_12_demandhr1_hour kwh=$d1_12_demandhr1_kwh\n";
        print "DEBUG_D1_12: TopHour2 date=$d1_12_demandhr2_date hour=$d1_12_demandhr2_hour kwh=$d1_12_demandhr2_kwh\n";
        print "DEBUG_D1_12: TopHour3 date=$d1_12_demandhr3_date hour=$d1_12_demandhr3_hour kwh=$d1_12_demandhr3_kwh\n";
}


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

print "\n";
print "---Proposed Time-of-Day With Demand Charge D1.12 Plan (U-20836)---\n";
print "Demand Hour 1: $d1_12_demandhr1_date $d1_12_demandhr1_hour $d1_12_demandhr1_kwh kWh\n";
print "Demand Hour 2: $d1_12_demandhr2_date $d1_12_demandhr2_hour $d1_12_demandhr2_kwh kWh\n";
print "Demand Hour 3: $d1_12_demandhr3_date $d1_12_demandhr3_hour $d1_12_demandhr3_kwh kWh\n";
print "Service Level (demand): $d1_12_demand_level\n\n";

print "Delivery Charge (demand): \$$d1_12_delivery_dollars_year\n";
print "Capacity Energy Charge (demand): \$$d1_12_capacity_dollars_year\n\n";

print "Non-Capacity Energy Charges (usage):\n";
print "Summer Peak     kWh: $d1_12_summer_peak_kwh Cost: \$$d1_12_summer_peak_dollars\n";
print "Summer Off-Peak kWh: $d1_12_summer_offpeak_kwh Cost: \$$d1_12_summer_offpeak_dollars\n";
print "Winter Peak     kWh: $d1_12_winter_peak_kwh Cost: \$$d1_12_winter_peak_dollars\n";
print "Winter Off-Peak kWh: $d1_12_winter_offpeak_kwh Cost: \$$d1_12_winter_offpeak_dollars\n";
print "    Subtotal Non-Capacity Energy kWh: $d1_12_total_kwh Cost: \$$d1_12_total_noncap_energy_dollars\n\n";
print "Total D1.12 Cost: \$$d1_12_grand_total_dollars\n\n";



