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
param scenario          := 0;                               # 1 for glass and 0 for PET

# Heat capacities
param cp_juice 			:= 3.8;								# heat capacity of juice	kJ/kgK
param cp_water 			:= 4.18;							# heat capacity of water kJ/kgK
param cp_glass          := 0.75;
param cp_pet            := 1.67;
param cp_empty_bottles 	:= scenario * 0.75 + (1-scenario)*1.67; # heat capacity 0.75 for glass, 1.67 for PET
param cp_bottles 		:= scenario * 2.6 + (1-scenario)*3.7; # heat capacity 2.6 for glass, 3.7 for PET  (filled bottles)

# Flow rates
param m1				:= 8;								# liter/second of juice or kg/s
param m_empty_bottles 	:= scenario * 0.37 + (1-scenario) * 0.08; # mass of bottle 0.370 for glass, 0.08 for PET ( empty bottles )
param bps				:= m1/0.5; 							# bottles per second
param m_bottles			:= bps*m_empty_bottles + m1;		# mass of filled bottles

# Temperatures
param T1 				:= 1;								# inlet temperature of juice oC
param Tambient          := 25;                              # ambient temperature
param Ttarget 			:= 90;								# target temperature of juice (pasteurisation)
param Tempty_bottles	:= 40; 								# temperature of empty bottles before bottling: 40 for glass, 40 for PET
param Twater			:= 15;								# Inlet water
param Trefrigeration	:= 10;
param DTmin				:= 2;
param Tsteam			:= 120; 							# Temperature of 2bar steam
param Tad_boiler        := 2055;                            # Adiabatic temperature of natural gas
param Tcool_out_step1   := 45;                              # outlet temperature cooling water STEP1 °C
param Tcool_in_step1    := 15;                              # inlet temperature cooling waterSTEP1 °C

param Tcool_in_step2    :=15;                               # coolant inlet temperature of step2 in °C
param Tcool_out_step2   :=30;                               # coolant inlet temperature of step2 in °C

param Tout_step1 := 40;
param Tin_step2 :=40;
param Tout_step2 := 25;

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



#########################################################################################
## VARIABLES
#########################################################################################


## heating demand
var Qboiler;
var Qcip;
var Qref;               # Refrigerating heat exchange

## mass flow rate
var m_cool_step1 >= 0;       # mass flow rate cooling water step 1
var m_cool_step2 >= 0;       # mass flow rate cooling water step 2

## temperature


## Boiler
var Tm_boiler;
var area_boiler;
var opex_boiler >=0;
var capex_boiler >=0;
var wasteheat_boiler;
var wasteheat_dic;

# spray cooler
var Tin_step1 >= 70;           # inlet temperature bottles STEP1 °C
#var Tout_step1;
#var Tin_step2;
#var Tout_step2;
var teta1_step1 >= DTmin;
var teta2_step1 >= DTmin;
var teta1_step2 >= DTmin;
var teta2_step2 >= DTmin;
var logT_step1;
var logT_step2; 
var area_step1 >= 0;
var area_step2 >= 0;
var opex_step1 >= 0;
var capex_step1 >= 0;
var opex_step2 >= 0;
var capex_step2 >= 0;

## refrigeration 

var p_elec_refrigeration;
var Qenv;

var opex_refrigeration;
var capex_refrigeration;

var annualized_factor;

var opex;
var capex;

#########################################################################################
## CONSTRAINTS
#########################################################################################


##############################################
# heat and mass balance
subject to Qboiler1:
Qboiler = cp_juice * (Ttarget - T1) * m1 * p_juice;

subject to LMTD_boiler:
Tm_boiler = (((Tsteam-Ttarget)^2*(Tsteam-T1)+(Tsteam-Ttarget)*(Tsteam-T1)^2)/2)^(1/3);

subject to mixing_bottles:
cp_juice * m1 * p_juice * (Ttarget - Tin_step1) = m_empty_bottles * bps * (Tin_step1 - Tempty_bottles) * cp_empty_bottles;

subject to T_equality_step1_step2:
Tin_step2 = Tout_step1;

