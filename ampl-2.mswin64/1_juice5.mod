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
param cp_empty_bottles 	:= scenario * 0.75 + (1-scenario)*1.67; # heat capacity 0.75 for glass, 1.67 for PET
param cp_bottles 		:= scenario * 2.6 + (1-scenario)*3.7;


# Flow rates
param m1		    	:= 8;								# liter/second of juice # kg/second
param m_empty_bottles 	:= scenario * 0.37 + (1-scenario) * 0.08; 							# mass of bottle 0.370 for glass, 0.04 for PET ( empty bottles )
param bps				:= m1/0.5; 							# bottles per second
param m_bottles			:= bps*m_empty_bottles + m1;		# mass flow rate of filled bottles
param flow_empty_bottles := bps*m_empty_bottles;             # mass flow rate of empty bottles

# Temperatures
param T1 				:= 1;								# inlet temperature of juice oC
param Tambient          := 25;                              # ambient temperature
param Tempty_bottles	:= 40; 								# temperature of empty bottles before bottling: 40 for glass, 40 for PET
param Twater			:= 15;								# inlet water
param Tfilled_bottles_final  	:= 10;
param DTmin				:= 2;
param Tsteam			:= 120; 							# Temperature of 2bar steam
param Tad_boiler        := 2055;                            # Adiabatic temperature of natural gas
param Ttarget           := 90;
param T_min_process		:= 122;
param T_min_DHN 		:= 60;

# Density
param p_water           := 1;                               # kg/l
param p_juice           := 1;                               # kg/l

# COSTING
# Resources
param NGprice			:= 0.06; # CHF/kWh
param watercost			:= 0.01; # CHF/m3
param Elprice			:= 0.15; # CHF/kWh_el
param optime 			:= 3000; # hr/yr
param eta_boiler		:= 0.85;
param COP				:= 3;
param Uref				:= 0.5; # kW/m2K
param i					:= 0.08; # interest rate
param n					:= 20;   # life time of heat exchanger
param MS2000			:= 400;
param MS2017			:= 562;
param Cref_ex			:= 750;
param beta_ex			:= 0.7;
param Cref_ref			:= 3400;
param beta_ref			:= 0.85;
param BM_ex				:= 4.74;
param BM_boiler			:= 2;
param BM_ref				:= 2;

param annualization_factor:=i*(1+i)^n/((1+i)^n-1);

# Heat recovery
param Tmax_process   := 122;
param Tmax_dhn       := 60;


#########################################################################################
## VARIABLES
#########################################################################################


# Preheating 1 using spray2
var T_HEX1 >= T1;         		# Juice temperature after HEX1 (Tcold, out)
var Tcool_out_HEX1 >= T1;       # coolant temperature leaving HEX1 (Thot, out)
var QHEX1 >= 0;     			# Heat exchanged HEX1
var m_cool_HEX1 >= 0;

# Preheating 2 using spray1
var T_HEX2 >= T1;         
var Tcool_out_HEX2 >= T1;       
var QHEX2 >= 0;     
var m_cool_HEX2 >= 0;

# Preheating 3 using hot cider
var T_HEX3 >=T1;         
var T_juice >=T1;        
var QHEX3 >= 0.;     

# Boiler heating and bottle filling
var Qboiler >= 0;   			# Heat provided by the boiler
var T_filled >= 70;     		# Bottle temperature after filling

# Spray cooling 1
var m_spray1 >=0; 
var Tspray1_out >= Tfilled_bottles_final;         # Bottle temperature leaving spray cooler 1 (Thot, out)
var Tcool_spray1_out >= Twater;          		  # Coolant temperature leaving spray cooler 1 (Tcold,out)
var Qspray1 >= 0;       						  # Heat exchanged in spray cooler 1

# Spray cooling 2
var m_spray2 >=0; 
var Tspray2_out >=Tfilled_bottles_final;            
var Tcool_spray2_out >= Twater;          
var Qspray2 >= 0;       

# Refrigerator 
var Qref >= 0;
var P_elec >= 0;
var Qevap >= 0;
var Qenv >= 0;

