Lindoglobal is a solver based on Lindo global optimizer versions 12 that can be used
either "stand-alone" or with AMPL's  -og option to solve
linear and nonlinear problems expressed in AMPL.

To use lindoglobal with AMPL, you have several options.  You can invoke
it within an AMPL session by saying

	solve;

or, if $solver is not already lindoglobal,

	option solver lindoglobal;
	solve;

Lindoglobal understands AMPL's -og output format; you can thus
use stand-alone invocations like

	ampl -ogfoo foo.mod foo.dat
	lindoglobal foo [assignments]

Invocation, in general, is

	lindoglobal [options] stub [-AMPL] [assignment ...]

where stub is from `ampl -ogstub`.
Assignments have the form spec_phrase=value.
The argument -AMPL causes lindoglobal to emit a one-line banner; when
$solver has its default value (lindoglobal), AMPL's solve command invokes

	lindoglobal stub -AMPL

If a stub is present, lindoglobal tries to write the computed solution to
stub.sol unless the -s option was specified.  Execute

	lindoglobal '-?'

for a summary of other options.

For invocations from AMPL's solve command or of the form

	lindoglobal stub 

(where stub.nl is from AMPL's -og output option), you can use:

outlev= to control the amount and kind of output:
	outlev=0	no chatter on stdout
	outlev=1	do chatter
For information on the other options available, execute:
   
    lindoglobal -=


-----------------------
solve_result_num values
=======================

Here is a table of solve_result_num values that lindoglobal can return
to an AMPL session, along with the text that appears in the associated
solve_message.

  Value   Message
   
  	0 	optimal solution
    1	basic solution
    200 infeasible problem
    201 local infeasible
    300 unbounded problem
    400 feasible solution
	401 near optimal solution
	402 local optimal solution
	403 worse than cutoff solution found
    500 infeasible or unbounded problem (generic presolve error)
    501 numerical error
    505 unknown error
};


Questions about this stuff? Contact dmg@ampl.com (David M. Gay).
