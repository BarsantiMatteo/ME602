reset;

#########################################################################################
# HOW TO RUN YOUR AMPL CODE:
# from Windows commandline type: ampl juice17.mod |Tee output.txt
# from ampl command line type: model juice17.mod 
#########################################################################################

# Code for TOTEX calculation + heat recovery
# Definitive code for Day 1
# Last update on 09/02/21

#########################################################################################
## PARAMETERS
#########################################################################################
# Heat capacities
param cp_juice 			:= 3.8;								# heat capacity of juice	kJ/kgK
param cp_water 			:= 4.18;							# heat capacity of water kJ/kgK
param cp_empty_bottles 	:= 0.75; 							# heat capacity 0.75 for glass, 1.67 for PET
param cp_bottles 		:= 2.6; 							# heat capacity 2.6 for glass, 3.7 for PET  (filled bottles)
param cp_ng 		    := 2.34; 							# heat capacity of natural gas kJ/kgK
param cp_co2		    := 0.849; 							# heat capacity of CO2 kJ/kgK
param cp_h2o    	    := 2.08; 							# heat capacity of H2O kJ/kgK
param specificEnergy_ng := 50000; 							# specific energy of natural gas kJ/kg

# Flow rates
param m1		    	:= 8;								# liter/second of juice # kg/second
param m_empty_bottles 	:= 0.37; 							# mass of bottle 0.370 for glass, 0.04 for PET ( empty bottles )
param bps				:= m1/0.5; 							# bottles per second
param m_bottles			:= bps*m_empty_bottles + m1;		# mass flow rate of filled bottles
param mfr_empty_bottles := bps*m_empty_bottles;             # mass flow rate of empty bottles

# Temperatures
param T1 				:= 1;								# inlet temperature of juice
param Ttarget_hot 		:= 90;								# target temperature of juice (pasteurisation)
param Tempty_bottles	:= 40; 								# temperature of empty bottles before bottling: 40 for glass, 40 for PET
param Twater			:= 15;								# inlet water
param Ttarget_cold  	:= 10;
param DTmin				:= 2;
param Tsteam			:= 120; 							# Temperature of 2bar steam

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
param Cref_hp			:= 3400;
param beta_hp			:= 0.85;
param BM_ex				:= 4.74;
param BM_boiler			:= 2;
param BM_hp				:= 2;
#param annualization_factor:=(MS2017/MS2000)*i*(1+i)^n/((1+i)^n-1);
param annualization_factor:=i*(1+i)^n/((1+i)^n-1);

# Heat recovery
param T_limit_process   := 122;
param T_limit_dhn       := 60;
param T_ambient         := 15;

#########################################################################################
## CURRENT CASE CALCULATIONS
#########################################################################################

# Temperatures
param Tspray1_cur       := 40;
param Tspray1_w_cur     := 45;
param Tspray2_cur       := 25;
param Tspray2_w_cur     := 30;

param heat_boiler_cur       := m1*cp_juice*(Ttarget_hot-T1); # heat provided from the boiler
param T_filled_cur          := ((mfr_empty_bottles*Tempty_bottles*cp_bottles)+(m1*Ttarget_hot*cp_juice))/(m_bottles*cp_bottles); # temperature after filling juice
param m_spray_cur          := ((m_bottles*cp_bottles)*(T_filled_cur-Tspray1_cur))/((Tspray1_w_cur-Twater)*cp_water);
param m_spray2_cur          := ((m_bottles*cp_bottles)*(Tspray1_cur-Tspray2_cur))/((Tspray2_w_cur-Twater)*cp_water);
param load_refrig_cur       := (m_bottles*cp_bottles)*(Tspray2_cur-Ttarget_cold);
param P_elec_cur            := load_refrig_cur/COP;
param load_evap_cur         := P_elec_cur*(COP+1);

