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

# param Tout_step2 =25;

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




#########################################################################################
## VARIABLES
#########################################################################################


## heating demand
var Qboiler;				 # boiler heat duty
var Qcip;					 # cleaning in place heat duty
var Qref;              		 # Refrigerating heat exchange

## mass flow rate
var m_cool_step1 >= 0;       # mass flow rate cooling water step 1
var m_cool_step2 >= 0;       # mass flow rate cooling water step 2

## temperature


## Boiler
var Tm_boiler;					# deltaT LM for boiler
var area_boiler;				# heat exchange area boiler
var opex_boiler >=0;			# operating cost boiler
var capex_boiler >=0;			# investment cost boiler
var wasteheat_boiler;			# heat lost to environment
var wasteheat_dic;				# heat lost to ??


# spray cooler
var Tin_step1 >= 70;           # inlet temperature bottles in spray cooling STEP1 °C
var Tinter_step1;			   # temperature of juice poured in bottle, outlet of heat recovery unit after boiler
var Tcool_out_step1 >=15;      # outlet temperature cooling water after spray cooling STEP1 °C
var Tcool_out_step2 >=15;      # coolant outlet temperature to spray cooling STEP2 in °C

var Tcool_out_step11;		   # Coolant outlet temperature after heat recovery with juice in 2nd additional heat exchanger using coolant fron spray STEP1
var Tcool_out_step22;		   # Coolant outlet temperature after heat recovery with juice in 1st additional heat exchanger using coolant from spray STEP2

var Tout_step1;				   # Bottle temperature after spray cooling STEP1
var Tin_step2; 				   # Bottle temperature into spray cooling STEP2
var Tout_step2 >= 10;		   # Bottle temperature after spray cooling STEP2 

var teta1_step1 >= DTmin;	   # Temperature difference between bottle in and coolant out in spray cooling STEP1
var teta2_step1 >= DTmin;	   # Temperature difference between bottle out and coolant in in spray cooling STEP1
var teta1_step2 >= DTmin;	   # Temperature difference between bottle in and coolant out in spray cooling STEP2
var teta2_step2 >= DTmin;	   # Temperature difference between bottle out and coolant in in spray cooling STEP2
var logT_step1;				   # deltaT LM for spray cooling STEP1
var logT_step2;				   # deltaT LM for spray cooling STEP2 
param area_step1 = 0;		   # heat exchange area spary cooling STEP1
param area_step2 = 0;		   # heat exchange area spary cooling STEP1
param opex_step1 = 0;		   # OPEX spary cooling STEP1
param capex_step1 = 0;		   # CAPEX exchange area spary cooling STEP1
param opex_step2 = 0;		   # OPEX exchange area spary cooling STEP1
param capex_step2 = 0;		   # CAPEX exchange area spary cooling STEP1

var T4 <=90;				   # Juice temperature after 1st additional heat exchanger using coolant from STEP2
var T3 <=90;				   # Juice temperature after 2nd additional heat exchanger using coolant from STEP1
var T2 <=90;				   # Juice temperature after 3rd additional heat exchanger for heat reovery of boiler
var Qstage1;				   # Heat duty of 2nd additonal using coolant from STEP1
var Qstage2;				   # Heat duty of 1st additonal using coolant from STEP2
var tinter_1 >= DTmin;	   # Temperature difference between juice target T and T4 of juice into boiler
var tinter_2 >= DTmin;		   # Temperature difference between temperature of juice poured in bottle and T3 of juice from 2nd additional heat exchanger
var Tm_interim_boiler;		   # LMDT of heat recovery unti from boiler
var area_interm_coolant;	   # heat exchange area of  heat recovery unti from boiler
var tcool_step_11 >= DTmin;   # Temperature difference between outlet T cooling water after STEP1 and juice outlet T after 2nd additional heat exchanger
var tcool_step_12 >= DTmin;   # Temperature difference between outlet T cooling water after 2nd additional heat exchanger and juice outlet T after 1st additional heat exchanger
var tcool_step_21 >= DTmin;   # Temperature difference between outlet T cooling water after STEP2 and juice outlet T after 1st additional heat exchanger
var tcool_step_22 >= DTmin;   # Temperature difference between outlet T cooling water after 1st additional heat exchanger and juice inlet T
var Tm_cool_step2_boiler;	   # LMDT heat recovery unit from boiler
var area_step1_coolant>= 0.001;		   # Heat exchange area of 2nd additonal heat exchanger using coolant from STEP1
var area_step2_coolant>= 0.001;		   # Heat exchange area of 1st additonal heat exchanger using coolant from STEP2
param capex_step1_coolant=0;	   # CAPEX of 2nd additonal heat exchanger using coolant from STEP1
param capex_step2_coolant=0;	   # CAPEX of 1st additonal heat exchanger using coolant from STEP2
var capex_interm_cool;	   	   # CAPEX of heat recovery unit from boiler
var Tm_cool_step1_boiler;
var m_cool_step22 >= 0;
var m_cool_step11>= 0;

