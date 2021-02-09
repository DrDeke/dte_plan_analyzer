# dte_plan_analyzer
A quick and very dirty script to examine a year's worth of your DTE Energy electric usage and calculate your cost on the D1 standard service plan vs the D1.2 time-of-day service plan

I whipped this up as a one-time thing and have not yet stepped through the debugging output in an attempt to verify that it is computing the D1.2 plan usage correctly. I plan to do that and will remove this statement once I have. 

I haven't yet decided whether I plan to tidy up and improve / generalize this code or not. 

# How to use 
1. Download exactly one year's worth of your electric usage data from dteenergy.com in CSV format
2. Use a text editor to delete the first line in the downloaded CSV file
3. Rename the resulting CSV file to input.csv and place it in the same directory as calc.pl
4. Run the script with no arguments
5. The results will be printed to standard output

# Rates and Assumptions
* All rate information was taken from [this rate sheet](https://newlook.dteenergy.com/wps/wcm/connect/23195474-a4d1-4d38-aa30-a4426fd3336b/WholeHouseRateOptions.pdf?MOD=AJPERES&CACHEID=23195474-a4d1-4d38-aa30-a4426fd3336b) as accessed on 9 February 2021. 
* Taxes, fees, surcharges, and credits not mentioned on the rate sheet are not accounted for by this script.
* Fixed monthly service charges are not accounted for by this script.
* Dollar and kWh amounts are truncated to integers near the end of the script (after all the accumulation has occurred).

# Example
    $ ./calc.pl
    
    
    ---Standard D1 Plan---
    Tier 1 kWh: 6543 Cost: $1000
    Tier 2 kWh: 10376 Cost: $1792
    Total  kWh: 16920 Cost: $2792
    
    ---Time-of-Day D1.2 Plan---
    Summer Peak     kWh: 1395 Cost: $316
    Summer Off-Peak kWh: 3409 Cost: $410
    Winter Peak     kWh: 3099 Cost: $626
    Winter Off-Peak kWh: 9015 Cost: $1065
    Total           kWh: 16920 Cost: $2417
    
In this example, the consumer would have paid approximately $375 more for the year's electricity on the D1 standard rate than the D1.2 time of day rate.
