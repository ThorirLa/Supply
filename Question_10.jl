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

    # Read the data into an array
    data = XLSX.getdata(sheet)

    # Convert the array to a matrix and remove the first row and column
    matrix_data = convert(Matrix, data)[2:end, 2:end]

    return matrix_data
end

# Function to read time windows data
function read_time_windows(file_path, sheet_name)
    wb = XLSX.readxlsx(file_path)
    sheet = wb[sheet_name]
    data = XLSX.getdata(sheet)
    time_windows = convert(Matrix, data)[2:end, :]
    return time_windows
end

# Replace "vrpData.xlsx" with the actual path to your Excel file

#repair_times = read_excel_to_matrix("vrpData.xlsx", "repairTimes")
c_ij = read_excel_to_matrix("vrpData.xlsx", "c_ij_new")
repair_times = read_excel_to_matrix("vrpData.xlsx", "repairTimes")

using JuMP
using Gurobi

function solve_facility_location()

    #------
    # DATA
    #------

    n = 30; 
    m = 30; # number of customers

    #f = Parameter, the cost of selectiong cust n as a cluster rep
    f = [8	18.26033954	20	10.77032961	10	10.19803903	12.64911064	25.45584412	8.485281374	17.11724277	21.28003759	18.02775638	4.472135955	24.75883681	12.16552506	13.41640786	21.9317122	25.61249695	39.59797975	34	22.91200559	24.08318916	24.54057864	36.87817783	22.36067977	27.91128804	9.666436779	5.440588203	15.31012737	2.473863375];
    # c: Parameter, the cost of assigning cust n to the cluster that cust m represents
    c = read_excel_to_matrix("vrpData.xlsx", "c_ij_new");
    d = read_excel_to_matrix("vrpData.xlsx", "repairTimes");
    d=d[2:end]; #exclude the depot

    C = 6; #we have γ = 1, so same capacity

    #------
    # MODEL
    #------

    model = Model(Gurobi.Optimizer);

    @variable(model, x[1:n] >= 0, Bin); #1 if cust n is chosen as "cluster representative"
    @variable(model, y[1:n,1:m] >= 0, Bin); #cust n is assigned to cluster that cust m represnts

    @objective(model, Min, sum( f[j]*x[j] for j in 1:n) + sum( sum( c[i,j]*y[i,j] for j in 1:n) for i = 1:m));

    @constraint(model,[i = 1:m], sum(y[i,j] for j in 1:n) == 1);
    @constraint(model,[j = 1:n], sum( d[i]*y[i,j] for i = 1:m) <= C*x[j]);

    #-------
    # SOLVE
    #-------
    set_optimizer_attribute(model, "TimeLimit", 30);
    optimize!(model)

    println();
    for j = 1:n
        allocated = false;
        for i = 1:n
            if (value(y[i,j]) >= 0.99999)
                print((i+1)," ");
                allocated = true;
            end
        end
        if allocated
            println();
        end
    end
    

end

solve_facility_location();
