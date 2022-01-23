# dte_plan_analyzer
A quick and very dirty script to examine a year's worth of your DTE Energy electric usage and calculate your cost on the D1 standard service plan vs the D1.2 time-of-day service plan

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