# CAPEX of the system
param Tlm_boiler_cur= ((30)*(30)*((30)+(30))/2)^(1/3);
param A_boiler_cur = heat_boiler_cur/(Uref*Tlm_boiler_cur);
param CAPEX_Boiler_cur=2*750*(A_boiler_cur+0.01)^(0.7);
param CAPEX_HP_cur=2*3400*(P_elec_cur+0.01)^0.85;
param CAPEX_cur= annualization_factor*(CAPEX_Boiler_cur+CAPEX_HP_cur);

# OPEX of the system 
param OPEX_Boiler_cur = NGprice*(heat_boiler_cur/eta_boiler)*optime; 
param OPEX_HP_cur = Elprice*P_elec_cur*optime;
param OPEX_spray_cur = watercost/1000*m_spray_cur*3600*optime;
param OPEX_cur = OPEX_Boiler_cur +OPEX_HP_cur +OPEX_spray_cur ;

# TOTEX of the system
param TOTEX_cur = CAPEX_cur+OPEX_cur;

# Waste heat
param waste_heat_cur = (1-eta_boiler)*(heat_boiler_cur/eta_boiler);
param gas_flow_cur = (heat_boiler_cur/eta_boiler)/specificEnergy_ng;

#########################################################################################
## VARIABLES
#########################################################################################


# Preheating 0 using spray2
var T_preheat0 >= T1;         # Tjuice after preheating1 (Tcold,out)
var Tspray0_out >= T1;       # Twater leaving preheat1 (Thot,out)
var heat_preheat0 >= 0;     # heat exchanged preheat1

# Preheating 1 using spray1
var T_preheat1 >= T1;         # Tjuice after preheating1 (Tcold,out)
var Tspray1_out >= T1;       # Twater leaving preheat1 (Thot,out)
var heat_preheat1 >= 0;     # heat exchanged preheat1

# Preheating 2 using hot cider
var T_preheat2 >=T1;         # T_juice after preheating2 (Tcold,out)
var T_juice >=T1;        # T_juice just before bottle filling (Thot,out)
var heat_preheat2 >= 0.;     # heat exchanged preheat2

# Boiler heating and bottle filling
var heat_boiler >= 0;   # heat provided from the boiler
var T_filled >= 70;     # Tjuice after filled in bottle

# Spray cooling 1
var m_spray1 >=0; 
var Tspray1 >= Ttarget_cold;            # Tjuice just after spray1 (Thot,out)
var Tspray1_w >= Twater;          # Twater leaving spray1 (Tcold,out)
var cool_spray1 >= 0;       # heat exchanged spray1

# Spray cooling 2
var m_spray2 >=0; 
var Tspray2 >=Ttarget_cold;            # Tjuice just after spray 2 (Thot,out)s
var Tspray2_w >= Twater;          # Twater leaving spray1 (Tcold,out)
var cool_spray2 >= 0;       # heat exchanged spray2

# Refrigerator 
var load_refrig >= 0;
var P_elec >= 0;
var load_evap >= 0;

# Heat exchangers design
var Tlm_boiler >= 0;
var A_boiler >= 0;
var Tlm_preheat0 >= 0;
var A_preheat0 >= 0;
var Tlm_preheat1 >= 0;
var A_preheat1 >= 0;
var Tlm_preheat2 >= 0;
var A_preheat2 >= 0;
var Tlm_spray1 >= 0;
var A_spray1 >= 0;
var Tlm_spray2 >= 0;
var A_spray2 >= 0;

# Heat recovery
var waste_heat >= 0;
var gas_flow >= 0;
#var co2_flow >= 0;
#var h2o_flow >= 0;
var heat_dhn >= 0;
var heat_exhaust >= 0;

# Cost 
var CAPEX_Boiler>=0;
var CAPEX_HP>=0;
var CAPEX_preheat0>=0;
var CAPEX_preheat1>=0;
var CAPEX_preheat2>=0;
var CAPEX_spray1>=0;
var CAPEX_spray2>=0;
var CAPEX>=0;

var OPEX_Boiler>=0;
var OPEX_HP>=0;
var OPEX_spray1>=0;
var OPEX_spray2>=0;
var OPEX>=0;

var TOTEX>=0;

#########################################################################################
## CONSTRAINTS
#########################################################################################

