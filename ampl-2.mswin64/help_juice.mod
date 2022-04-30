reset;

#########################################################################################
# HOW TO RUN YOUR AMPL CODE:
# from Windows commandline type: ampl juice17.mod |Tee output.txt
# from ampl command line type: model juice17.mod 
#########################################################################################


#########################################################################################
## PARAMETERS
#########################################################################################
# Heat capacities
param cp_juice 			:= 3.8;								# heat capacity of juice	kJ/kgK
param cp_water 			:= 4.18;							# heat capacity of water kJ/kgK
param cp_empty_bottles 	:= 0.75; 							# heat capacity 0.75 for glass, 1.67 for PET
param cp_bottles 		:= 2.6; 							# heat capacity 2.6 for glass, 3.7 for PET  (filled bottles)

# Flow rates
param m1				:= 8;								# liter/second of juice
param m_empty_bottles 	:= 0.37; 							# mass of bottle 0.370 for glass, 0.04 for PET ( empty bottles )
param bps				:= m1/0.5; 							# bottles per second
param m_bottles			:= bps*m_empty_bottles + m1;		# mass flux of filled bottles

# Temperatures
param T1 				:= 1;								# inlet temperature of juice oC
param Ttarget 			:= 90;								# target temperature of juice (pasteurisation)
param Tempty_bottles	:= 40; 								# temperature of empty bottles before bottling: 40 for glass, 40 for PET
param Twater			:= 15;								# Inlet water
param Trefrigeration	:= 10;
param DTmin				:= 2;
param Tsteam			:= 120; 							# Temperature of 2bar steam 


# COSTING
# Resources
param NGprice			:= 0.06; # CHF/kWh
param watercost		    := 0.01; # CHF/m3
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

#var ex1 >= 1;			# example variable
#var ex2	>= 3 <= 50;		# example variable

# Heat loads
var Q_hex1 >= 10;         # Heat exhanger load steam/juice
var Q_hex2 >= 10;         # "Heat exhanger" load spray 1
var Q_hex3 >= 10;         # "Heat exhanger" load spray 2
var Q_env >= 10;             # heat rejected by the refrigeration system
var Qboiler >= 10;       # Heat load to Boiler
var Q_ref   >= 10;
var Q_hex90 >= 10;       #Heat load new HEX
var Q_hexs1 >= 10;       #Heat load new heat exchanger spray 1
var Q_dhn   >= 10;         # Heat load from boiler to DHN

# Temperatures
var T70 >= 70;          # Temperature of filled bottles
var Tinter_spray        >= 15;                              # Temperature of bottle intermediate sprays
var Twater_spray1       >= 15;                              # Temperature of waste water spray 1
var Twater_spray2       >=15;                              # Temperature of waste water spray 2
var T25                 >=15;                              # Temperature of bottle after spraying
var Tout_hex90          >=70;  #Temperature out of new HEX
var T1_hex90            >=1; # new Temperature input to boiler due to HEX 90
var Tout_hexs1          >=2;
var T1_hexs1            >=1;


# Mass flows
var m_spray1 >= 0;      # mass flow water of spray cooling step 1
var m_spray2 >= 0;      # mass flow water of spray cooling step 2

# Electricity
var P_ref_elec >=0;     # power consumption of the refrigeration system

# DTmin
var DTmin90 >= 0.01;
var DTmins1 >= 0.01;

# Costs
var tau             >= 0;

var c_inv           >= 0;
var c_inv_hex90     >= 0;
var c_inv_hexs1     >= 0;

var c_op            >= 0;
var c_gas >= 0;         # Operating costs boiler
var c_elect >= 0;          # Operating costs refrigeration
var c_water >= 0;       # water cost


# Objective function
var fobj >= 0;
#########################################################################################
## CONSTRAINTS
#########################################################################################


##############################################
# Example constraint

#subject to example1:
#ex1 = NGprice*ex2 + 3;


/*
BELOW THIS LONG COMMENT YOU SHOULD TYPE YOUR CONSTRAINTS
*/
# Heat exchanger heat balance juice flow
subject to Qhex1_calc1:
    Q_hex1 = m1*cp_juice*(Ttarget-T1_hex90);
# Heat exchanger heat balance steam
subject to Qhex1_calc2:
    Q_hex1 = Qboiler*eta_boiler;
# calculate gas cost for boiler heat load
subject to c_gas_calc:
    c_gas = Qboiler*NGprice*optime; # kW * CHF/kWh * h

# New exchanger on T90
subject to Q_hex90_calc1:
    Q_hex90 = m1 * 1 * (Ttarget - Tout_hex90) * cp_juice;
subject to Q_hex90_calc2:
    -Q_hex90 = m1*(T1_hexs1-T1_hex90)*cp_juice;    

# New exchanger on Spray 1
subject to Q_hexs1_calc1:
    Q_hexs1 = m_spray1 * (Twater_spray1 - Tout_hexs1) * cp_water;
subject to Q_hexs1_calc2:
    -Q_hexs1 = m1*(T1-T1_hexs1)*cp_juice; 



# Thermal equilibrium when filling the bottles
subject to ThermEqFill_calc1:
    m_empty_bottles * bps * (T70 - Tempty_bottles) * cp_empty_bottles = m1 * 1 * (Tout_hex90 - T70) * cp_juice;

# Heat exchanger bottle spray 1 bottles
subject to Qhex2_calc1:
    -Q_hex2 = m_bottles*cp_bottles*(Tinter_spray-T70);
# Heat exchanger bottle spray 1 water
subject to Qhex2_calc2:
    Q_hex2 = m_spray1*cp_water*(Twater_spray1-Twater);
    
 # Heat exchanger bottle spray 2 bottles
