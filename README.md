# Prediction PBA Slack values from GBA Slack values using Machine Learning Regressor Algorithm
## Directory Structure <br />
```bash
├── fifo_bkp
│   ├── Tcl scripts - RTL2GDS flow
├── run.sh
├── FinalCodeBase
│   ├── main.py
│   ├── parameters.json
│   └── PBA_GBA.log
│   └── random_forest_bestmodel_inputs.joblib
│   └── random_forest_bestmodel_outputs.joblib
│   └── random_forest_bestmodel_reg2reg.joblib
├── Predicted Files 
│   └── GBA (Files - predicting PBA slack)
│   └── PBA (Files to compare the predicted PBA value)
├── OutFiles
│   └── inputsmaxdf.csv
│   └── outputmaxdf.csv
│   └── reg2regmaxdf.csv
├── Files
│   └── GBA
│       └── (Files - training the ML model)
│   └── PBA
│       └── (Files - training the ML model)
```

<p align="center">
  <img width="577" alt="image" src="https://github.com/abelmathew98/PBA-GBA/assets/50398012/2f24deb3-8b21-47b7-aade-55d4fdeccc49">
</p>
<p align="center">
  Figure 1: Transition time propagation. a) GBA        b) PBA
</p>

