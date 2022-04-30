reset; 

#########################################################################################
# HOW TO RUN YOUR AMPL CODE:
# from Windows commandline type: ampl juice17.mod |Tee output.txt
# from ampl command line type: model juice17.mod 
#########################################################################################


#########################################################################################
## PARAMETERS
#########################################################################################

# Scenario
param scenario          := 1;                               # 1 for glass and 0 for PET

# Heat capacities
param cp_juice 			:= 3.8;								# heat capacity of juice	kJ/kgK
param cp_water 			:= 4.18;							# heat capacity of water kJ/kgK
param cp_glass          := 0.75;
param cp_pet            := 1.67;
param cp_empty_bottles 	:= scenario * 0.75 + (1-scenario)*1.67; # heat capacity 0.75 for glass, 1.67 for PET
param cp_bottles 		:= scenario * 2.6 + (1-scenario)*3.7; # heat capacity 2.6 for glass, 3.7 for PET  (filled bottles)

# Flow rates
param m1				:= 8;								# liter/second of juice or kg/s
param m_empty_bottles 	:= scenario * 0.37 + (1-scenario) * 0.04; # mass of bottle 0.370 for glass, 0.04 for PET ( empty bottles )
param bps				:= m1/0.5; 							# bottles per second
param m_bottles			:= bps*m_empty_bottles + m1;		# mass of filled bottles

# Temperatures
param T1 				:= 1;								# inlet temperature of juice oC
param Tambient          := 25;                              # ambient temperature
param Ttarget 			:= 90;								# target temperature of juice (pasteurisation)
param Tempty_bottles	:= 40; 								# temperature of empty bottles before bottling: 40 for glass, 40 for PET
param Twater			:= 15;								# Inlet water
param Trefrigeration	:= 10;								# Temperature of bottles after refrigeration
param DTmin				:= 2;
param Tsteam			:= 120; 							# Temperature of 2bar steam
param Tad_boiler        := 2055;                            # Adiabatic temperature of natural gas
param Tcool_in_step1    := 15;                              # inlet temperature cooling waterSTEP1 °C
param Tcool_in_step2    := 15;                               # coolant inlet temperature of step2 in °C
param Tfilled_bottles_final := 10;                           # final bottle temperature in °C

# density
param p_water           := 1;                               # kg/l
param p_juice           := 1;                               # kg/l


# COSTING
# Resources
param NGprice			:= 0.06; # CHF/kWh
param watercost			:= 0.01; # CHF/m3
param Elprice			:= 0.15; # CHF/kWh_el
param optime 			:= 3000;
param eta_boiler		:= 0.85;
param COP				:= 3;
param Uref				:= 0.5; # kW/m2K
param i					:= 0.08;
param n					:= 20;
param MS2000			:= 400;
param MS2017			:= 562;
param Cref_ex			:= 700;
param beta_ex			:= 0.7;
param Cref_hp			:= 3400;
param beta_hp			:= 0.85;
param BM_ex				:= 4.74;
param BM_boiler			:= 2;
param BM_hp				:= 2;

#param Tin_step1 = 70;



#########################################################################################
## VARIABLES
#########################################################################################


## Heating demand
var Qboiler>=0;				 # Boiler heat duty
var Qref>=0;              		 # Refrigeration heat duty
var Qspray1>=0;              	 # Spay cooling STEP1 heat exchange
var Qspray2>=0;              	 # Spray cooling STEP2 heat exchange
var QHEX1>=0;              	 # New HEX1 heat exchange
var QHEX2>=0;              	 # New HEX2 heat exchange
var QHEX3>=0;              	 # New HEX3 heat exchange

## Mass flow rate
var m_cool_step1 >= 0.001;       	# mass flow rate cooling water step 1
var m_cool_step2 >= 0.001;       	# mass flow rate cooling water step 2


## Boiler
var Tm_boiler;					# deltaT LM for boiler
var area_boiler;				# heat exchange area boiler
var opex_boiler >=0;			# operating cost boiler
var capex_boiler >=0;			# investment cost boiler
var wasteheat_boiler;			# heat lost to environment
var wasteheat_dic;				# heat lost to district


