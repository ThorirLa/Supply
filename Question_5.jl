using XLSX
using DataFrames
using JuMP
using Gurobi



# Extract the data from the worksheet
customer_demands_data = XLSX.readtable("facilityData.xlsx", "CustomerDemands")
facility_capacities_data = XLSX.readtable("facilityData.xlsx", "FacilityCapacities")

# Convert the extracted data to a DataFrame
customer_demands_df = DataFrame(customer_demands_data)
facility_capacities_df = DataFrame(facility_capacities_data)

# Get the customer demands scenarios columns
cust_scenarios = names(customer_demands_df)[2:end]
# Get the customer demands scenarios columns
fac_scenarios= names(facility_capacities_df)[2:end]


# Select only the scenario columns
customer_demands_scenarios = customer_demands_df[:, cust_scenarios]
facility_capacities_scenarios = facility_capacities_df[:, fac_scenarios]






