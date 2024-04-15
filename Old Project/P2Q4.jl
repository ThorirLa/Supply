using JuMP
using Gurobi


#------
# DATA
#------

K = 15; # number vehicles
N = 16; # number of nodes, node 1 is the depot

C = 50;

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

@variable(model, x[1:N,1:N,1:K], Bin); # Binary, if vehicle k goes directly from node i to node j
@variable(model, y[1:N,1:K], Bin); # Binary, if vehicle k visits customer i
@variable(model, z[1:N,1:K] >= 0); # load of truck k when arriving at node i

@objective(model, Min, sum( 0.5*c[i,j]*x[i,j,k] for j = 1:N, i = 1:N, k = 1:K));

@constraint(model,[i = 2:N], sum(y[i,k] for k in 1:K) == 1); #each node has to be visited once
# if vehicle visits node it has to leave as well, inflow equals outflow
@constraint(model,[h = 1:N, k = 1:K], sum(i == h ? 0 : x[i,h,k] for i = 1:N) == y[h,k]);
@constraint(model,[h = 1:N, k = 1:K], sum(j == h ? 0 : x[h,j,k] for j = 1:N) == y[h,k]);
#capacity of the vehicle
@constraint(model,[k = 1:K], sum(d[i]*y[i,k] for i = 2:N) <= C);

#load-variable formulation
@constraint(model,[i = 2:N, j = 2:N, k = 1:K], z[i,k] - d[i] >= z[j,k] - (1-x[i,j,k])*sum(d));


#-------
# SOLVE
#-------

optimize!(model)

println();
for k = 1:K
    has_route = false;
    for i = 1:N
        for j = 1:N
            if (value(x[i,j,k]) == 1)
                print((i-1),"->",(j-1)," ")
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