# Spray cooling
var Tin_step1 >= 70;           # inlet temperature bottles in spray cooling STEP1 °C
var Tout_step1>=15;			   # Bottle temperature after spray cooling STEP1
var Tcool_out_step1 >=15;      # outlet temperature cooling water after spray cooling STEP1 °C
var Tin_step2>=15; 				   # Bottle temperature into spray cooling STEP2
var Tout_step2 >= 15;		   # Bottle temperature after spray cooling STEP2 
var Tcool_out_step2 >=15;      # coolant outlet temperature to spray cooling STEP2 in °C

var teta1_step1 >= DTmin;	   # Temperature difference between bottle in and coolant out in spray cooling STEP1
var teta2_step1 >= DTmin;	   # Temperature difference between bottle out and coolant in in spray cooling STEP1
var teta1_step2 >= DTmin;	   # Temperature difference between bottle in and coolant out in spray cooling STEP2
var teta2_step2 >= DTmin;	   # Temperature difference between bottle out and coolant in in spray cooling STEP2

var logT_step1;				   # deltaT LM for spray cooling STEP1
var logT_step2;				   # deltaT LM for spray cooling STEP2 
var area_step1 >= 0;	   # heat exchange area spary cooling STEP1
var area_step2 >= 0;	   # heat exchange area spary cooling STEP1
var opex_step1 >= 0;		   # OPEX spary cooling STEP1
var capex_step1 >= 0;		   # CAPEX exchange area spary cooling STEP1
var opex_step2 >= 0;		   # OPEX exchange area spary cooling STEP1
var capex_step2 >= 0;		   # CAPEX exchange area spary cooling STEP1

# Additional heat exchangers
var Tout_HEX1 >= T1;				# Juice temperature after 1st additional heat exchanger using coolant from STEP2
var Tout_HEX2 >= T1;				# Juice temperature after 2nd additional heat exchanger using coolant from STEP1
var Tout_HEX3 >= T1;				# Juice temperature after 3rd additional heat exchanger for heat reovery of boiler
var Tout_cold_HEX3 >= T1;		# temperature of juice poured in bottle, outlet of heat recovery unit after boiler

var Tcool_out_HEX2>= T1;		   # Coolant outlet temperature after heat recovery with juice in 2nd additional heat exchanger using coolant fron spray STEP1
var Tcool_out_HEX1>= T1;		   # Coolant outlet temperature after heat recovery with juice in 1st additional heat exchanger using coolant from spray STEP2


var t_HEX3_1 >= DTmin;	   	   # Temperature difference between juice target T and T4 of juice into boiler
var t_HEX3_2 >= DTmin;		   # Temperature difference between temperature of juice poured in bottle and T3 of juice from 2nd additional heat exchanger
var t_HEX2_1 >= DTmin;   # Temperature difference between outlet T cooling water after STEP1 and juice outlet T after 2nd additional heat exchanger
var t_HEX2_2 >= DTmin;   # Temperature difference between outlet T cooling water after 2nd additional heat exchanger and juice outlet T after 1st additional heat exchanger
var t_HEX1_1 >= DTmin;   # Temperature difference between outlet T cooling water after STEP2 and juice outlet T after 1st additional heat exchanger
var t_HEX1_2 >= DTmin;   # Temperature difference between outlet T cooling water after 1st additional heat exchanger and juice inlet T

var Tm_cool_HEX1;	   # LMDT heat recovery unit from boiler
var Tm_cool_HEX2;
var Tm_HEX3_boiler;		   # LMDT of heat recovery unti from boiler

var area_HEX3>= 0;	   # heat exchange area of  heat recovery unti from boiler
var area_HEX2>= 0;		   # Heat exchange area of 2nd additonal heat exchanger using coolant from STEP1
var area_HEX1>= 0;		   # Heat exchange area of 1st additonal heat exchanger using coolant from STEP2
var capex_HEX2;	   # CAPEX of 2nd additonal heat exchanger using coolant from STEP1
var capex_HEX1;	   # CAPEX of 1st additonal heat exchanger using coolant from STEP2
var capex_HEX3;	   	   # CAPEX of heat recovery unit from boiler

var m_cool_HEX1 >= 0;
var m_cool_HEX2 >= 0;

