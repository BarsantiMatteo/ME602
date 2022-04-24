# ------------------------------------------------------------------------------------------
# cleaning-in-place (cip) for glass bottles (model file)
# Author: Maziar Kermani
# Last updated: 2019-12-05
# Reference (case study): Marechal, F., Sachan, A.K., Salgueiro, l., 2013. 27 - application of process integration methodologies in 
#  the brewing industry a2  - Klemeš, Jiří j., in: handbook of process integration (pi),
#	 woodhead publishing series in energy. woodhead publishing, pp. 820–863.
# ------------------------------------------------------------------------------------------

# ------------------------------------------------------------------------------------------
# independent parameters declaration

param juice_mass;        # juice mass flow [kg/s]
param bottle_weight;     # bottle weight
param bottle_cap;        # bottle capacity [l/bottle = kg/bottle]
param bottle_cp;         # heat capacity [kJ/kgK]
param bottle_cold_tin;   # inlet temperature of cold dirty bottle [C]
param bottle_cold_tout;  # outlet temperature of cold dirty bottle [C]
param bottle_cold_dt;    # delta T approach
param bottle_hot_tin;    # inlet temperature of hot clean bottle
param bottle_hot_tout;   # outlet temperature of hot clean bottle
param bottle_hot_dt;     # delta T approach
param eff_he_bottle_in;# assuming an efficiency in pre-rinsing for heating up bottles (low because it is a spray)
param eff_he_bottle_out;# assuming an efficiency in soda bath for heating up bottles
param eff_he_bottle_fin; # the bottles are soaked in water

param price_water;       # price of water CHF/m3
param price_steam;       # price of steam CHF/kWh
param op_time;           # operating hours per year
param water_dt;          # heat recovery approach temperature for water
# calculated parameters

param bottle_mass_flow  := juice_mass/bottle_cap*bottle_weight;	# mass flow of bottles
param bottle_cold_dh    := bottle_mass_flow * bottle_cp * abs(bottle_cold_tin - bottle_cold_tout);
param bottle_hot_dh     := bottle_mass_flow * bottle_cp * abs(bottle_hot_tin - bottle_hot_tout);
param heat_load_initial := bottle_cold_dh; # heat load of the initial rinsing and soda bath (what you have calculated, although from the bottle side considering the efficiency)
param heat_load_final   := bottle_hot_dh/eff_he_bottle_out; # heat load of the final rinsing (what you have calculated, although from the bottle side considering the efficiency)

# ------------------------------------------------------------------------------------------
# sets
set SOURCES default {};
set SINKS default {};
set CONTAMINANT default {};
set UNITS := SOURCES union SINKS;
set UNITS_MASS := SOURCES inter SINKS;
# ------------------------------------------------------------------------------------------
# parameters based on sets

param units_cont_max_in {u in SINKS, c in CONTAMINANT} default 0;
param units_cont_max_out {u in SOURCES, c in CONTAMINANT} default 0;
param units_mass_load {u in UNITS_MASS, c in CONTAMINANT} default 0;
param t_u {u in UNITS diff UNITS_MASS} default 15;

# minimum and maximum size of units
param units_fmin {u in UNITS} :=
	if (u in UNITS_MASS) then
		max {c in CONTAMINANT} units_mass_load[u,c]*1000/units_cont_max_out[u,c]
	else
		0;

param units_fmax {u in UNITS} := 
	# if (u in UNITS_MASS) then
	# 	min {c in CONTAMINANT} units_mass_load[u,c]*1000/(units_cont_max_in[u,c] - units_cont_max_in[u,c])
	# else 
		100; 

# ------------------------------------------------------------------------------------------
# variables

var t_u_in 	{u in SINKS} >= 0, <= 90;
var t_u_out {u in SOURCES} >= 0;
var mass_flow {u in UNITS} >= 0;
var mass_ship {u in SOURCES, uu in SINKS} >= 0;
var mass_contaminant {u in SINKS, c in CONTAMINANT} >= 0;
var mass_contaminant_out {u in SOURCES, c in CONTAMINANT} >= 0;
var t_ww_out >= t_u['u_waste'];
var heat_hot >= 0;
var heat_load_ww_cooler >= 0;

