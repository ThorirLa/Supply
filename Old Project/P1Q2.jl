using JuMP
using Gurobi
using DelimitedFiles

C = 10; # Number of customer
DC = 7; # Number of DC
P = 6; # Number of possible location for plants

f_plant_open = [0, 0, 1200000, 1850000, 1600000, 950000] #fixed cost for opening a plant
f_plant_close = [800000, 730000, 0, 0, 0, 0]
f_dc_open = [0, 0, 680000, 810000, 940000, 920000, 770000] #fixed cost for opening a DC
f_dc_close = [130000, 185000, 0, 0, 0, 0, 0]

plant_cap = [8000, 6500, 4800, 3600, 8100, 5200] #capacity for the plants k
dc_cap = [6000, 7000, 5000, 4000, 7500, 3400, 2800] #capacity for the DC

distance_DC_Customer = [269	    886	    1513	1379	2122	1346	2408	2620	2926	3920;
                        2470	1601	1238	2126	1961	1251	850	    400	    495	    1640;
                        3061	2164	2103	3002	2947	1651	1853	608	    696	    949;
                        2080	1309	716	    1557	1360	1166	391	    982	    1082	2233;
                        1188	447	    354	    1031	1346	658	    1177	1524	1776	2869;
                        1581	1250	559	    632	    474	    1518	971	    1970	2094	3245;
                        1221	1501	1262	361	    951	    1981	1914	2802	2977	4123]

distance_Plant_DC = [1733   996     1262	1101	922	1707	2294;
                    960	    1651    2041	1487	743	1595	1851;
                    3380	1141	450	1744	2335	2754	3610;
                    1803	814	1701	350	552	873	1680;
                    760	1994	2708	1542	700	1008	909;
                    1432	1665	2550	1101	652	335	820]

demand = [1500, 2200, 6100, 1400, 2100, 1800, 3800, 900, 4200, 1500]


model = Model(Gurobi.Optimizer);

@variable(model, x[1:DC], Bin); #if we open DC
@variable(model, z[1:P], Bin); #if we open a plant
@variable(model, w[1:P,1:DC] >= 0); #number of units transported from plant and DC
@variable(model, y[1:DC,1:C] >= 0); #number of units transported from DC to customer

@objective(model, Min,
          sum(f_dc_open[d]*x[d] for d = 1:DC) #fixed cost of opening a DC
        + sum(f_plant_open[p]*z[p] for p = 1:P) #fixed cost of opening a plant
        + sum(f_dc_close[d]*(1-x[d]) for d = 1:DC )
        + sum(f_plant_close[p]*(1-z[p]) for p = 1:P)
        + sum( 0.2*distance_DC_Customer[d,c]*y[d,c] for d = 1:DC, c = 1:C) #transportation cost between DC and customer
        + sum( 0.1*distance_Plant_DC[p,d]*w[p,d] for p = 1:P, d = 1:DC)); #transportation cost plant and DC


@constraint(model,[c = 1:C], sum(y[d,c] for d in 1:DC) == demand[c]); # fulfill demand fr each customer
@constraint(model,[d = 1:DC], sum(y[d,c] for c in 1:C) <= dc_cap[d]*x[d]); # DC capacity
@constraint(model,[p = 1:P], sum(w[p,d] for d in 1:DC) <= plant_cap[p]*z[p]); #plant capacity
@constraint(model,[d = 1:DC], sum(w[p,d] for p in 1:P) == sum(y[d,c] for c in 1:C)); #Balance constraint for DC eqally much in and out

optimize!(model)
println("The objective value: ", objective_value(model))

#What DC are open
for d = 1:DC
    if value(x[d]) == 1.0
        println("DC number ", d , " is open : ", value(x[d]))
    end
end

#What plants are open
for p = 1:P
    if value(z[p]) == 1.0
        println("Plant number ", p , " is open : ", value(z[p]))
    end
end

#Capacity usage at DC
for d = 1:DC
    println("DC number ",d," is using " ,value(sum(y[d,c] for c in 1:C)), " of max cap ", value(dc_cap[d]))
end

#Capacity usage at plants
for p = 1:P
    println("Plant number ",p," is using " ,value( sum(w[p,d] for d in 1:DC)), " of max cap ", value(plant_cap[p]))
end