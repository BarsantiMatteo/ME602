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
param bottle_weight;    # bottle weight
param bottle_cap;     # bottle capacity [l/bottle = kg/bottle]
param bottle_cp;    # heat capacity [kJ/kgK]
param bottle_prerinsing_tin;      # inlet temperature of cold dirty bottle [C]
param bottle_presinsing_tout;      # outlet temperature of cold dirty bottl after prerinsing [C]
#param bottle_cold_dt;       # delta T approach
param bottle_soda_tout;      # outlet temperature of hot clean bottle after soda bath
param bottle_final_tout;  
param price_water;    # price of water CHF/kg
param price_steam;    # price of steam CHF/kWh
param op_time;    # operating hours per year
param water_dt;       # heat recovery approach temperature for water
param m_water_prerinsing;  # mass of water in prerinsing stage for 19.1 kg/s cider
param m_water_soda;  # mass of water in soda washing stage (kg/s) for 19.1 kg/s cider
param m_water_final;  # mass of water in final rinsing stage (kg/s) for 19.1 kg/s cider
param cp_water; #kJ/kgK
param Twater_in_prerinsing;
param Twater_out_prerinsing;
param Twater_in_soda;
param Twater_out_soda;
param Twater_in_final;
param Twater_out_final;
param m_bottle_basecase; # mass flow of bottles in 19.1 kg/s cider plant

# calculated parameters

param bottle_mass_flow  := juice_mass/bottle_cap*bottle_weight;	# mass flow of bottles
param bottle_cold_dh    := bottle_mass_flow * bottle_cp * abs(bottle_cold_tin - bottle_cold_tout);
param bottle_hot_dh     := bottle_mass_flow * bottle_cp * abs(bottle_hot_tin - bottle_hot_tout);
param heat_load_initial := ; # heat load of the initial rinsing and soda bath (what you have calculated, although from the bottle side considering the efficiency)
param heat_load_final   := bottle_mass_flow * bottle_cp * abs(bottle_hot_tin - bottle_hot_tout)/eff_he_bottle_out2 ; # heat load of the final rinsing (what you have calculated, although from the bottle side considering the efficiency)

# Heat exchanger efficicencies for 19.1 kg/s cider production plant
param Q_w_prerinsing := m_water_prerinsing * cp_water * abs(Twater_out_prerinsing-Twater_in_prerinsing); # heat load of prerinsing water
param Q_w_soda := m_water_soda * cp_water * abs(Twater_out_soda-Twater_in_soda); # heat load of soda bath water
param Q_w_final := m_water_final * cp_water * abs(Twater_out_final-Twater_in_final); # heat load of final rinsing water

param Q_bottle_prerinsing := m_bottle_basecase * cp_bottles * abs(bottle_prerinsing_tout-bottle_prerinsing_tin); #heating of bottles in prerinsing
param Q_bottle_soda := m_bottle_basecase * cp_bottles * abs(bottle_soda_tout-bottle_prerinsing_tout); # heating of bottles in soda bath
param Q_bottle_final := m_bottle_basecase * cp_bottles * abs(bottle_final_tout-bottle_soda_tout); # heating of bottles in final rinsing

param eff_he_bottle_prerinsing := Q_bottle_prerinsing / Q_w_prerinsing; # HX efficiency for prerinsing (should be 35.68%)
param eff_he_bottle_soda := Q_bottle_soda / Q_w_soda;
param eff_he_bottle_final := Q_bottle_final / Q_w_final;


# ------------------------------------------------------------------------------------------
# sets

set SOURCES default {};
set SINKS default {};
set UNITS := SOURCES union SINKS;
set UNITS_MASS := SOURCES inter SINKS;
set CONTAMINANT default {};

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
	if (u in UNITS_MASS) then
		max {c in CONTAMINANT} units_mass_load[u,c]*1000/units_cont_max_in[u,c] # Matteo: 
	else
		100;

# ------------------------------------------------------------------------------------------
# variables

var t_u_in 	{u in SINKS} >= 0, <= 90;
var t_u_out 	{u in SOURCES} >= 0;
var mass_flow {u in UNITS} >= 0;
var mass_ship {u in SOURCES, uu in SINKS} >= 0;
var mass_contaminant {u in SINKS, c in CONTAMINANT} >= 0;

# ------------------------------------------------------------------------------------------
# constraints

# upper bound of mass of units
subject to unit_mass_lb {u in UNITS}:
	mass