# (written as to follow the process line)

# Preheating 0 using spray1 hot water
subject to temp_const_pre0:
Tspray0_out <=Tspray2_w;
subject to delta_preheat0a:
Tspray0_out - T1 >= DTmin; # Thot,out - Tcold,in >= DTmin
subject to delta_preheat0b:
Tspray2_w - T_preheat2 >= DTmin; # Thot,in - Tcold,out >= DTmin
subject to preheat0:
heat_preheat0 = m1*cp_juice*(T_preheat0-T1); # heat added to cold juice
subject to exPreheat0:
heat_preheat0 = m_spray2*cp_water*(Tspray2_w-Tspray0_out); # heat removed from hot water

# Preheating 1 using spray1 hot water
subject to temp_const_pre1:
Tspray1_out <=Tspray1_w;
subject to delta_preheat1a:
Tspray1_out - T_preheat0 >= DTmin; # Thot,out - Tcold,in >= DTmin
subject to delta_preheat1b:
Tspray1_w - T_preheat1 >= DTmin; # Thot,in - Tcold,out >= DTmin
subject to preheat1:
heat_preheat1 = m1*cp_juice*(T_preheat1-T_preheat0); # heat added to cold juice
subject to exPreheat1:
heat_preheat1 = m_spray1*cp_water*(Tspray1_w-Tspray1_out); # heat removed from hot water

# Preheating 2 using pasteurized hot cider
subject to temp_const_pre2:
T_juice <= Ttarget_hot;
subject to delta_preheat2a:
T_juice - T_preheat1 >= DTmin; # Thot,out - Tcold,in >= DTmin
subject to delta_preheat2b:
Ttarget_hot - T_preheat2 >= DTmin; # Thot,in - Tcold,out >= DTmin
subject to preheat2:
heat_preheat2 = m1*cp_juice*(T_preheat2-T_preheat1); # heat added to cold juice
subject to exPreheat2:
heat_preheat2 = m1*cp_juice*(Ttarget_hot-T_juice); # heat removed from hot juice

# Boiler heating
subject to boiler:
heat_boiler = m1*cp_juice*(Ttarget_hot-T_preheat2); 

# Bottles filling
subject to temp:
T_filled = ((mfr_empty_bottles*Tempty_bottles*cp_empty_bottles)+(m1*T_juice*cp_juice))/(m_bottles*cp_bottles); 

# Spray cooling 1
subject to temp_const_sp1a:
T_filled >= Tspray1;
subject to temp_const_sp1b:
Tspray1_w >= Twater;
subject to temp_const_sp1c:
T_filled >= Twater;
subject to delta_spray1a:
T_filled - Tspray1_w >= DTmin; # Thot,in - Tcold,out >= DTmin
subject to delta_spray1b:
Tspray1 - Twater >= DTmin; # Thot,out - Tcold,in >= DTmin
subject to Tspray1juice:
cool_spray1 = m_spray1*cp_water*(Tspray1_w-Twater);
subject to spray1:
cool_spray1 = m_bottles*cp_bottles*(T_filled-Tspray1);

# Spray cooling 2
subject to temp_const_sp2a:
Tspray1 >= Tspray2;
subject to temp_const_sp2b:
Tspray2_w >= Twater;
subject to temp_const_sp2c:
Tspray2 >= Twater;
subject to delta_spray2a:
Tspray1 - Tspray2_w >= DTmin; # Thot,in - Tcold,out >= DTmin
subject to delta_spray2b:
Tspray2 - Twater >= DTmin; # Thot,out - Tcold,in >= DTmin
subject to Tspray2juice:
cool_spray2 = m_spray2*(Tspray2_w-Twater)*cp_water;
subject to spray2:
cool_spray2 = m_bottles*cp_bottles*(Tspray1-Tspray2);

# Refrigerator
subject to refrigerator:
load_refrig = m_bottles*cp_bottles*(Tspray2-Ttarget_cold);
subject to elec_refrig:
load_refrig = COP*P_elec;
subject to evap_refrig:
load_evap = P_elec*(COP+1);

