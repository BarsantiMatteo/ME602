######
# Author: S. Moret and X. Li
# Date: 04.12.2019
#
# Reference:
# S. Moret, M. Bierlaire and F. Marechal. Robust Optimization for Strategic Energy Planning, in Informatica, vol. 27, num. 3, p. 625-648, 2016.
######

#------------------------------------------
# SETS
#------------------------------------------

set PERIODS := 1 .. 13;
set UNITS := {"BOIL", "FC", "STO", "HP", "PV", "GSHP"};

#------------------------------------------
# PARAMETERS
#------------------------------------------

param c_ng {PERIODS} >= 0; # Natural gas cost [CHF/kWh]
param c_el_buy {PERIODS} >= 0; # Cost of importing electricity [CHF/kWh]
param f_min {UNITS} >= 0; # Lower bound for multiplication factor of each unit
param f_max {UNITS} >= 0; # Upper bound for multiplication factor of each unit
param C_inv1 {UNITS} >= 0; # q coefficient of the linear equation for inv cost [CHF]
param C_inv2 {UNITS} >= 0; # m coefficient of the linear equation for inv cost [CHF]
param E_out_ref {UNITS} >= 0; # default 0; # Electrical power in output if f(u,t) = 1
param Q_out_ref {UNITS} >= 0; # default 0; # Thermal power in output if f(u,t) = 1
param E_demand {PERIODS} >= 0; # electricity demand from the house [kW]
param Q_demand {PERIODS} >= 0; # heating demand from the house [kW]
param t_op {PERIODS} >= 0; # duration of one time [h]
param i >= 0; # interest rate
param n >= 0; # equipment lifetime [years]
param c_p {PERIODS, UNITS} >= 0 default 1; # capacity factor for each technology for each month
param eff_el {UNITS} >= 0; # units electrical efficiency [-]
param eff_th {UNITS} >= 0; # units thermal efficiency [-]
param p_el_sell {PERIODS} >= 0; # Price of selling electricity [CHF/kWh]
param	tau := i*(i+1)^n/((1+i)^n - 1); # Annualisation factor (specified as parameter in GLPK)

#------------------------------------------------------
# VARIABLES
#------------------------------------------------------

var y {UNITS} >= 0 binary; # 0/1 variable/investment decision for the unit
var f {UNITS, PERIODS} >= 0; # multiplication factor for each unit and each time
var f_c_p {UNITS, PERIODS} >= 0; # multiplication factor taking into account c_p
var E_buy {PERIODS} >= 0; # Electricity imported [kW]
var E_sell {PERIODS} >= 0; # Electricity exported [kW]
var Q_ng {UNITS, PERIODS} >= 0; # Natural gas input [kW]
var E_in {UNITS, PERIODS} >= 0; # Electrical power input [kW]
var E_out {UNITS, PERIODS} >= 0; # Electrical power output [kW]
var Q_in {UNITS, PERIODS} >= 0; # Thermal power input [kW]
var Q_out {UNITS, PERIODS} >= 0; # Thermal power output [kW]
var Q_rej {PERIODS} >= 0; # Heat rejected from the system
var f_size {UNITS} >= 0; # Size of the unit (max. value over different PERIODS)
var C_inv {UNITS} >= 0;  
var STO_level {PERIODS} >= 0; # Level of the storage tank [kWh]
var yy >= 0; # fuel cell heat pump

var Q_district {PERIODS} <= 0.01 * 106; # THERMAL POWER FROM DISTRICT HEATING IN KW

#------------------------------------------------------
# CONSTRAINTS
#------------------------------------------------------

subject to units_f_max {u in UNITS}:
	f_size[u] <= f_max[u] * y[u];

subject to units_size {u in UNITS diff {"STO"}, t in PERIODS}:
	f[u,t] <= f_size [u];
	
subject to units_f_min {u in UNITS}:
	f_size[u] >= f_min[u] * y[u];
	
subject to units_f_c_p {u in UNITS, t in PERIODS}:
	f_c_p [u,t] = f [u,t] * c_p [t, u];
	
subject to Cost_inv {u in UNITS}:
	C_inv[u] = C_inv1[u] * y [u] + f_size[u] * C_inv2[u];

subject to Elec_balance {t in PERIODS}:
	E_buy[t] + sum {u in UNITS} (E_out[u,t] - E_in[u,t]) - E_demand[t] - E_sell [t] = 0;

subject to Heat_balance {t in PERIODS}:
	sum{u in UNITS} (Q_out[u,t] - Q_in[u,t]) - Q_demand[t] - Q_rej[t] + Q_district[t] = 0;
	
subject to Elec_out {u in UNITS, t in PERIODS}:
	E_out [u, t] = E_out_ref [u] * f_c_p [u, t];

# Need of using a different equation for cogeneration (FC)
subject to Heat_out {u in UNITS diff {"STO"}, t in PERIODS}:
	Q_out [u, t] = (if u != "FC"
		then 
			Q_out_ref [u] * f_c_p [u, t]
		else
			Q_ng ["FC", t] * eff_th["FC"]);
			

subject to yy_1 :
	yy <= 1 - y["PV"];

subject to yy_2 :
	yy <= 1 - y["FC"];

subject to cons_el:
	E_buy [13] <= 2 + y ["HP"] + 4 * yy ;

# constrain minimum heat recovery from waste heat
subject to const_waste_heat {t in PERIODS}:
	Q_district[t] >= 0;

#-------------------------------------------
# TECHNOLOGY-SPECIFIC CONSTRAINTS
#-------------------------------------------

## Boiler
subject to Boiler_NG_in {t in PERIODS}:
	Q_ng ["BOIL", t] = Q_out_ref ["BOIL"] / eff_th["BOIL"] * f_c_p ["BOIL", t];

## Fuel Cell
subject to FC_NG_in {t in PERIODS}:
	Q_ng ["FC", t] = E_out_ref ["FC"] / eff_el["FC"] * f_c_p["FC",t];

## Storage
subject to Storage_level {t in PERIODS}: STO_level [t] = (if t == 1
then
	STO_level [13] + (E_in ["STO",t] + Q_in ["STO",t] - Q_out ["STO", t]) * t_op [t]
else
	STO_level [t-1] + (E_in ["STO",t] + Q_in ["STO",t] - Q_out ["STO", t]) * t_op [t]);

# This equation makes sure that the cost of the storage unit is calculated based not on the output
# but on the STO_level -> the maximum of STO_level is the storage size.
subject to Storage_capacity {t in PERIODS}:
	STO_level[t] <= Q_out_ref ["STO"] * f_size ["STO"];

# The storage shouldn't be used to cover the peak. Minimum discharge time is one month
subject to Storage_peak2{t in PERIODS}:
	Q_out ["STO", t] <=  Q_out_ref ["STO"] * f_size ["STO"] / 672;

## Heat Pump
subject to HP_E_in {t in PERIODS}:
	E_in ["HP", t] = Q_out_ref ["HP"] / eff_th["HP"] * f_c_p["HP",t];

## Heat Pump
subject to GSHP_E_in {t in PERIODS}:
	E_in ["GSHP", t] = Q_out_ref ["GSHP"] / eff_th["GSHP"] * f_c_p["GSHP",t];
#--------------------------------------------
# OBJECTIVE FUNCTION
#--------------------------------------------

minimize TotalCost:
	(tau) * sum{u in UNITS} C_inv[u] + sum {t in PERIODS} ((sum{u in UNITS} (c_ng[t] * Q_ng [u, t]) + c_el_buy[t] * E_buy[t] - p_el_sell[t] * E_sell[t])*t_op[t]);
	