# ------------------------------------------------------------------------------------------
# constraints

# upper bound of mass of units
subject to unit_mass_lb {u in UNITS}:
	mass_flow[u] <= units_fmax[u];
# lower bound of mass of units
subject to unit_mass_ub {u in UNITS}:
	mass_flow[u] >= units_fmin[u];

# contamination at mixers
# mC_i = sum_{j in resources} m_{j,i} * C_max{j,out}
subject to mass_contaminant_cstr {u in SINKS, c in CONTAMINANT}:
	mass_contaminant[u,c] = sum {uu in SOURCES} units_cont_max_out[uu,c]*mass_ship[uu,u]; # see project comments

# contamination inequality at inlets of units (i.e. at the inlet of unit due to mixing contamination cannot be higher than the maximum allowed)
subject to mass_contaminant_ub {u in SINKS, c in CONTAMINANT}:
	mass_contaminant[u,c] / mass_flow[u] <= units_cont_max_in[u,c];  # check

# contamination mass transfer in each unit (the formulation that you have in your project description)
subject to mass_load_cstr {u in UNITS_MASS, c in CONTAMINANT}:
	mass_contaminant[u,c] + units_mass_load[u,c] <= units_cont_max_out[u,c] * mass_flow[u];

# non-isothermal mixing. This is an equaity but for convergence reasons we make two equations out of it.
# upper bound of non-isothermal mixing
subject to mass_temperature_cstr_1 {u in SINKS}:
	sum {uu in SOURCES} (mass_ship[uu,u] * t_u_out[uu]) - mass_flow[u] * t_u_in[u] <= 0.001;

# lower bound of non-isothermal mixing
subject to mass_temperature_cstr_2 {u in SINKS}:
	sum {uu in SOURCES} (mass_ship[uu,u] * t_u_out[uu]) - mass_flow[u] * t_u_in[u] >= -0.001; # to make it converge to 0

# mass balance at inlets of sinks
subject to mass_balance_sink_cstr {u in SOURCES}:
	sum {uu in SINKS} mass_ship[u,uu] = mass_flow[u];

# mass balance at the outlet of sources
subject to mass_balance_source_cstr {u in SINKS}:
	sum {uu in SOURCES} mass_ship[uu,u] = mass_flow[u];

# overall mass balance
subject to overall_mass_balance_cstr:
	sum {u in SOURCES} mass_flow[u] = sum {uu in SINKS} mass_flow[uu];

# heat load of final rinsing
subject to bottle_hot_heat_balance {u in UNITS_MASS: u = 'u_final'}: # use u_final as name of the final rinsing unit
	mass_flow[u] * 4.18 * (t_u_out[u] - t_u_in[u]) = heat_load_final;

# DT_min approach in final rinsing (one end)
subject to u_final_tin_cstr {u in UNITS_MASS: u = 'u_final'}:
	t_u_in[u] <= bottle_hot_tout - bottle_hot_dt;

# DT_min approach in final rinsing (the other end)	
subject to u_final_tout_cstr {u in UNITS_MASS: u = 'u_final'}: #name of the final rinsing unit#
	t_u_out[u] <= bottle_hot_tin - bottle_hot_dt; 

# inlet of final rinsing has higher temperature than fresh water
subject to u_final_tin_lb_cstr {u in UNITS_MASS: u = 'u_final'}: #name of the final rinsing unit#
	t_u_in[u] >= 15; # the temperature of fresh water is 15

# heat load of bottle warming
subject to bottle_cold_heat_balance:
	sum {u in UNITS_MASS: u <> 'u_final'} mass_flow[u] * 4.18 * (t_u_in[u] - t_u_out[u]) =  bottle_mass_flow * bottle_cp * (bottle_cold_tout - bottle_cold_tin)/eff_he_bottle_in;

