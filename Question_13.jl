using DataFrames, XLSX, Dates

# Load the workbook
wb = XLSX.readxlsx("vrpData.xlsx")

# Get the specified sheets
sheet_cw = wb["cw"]
sheet_times = wb["times"]
sheet_repairTimes = wb["repairTimes"]
sheet_distance = wb["dis_min_round"]

# Read the data into an array and skip headers by adjusting range
data_cw = XLSX.getdata(sheet_cw, "A2:C436")
data_times = XLSX.getdata(sheet_times, "A2:C31")
data_repairTimes = XLSX.getdata(sheet_repairTimes, "A2:C32")
data_distance = XLSX.getdata(sheet_distance, "B2:AF32")  # Adjust the range to exclude headers

# Convert to DataFrame and assign column names
savings = DataFrame(data_cw, [:i, :j, :s_ij])
times = DataFrame(data_times, [:Customer, :Start, :End])
repair_times = DataFrame(data_repairTimes, [:Customer, :Service_Time_h, :Service_Time_m])
distance_matrix = DataFrame(data_distance, Symbol.(0:30))  # Assuming there are 30 customers




# Function to convert time strings to Time type
function parse_time(str)
    h, m, s = split(str, ":")
    return Time(parse(Int, h), parse(Int, m), parse(Int, s))
end

# Apply time parsing if times are strings
if typeof(times[1, :Start]) == String
    times[!, :Start] = parse_time.(times[!, :Start])
    times[!, :End] = parse_time.(times[!, :End])
end

# Ensure the 's_ij' column is of type Float64
if savings[1, :s_ij] isa Number  # Check if the first element is a number
    savings[!, :s_ij] = float.(savings[!, :s_ij])  # Convert all to Float64 if not already
elseif savings[1, :s_ij] isa String
    savings[!, :s_ij] = parse.(Float64, savings[!, :s_ij])  # Parse strings to Float64
end




function check_time_feasibility(route, times, repair_times, travel_time_matrix, max_duration_minutes)
    # Start with the travel time from Home to the first customer
    customer_1 = route[1]
    #initial_travel_time_minutes = travel_time_matrix[1, customer_1 + 1]  # Assuming 'route' array is 1-indexed and corresponds to the matrix columns starting from the second column
    #initial_travel_time = Minute(initial_travel_time_minutes)
    #total_time = initial_travel_time_minutes
    
    # Get the start and end times for the first customer
    first_customer_start_time = times.Start[times.Customer .== customer_1][1]

    # Include service time at the first customer's location
    first_customer_service_time = repair_times.Service_Time_m[repair_times.Customer .== customer_1][1]
    total_time = first_customer_service_time

    # Start the service at the later of customer's start time or after travel time
    #current_time = max(first_customer_start_time, Time(0, 0) + Minute(initial_travel_time))
    
    current_time = max(first_customer_start_time, Time(0, 0))
    current_time += Minute(first_customer_service_time)

    #println("Customer $customer_1: Start - $first_customer_start_time, End - $current_time, Travel Time - $initial_travel_time, Service Time - $first_customer_service_time")
    println("Customer $customer_1: Start - $first_customer_start_time, End - $current_time, Service Time - $first_customer_service_time")



    # Start the loop from the second customer since we've already handled the travel time to the first customer
    for customer_idx in 2:length(route)
        prev_customer = route[customer_idx - 1]
        customer = route[customer_idx]
        customer_start = times.Start[times.Customer .== customer][1]
        customer_end = times.End[times.Customer .== customer][1]

        # Retrieve travel time from the previous customer to the current one
        travel_time_minutes = travel_time_matrix[prev_customer + 1, customer + 1]
        travel_time = Minute(travel_time_minutes)

        service_time_minutes = repair_times.Service_Time_m[repair_times.Customer .== customer][1]
        service_time = Minute(service_time_minutes)

        # Calculate earliest possible start time for this customer
        possible_start = max(current_time + travel_time, customer_start)
        
        # Print detailed timing information
        println("Customer $customer: Start - $possible_start, End - $(possible_start + service_time), Travel Time - $travel_time, Service Time - $service_time")

        # Check if the service can be completed within the customer's time window
        if possible_start > customer_end
            println("Cannot service customer $customer within their time window.")
            return false
        end

        # Update current_time and total_time after servicing this customer
        current_time = possible_start + service_time
        total_time += travel_time_minutes + service_time_minutes
    end

   

    # Final check against maximum duration
    if total_time <= max_duration_minutes
        println("Total route time: $total_time minutes (within limit)")
        return true
    else
        println("Total route time: $total_time minutes (exceeds limit!)")
        return false
    end

    
end


# Initialize routes with each customer as a separate route
routes = [[i] for i in 1:nrow(times)]
#sort!(savings, :s_ij, rev=true)  # Sort savings in descending order



# Implement the Clarke-Wright algorithm with time window constraints
for row in eachrow(savings)
    i, j = row.i, row.j
    route_i = findfirst(route -> i in route, routes)
    route_j = findfirst(route -> j in route, routes)

    if route_i != route_j
        merged_route = vcat(routes[route_i], routes[route_j])
        if check_time_feasibility(merged_route, times,repair_times, distance_matrix, 6 * 60)  # 6 hours converted to minutes
            routes[route_i] = merged_route
            deleteat!(routes, route_j)
        end
    end
end

println("Final route checks:")
for (index, route) in enumerate(routes)
    println("\nRoute $index: $route")
    check_time_feasibility(route, times, repair_times, distance_matrix, 6 * 60)  # 6 hours in minutes
end