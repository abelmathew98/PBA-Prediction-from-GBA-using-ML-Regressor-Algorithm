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
## Abstract
Static Timing Analysis (STA) is necessary for digital design to verify timing and ensure proper operation of integrated circuits (IC), especially as IC designs become increasingly complex with millions or billions of transistors on a single chip.  STA can be done in two ways: Path-Based Analysis (PBA) and Graph-Based Analysis (GBA). PBA is very accurate but takes longer, whereas GBA is faster but less accurate. The aim is to obtain PBA slack results with GBA runtime. In this paper, we propose a Machine Learning (ML) model which can predict PBA slack values from GBA slack using Random Forests. 

<p align="center">
  <img width="577" alt="image" src="https://github.com/abelmathew98/PBA-GBA/assets/50398012/2f24deb3-8b21-47b7-aade-55d4fdeccc49">
</p>

<p align="center">
  Figure 1: Transition time propagation. a) GBA        b) PBA
</p>

<br />
In GBA, the worst-case transition times are propagated. In Fig. 1.a., it can be seen that there are two paths to flipflop C1, from flipflop L1 and flipflop L2. If the path from L2 to C1 is considered, at gate A1, there are two transition times. The worst-case transition time is propagated to the next gate out of these two. But it is not part of the path that is getting evaluated. Since this is a factor in calculating the path delays and thus, slack, a certain amount of pessimism is added to the calculation. As the analysis progresses, the pessimism added gets accumulated, and in the end, the slack computation becomes pessimistic and thus less accurate. 
<br />
In PBA, the path-specific transition time is propagated as illustrated in Fig.1.b., for the path from L2 to C1, at node A1, the transition time corresponding to the path is propagated. This process gives accurate results as it is not pessimistic. But the computation of the delay values for all possible combinations of these paths is runtime-intensive, especially if the design is large. Due to these reasons, while running GBA, the chip will mostly be overdesigned. But in this age and era where even the smallest margins matter, the design needs to be as precise as possible. Due to PBA's huge runtime overhead and GBA's inaccuracy, an amalgam of the two methods is used in the design cycle.

## Introduction
In the present-day setting, STA has been gaining more importance as the designs are getting bigger and more complex. It is needed to ensure the design functions properly without any timing violations.  Techniques such as crosstalk analysis and Multi-Corner Multi-Mode (MCMM) incorporated into STA modelling make it more accurate. But still, the runtime for precise STA runs is huge, whereas the faster runs are less accurate. This happens because, during STA, the transition times can be propagated in two ways: i) GBA, and ii) PBA.

During the initial stages, GBA is used to identify the critical paths, and in the final stages, PBA is run on the most critical path to identify whether they are actual violations or violations due to the over-pessimism in GBA. But since the design is implemented with GBA-based results, the synthesis, layout constraints, and optimizations are also pessimistic and overdesigned. Therefore, it would be optimal if one were to run STA with PBA accuracy in GBA runtime. This acts as the motivation for our project, which is to create a Machine Learning (ML) model for better and faster prediction of PBA slack values from GBA values. In our project, we plan to do a Regression Model only approach rather than the classification and regression trees (CART) approach mentioned in the reference paper [1].

We propose an ML-based regression model that could predict the PBA slack values (as observed when running Synopsys PrimeTime Tool) from GBA slack timing reports. 
We have done this project on the Synopsys 32 nm Open PDK with a few open-source test benches and some designs from our colleagues.

## Preliminary Efforts and Understanding
The first model that we tried to implement this idea was through a linear regression-based ML algorithm. The metrics used to evaluate the model's accuracy, Mean Squared Error (MSE),  produced a value of around 45-52%, an extremely huge deviation from the predicted values. 
During the preliminary stages, one of the hardest parts was figuring out what features affected PBA slack values. The reference paper [1] had features directly extracted from the lib file, such as the transition time of the first cell in the bigram unit or the arrival time of the first cell in the bigram unit, to name a few. The features selected for the initial analysis include violated, pathlength, sumCap, sumFO, RVTcount,LVTcount, HVTCount, GBAslack, arrivalTime, and requiredTime. These features will be further explained in future sections. We fixed on Random Forest Regressor because it was giving an MSE below 10% in certain instances. We saved the model at those instances and checked the predictions, which are sufficiently closer to the PBA slack value determined by PT.
<br />

## Implementation 
<!-- <p align="center"> -->
  <img width="477" alt="image" src="https://github.com/abelmathew98/PBA-GBA/assets/50398012/77f83952-213a-47ff-99b6-bfd0f802dafd">
  <br />
<!-- </p> -->
<br />
### Stage1 : FILE PARSING and DATA EXTRACTION 


