# dte_plan_analyzer
A quick and somewhat dirty script to examine a year's worth of your DTE Energy electric usage and calculate what your cost would have been on various residential rate plans including:
* D1 Standard Residential Electric Service Rate
* D1.2 Residential Time-of-Day Rate
* D1.11 Proposed Residential Time-of-Day Rate (U-20836)
* D1.12 Proposed Residential Time-of-Day with Demand Component Rate (U-20836)

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
* For the D1.12 plan, each month's demand-based charges are computed based on the past 12 billing months on a rolling basis. Since we only have one year's worth of data to work with, this script computes your demand level for the entire service year and uses that level for each billing month.
* For the D1.12 plan, if your demand level is greater than 9 kW, DTE computes the additional demand-based charges with a granularity of 0.1 kW. This script does not use 0.1 kW thresholds; instead, it uses all available precision. 
* This script does not currently work on DTE accounts associated with more than one electric meter. If your DTE account is associated with more than one electric meter, you will need to edit the CSV usage file to remove all rows pertaining to all meters other than the one you want to analyze. You will also need to remove the entire "meter number" column from the CSV usage file.

# Example
    ./calc.pl input.csv
    NOTICE: No (or invalid) data recorded for this hour: 2021-08-11 22
    NOTICE: No (or invalid) data recorded for this hour: 2021-08-11 23
    Note: It is normal to have "no (or invalid) data" for hours during which the power to your meter was out.
    
    
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
    Summer Peak     kWh: 1027 Cost: $196
    Summer Off-Peak kWh: 5332 Cost: $927
    Winter Peak     kWh: 1268 Cost: $225
    Winter Off-Peak kWh: 8966 Cost: $1559
    Total           kWh: 16595 Cost: $2907
    
    ---Proposed Time-of-Day With Demand Charge D1.12 Plan (U-20836)---
    Demand Hour 1: 10/02/2021 8:00 PM 7.231 kWh
    Demand Hour 2: 06/09/2021 3:00 PM 7.227 kWh
    Demand Hour 3: 06/10/2021 2:00 PM 6.621 kWh
    Service Level (demand): 7
    
    Delivery Charge (demand): $903
    Capacity Energy Charge (demand): $491
    
    Non-Capacity Energy Charges (usage):
    Summer Peak     kWh: 1027 Cost: $66
    Summer Off-Peak kWh: 5332 Cost: $252
    Winter Peak     kWh: 1268 Cost: $65
    Winter Off-Peak kWh: 8966 Cost: $424
        Subtotal Non-Capacity Energy kWh: 16595 Cost: $807
    
    Total D1.12 Cost: $2201
    
    ---Comparison Summary---
    D1               Cost: $2736
    D1.2             Cost: $2400
    D1.11 (Proposed) Cost: $2907
    D1.12 (Proposed) Cost: $2201
