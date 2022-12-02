# dte_plan_analyzer
A quick and somewhat dirty script to examine a year's worth of your DTE Energy electric usage and calculate what your cost would have been on various residential rate plans including:
* D1 Standard Residential Service Rate
* D1.2 Enhanced Time-of-Use Residential Service Rate
* D1.11 Standard Time-of-Use Residential Service Rate


# How to use 
1. Download exactly one year's worth of your electric usage data from dteenergy.com in CSV format
2. Run the script with the CSV file as the argument
3. The results will be printed to standard output

# Rates and Assumptions
* Rate information for the D1, D1.2, and D1.11 plans were obtained from the [final order in rate case U-20836](https://mi-psc.force.com/sfc/servlet.shepherd/version/download/0688y0000058iIbAAI) as accessed on December 1, 2022.
* The rate elements considered by this script are the per-kWh component of: capacity energy charges, non-capacity energy charges, delivery charges
* Fixed monthly service charges are not accounted for by this script.
* Taxes, fees, surcharges, and credits not mentioned on the rate sheet are not accounted for by this script.
* Dollar and kWh amounts are truncated to integers near the end of the script (after all the accumulation has occurred).

# Known Bugs/Limitations/Caveats
* The 17 kWh/day tiering logic for the D1 standard plan is only computed to an hourly basis here. On actual DTE bills, the 17 kWh threshold is exact.
* This script does not currently work on DTE accounts associated with more than one electric meter. If your DTE account is associated with more than one electric meter, you will need to edit the CSV usage file to remove all rows pertaining to all meters other than the one you want to analyze. You will also need to remove the entire "meter number" column from the CSV usage file.

# Example
    ./calc.pl input.csv
    NOTICE: No (or invalid) data recorded for this hour: 2021-08-11 22
    NOTICE: No (or invalid) data recorded for this hour: 2021-08-11 23
    Note: It is normal to have "no (or invalid) data" for hours during which the power to your meter was out.
    
    
    ---Residential D1 Rate (U-20836)---
Tier 1 kWh: 6588 Cost: $1003
Tier 2 kWh: 13590 Cost: $2333
Total  kWh: 20178 Cost: $3336

---Residential D1.2 Enhanced Time-of-Use Rate (U-20836)---
Summer Peak     kWh: 2881 Cost: $634
Summer Off-Peak kWh: 7030 Cost: $841
Winter Peak     kWh: 2606 Cost: $512
Winter Off-Peak kWh: 7660 Cost: $902
Total           kWh: 20178 Cost: $2889

---Residential D1.11 Standard Time-of-Use Rate (U-20836)---
Summer Peak     kWh: 1291 Cost: $271
Summer Off-Peak kWh: 6929 Cost: $1070
Winter Peak     kWh: 1523 Cost: $255
Winter Off-Peak kWh: 10433 Cost: $1612
Total           kWh: 20178 Cost: $3208