# Heat exchangers design
var Tlm_boiler >= 0;
var A_boiler >= 0;
var Tlm_HEX1 >= 0;
var A_HEX1 >= 0;
var Tlm_HEX2 >= 0;
var A_HEX2 >= 0;
var Tlm_HEX3 >= 0;
var A_HEX3 >= 0;
var Tlm_spray1 >= 0;
var A_spray1 >= 0;
var Tlm_spray2 >= 0;
var A_spray2 >= 0;

# Heat recovery
var Qdhn >= 0;

# Cost 
var CAPEX_Boiler>=0;
var OPEX_Boiler>=0;

var CAPEX_refrigeration>=0;
var OPEX_refrigeration >=0;

var CAPEX_HEX1>=0;
var OPEX_HEX1>=0;

var CAPEX_HEX2>=0;
var OPEX_HEX2>=0;

var CAPEX_HEX3>=0;
var OPEX_HEX3>=0;

var CAPEX_spray1>=0;
var OPEX_spray1>=0;

var CAPEX_spray2>=0;
var OPEX_spray2>=0;

var CAPEX>=0;
var OPEX>=0;
var TOTEX>=0;

#########################################################################################
## CONSTRAINTS
#########################################################################################

# Preheating 1 using water from spray2 
subject to temp_const_HEX1:	# Coolant temperature out < coolant temperature in
Tcool_out_HEX1 <=Tcool_spray2_out;
subject to delta_HEX1a:	# Thot, out - Tcold, in > DTmin
Tcool_out_HEX1 - T1 >= DTmin; 
subject to delta_HEX1b:	# Thot,in - Tcold, out > DTmin
Tcool_spray2_out - T_HEX1 >= DTmin;
subject to HEX1a: # Juice heating
QHEX1 = m1*cp_juice*(T_HEX1-T1);
subject to HEX1b: # Water cooling
QHEX1 = m_spray2*cp_water*(Tcool_spray2_out-Tcool_out_HEX1); 
subject to HEX1_LMTD: # LMTD calculation with eq 8 from Chen, 1987
Tlm_HEX1 = (((Tcool_spray2_out-T_HEX1)^2*(Tcool_out_HEX1-T1)+(Tcool_spray2_out-T_HEX1)*(Tcool_out_HEX1-T1)^2)/2)^(1/3);
subject to HEX1_area: # HEX area
QHEX1=A_HEX1*Uref*Tlm_HEX1;


# Preheating 2 using water from spray1 
subject to temp_const_HEX2:
Tcool_out_HEX2 <=Tcool_spray1_out;
subject to delta_HEX2a:
Tcool_out_HEX2 - T_HEX1 >= DTmin; 
subject to delta_HEX2b:
Tcool_spray1_out - T_HEX2 >= DTmin; 
subject to HEX2a:
QHEX2 = m1*cp_juice*(T_HEX2-T_HEX1);
subject to HEX2b:
QHEX2 = m_spray1*cp_water*(Tcool_spray1_out-Tcool_out_HEX2); 
subject to HEX2_LMTD:
Tlm_HEX2 = (((Tcool_spray1_out-T_HEX2)^2*(Tcool_out_HEX2-T_HEX1)+(Tcool_spray1_out-T_HEX2)*(Tcool_out_HEX2-T_HEX1)^2)/2)^(1/3);
subject to HEX2_area:
QHEX2=A_HEX2*Uref*Tlm_HEX2;


# Preheating 3 using hot cider after boiler
subject to temp_const_HEX3:
T_juice <= Ttarget;
subject to delta_HEX3a:
T_juice - T_HEX2 >= DTmin; 
subject to delta_HEX3b:
Ttarget - T_HEX3 >= DTmin; 
subject to HEX3a:
QHEX3 = m1*cp_juice*(T_HEX3-T_HEX2); 
subject to HEX3b:
QHEX3 = m1*cp_juice*(Ttarget-T_juice); 
subject to HEX3_LMTD:
Tlm_HEX3 = (((Ttarget-T_HEX3)^2*(T_juice-T_HEX2)+(Ttarget-T_HEX3)*(T_juice-T_HEX2)^2)/2)^(1/3);
subject to HEX3_area:
QHEX3=A_HEX3*Uref*Tlm_HEX3;


