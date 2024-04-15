using XLSX
using DataFrames

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
    capacity = read_column(sheet, firstrow, col)

    col = 6
    type = read_column(sheet, firstrow, col)

    rawdata = DataFrame(facility = facility, latitude = latitude, 
            longitude = longitude, closing_cost = closing_cost, capacity = capacity, type = type)
    return rawdata
end


customers_data = Customer_data(xf, "Customers")

facility_data = facilities_data(xf, "Fac")