# Area of heat exchangers
# T cold out        T_preheat1          Ttarget_hot 90°C
# T cold in         T1                  T_preheat2
# T hot in          Tspray1_w           Tintermediate_hot
# T hot out         Tspray1_out         Tintermediate_cold 120°C

# gas boiler is used to heat an intermediate fluid that will exchange its heat (cooling) with the cider (getting warmer)
# assumption that the DeltaT between cider and this intermediate fluid id around 30°C
subject to boiler_Tlm:
Tlm_boiler= ((30)*(30)*((30)+(30))/2)^(1/3);
subject to boiler_area:
heat_boiler=A_boiler*Uref*Tlm_boiler;

subject to preheat0_Tlm:
Tlm_preheat0= ((Tspray2_w - T_preheat0)*(Tspray0_out - T1)*((Tspray2_w - T_preheat0)+(Tspray0_out - T1))/2)^(1/3);
subject to preheat0_area:
heat_preheat0=A_preheat0*Uref*Tlm_preheat0;

subject to preheat1_Tlm:
Tlm_preheat1= ((Tspray1_w - T_preheat1)*(Tspray1_out - T_preheat0)*((Tspray1_w - T_preheat1)+(Tspray1_out - T_preheat0))/2)^(1/3);
subject to preheat1_area:
heat_preheat1=A_preheat1*Uref*Tlm_preheat1;

subject to preheat2_Tlm:
Tlm_preheat2= ((Ttarget_hot - T_preheat2)*(T_juice - T_preheat1)*((Ttarget_hot - T_preheat2)+(T_juice - T_preheat1))/2)^(1/3);
subject to preheat2_area:
heat_preheat2=A_preheat2*Uref*Tlm_preheat2;

subject to spray1_Tlm:
Tlm_spray1= ((T_filled - Tspray1_w)*(Tspray1 - Twater)*((T_filled - Tspray1_w)+(Tspray1 - Twater))/2)^(1/3);
subject to spray1_area:
cool_spray1=A_spray1*Uref*Tlm_spray1;

subject to spray2_Tlm:
Tlm_spray2= ((Tspray1 - Tspray2_w)*(Tspray2 - Twater)*((Tspray1 - Tspray2)+(Tspray2 - Twater))/2)^(1/3);
subject to spray2_area:
cool_spray2=A_spray2*Uref*Tlm_spray2;

# Urban heating using waste heat from the boiler
subject to waste_heat_calc:
waste_heat = (1-eta_boiler)*(heat_boiler/eta_boiler);
subject to gas_flow_calc:
gas_flow = (heat_boiler/eta_boiler)/specificEnergy_ng;

subject to heat_dhn_calc:
heat_dhn = (T_limit_process-T_limit_dhn)/(T_limit_process-T_ambient)*waste_heat;
subject to heat_exhaust_calc:
heat_exhaust = waste_heat-heat_dhn;

/*
subject to co2_flow_calc:
co2_flow = (44/16)*gas_flow;
subject to h2o_flow_calc:
h2o_flow = (2*18/16)*gas_flow;
subject to heat_dhn_calc:
heat_dhn = (cp_co2*co2_flow+cp_h2o*h2o_flow)*(T_limit_process-T_limit_dhn);
subject to heat_exhaust_calc:
heat_exhaust = waste_heat-heat_dhn;
*/
	
#########################################################################################
## COSTING OBJECTIVE FUNCTION
#########################################################################################

# CAPEX of the system
subject to boiler_cost: 
CAPEX_Boiler=BM_boiler*Cref_ex*(A_boiler+0.01)^(beta_ex);
subject to heatpump_cost:
CAPEX_HP=BM_hp*Cref_hp*(P_elec+0.01)^beta_hp;

