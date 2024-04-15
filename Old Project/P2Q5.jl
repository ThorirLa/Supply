using JuMP
using Gurobi


#------
# DATA
#------

K_Truck = 15; # number vehicles
K_El = 5;
N = 16; # number of nodes, node 1 is the depot

C_Truck = 80;
C_El = 50;

d = [0 20 38 16 41 19 30 17 38 26 19 32 25 33 14 31] 


c =  [   0	296	68	237	174	36	59	335	54	342	295	221	191	154	190	211
296	0	364	202	197	314	237	470	313	228	55	499	123	450	408	224
68	364	0	291	231	61	127	335	76	397	362	165	257	87	177	260
237	202	291	0	64	230	200	271	283	106	245	454	212	357	246	322
174	197	231	64	0	170	137	279	220	168	228	393	170	302	216	270
36	314	61	230	170	0	82	302	84	336	318	225	217	138	155	245
59	237	127	200	137	82	0	349	87	303	237	272	134	213	221	175
335	470	335	271	279	302	349	0	386	314	507	470	442	337	161	522
54	313	76	283	220	84	87	386	0	388	303	187	197	157	236	185
342	228	397	106	168	336	303	314	388	0	281	560	285	461	334	402
295	55	362	245	228	318	237	507	303	281	0	484	106	449	429	184
221	499	165	454	393	225	272	470	187	560	484	0	380	133	310	333
191	123	257	212	170	217	134	442	197	285	106	380	0	344	342	118
154	450	87	357	302	138	213	337	157	461	449	133	344	0	178	341
190	408	177	246	216	155	221	161	236	334	429	310	342	178	0	396
211	224	260	322	270	245	175	522	185	402	184	333	118	341	396	0];


#------
# MODEL
#------

model = Model(Gurobi.Optimizer);
set_optimizer_attribute(model, "TimeLimit", 90);

@variable(model, xt[1:N,1:N,1:K_Truck], Bin); # Binary, if vehicle k goes directly from node i to node j
@variable(model, yt[1:N,1:K_Truck], Bin); # Binary, if vehicle k visits customer i
@variable(model, zt[1:N,1:K_Truck] >= 0); # load of truck k when arriving at node i

@variable(model, xe[1:N,1:N,1:K_El], Bin); # Binary, if vehicle k goes directly from node i to node j
@variable(model, ye[1:N,1:K_El], Bin); # Binary, if vehicle k visits customer i
@variable(model, ze[1:N,1:K_El] >= 0); # load of truck k when arriving at node i

@objective(model, Min, sum( 0.5*c[i,j]*xe[i,j,ke] for j = 1:N, i = 1:N, ke = 1:K_El)
                    + sum( c[i,j]*xt[i,j,kt] for j = 1:N, i = 1:N, kt = 1:K_Truck));

#each node has to be visited once, either by truck or el
@constraint(model,[i = 2:N], sum(ye[i,ke] for ke in 1:K_El) + sum(yt[i,kt] for kt in 1:K_Truck) == 1); 

# if vehicle visits node it has to leave as well, inflow equals outflow
@constraint(model,[h = 1:N, ke = 1:K_El], sum(i == h ? 0 : xe[i,h,ke] for i = 1:N) == ye[h,ke]);
@constraint(model,[h = 1:N, ke = 1:K_El], sum(j == h ? 0 : xe[h,j,ke] for j = 1:N) == ye[h,ke]);

@constraint(model,[h = 1:N, kt = 1:K_Truck], sum(i == h ? 0 : xt[i,h,kt] for i = 1:N) == yt[h,kt]);
@constraint(model,[h = 1:N, kt = 1:K_Truck], sum(j == h ? 0 : xt[h,j,kt] for j = 1:N) == yt[h,kt]);

#capacity of the vehicle
@constraint(model,[ke = 1:K_El], sum(d[i]*ye[i,ke] for i = 2:N) <= C_El);
@constraint(model,[kt = 1:K_Truck], sum(d[i]*yt[i,kt] for i = 2:N) <= C_Truck);

#load-variable formulation
@constraint(model,[i = 2:N, j = 2:N, ke = 1:K_El], ze[i,ke] - d[i] >= ze[j,ke] - (1-xe[i,j,ke])*sum(d));
@constraint(model,[i = 2:N, j = 2:N, kt = 1:K_Truck], zt[i,kt] - d[i] >= zt[j,kt] - (1-xt[i,j,kt])*sum(d));

#max driving distance for electricity car
@constraint(model,[ke = 1:K_El], sum( c[i,j]*xe[i,j,ke] for i=1:N,j=1:N) <= 500);


#-------
# SOLVE
#-------

optimize!(model)

print("\ntotal cost = ");
println(objective_value(model));

println();
for ke = 1:K_El
    has_route = false;
    for i = 1:N
        for j = 1:N
            if (value(xe[i,j,ke]) == 1)
                print((i-1),"->",(j-1)," ")
                has_route = true;
            end
        end
    end
    if has_route
        println();
    end
end

println();
for k = 1:K_Truck
    has_route = false;
    for i = 1:N
        for j = 1:N
            if (value(xt[i,j,k]) == 1)
                print((i-1),"->",(j-1)," ")
                has_route = true;
            end
        end
    end
    if has_route
        println();
    end
end