# Boiler 
subject to Qboiler1: # Heating juice
Qboiler = m1*cp_juice*p_juice*(Ttarget-T_HEX3); 
subject to boiler_LMTD:
Tlm_boiler = (((Tsteam-Ttarget)^2*(Tsteam-T_HEX3)+(Tsteam-Ttarget)*(Tsteam-T_HEX3)^2)/2)^(1/3);
subject to boiler_area:
Qboiler=A_boiler*Uref*Tlm_boiler;
subject to heat_district:
Qdhn = (1-eta_boiler)/eta_boiler*Qboiler*(T_min_process-T_min_DHN)/(T_min_process-Tambient);

# Pouring juice into bottles
subject to mixing_bottles:
T_filled = ((m1*T_juice*cp_juice)+(flow_empty_bottles*Tempty_bottles*cp_empty_bottles))/(m_bottles*cp_bottles); 

# Spray cooling 1
subject to temp_const_step1a:
T_filled >= Tspray1_out;
subject to temp_const_step1b:
Tcool_spray1_out >= Twater;
subject to temp_const_step1c:
T_filled >= Twater;
subject to delta_spray1a:
T_filled - Tcool_spray1_out >= DTmin; 
subject to delta_spray1b:
Tspray1_out - Twater >= DTmin; 
subject to Qspray1juice:
Qspray1 = m_spray1*cp_water*(Tcool_spray1_out-Twater);
subject to Qspray1water:
Qspray1 = m_bottles*cp_bottles*(T_filled-Tspray1_out);
subject to spray1_LMTD:
Tlm_spray1 = (((T_filled-Tcool_spray1_out)^2*(Tspray1_out - Twater)+(T_filled - Tcool_spray1_out)*(Tspray1_out - Twater)^2)/2)^(1/3);
subject to spray1_area:
Qspray1=A_spray1*Uref*Tlm_spray1;

# Spray cooling 2
subject to temp_const_step2a:
Tspray1_out >= Tspray2_out;
subject to temp_const_step2b:
Tcool_spray2_out >= Twater;
subject to temp_const_step2c:
Tspray2_out >= Twater;
subject to delta_spray2a:
Tspray1_out - Tcool_spray2_out >= DTmin; 
subject to delta_spray2b:
Tspray2_out - Twater >= DTmin; 
subject to Qspray2juice:
Qspray2 = m_spray2*(Tcool_spray2_out-Twater)*cp_water;
subject to Qspray2water:
Qspray2 = m_bottles*cp_bottles*(Tspray1_out-Tspray2_out);
subject to spray2_LMTD:
Tlm_spray2 = (((Tspray1_out - Tcool_spray2_out)^2*(Tspray2_out - Twater)+(Tspray1_out - Tcool_spray2_out)*(Tspray2_out - Twater)^2)/2)^(1/3);
subject to spray2_area:
Qspray2=A_spray2*Uref*Tlm_spray2;

# Refrigeration
subject to refrigeration:
Qref = m_bottles*cp_bottles*(Tspray2_out-Tfilled_bottles_final);
subject to electrical_power:
Qref = COP*P_elec;
subject to evaporation_refrig:
Qevap = P_elec*(COP+1);
subject to heat_release_environment: 
Qenv = P_elec + Qref;


#########################################################################################
## COSTING OBJECTIVE FUNCTION
#########################################################################################

# Preheaters
subject to HEX1_capex:
CAPEX_HEX1=BM_ex*Cref_ex*(A_HEX1+0.01)^(beta_ex);
subject to HEX2_capex:
CAPEX_HEX2=BM_ex*Cref_ex*(A_HEX2+0.01)^(beta_ex);
subject to HEX3_capex:
CAPEX_HEX3=BM_ex*Cref_ex*(A_HEX3+0.01)^(beta_ex);

# Boiler
subject to boiler_capex: 
CAPEX_Boiler=BM_boiler*Cref_ex*(A_boiler+0.01)^(beta_ex);
subject to boiler_opex: 
OPEX_Boiler=NGprice*(Qboiler/eta_boiler)*optime; 