subject to preheat0_cost:
CAPEX_preheat0=BM_ex*Cref_ex*(A_preheat0+0.01)^(beta_ex);
subject to preheat1_cost:
CAPEX_preheat1=BM_ex*Cref_ex*(A_preheat1+0.01)^(beta_ex);
subject to preheat2_cost:
CAPEX_preheat2=BM_ex*Cref_ex*(A_preheat2+0.01)^(beta_ex);
subject to spray1_cost:
CAPEX_spray1=BM_ex*Cref_ex*(A_spray1+0.01)^(beta_ex);
subject to spray2_cost:
CAPEX_spray2=BM_ex*Cref_ex*(A_spray2+0.01)^(beta_ex);

subject to totalcapex:
CAPEX=annualization_factor*(CAPEX_Boiler+CAPEX_HP+CAPEX_preheat0+CAPEX_preheat1+CAPEX_preheat2+CAPEX_spray1+CAPEX_spray2);

# OPEX of the system 
subject to boiler_op: 
OPEX_Boiler=NGprice*(heat_boiler/eta_boiler)*optime; 

subject to spray_op1:
OPEX_spray1=(watercost/1000)*m_spray1*3600*optime;
subject to spray_op2:
OPEX_spray2=(watercost/1000)*m_spray2*3600*optime;

subject to totalopex:
OPEX=OPEX_Boiler+OPEX_HP+OPEX_spray1+OPEX_spray2;