## refrigeration 

var p_elec_refrigeration;	   # Electrical power reauired for refrigeration
var Qenv;					   # Heat released into environment

var opex_refrigeration;		   # OPEX refrigeration cycle
var capex_refrigeration;	   # CAPEX refrigeration

var annualized_factor;		   # CAPEX annulization

var opex;					   # sum of OPEX
var capex;					   # sum of CAPEX

#########################################################################################
## CONSTRAINTS
#########################################################################################


##############################################
# heat and mass balance
subject to Qboiler1: 
Qboiler = cp_juice * (Ttarget - T4) * m1 * p_juice;

subject to LMTD_boiler:
Tm_boiler = (((Tsteam-Ttarget)^2*(Tsteam-T4)+(Tsteam-Ttarget)*(Tsteam-T4)^2)/2)^(1/3);

subject to heat_recov_after_boiler: # energy balance preheater 3 
cp_juice * (Ttarget - Tinter_step1) * m1 * p_juice - cp_juice * (T4 - T1) * m1 * p_juice = 0;

subject to temp_req_mix_bottles:
Tinter_step1 >=70;

subject to temp_T2:
T2 >=0;

subject to temp_Tinter:
Tinter_step1 <= Ttarget;

subject to inter_step1:
tinter_1 = (Ttarget - T4);

subject to inter_step2:
tinter_2 = (Tinter_step1 - T1);

subject to lmtd_interim_boiler:
Tm_interim_boiler = ((tinter_1*tinter_2**2 + tinter_2*tinter_1^2)/2)**(1/3);

subject to temp_step_constraint:
T4 >= T1;

subject to area_interm_cool:
area_interm_coolant = cp_juice * (T4 - T1) * m1 * p_juice / (Tm_interim_boiler * Uref);



subject to mixing_bottles: # Energy balance where juice is poured into the bottles
cp_juice * m1 * p_juice * (Tinter_step1 - Tin_step1) - m_empty_bottles * bps * (Tin_step1 - Tempty_bottles) * cp_empty_bottles = 0;

#subject to step1: # Energy balance of spray cooling STEP1
#m_bottles * cp_bottles * (Tin_step1 - Tout_step1) + m_cool_step1 * cp_water * (Tcool_in_step1 - Tcool_out_step1) = 0;

#subject to step2: # Energy balance of spray cooling STEP2
#m_bottles * cp_bottles * (Tin_step2 - Tout_step2) + m_cool_step2 * cp_water * (Tcool_in_step2 - Tcool_out_step2) = 0;

#subject to heat_transfer_cons3:
#Tin_step1 >= Tout_step1;

#subject to heat_transfer_cons4:
#Tin_step2 >= Tout_step2;

#subject to heat_transfer_cons1: # Cooling in preheater 2
#Qstage1 = m_cool_step11 * cp_water * (Tcool_out_step1 - Tcool_out_step11);

#subject to binary_mass1:
#m_cool_step11 <= m_cool_step1;

#subject to heat_transfer_cons2: # Cooling in preheater 1
#Qstage2 = m_cool_step22 * cp_water * (Tcool_out_step2 - Tcool_out_step22);

#subject to binary_mass2:
#m_cool_step22 <= m_cool_step2;

#subject to heat_balance1: # juice heating in preheater 2
#Qstage1 =  cp_juice * (T3 - T2) * m1 * p_juice;

#subject to heat_balance2: # juice heating in preheater 1
#Qstage2 =  cp_juice * (T2 - T1) * m1 * p_juice;

#subject to temp_step_constraint1:
#T3 >= T2;

#subject to temp_step_constraint2:
#T2 >= T1;

#subject to temp_step_constraint3:
#Tcool_out_step11 <= Tcool_out_step1;

#subject to temp_step_constraint4:
#Tcool_out_step22 <= Tcool_out_step2;



#subject to inter_cool_step11:
#tcool_step_11 = (Tcool_out_step1 - T3);

#subject to inter_cool_step12:
#tcool_step_12 = (Tcool_out_step11 - T2);

#subject to lmtd_interim_boiler1:
#Tm_cool_step1_boiler = ((tcool_step_11*tcool_step_12**2 + tcool_step_12*tcool_step_11^2)/2)**(1/3);


#subject to inter_cool_step21:
#tcool_step_21 = (Tcool_out_step2 - T2);

#subject to inter_cool_step22:
#tcool_step_22 = (Tcool_out_step22 - T1);

#subject to lmtd_interim_boiler2:
#Tm_cool_step2_boiler = ((tcool_step_21*tcool_step_22**2 + tcool_step_22*tcool_step_21^2)/2)**(1/3);


#subject to step1_area_coolant:
#area_step1_coolant = Qstage1 / (Tm_cool_step1_boiler * Uref);

#subject to step2_area_coolant:
#area_step2_coolant = Qstage2 / (Tm_cool_step2_boiler * Uref);