# Spray coolers
subject to spray1_capex:
CAPEX_spray1=BM_ex*Cref_ex*(A_spray1+0.01)^(beta_ex);
subject to spray2_capex:
CAPEX_spray2=BM_ex*Cref_ex*(A_spray2+0.01)^(beta_ex);
subject to spray1_opex:
OPEX_spray1=watercost*m_spray1*3.6*optime;
subject to spray2_opex:
OPEX_spray2=watercost*m_spray2*3.6*optime;

# Refrigeration
subject to refri_capex:
CAPEX_refrigeration=BM_ref*Cref_ref*(P_elec+0.01)^beta_ref;
subject to refri_opex:
OPEX_refrigeration=Elprice*P_elec*optime;


subject to totalcapex:
CAPEX=CAPEX_Boiler+CAPEX_refrigeration+CAPEX_HEX1+CAPEX_HEX2+CAPEX_HEX3+CAPEX_spray1+CAPEX_spray2;

subject to totalopex:
OPEX=OPEX_Boiler+OPEX_refrigeration+OPEX_spray1+OPEX_spray2;

subject to totex_calc:
TOTEX=annualization_factor*CAPEX+OPEX;


#######################################################

# Objective
minimize Obj: TOTEX;

# Path for solvers
option solver 'snopt';
option snopt_options  'timing = 1 meminc = 1 iterations = 10000 feas_tol = 0.001 ';

solve;