## Refrigeration 

var p_elec_refrigeration>=0;	   # Electrical power reauired for refrigeration
var Qenv>=0;					   # Heat released into environment

var opex_refrigeration>=0;		   # OPEX refrigeration cycle
var capex_refrigeration>=0;	   # CAPEX refrigeration

## Economics

var annualized_factor>=0;		   # CAPEX annulization

var opex>=0;					   # sum of OPEX
var capex>=0;					   # sum of CAPEX
var TOTEX>=0;

#########################################################################################
## CONSTRAINTS
#########################################################################################


##############################################
# Boiler
subject to Qboiler1: 
Qboiler = cp_juice * (Ttarget - Tout_HEX3) * m1 * p_juice;

subject to LMTD_boiler:
Tm_boiler = (((Tsteam-Ttarget)^2*(Tsteam-Tout_HEX3)+(Tsteam-Ttarget)*(Tsteam-Tout_HEX3)^2)/2)^(1/3);

# Heat exchanger 3

subject to QHEX3_calc1: # energy balance preheater 3 
QHEX3 = cp_juice * (Ttarget - Tout_cold_HEX3) * m1 * p_juice;

subject to QHEX3_calc2:
QHEX3 = cp_juice * (Tout_HEX3 - Tout_HEX2) * m1 * p_juice;

subject to temp_Tinter:
Tout_cold_HEX3 <= Ttarget;

subject to inter_step1:
t_HEX3_1 = (Ttarget - Tout_HEX3);

subject to inter_step2:
t_HEX3_2 = (Tout_cold_HEX3 - Tout_HEX2);

subject to lmtd_interim_boiler:
Tm_HEX3_boiler = ((t_HEX3_1*t_HEX3_2**2 + t_HEX3_2*t_HEX3_1^2)/2)**(1/3);

subject to temp_step_constraint:
Tout_HEX3 >= Tout_HEX2;

subject to temp_step_constraint5:
Tout_cold_HEX3 >= Tout_HEX3;

subject to area_interm_cool:
area_HEX3 = cp_juice * (Tout_HEX3 - Tout_HEX2) * m1 * p_juice / (Tm_HEX3_boiler * Uref);

# Pouring juice into bottles

subject to mixing_bottles: # Energy balance where juice is poured into the bottles
Tin_step1 = (cp_juice*m1*Tout_cold_HEX3 + m_empty_bottles*bps*cp_empty_bottles*Tempty_bottles)/(m_bottles*cp_bottles);
#T_filled = ((mfr_empty_bottles*Tempty_bottles*cp_empty_bottles)+(m1*T_juice*cp_juice))/(m_bottles*cp_bottles); 
#cp_juice * m1 * p_juice * (Tout_cold_HEX3 - Tin_step1) = m_empty_bottles * bps * (Tin_step1 - Tempty_bottles) * cp_empty_bottles;

# Spray cooling

subject to step1_bottle: # Energy balance of spray cooling STEP1
- Qspray1 = m_bottles * cp_bottles * (Tout_step1 - Tin_step1);

subject to step1_coolant:
Qspray1 = m_cool_step1 * cp_water * (Tcool_out_step1 - Tcool_in_step1);

subject to step2_bottle: # Energy balance of spray cooling STEP2
- Qspray2 = m_bottles * cp_bottles * (Tout_step2 - Tin_step2);

subject to step2_coolant: # Energy balance of spray cooling STEP2
 Qspray2 = m_cool_step2 * cp_water * (Tcool_out_step2 - Tcool_in_step2);

subject to heat_transfer_cons3:
Tin_step1 >= Tout_step1;

subject to heat_transfer_cons4:
Tin_step2 >= Tout_step2;

# Heat exchangers 1 and 2

subject to HEX2_coolant: # Cooling in preheater 2
- QHEX2 = m_cool_HEX2 * cp_water * (Tcool_out_HEX2 - Tcool_out_step1);

subject to binary_mass1:
m_cool_HEX2 <= m_cool_step1;

subject to HEX1_coolant: # Cooling in preheater 1
- QHEX1 = m_cool_HEX1 * cp_water * (Tcool_out_HEX1 - Tcool_out_step2);