subject to Tconstraint_step1:
Tin_step1 >= Tout_step1;

subject to Tconstraint_step2:
Tin_step2 >= Tout_step2;

subject to step1:
m_bottles * cp_bottles * (Tin_step1 - Tout_step1) + m_cool_step1 * cp_water * (Tcool_in_step1 - Tcool_out_step1) = 0;

subject to step2:
m_bottles * cp_bottles * (Tin_step2 - Tout_step2) + m_cool_step2 * cp_water * (Tcool_in_step2 - Tcool_out_step2) = 0;

subject to refrigeration:
Qref - m_bottles * cp_bottles * (Tout_step2 - Tfilled_bottles_final) = 0;

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


subject to boiler_opex:
opex_boiler = NGprice * optime * Qboiler / eta_boiler;

subject to boiler_area:
area_boiler = Qboiler/Tm_boiler/Uref;

subject to boiler_capex:
capex_boiler = 750 * area_boiler^0.7 * MS2017 / MS2000 * BM_boiler;

subject to refrigeration_opex:
opex_refrigeration = p_elec_refrigeration * Elprice * optime;

subject to refrigeration_evap_capex:
capex_refrigeration = 3400 * p_elec_refrigeration**(0.7) *BM_hp * MS2017/ MS2000;

subject to opex_total:
opex = opex_step1 + opex_step2 + opex_refrigeration + opex_boiler;

subject to capex_total:
capex = capex_step1 + capex_step2 + capex_refrigeration + capex_boiler;

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
printf 'Mass of empty bottles     :\t %0.4f kg\n', m_empty_bottles;
printf '------------------------------------------------------\n';
printf 'Mass of filled bottles          :\t %0.4f kg/s\n', m_bottles; 
printf '------------------------------------------------------\n';
printf 'Boiler consumption                :\t %0.4f kW\n', Qboiler; 
printf '------------------------------------------------------\n';
printf 'Cooling water consumption step 1 and 2   :\t %0.4f, %0.4f kg/s\n', m_cool_step1, m_cool_step2; 
printf '------------------------------------------------------\n';
printf 'Load of refrigerator   :\t %0.4f kW\n', p_elec_refrigeration; 
printf '------------------------------------------------------\n';
printf 'Temperature of bottles after filling  :\t %0.4f C\n', Tin_step1; 
printf '------------------------------------------------------\n';
printf 'Temperature bottle after step 1   :\t %0.4f C\n', Tout_step1; 
printf '------------------------------------------------------\n';
printf 'Temperature bottle after step 2   :\t %0.4f C\n', Tout_step2; 
printf '------------------------------------------------------\n';
printf 'area step 1   :\t %0.4f C\n', area_step1; 
printf '------------------------------------------------------\n';
printf 'area step 2   :\t %0.4f C\n', area_step2; 
printf '------------------------------------------------------\n';
printf 'OPEX   :\t %0.4f C\n', opex; 
printf '------------------------------------------------------\n';
printf 'CAPEX   :\t %0.4f C\n', capex*annualized_factor; 
printf '------------------------------------------------------\n';
printf 'Objective function value          :\t %0.4f $\n', opex + capex*annualized_factor;
printf 'CAPEX boiler   :\t %0.4f C\n', capex_boiler*annualized_factor; 
printf 'CAPEX refrigerator   :\t %0.4f CHF\n', capex_refrigeration*annualized_factor; 
printf 'CAPEX spray cooler 1  :\t %0.4f CHF\n', capex_step1*annualized_factor; 
printf 'CAPEX spray cooler 2  :\t %0.4f CHF\n', capex_step2*annualized_factor; 
printf 'OPEX NG   :\t %0.4f CHF\n',opex_boiler; 
printf 'OPEX water   :\t %0.4f CHF\n', opex_step2+opex_step1; 
printf 'OPEX electricity   :\t %0.4f CHF\n', opex_refrigeration; 
printf '------------------------------------------------------\n';
printf 'Test succeeded\n';
printf '------------------------------------------------------\n';



end;