# TOTEX of the system
subject to totex:
TOTEX=CAPEX+OPEX;


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
printf 'CURRENT RESULTS\n';
printf '------------------------------------------------------\n';
printf 'Heat from the boiler                    :\t %0.2f kW\n', heat_boiler_cur;
printf 'Boiler heat waste                       :\t %0.2f kW \n', waste_heat_cur;
printf 'NG flow                                 :\t %0.2f kg/s \n', gas_flow_cur;
printf 'Temperature of cider before filling     :\t %0.2f degC\n', T_filled_cur;
printf 'Mass flow spray1                        :\t %0.2f kg/s\n', m_spray_cur;
printf 'Mass flow spray2                        :\t %0.2f kg/s\n', m_spray2_cur;
printf 'Refrigerator load                       :\t %0.2f kW\n', load_refrig_cur;
printf 'Electrical power                        :\t %0.2f kW\n', P_elec_cur;
printf 'Evaporator load                         :\t %0.2f kW\n', load_evap_cur;
printf '--------------------CURRENT COSTS-------------------\n';
printf 'CAPEX                    :\t %0.2f $/yr\n', CAPEX_cur;
printf 'OPEX                     :\t %0.2f $/yr\n', OPEX_cur;
printf 'TOTEX                    :\t %0.2f $/yr\n', TOTEX_cur;
printf '------------------------------------------------------\n';
printf '------------------------------------------------------\n';
printf '------------------------------------------------------\n';
printf 'OPTIMIZED RESULTS\n';
printf '------------------------------------------------------\n';
printf '------------------------------------------------------\n';
printf '---------Preheating 1 using output of Spray 1---------\n';
printf 'Temperature of cider before        :\t %0.2f degC\n', T_preheat0;
printf 'Temperature of cider after         :\t %0.2f degC\n', T_preheat1;
printf 'Inlet water temperature            :\t %0.2f degC\n', Tspray1_w;
printf 'Outlet water temperature           :\t %0.2f degC\n', Tspray1_out;
printf 'Heat                               :\t %0.2f kW\n', heat_preheat1;
printf 'Tlm preheat1                       :\t %0.2f \n', Tlm_preheat1;
printf 'A preheat1                         :\t %0.2f m2\n', A_preheat1;
printf '------------------------------------------------------\n';
printf '---------Preheating 2 using pasteurized cider---------\n';
printf 'Temperature of cider before                :\t %0.2f degC\n', T_preheat1;
printf 'Temperature of cider after                 :\t %0.2f degC\n', T_preheat2;
printf 'Initial temperature of pasteurized cider   :\t %0.2f degC\n', Ttarget_hot;
printf 'Final temperature of pasteurized cider     :\t %0.2f degC\n', T_juice;
printf 'Heat                                       :\t %0.2f kW\n', heat_preheat2;
printf 'Tlm preheat2                               :\t %0.2f \n', Tlm_preheat2;
printf 'A preheat2                                 :\t %0.2f m2\n', A_preheat2;
printf '------------------------------------------------------\n';
printf '------------------------Boiler------------------------\n';
printf 'Temperature of cider before           :\t %0.2f kW\n', T_preheat2;
printf 'Temperature of cider after            :\t %0.2f kW\n', Ttarget_hot;
printf 'Heat                                 :\t %0.2f kW\n', heat_boiler;
printf '------------------------------------------------------\n';
printf '------------------------Filling-----------------------\n';
printf 'Temperature of cider before filling   :\t %0.2f degC\n', T_juice;
printf 'Temperature of cider after filling    :\t %0.2f degC\n', T_filled;
printf '------------------------------------------------------\n';
printf '-------------------Spray Cooling 1-------------------- \n';
printf 'Temperature of cider before    :\t %0.2f degC\n', T_filled;
printf 'Temperature of cider after     :\t %0.2f degC\n', Tspray1;
printf 'Inlet water temperature        :\t %0.2f degC\n', Twater;
printf 'Outlet water temperature       :\t %0.2f degC\n', Tspray1_w;
printf 'Mass flow                      :\t %0.2f kg/s\n', m_spray1;
printf 'Heat                           :\t %0.2f kW\n', cool_spray1;
printf 'Tlm spray1                     :\t %0.2f \n', Tlm_spray1;
printf 'A spray1                       :\t %0.2f m2\n', A_spray1;
printf '------------------------------------------------------\n';
printf '-------------------Spray Cooling 2-------------------- \n';
printf 'Temperature of cider before    :\t %0.2f degC\n', Tspray1;
printf 'Temperature of cider after     :\t %0.2f degC\n', Tspray2;
printf 'Inlet water temperature        :\t %0.2f degC\n', Twater;
printf 'Outlet water temperature       :\t %0.2f degC\n', Tspray2_w;
printf 'Mass flow                      :\t %0.2f kg/s\n', m_spray2;
printf 'Heat                           :\t %0.2f kW\n', cool_spray2;
printf 'Tlm spray2                     :\t %0.2f \n', Tlm_spray2;
printf 'A spray2                       :\t %0.2f m2\n', A_spray2;
printf '------------------------------------------------------\n';
printf '--------------------Refrigeration--------------------- \n';
printf 'Temperature of cider before    :\t %0.2f degC\n', Tspray2;
printf 'Temperature of cider after     :\t %0.2f degC\n', Ttarget_cold;
printf 'Refrigerator load              :\t %0.2f kW\n', load_refrig;
printf 'Electrical power               :\t %0.2f kW\n', P_elec;
printf 'Evaporator load                :\t %0.2f kW\n', load_evap;
printf '------------------------------------------------------\n';
printf '------------------- Heat recovery --------------------\n';
printf 'Boiler heat waste                :\t %0.2f kW \n', waste_heat;
printf 'NG flow                          :\t %0.2f kg/s \n', gas_flow;
printf 'Heat used for DHN                :\t %0.2f kW \n', heat_dhn;
printf 'Heat unusable (exhaust)          :\t %0.2f kW \n', heat_exhaust;
printf '------------------------------------------------------\n';
printf '-------------------- COSTS----------------------------\n';
printf 'CAPEX                          :\t %0.2f $/yr\n', CAPEX;
printf 'OPEX                           :\t %0.2f $/yr\n', OPEX;
printf 'TOTEX                          :\t %0.2f $/yr\n', TOTEX;
printf '------------------------------------------------------\n';
printf 'CAPEX improvement              :\t %0.2f $/yr\n', CAPEX-CAPEX_cur;
printf 'OPEX improvement               :\t %0.2f $/yr\n', OPEX-OPEX_cur;
printf 'TOTEX improvement              :\t %0.2f $/yr\n', TOTEX-TOTEX_cur;
printf 'TOTEX improvement (relative)   :\t %0.2f \%\n', 100*(TOTEX-TOTEX_cur)/TOTEX_cur;
printf '------------------------------------------------------\n';
printf '------------------------------------------------------\n';
printf '>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n';

end;