#subject to binary_mass2:
#m_cool_HEX1 <= m_cool_step2;

subject to heat_balance1: # juice heating in preheater 2
QHEX2 =  cp_juice * (Tout_HEX2 - Tout_HEX1) * m1 * p_juice;

subject to heat_balance2: # juice heating in preheater 1
QHEX1 =  cp_juice * (Tout_HEX1 - T1) * m1 * p_juice;

subject to temp_step_constraint1:
Tout_HEX2 >= Tout_HEX1;

subject to temp_step_constraint2:
Tout_HEX1 >= T1;

subject to temp_step_constraint3:
Tcool_out_HEX2 <= Tcool_out_step1;

subject to temp_step_constraint4:
Tcool_out_HEX1 <= Tcool_out_step2;



subject to inter_cool_step11:
t_HEX2_1 = (Tcool_out_step1 - Tout_HEX2);

subject to inter_cool_step12:
t_HEX2_2 = (Tcool_out_HEX2 - Tout_HEX1);

subject to lmtd_interim_boiler1:
Tm_cool_HEX2 = ((t_HEX2_1*t_HEX2_2**2 + t_HEX2_2*t_HEX2_1^2)/2)**(1/3);


subject to inter_cool_step21:
t_HEX1_1 = (Tcool_out_step2 - Tout_HEX1);

subject to inter_cool_step22:
t_HEX1_2 = (Tcool_out_HEX1 - T1);

subject to lmtd_interim_boiler2:
Tm_cool_HEX1 = ((t_HEX1_1*t_HEX1_2**2 + t_HEX1_2*t_HEX1_1^2)/2)**(1/3);


subject to step1_area_coolant:
area_HEX1 = QHEX1 / (Tm_cool_HEX1 * Uref);

subject to step2_area_coolant:
area_HEX2 = QHEX2 / (Tm_cool_HEX2 * Uref);

# Refrigeration
subject to refrigeration: # cooling requirement for refrigeration 
Qref - m_bottles * cp_bottles * (Tout_step2 - Tfilled_bottles_final) = 0;


subject to temp_equality_cnst:
Tin_step2 = Tout_step1;


subject to electrical_power:
p_elec_refrigeration = Qref/COP;

subject to heat_release_environment: 
Qenv = p_elec_refrigeration + Qref;

subject to wasteheat:
wasteheat_boiler = (Tsteam  - Tambient)/(Tad_boiler-Tsteam)*Qboiler; 

subject to wasteheatdic:
wasteheat_dic =(Tsteam - 60)/(Tad_boiler-Tsteam)*Qboiler; 

##############################################
# technical precalculation for economics

subject to step1_teta1:
teta1_step1 = Tin_step1 - Tcool_out_step1;

subject to step1_teta2:
teta2_step1 = Tout_step1 - Tcool_in_step1;

subject to step2_teta1:
teta1_step2 = Tin_step2 - Tcool_out_step2;

subject to step2_teta2:
teta2_step2 = Tout_step2 - Tcool_in_step2;

subject to step1_logT:
logT_step1 = ((teta1_step1*teta2_step1**2 + teta2_step1*teta1_step1^2)/2)**(1/3);

subject to step2_logT:
logT_step2 = ((teta1_step2*teta2_step2**2 + teta2_step2*teta1_step2^2)/2)**(1/3);

subject to step1_area:
area_step1 = m_bottles * (Tin_step1 - Tout_step1) * cp_bottles / (logT_step1 * Uref);

subject to step2_area:
area_step2 = m_bottles * (Tin_step2 - Tout_step2) * cp_bottles / (logT_step2 * Uref);
###################
# economics

subject to step1_opex:
opex_step1 = m_cool_step1 * optime * 3.6 * watercost;	

subject to step2_opex:
opex_step2 = m_cool_step2 * optime * 3.6 * watercost;	

subject to step1_capex:
capex_step1 = 750 * area_step1^(0.7)*MS2017/MS2000*BM_ex;

subject to step2_capex:
capex_step2 = 750 * area_step2^(0.7)*MS2017/MS2000*BM_ex;


subject to step1_capex_coolant:
capex_HEX1 = 750 * (area_HEX1+0.001)^(0.7)*MS2017/MS2000*BM_ex;