subject to Qhex3_calc1:
    -Q_hex3 = m_bottles*cp_bottles*(T25-Tinter_spray);
# Heat exchanger bottle spray 2 water
subject to Qhex3_calc2:
    Q_hex3 = m_spray2*cp_water*(Twater_spray2-Twater);
# Water cost
subject to c_water_calc:
    c_water = watercost/1000*optime*3600*(m_spray1+m_spray2);

# Refrigeration
subject to Q_ref_calc1:
    Q_ref = - m_bottles * (Trefrigeration - T25);
subject to Q_ref_calc2:
    Q_ref = COP * P_ref_elec;
subject to Q_env_calc1:
    Q_env = Q_ref + P_ref_elec;
subject to c_elec_calc1:
    c_elect = P_ref_elec * Elprice * optime;

# DTmin constraints
subject to DTmin1:
    Twater_spray1 <= T70-DTmin;
subject to DTmin2:
    Twater_spray2 <= Tinter_spray-DTmin;
subject to Twater_spray1_calc:
    Twater_spray1 >= Twater;
subject to Twater_spray2_calc:
    Twater_spray2 >= Twater;
subject to Tinter_spray1_calc:
    Tinter_spray >= Twater+DTmin;
subject to T25_calc:
    T25 >= Twater+DTmin;
subject to T1_hex90_calc:
    T1_hex90 >= T1_hexs1;
subject to Tout_hex90_calc:
    Tout_hex90 <= Ttarget;
subject to DTmin3:
    T1_hex90 <= Ttarget-DTmin90;
subject to DTmin4:
    Tout_hex90 >= T1_hexs1 + DTmin90;

subject to T1_hexs1_calc:
    T1_hexs1 >= T1;
subject to Tout_hexs1_calc:
    Tout_hexs1 <= Twater_spray1;
subject to DTmin5:
    T1_hexs1 <= Twater_spray1-DTmins1;
subject to DTmin6:
    Tout_hexs1 >= T1 + DTmins1;


# Boiler waste heat DHN
subject to Q_boiler_dhn_calc:
    Q_dhn = (1-eta_boiler)*Qboiler*(122-60)/(122-25);

# Investment costs

subject to tau_calc:
    tau = ((i*(1+i)^n)/(((1+i)^n)-1));

subject to c_inv_hex90_calc:
    c_inv_hex90 = tau * BM_ex * MS2017/MS2000 * 750 * (((Q_hex90)/(Uref*((Ttarget-T1_hex90)*(Tout_hex90-T1_hexs1)*((Ttarget-T1_hex90)+(Tout_hex90-T1_hexs1))/2)**0.33))**0.7);
subject to c_inv_hexs1_calc:   
    c_inv_hexs1 = tau * BM_ex * MS2017/MS2000 * 750 *(((Q_hexs1)/(Uref*((Twater_spray1-T1_hexs1)*(Tout_hexs1-T1)*((Twater_spray1-T1_hexs1)+(Tout_hexs1-T1))/2)**0.33))**0.7);

subject to c_inv_calc:
    c_inv = c_inv_hexs1 + c_inv_hex90;

subject to c_op_calc:
    c_op = c_gas + c_elect + c_water;
subject to obj_calc:
    fobj = c_op + c_inv;
#########################################################################################
## COSTING OBJECTIVE FUNCTION
#########################################################################################



minimize Obj: fobj;
option solver 'snopt';
#option solver 'baron';
solve;

#########################################################################################
## DISPLAY COMMANDS
#########################################################################################
printf '\n\n';
printf '------------------------------------------------------\n';
printf 'RESULTS\n';
printf '------------------------------------------------------\n';
printf 'c_gas      :\t %0.4f $\n', c_gas;
printf 'c_elect     :\t %0.4f $\n', c_elect;
printf 'c_water     :\t %0.4f $\n', c_water;
printf 'C_inv 90      :\t %0.4f $\n', c_inv_hex90;
printf 'C_inv S1     :\t %0.4f $\n', c_inv_hexs1;

printf 'T1_hexs1     :\t %0.4f C\n', T1_hexs1;
printf 'Tout_hexs1     :\t %0.4f C\n', Tout_hexs1;
printf 'T1_hex90     :\t %0.4f C\n', T1_hex90;
printf 'Tout_hex90     :\t %0.4f C\n', Tout_hex90;


printf 'T70        :\t %0.4f C\n', T70;
printf 'Tinter spray         :\t %0.4f C\n', Tinter_spray;
printf 'Twater spray 1        :\t %0.4f C\n', Twater_spray1;
printf 'Twater spray 2        :\t %0.4f C\n', Twater_spray2;
printf 'T25        :\t %0.4f C\n', T25;
printf 'mspray1        :\t %0.4f kg/s\n', m_spray1;
printf 'mspray2        :\t %0.4f kg/s\n', m_spray2;
printf 'DTmin 90        :\t %0.4f C\n', DTmin90;
printf 'DTmin S1        :\t %0.4f C\n', DTmins1;
printf 'Q 90        :\t %0.4f kW\n', Q_hex90;
printf 'Q S1        :\t %0.4f kW\n', Q_hexs1;
printf 'Q DHN        :\t %0.4f kW\n', Q_dhn;
printf '------------------------------------------------------\n';
printf 'Fresh Water        :\t %0.4f kg/s\n', m_spray1+m_spray2;
printf 'Q Boiler        :\t %0.4f kW\n', Qboiler;
printf 'P elec        :\t %0.4f kW\n', P_ref_elec;
printf 'Total cost        :\t %0.4f CHF/year\n', fobj;
printf '------------------------------------------------------\n';
printf 'Test succeeded\n';
printf '------------------------------------------------------\n';

end;