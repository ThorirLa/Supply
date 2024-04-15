using XLSX
using DataFrames
using JuMP
using Gurobi
using Plots
using PyPlot


function solve_facility_location(n,m,c, f_closing_costs, f_opening_costs, capacity, h)

    #------
    # MODEL
    #------

    # n = facilities = j 
    # m = customers = i

    model = Model(Gurobi.Optimizer);

    @variable(model, x[1:n] >= 0, Bin);
    @variable(model, y[1:m,1:n] >= 0);

    @objective(model, Min, 
        sum(f_opening_costs[j]*x[j] for j in 1:n) + 
        sum(f_closing_costs[j]*(1-x[j]) for j in 1:n) + 
        sum(sum(h[i]*c[i,j]*y[i,j] for j in 1:n) for i = 1:m)  
        );

    @constraint(model,[i = 1:m], sum(y[i,j] for j in 1:n) == 1);
    @constraint(model,[i = 1:m, j = 1:n], y[i,j] <= x[j]);
    @constraint(model,[j = 1:n], sum(h[i]*y[i,j] for i in 1:m) <= capacity[j]);

    #-------
    # SOLVE
    #-------

    optimize!(model)

    # Print the optimal objective value
    println("Optimal Objective Value: ", objective_value(model))

    # Print which facilities are open
    for j = 1:n
        if value(x[j]) > 0.5
            println("Facility ", j, " is open")
        end
    end

    # Print capacity usage at facilities
    for j = 1:n
        println("Facility ", j , " usage: ", sum(value(h[i]*y[i, j]) for i = 1:m), "/", capacity[j])
    end

    return JuMP.value.(y)
    
end

# Read data from Excel file
xf = XLSX.readxlsx("facilityData.xlsx")




function read_column(sheet, firstrow, col)
    res = []
    row = firstrow
    while !ismissing(sheet[row,col])
        push!(res,sheet[row,col])
        row+=1
    end 
    return res
end


function Customer_data(xf, sheet_name)
    sheet = xf[sheet_name]

    firstrow = 2
    col = 1
    customer = read_column(sheet, firstrow, col)

    col = 2
    latitude = read_column(sheet, firstrow, col)

    col = 3
    longitude = read_column(sheet, firstrow, col)

    col = 4
    visits = read_column(sheet, firstrow, col)

    rawdata = DataFrame(customer = customer, latitude = latitude, 
            longitude = longitude, visits = visits)
    return rawdata
end

function facilities_data(xf, sheet_name)
    sheet = xf[sheet_name]

    firstrow = 2
    col = 1
    facility = read_column(sheet, firstrow, col)

    col = 2
    latitude = read_column(sheet, firstrow, col)

    col = 3
    longitude = read_column(sheet, firstrow, col)

    col = 4
    closing_cost = read_column(sheet, firstrow, col)

    col = 5
    opening_cost = read_column(sheet, firstrow, col)
    
    col = 6
    capacity = read_column(sheet, firstrow, col)

    col = 7
    type = read_column(sheet, firstrow, col)

    rawdata = DataFrame(facility = facility, latitude = latitude, longitude = longitude, closing_cost = closing_cost, opening_cost = opening_cost, capacity = capacity, type = type)
    return rawdata
end


customers_data = Customer_data(xf, "Customers")

facility_data = facilities_data(xf, "Fac")


# Function to calculate the Haversine distance between two points
function haversine_distance(lat1, lon1, lat2, lon2)
    # Radius of the Earth in kilometers
    R = 6371.0
    
    # Convert latitude and longitude from degrees to radians
    alfa1 = deg2rad(lat1)
    alfa2 = deg2rad(lat2)
    delta_alfa = deg2rad(lat2 - lat1)
    delta_beta = deg2rad(lon2 - lon1)
    
    # Haversine formula
    a = sin(delta_alfa/2)^2 + cos(alfa1) * cos(alfa2) * sin(delta_beta/2)^2
    c = 2 * atan(sqrt(a), sqrt(1-a))
    d = R * c  # Distance in kilometers
    
    return d
end

# Function to create distance matrix
function distance_matrix(customers_data, facility_data)
    n_customers = size(customers_data, 1)
    n_facilities = size(facility_data, 1)
    
    distance_mat = zeros(n_customers, n_facilities)
    
    for i in 1:n_customers
        for j in 1:n_facilities
            distance_mat[i, j] = haversine_distance(customers_data[i, :latitude], customers_data[i, :longitude],
                                                     facility_data[j, :latitude], facility_data[j, :longitude])
        end
    end
    
    return distance_mat
end


distance_mat = distance_matrix(customers_data, facility_data)

c = distance_mat*10


# Extract closing costs and opening costs 
f_closing_costs = facility_data.closing_cost
f_opening_costs = facility_data.opening_cost

# Extract the capacity
capacity = facility_data.capacity

h = customers_data.visits

# numer of customers 
m = length(customers_data.customer)
# number of facilities_data
n = length(facility_data.facility)


y = solve_facility_location(n,m,c, f_closing_costs, f_opening_costs, capacity, h)



#= # Function to plot facilities on a map
function plot_facilities_on_map(facility_data, opened_facilities)
    figure()
    scatter(facility_data.longitude, facility_data.latitude, label="Not operating facilities")
    scatter(facility_data.longitude[opened_facilities], facility_data.latitude[opened_facilities], color="red", label="Opened Facilities")
    xlabel("Longitude")
    ylabel("Latitude")
    title("Visualization of the Facilities")
    legend()
    grid(true)
    
    # Annotate opened facilities with their indices
    for i in opened_facilities
        annotate(string(i), xy=(facility_data.longitude[i], facility_data.latitude[i]), xytext=(3,3), textcoords="offset points")
    end
    
    # Save the plot as an image file
    savefig("opened_facilities_map.png")
end 

plot_facilities_on_map(facility_data, opened_facilities)

=#


using PyPlot

# Function to plot facilities and their connections to customers
function plot_facilities_connections(facility_data, opened_facilities, customer_data, y)
    # Initialize the PyPlot figure
    figure()
    # Plot all facilities
    scatter(facility_data.longitude, facility_data.latitude, label="Facilities", color="blue", alpha=0.5)
    scatter(facility_data.longitude[opened_facilities], facility_data.latitude[opened_facilities], color="red", label="Opened Facilities")

    # Draw connections from each customer to the assigned opened facility
    for i in 1:size(customer_data, 1)
        for j in opened_facilities
            if y[i,j] > 0.5  # This assumes y[i,j] is the decision variable for customer i to facility j
                plot([customer_data.longitude[i], facility_data.longitude[j]], [customer_data.latitude[i], facility_data.latitude[j]], "k-")
            end
        end
    end

    # Label axes and show legend
    xlabel("Longitude")
    ylabel("Latitude")
    title("Visualization of Facilities and Customer Connections")
    legend()
    grid(true)

    # Save the plot as an image file
    savefig("facilities_connections.png")
end




# Example usage
opened_facilities = [1, 2, 3, 8, 10]  # Assuming these are the indices of the opened facilities
plot_facilities_connections(facility_data, opened_facilities, customers_data, y)