# heat load of bottle warming just for initial rinsing
subject to bottle_cold_initial_heat_cstr:
	sum {u in UNITS_MASS: u = 'u_initial'} mass_flow[u] * 4.18 * (t_u_in[u] - t_u_out[u]) = bottle_mass_flow * bottle_cp * (bottle_cold_tout- bottle_cold_tin)/eff_he_bottle_in; # should the change the temperature of bottles to variable

# heat load of bottle warming just for soda bath
subject to bottle_cold_middle_heat_cstr:
	sum {u in UNITS_MASS: u = 'u_middle'} mass_flow[u] * 4.18 * (t_u_in[u]- t_u_out[u]) = bottle_mass_flow * bottle_cp * (56 - 75)/eff_he_bottle_in; # should be converted into variables becaraeful here
	
# DT_min approach in initial rinsing (one end)
subject to u_initial_tin_cstr {u in UNITS_MASS: u = 'u_initial' }:
	t_u_in[u] >= bottle_cold_tin + bottle_cold_dt;

# DT_min approach in initial rinsing (the other end)
subject to u_initial_tout_cstr {u in UNITS_MASS: u = 'u_initial' }:
	t_u_out[u] >= 56 + bottle_cold_dt;

# DT_min approach in middle rinsing (one end)
subject to u_middle_tin_cstr {u in UNITS_MASS: u = 'u_middle'}:
	t_u_in[u] >= 56 + bottle_hot_dt; # should we use bottle_cold_dt (7°C) or bottle_hot_dt (2°C)

# DT_min approach in middle rinsing (the other end)
subject to u_middle_tout_cstr {u in UNITS_MASS: u = 'u_middle'}:
	t_u_out[u] >= 75 + bottle_hot_dt;

# fresh water temperature
subject to temperature_fw_cstr {u in SOURCES: u = 'u_fresh'}:
	t_u_out[u] = t_u[u];

# temperature of steam (h/cp)
subject to temperature_steam_cstr {u in SOURCES: u = 'u_steam'}:
	t_u_out[u] = t_u[u];

# temperature of waste mixing higher than 20
subject to temperature_ww_cstr {u in SINKS: u = 'u_waste'}:
	t_u_in[u] >= 20;

# heat of heating up fresh water with steam (indirect HE)
subject to hot_needs_cstr {u in SOURCES: u = 'u_hot'}:
	heat_hot = mass_flow[u] * 4.18 * (t_u_out[u] - t_u[u]);

# nonzero HEs for u_fw_ww and u_hot
subject to hot_needs_t_cstr {u in SOURCES: u = 'u_hot' or u = 'u_fw_ww'}:
	t_u_out[u] >= t_u[u] + 0.001;


# soda bath cannot be recycled in the final rinsing (soda content)
subject to no_soda_end:
	mass_ship['u_middle','u_final'] = 0;

#waste heat recovery from wastewater
subject to ww_cooler_hot_side_cstr:
	heat_load_ww_cooler = mass_flow['u_waste'] * 4.18 * (t_u_in['u_waste'] - t_ww_out);

#waste heat recovery from wastewater	
subject to ww_cooler_cold_side_cstr:
	heat_load_ww_cooler = mass_flow['u_fw_ww'] * 4.18 * (t_u_out['u_fw_ww'] - t_u['u_fw_ww']);

# DTmin of fw_ww HE (one end)
subject to ww_cooler_dtmin1_cstr:
	t_ww_out >= t_u['u_fw_ww'] + water_dt;

# DTmin of fw_ww HE (the other end)
subject to ww_cooler_dtmin2_cstr:
	t_u_in['u_waste'] >= t_u_out['u_fw_ww'] + water_dt;

minimize opex:
	3.6 * price_water * mass_flow['u_fresh'] +
	3.6 * price_water * mass_flow['u_hot'] +
	price_steam * heat_hot +
	price_steam * mass_flow['u_steam'] * 2000;

