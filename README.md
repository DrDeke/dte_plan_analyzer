# dte_plan_analyzer
A quick and somewhat dirty script to examine a year's worth of your DTE Energy electric usage and calculate what your cost would have been on various residential rate plans including:
* D1 Standard Residential Electric Service Rate
* D1.2 Residential Time-of-Day Rate
* D1.11 Proposed Residential Time-of-Day Rate (U-20836)

# How to use 
1. Download exactly one year's worth of your electric usage data from dteenergy.com in CSV format
2. Run the script with the CSV file as the argument
3. The results will be printed to standard output

# Rates and Assumptions
* Rate information for the D1 and D1.2 plans were taken from [this rate sheet](https://newlook.dteenergy.com/wps/wcm/connect/23195474-a4d1-4d38-aa30-a4426fd3336b/WholeHouseRateOptions.pdf?MOD=AJPERES&CACHEID=23195474-a4d1-4d38-aa30-a4426fd3336b) as accessed on 9 February 2021. 
* Rate information for the proposed D1.11 and D1.12 plans were taken from DTE's [2022 Rate Case U-20836](https://mi-psc.force.com/s/case/500t000000WH1HKAA1/in-the-matter-of-the-application-of-dte-electric-company-for-authority-to-increase-its-rates-amend-its-rate-schedules-and-rules-governing-the-distribution-and-supply-of-electric-energy-and-for-miscellaneous-accounting-authority) as filed on 21 January 2022.
* Taxes, fees, surcharges, and credits not mentioned on the rate sheet are not accounted for by this script.
* Fixed monthly service charges are not accounted for by this script.
* Dollar and kWh amounts are truncated to integers near the end of the script (after all the accumulation has occurred).

# Known Bugs/Limitations/Caveats
* The 17 kWh/day tiering logic for the D1 standard plan is only computed to an hourly basis here. On actual DTE bills, the 17 kWh threshold is exact.
* This script does not currently work on DTE accounts associated with more than one electric meter. If your DTE account is associated with more than one electric meter, you will need to edit the CSV usage file to remove all rows pertaining to all meters other than the one you want to analyze. You will also need to remove the entire "meter number" column from the CSV usage file.

# Example
    $ ./calc.pl input.csv
    
    ---Standard D1 Plan---
    Tier 1 kWh: 6548 Cost: $1001
    Tier 2 kWh: 10047 Cost: $1735
    Total  kWh: 16595 Cost: $2736

    ---Time-of-Day D1.2 Plan---
    Summer Peak     kWh: 2199 Cost: $499
    Summer Off-Peak kWh: 5443 Cost: $654
    Winter Peak     kWh: 2256 Cost: $456
    Winter Off-Peak kWh: 6696 Cost: $791
    Total           kWh: 16595 Cost: $2400

    ---Proposed Time-of-Day D1.11 Plan (U-20836)---
    Summer Peak     kWh: 1253 Cost: $239
    Summer Off-Peak kWh: 5106 Cost: $888
    Winter Peak     kWh: 1593 Cost: $283
    Winter Off-Peak kWh: 8641 Cost: $1502
    Total           kWh: 16595 Cost: $2912
    
In this example, the consumer would have paid approximately $375 more for the year's electricity on the D1 standard rate than the D1.2 time of day rate.