subject to step2_capex_coolant:
capex_HEX2 = 750 * (area_HEX2+0.001)^(0.7)*MS2017/MS2000*BM_ex;

subject to interm_cooling:
capex_HEX3 = 750 * (area_HEX3+0.001)^(0.7)*MS2017/MS2000*BM_ex;


subject to boiler_opex:
opex_boiler = NGprice * optime * Qboiler / eta_boiler;

subject to boiler_area:
area_boiler = Qboiler/Tm_boiler/Uref;

subject to boiler_capex:
capex_boiler = 750 * (area_boiler+0.001)^0.7 * MS2017 / MS2000 * BM_boiler;

subject to refrigeration_opex:
opex_refrigeration = p_elec_refrigeration * Elprice * optime;

subject to refrigeration_evap_capex:
capex_refrigeration = 3400 * p_elec_refrigeration^(0.85) *BM_hp * MS2017/ MS2000;

subject to opex_total:
opex = opex_step1 + opex_step2 + opex_refrigeration + opex_boiler;

subject to capex_total:
capex = capex_step1 + capex_step2 + capex_refrigeration + capex_boiler + capex_HEX1 + capex_HEX2 + capex_HEX3;

subject to annualizedfactor:
annualized_factor = i*(1+i)^n/((1+i)^n-1);

subject to totex_calc:
TOTEX = opex + capex*annualized_factor;

/*
BELOW THIS LONG COMMENT YOU SHOULD TYPE YOUR CONSTRAINTS
*/

	
#########################################################################################
## COSTING OBJECTIVE FUNCTION
#########################################################################################


minimize Obj: TOTEX;

option solver 'snopt';
option snopt_options  'timing = 1 meminc = 1 iterations = 10000 feas_tol = 0.001 ';
solve;

#########################################################################################
## DISPLAY COMMANDS
#########################################################################################
printf '\n\n';
printf '------------------------------------------------------\n';
printf 'RESULTS\n';
printf '------------------------------------------------------\n';
printf 'Mass of empty bottles     :\t %0.4f kg/s\n', m_empty_bottles;
printf '------------------------------------------------------\n';
printf 'Mass of filled bottles          :\t %0.4f kg/s\n', m_bottles; 
printf '------------------------------------------------------\n';
printf 'Boiler consumption                :\t %0.4f kW\n', Qboiler; 
printf '------------------------------------------------------\n';
printf 'spray consumption step 1 and 2   :\t %0.4f, %0.4f kg/s\n', m_cool_step1, m_cool_step2; 
printf '------------------------------------------------------\n';
printf 'Load of refrigerator   :\t %0.4f kW\n', Qref; 
printf '------------------------------------------------------\n';
printf 'Objective function value          :\t %0.4f $\n', opex + capex*annualized_factor;
printf '------------------------------------------------------\n';
printf 'tenperature value in step1 after filling         :\t %0.4f C\n', Tin_step1;
printf '------------------------------------------------------\n';
printf 'tenperature value out step 1        :\t %0.4f C\n', Tin_step2;
printf '------------------------------------------------------\n';
printf 'tenperature value out step2         :\t %0.4f C\n', Tout_step2;
printf '------------------------------------------------------\n';
printf 'tenperature value after first preheat         :\t %0.4f C\n', Tout_HEX1;
printf '------------------------------------------------------\n';
printf 'tenperature value after second preheat         :\t %0.4f C\n', Tout_HEX2;
printf '------------------------------------------------------\n';
printf 'tenperature value after third preheat          :\t %0.4f C\n', Tout_HEX3;
printf '------------------------------------------------------\n';
printf 'tenperature value after before filling         :\t %0.4f C\n', Tout_cold_HEX3;
printf '------------------------------------------------------\n';
printf 'tenperature value of coolant after STEP1         :\t %0.4f C\n', Tcool_out_step1;
printf '------------------------------------------------------\n';
printf 'tenperature value of coolant after STEP2           :\t %0.4f C\n', Tcool_out_step2;
printf '------------------------------------------------------\n';
printf 'Test succeeded\n';
printf '------------------------------------------------------\n';



end;