#########################################################################################
## DISPLAY COMMANDS
#########################################################################################
printf '\n\n';
printf '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n';
printf '------------------------------------------------------\n';
printf 'OPTIMIZED RESULTS\n';
printf '------------------------------------------------------\n';
printf '------------------------------------------------------\n';
printf '---------Preheating 1 using water from Spray 2---------\n';
printf 'Temperature of juice in        :\t %0.2f degC\n', T1;
printf 'Temperature of juice out         :\t %0.2f degC\n', T_HEX1;
printf 'Inlet water temperature            :\t %0.2f degC\n', Tcool_spray2_out;
printf 'Outlet water temperature           :\t %0.2f degC\n', Tcool_out_HEX1;
printf 'Heat exchanged                             :\t %0.2f kW\n', QHEX1;
printf 'Tlm HEX1                     :\t %0.2f \n', Tlm_HEX1;
printf 'Area HEX1                        :\t %0.2f m2\n', A_HEX1;
printf 'CAPEX HEX1                        :\t %0.2f CHF/y\n', CAPEX_HEX1*annualization_factor;
printf '------------------------------------------------------\n';
printf '---------Preheating 2 using water from Spray 1---------\n';
printf 'Temperature of juice in        :\t %0.2f degC\n', T_HEX1;
printf 'Temperature of juice out         :\t %0.2f degC\n', T_HEX2;
printf 'Inlet water temperature            :\t %0.2f degC\n', Tcool_spray1_out;
printf 'Outlet water temperature           :\t %0.2f degC\n', Tcool_out_HEX2;
printf 'Heat exchanged                             :\t %0.2f kW\n', QHEX2;
printf 'Tlm HEX2                    :\t %0.2f \n', Tlm_HEX2;
printf 'Area HEX2                       :\t %0.2f m2\n', A_HEX2;
printf 'CAPEX HEX2                      :\t %0.2f CHF/y\n', CAPEX_HEX2*annualization_factor;
printf '------------------------------------------------------\n';
printf '---------Preheating 3 using hot juice---------\n';
printf 'Temperature of juice in               :\t %0.2f degC\n', T_HEX2;
printf 'Temperature of juice out                 :\t %0.2f degC\n', T_HEX3;
printf 'Initial temperature of pasteurized juice   :\t %0.2f degC\n', Ttarget;
printf 'Final temperature of pasteurized juice     :\t %0.2f degC\n', T_juice;
printf 'Heat exchanged                                    :\t %0.2f kW\n', QHEX3;
printf 'Tlm HEX3                               :\t %0.2f \n', Tlm_HEX3;
printf 'A HEX3                                :\t %0.2f m2\n', A_HEX3;
printf 'CAPEX HEX3                        :\t %0.2f CHF/y\n', CAPEX_HEX3*annualization_factor;
printf '------------------------------------------------------\n';
printf '------------------------Boiler------------------------\n';
printf 'Temperature of juice in           :\t %0.2f C\n', T_HEX3;
printf 'Temperature of juice out           :\t %0.2f C\n', Ttarget;
printf 'Heat                                 :\t %0.2f kW\n', Qboiler;
printf 'Heat for district                                 :\t %0.2f kW\n', Qdhn;
printf 'CAPEX Boiler                        :\t %0.2f CHF/y\n', CAPEX_Boiler*annualization_factor;
printf 'OPEX Boiler                       :\t %0.2f CHF/y\n', OPEX_Boiler;
printf '------------------------------------------------------\n';
printf '------------------------Filling-----------------------\n';
printf 'Temperature of juice in   :\t %0.2f degC\n', T_juice;
printf 'Temperature of juice out    :\t %0.2f degC\n', T_filled;
printf '------------------------------------------------------\n';
printf '-------------------Spray Cooling 1-------------------- \n';
printf 'Temperature of juice in    :\t %0.2f degC\n', T_filled;
printf 'Temperature of juice out     :\t %0.2f degC\n', Tspray1_out;
printf 'Inlet water temperature        :\t %0.2f degC\n', Twater;
printf 'Outlet water temperature       :\t %0.2f degC\n', Tcool_spray1_out;
printf 'Mass flow                      :\t %0.2f kg/s\n', m_spray1;
printf 'Heat                           :\t %0.2f kW\n', Qspray1;
printf 'Tlm spray1                     :\t %0.2f \n', Tlm_spray1;
printf 'A spray1                       :\t %0.2f m2\n', A_spray1;
printf 'CAPEX Spray 1                       :\t %0.2f CHF/y\n', CAPEX_spray1*annualization_factor;
printf '------------------------------------------------------\n';
printf '-------------------Spray Cooling 2-------------------- \n';
printf 'Temperature of juice in    :\t %0.2f degC\n', Tspray1_out;
printf 'Temperature of juice out     :\t %0.2f degC\n', Tspray2_out;
printf 'Inlet water temperature        :\t %0.2f degC\n', Twater;
printf 'Outlet water temperature       :\t %0.2f degC\n', Tcool_spray2_out;
printf 'Mass flow                      :\t %0.2f kg/s\n', m_spray2;
printf 'Heat                           :\t %0.2f kW\n', Qspray2;
printf 'Tlm spray2                     :\t %0.2f \n', Tlm_spray2;
printf 'A spray2                       :\t %0.2f m2\n', A_spray2;
printf 'CAPEX Spray 2                       :\t %0.2f CHF/y\n', CAPEX_spray2*annualization_factor;
printf '------------------------------------------------------\n';
printf '--------------------Refrigeration--------------------- \n';
printf 'Temperature of cider before    :\t %0.2f degC\n', Tspray2_out;
printf 'Temperature of cider after     :\t %0.2f degC\n', Tfilled_bottles_final;
printf 'Refrigerator load              :\t %0.2f kW\n', Qref;
printf 'Electrical power               :\t %0.2f kW\n', P_elec;
printf 'Evaporator load                :\t %0.2f kW\n', Qevap;
printf 'CAPEX Refrigeration                       :\t %0.2f CHF/y\n', CAPEX_refrigeration*annualization_factor;
printf 'OPEX Refrigeration                      :\t %0.2f CHF/y\n', OPEX_refrigeration;
printf '------------------------------------------------------\n';
printf '-------------------- COSTS----------------------------\n';
printf 'OPEX water                       :\t %0.2f CHF/y\n', OPEX_spray1+OPEX_spray2;
printf 'CAPEX                          :\t %0.2f $/yr\n', CAPEX*annualization_factor;
printf 'OPEX                           :\t %0.2f $/yr\n', OPEX;
printf 'TOTEX                          :\t %0.2f $/yr\n', TOTEX;
printf '------------------------------------------------------\n';
printf '------------------------------------------------------\n';
printf '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n';

end;