# lower bound of mass of units
subject to unit_mass_ub {u in UNITS}:

# contamination at mixers
# mC_i = sum_{j in resources} m_{j,i} * C_max{j,out}
subject to mass_contaminant_cstr {u in SINKS, c in CONTAMINANT}:
	mass_contaminant[u,c] = sum {uu in SOURCES} mass_ship[uu,u] * units_cont_max_out[uu,c];

# contamination inequality at inlets of units (i.e. at the inlet of unit due to mixing contamination cannot be higher than the maximum allowed)
subject to mass_contaminant_ub {u in SINKS, c in CONTAMINANT}:
	

# contamination mass transfer in each unit (the formulation that you have in your project description)
subject to mass_load_cstr {u in UNITS_MASS, c in CONTAMINANT}:
	#mass_contaminant[u,c] - units_mass_load[u,c] = ???

# non-isothermal mixing. This is an equaity but for convergence reasons we make two equations out of it.
# upper bound of non-isothermal mixing
subject to mass_temperature_cstr_1 {u in SINKS}:
	sum {uu in SOURCES} (mass_ship[uu,u] * t_u_out[uu]) - mass_flow[u] * t_u_in[u] <= 0.001;

# lower bound of non-isothermal mixing
subject to mass_temperature_cstr_2 {u in SINKS}:

# mass balance at inlets of sinks
subject to mass_balance_sink_cstr {u in SINKS}:

# mass balance at the outlet of sources
subject to mass_balance_source_cstr {u in SOURCES}:

# overall mass balance
subject to overall_mass_balance_cstr:
	sum {u in SOURCES} mass_flow[u] = sum {uu in SINKS} mass_flow[uu];

# heat load of final rinsing
subject to bottle_hot_heat_balance {u in UNITS_MASS: u = #name of the final rinsing unit#}:
	mass_flow[u] * 4.18 * (t_u_out[u] - t_u_in[u]) = heat_load_final;

# DT_min approach in final rinsing (one end)
subject to u_final_tin_cstr {u in UNITS_MASS: u = #name of the final rinsing unit#}:


# DT_min approach in final rinsing (the other end)	
subject to u_final_tout_cstr {u in UNITS_MASS: u = #name of the final rinsing unit#}:
	t_u_out[u] <= bottle_hot_tin - bottle_hot_dt;

# inlet of final rinsing has higher temperature than fresh water
subject to u_final_tin_lb_cstr {u in UNITS_MASS: u = #name of the final rinsing unit#}:

# heat load of bottle warming
subject to bottle_cold_heat_balance:
	sum {u in UNITS_MASS: u <> #name of the final rinsing unit#} mass_flow[u] * 4.18 * (t_u_in[u] - t_u_out[u]) = heat_load_initial;

# heat load of bottle warming just for initial rinsing
subject to bottle_cold_initial_heat_cstr:
	sum {u in UNITS_MASS: u = ''} mass_flow[u] * 4.18 * () = bottle_mass_flow * bottle_cp * (t_bottle - )/eff_he_bottle_in;

# heat load of bottle warming just for soda bath
subject to bottle_cold_middle_heat_cstr:
	sum {u in UNITS_MASS: u = } mass_flow[u] * 4.18 * (- t_u_out[u]) = bottle_mass_flow * bottle_cp;
	
# DT_min approach in initial rinsing (one end)
subject to u_initial_tin_cstr {u in UNITS_MASS: u = }:
	t_u_in[u] >= t_bottle + bottle_cold_dt;

# DT_min approach in initial rinsing (the other end)
subject to u_initial_tout_cstr {u in UNITS_MASS: u = }:

# DT_min approach in middle rinsing (one end)
subject to u_middle_tin_cstr {u in UNITS_MASS: u = }:

# DT_min approach in middle rinsing (the other end)
subject to u_middle_tout_cstr {u in UNITS_MASS: u = }:

# fresh water temperature
#subject to temperature_fw_cstr {u in SOURCES: u = 'u_fresh'}:
#	t_u_out[u] = t_u[u];


# temperature of waste mixing higher than 20
subject to temperature_ww_cstr {u in SINKS: u = ''}:

	
# soda bath cannot be recycled in the final rinsing (soda content)
subject to no_soda_end:
	mass_ship['soda bath','final rinsing'] = 0;


minimize opex:
	price_water * 'freshwater' +
	price_steam * 'heat_hot' + 
	price_steam * 'u_steam' * 2000;

