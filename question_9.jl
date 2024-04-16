#module Routing_Tech1
using JuMP
using Gurobi
using XLSX
using DataFrames

# Function to read Excel data into a matrix, skipping the first row and column
function read_excel_to_matrix(file_path, sheet_name)
    # Load the workbook
    wb = XLSX.readxlsx(file_path)

    # Get the specified sheet
    sheet = wb[sheet_name]

    # Read the data into an array, dropping the first row and column
    data = XLSX.getdata(sheet)#, drop=1:1, droprows=1)
    data=data[2:end,2:end]
    
    
    # Convert the array to a matrix
    #matrix_data = hcat(data...)
    return data
end

distances_matrix = read_excel_to_matrix("vrpData.xlsx", "distances")
#repair_times = read_excel_to_matrix("vrpData.xlsx", "repairTimes")
repair_times = read_excel_to_matrix("vrpData.xlsx", "repairTimes")
distances_matrix


# Function to read Excel data into a matrix, skipping the first row and column
function read_excel_to_matrix(file_path, sheet_name)
    # Load the workbook
    wb = XLSX.readxlsx(file_path)

    # Get the specified sheet
    sheet = wb[sheet_name]

    # Read the data into an array
    data = XLSX.getdata(sheet)

    # Convert the array to a matrix and remove the first row and column
    # The `[2:end, 2:end]` slicing skips the first row and the first column
    matrix_data = convert(Matrix, data)[2:end, 2:end]

    return matrix_data
end

# Replace "vrpData.xlsx" with the actual path to your Excel file
distances_matrix = read_excel_to_matrix("vrpData.xlsx", "distances")
#repair_times = read_excel_to_matrix("vrpData.xlsx", "repairTimes")
repair_times = read_excel_to_matrix("vrpData.xlsx", "repairTimes")

function vrp_load_constraint()

    #------
    # DATA
    #------

    K = 10 # number vehicles
    N = 31; # number of nodes, node 1 is the depot

    C = 6; #capa for working hours excluding driving

    d = repair_times

    c = distances_matrix
    
    #------
    # MODEL
    #------

    model = Model(Gurobi.Optimizer);

    @variable(model, x[1:N,1:N,1:K] >= 0, Bin); #node to node coverd by truck
    @variable(model, y[1:N,1:K] >= 0, Bin); #
    @variable(model, z[1:N,1:K] >= 0); # load of truck k when arriving at node i

    @objective(model, Min, sum( sum( sum( c[i,j]*x[i,j,k]  for j in 1:N) for i in 1:N) for k = 1:K)); #mimize distance covered
    

    @constraint(model,[i = 2:N], sum(y[i,k] for k in 1:K) == 1); #every cust visited
    @constraint(model,[h = 1:N, k = 1:K], sum(i == h ? 0 : x[i,h,k] for i = 1:N) == y[h,k]); #inflow = outflow
    @constraint(model,[h = 1:N, k = 1:K], sum(j == h ? 0 : x[h,j,k] for j = 1:N) == y[h,k]); #inflow = outflow
    @constraint(model,[k = 1:K], sum(d[i]*y[i,k] for i = 2:N) <= C); #not exceeding work hours capa

    @constraint(model,[i = 2:N, j = 2:N, k = 1:K], z[i,k] - d[i] >= z[j,k] - (1-x[i,j,k])*sum(d));  #load constraint - subtour elimi

    #-------
    # SOLVE
    #-------
    set_optimizer_attribute(model, "TimeLimit", 30);
    optimize!(model)
    

    println();
    for k = 1:K
        has_route = false;
        for i = 1:N
            for j = 1:N
                if (value(x[i,j,k]) == 1)
                    print(i-1,"->",j-1," ")
                    has_route = true;
                end
            end
        end
        if has_route
            println();
        end
    end

    print("\ntotal cost = ");
    println(objective_value(model));

end

vrp_load_constraint();