Course: EE5302,VLSI Design Automation 2


Contributors : Sreelakshmi Vinod Pramila Devi, Abel Mathew Varghese

Current Directory : EE5302_Project/

Full Directory:
-EE5302_Project
 -RTL2GDSScripts (tcl scripts for RTL2GDS flow)
 -run.sh
 -FinalCodeBase
  -main.py
  -parameters.json
  -PBA_GBA.log
  -random_forest_bestmodel_inputs.joblib
  -random_forest_bestmodel_outputs.joblib
  -random_forest_bestmodel_reg2reg.joblib
 -Predicted Files
  -GBA (Files for predicting PBA slack)
  -PBA
 -OutFiles
  -inputsmaxdf.csv
  -outputmaxdf.csv
  -reg2regmaxdf.csv
 -Files
  -GBA 
   - (Files for training the ML model)
  -PBA 
   - (Files for training the ML model)


Required Libraries
-> Pandas
-> Json
-> Matplotlib
-> Scikitlearn
-> Joblib
-> Shutup


Run it in this directory : 
Python3 main.py

Note: Change Directories used based on the system you're at in the parameters.json


Running RTL2GDS flow : 
While running the ./run file, make sure the file is executable. If not ,do 'chmod 755 ./run' 

Inorder to make the designs run error free , please make note of the following things :
 -> Make sure there is a clock in the design
 -> Scan Chain insertion with ,test_se and test_si as inputs and test_so as the output
 -> Make sure the name of the top module is same as the file name as well as the design name.


Logs :
The Logging is semi-done for all the try catch cases and can be found in PBA_GBA.log