subject to refrigeration: # cooling reauirement for refrigeration 
Qref - m_bottles * cp_bottles * (Tout_step2 - Tfilled_bottles_final) = 0;



#subject to temp_equality_cnst:
#Tin_step2 = Tout_step1;


subject to electrical_power:
p_elec_refrigeration = Qref/COP;

subject to heat_release_environment: 
Qenv - p_elec_refrigeration + Qref = 0;

subject to wasteheat:
wasteheat_boiler = (Tsteam  - Tambient)/(Tad_boiler-Tsteam)*Qboiler; 

subject to wasteheatdic:
wasteheat_dic =(Tsteam - 60)/(Tad_boiler-Tsteam)*Qboiler; 

##############################################
# technical precalculation for economics

#subject to step1_teta1:
#teta1_step1 = Tin_step1 - Tcool_out_step1;

#subject to step1_teta2:
#teta2_step1 = Tout_step1 - Tcool_in_step1;

#subject to step2_teta1:
#teta1_step2 = Tin_step2 - Tcool_out_step2;

#subject to step2_teta2:
#teta2_step2 = Tout_step2 - Tcool_in_step2;

#subject to step1_logT:
#logT_step1 = ((teta1_step1*teta2_step1**2 + teta2_step1*teta1_step1^2)/2)**(1/3);

#subject to step2_logT:
#logT_step2 = ((teta1_step2*teta2_step2**2 + teta2_step2*teta1_step2^2)/2)**(1/3);

#subject to step1_area:
#area_step1 = m_bottles * (Tin_step1 - Tout_step1) * cp_bottles / (logT_step1 * Uref);

#subject to step2_area:
#area_step2 = m_bottles * (Tin_step2 - Tout_step2) * cp_bottles / (logT_step2 * Uref);
###################
# economics

#subject to step1_opex:
#opex_step1 = m_cool_step1 * optime * 3.6 * watercost;	

#subject to step2_opex:
#opex_step2 = m_cool_step2 * optime * 3.6 * watercost;	

#subject to step1_capex:
#capex_step1 = 750 * area_step1^(0.7)*MS2017/MS2000*BM_ex;

#subject to step2_capex:
#capex_step2 = 750 * area_step2^(0.7)*MS2017/MS2000*BM_ex;


#subject to step1_capex_coolant:
#capex_step1_coolant = 750 * area_step1_coolant^(0.7)*MS2017/MS2000*BM_ex;

#subject to step2_capex_coolant:
#capex_step2_coolant = 750 * area_step2_coolant^(0.7)*MS2017/MS2000*BM_ex;

subject to interm_cooling:
capex_interm_cool = 750 * area_interm_coolant^(0.7)*MS2017/MS2000*BM_ex;


subject to boiler_opex:
opex_boiler = NGprice * optime * Qboiler / eta_boiler;

subject to boiler_area:
area_boiler = Qboiler/Tm_boiler/Uref;

subject to boiler_capex:
capex_boiler = 750 * area_boiler^0.7 * MS2017 / MS2000 * BM_boiler;

subject to refrigeration_opex:
opex_refrigeration = p_elec_refrigeration * Elprice * optime;

subject to refrigeration_evap_capex:
capex_refrigeration = 3400 * p_elec_refrigeration^(0.85) *BM_hp * MS2017/ MS2000;

subject to opex_total:
opex = opex_step1 + opex_step2 + opex_refrigeration + opex_boiler;

subject to capex_total:
capex = capex_step1 + capex_step2 + capex_refrigeration + capex_boiler  + capex_interm_cool;

subject to annualizedfactor:
annualized_factor = i*(1+i)^n/((1+i)^n-1);



/*
BELOW THIS LONG COMMENT YOU SHOULD TYPE YOUR CONSTRAINTS
*/

	
#########################################################################################
## COSTING OBJECTIVE FUNCTION
#########################################################################################


minimize Obj: opex + capex*annualized_factor;

option solver 'snopt';
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
printf 'tenperature value in step1         :\t %0.4f $\n', Tin_step1;
printf '------------------------------------------------------\n';
printf 'tenperature value out step 1        :\t %0.4f $\n', Tin_step2;
printf '------------------------------------------------------\n';
printf 'tenperature value out step2         :\t %0.4f $\n', Tout_step2;
printf '------------------------------------------------------\n';
printf 'tenperature value after first preheat         :\t %0.4f $\n', T2;
printf '------------------------------------------------------\n';
printf 'tenperature value after second preheat         :\t %0.4f $\n', T3;
printf '------------------------------------------------------\n';
printf 'tenperature value after third preheat         :\t %0.4f $\n', T4;
printf '------------------------------------------------------\n';
printf 'tenperature value after cooling after boiler         :\t %0.4f $\n', Tinter_step1;
printf '------------------------------------------------------\n';
printf 'Test succeeded\n';
printf '------------------------------------------------------\n';



end;
