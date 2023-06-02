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
<p align="center">
  <img width="527" alt="image" src="https://github.com/abelmathew98/PBA-GBA/assets/50398012/77f83952-213a-47ff-99b6-bfd0f802dafd">
  <br />
</p>

## STAGE 1 : FILE PARSING and DATA EXTRACTION 
<p align="center">
  <img width="427" alt="image" src="https://github.com/abelmathew98/PBA-GBA/assets/50398012/7a74608e-5d82-409b-98b8-ac1bcaebcb8d">
  <br />
</p>

### RTL2GDS Flow and Generating PBA/GBA Files
Since we had to run the full flow to obtain the timing reports, we chose to automate the flow. Starting with Synthesis in Synopsys Design Compiler (DC), the flow goes on to floor planning with IC Compiler II (ICC2) and then comes back to DC for the topological run for better optimization. Then Place and Route are done with ICC2 before moving on to STA with PrimeTime. A tcsh shell script was created to run from synthesis to STA, which can be reused by changing only the design name.

### Required Fields.json
This file consists of all the fields that are required to be extracted from the PBA/GBA reports that are generated.

### File Parser
Within the Python script, the fileparser function extracts fields from PBA/GBA reports per the specifications mentioned in the 'requiredFields.json' file. The extraction process is executed by implementing a switch case equivalent to a state machine. The 'parameters.json' file stores the paths leading to the segregated PBA and GBA files of different designs. The hold timing files and combination paths did not produce significant divergence in the PBA-GBA slack values, so we have ignored it. Therefore, the resulting output of this function is then written into three CSV files: ' reg2regmaxdf.csv', 'inputsmaxdf.csv', and 'outputsmaxdf.csv'. These CSV files contain the cumulative data extracted from each file, which will be employed for model training and testing. This extracted data serves as input for our program's second stage, Model Training.

## STAGE 2: MODEL TRAINING
<p align="center">
  <img width="610" alt="image" src="https://github.com/abelmathew98/PBA-GBA/assets/50398012/8c60fad0-0149-46d0-8685-54002ebe4517">
  <br />
</p>

### Data Cleaning
In model training, it is common to discard fields deemed unnecessary, such as the name of the design from which the data was extracted. The feature selection technique used during model training identifies the specific fields to be eliminated. This iterative method typically involves a cycle of data cleaning and feature selection that continues until the model's best set of features is identified.

Feature Selection
The following features were the main consideration for the prediction model.
1. Violated: This field depicts if the timing report has a slack violation or not; True if there is a slack violation and false if there is none.
2.PathLength: The length of the path from the start point and endpoint described at the start of the timing file for the particular path group(inputs, outputs, or reg2reg).
3.SumCap: This field consists of the sum of the capacitance that the path has at each point of consideration.
4. SumFO: This field consists of the sum of the path's fanout at each point of consideration.
5. RVTCount: Total Number of RVT cells in the path that is being considered.
6. LVTCount: Total Number of LVT cells in the path that is being considered.
7. HVTCount: Total Number of HVT cells in the path that is being considered.
8. GBASlack: GBA Slack value from the each design’s gba_setup.rpt file
9. arrivalTime: arrivalTime value from the each design’s gba_setup.rpt file
10. requiredTime: requiredTime value from the each design’s gba_setup.rpt file

The PBASlack value from each design’s pba_setup.rpt file is used as the label, which is the expected output for our model.

### Feature/Label Split
A feature in machine learning is a measurable attribute of the data that acts as an input variable for predicting or classifying an outcome. Features distinguish one data point from another and are essential for developing reliable models. Conversely, a label is the output variable that the model tries to estimate or classify based on the input features. The label indicates the target value the model is attempting to predict, and its precision is crucial for assessing its performance.

### Train/Test Split
The train/test split divides the data set into two sections: training and testing. A training set trains the model, and a test set evaluates its performance. This approach seeks to predict output for a fresh set of inputs from the testing set that was previously unknown to the model. It is important to emphasize that the train/test split should be assigned at random to minimize bias in the model's performance rating. The proportion of data utilized for training and testing can vary depending on the size of the dataset. We used an 80:20 split for a set of 20 GBA/PBA files.

### Regression Model 
Regression models are a type of supervised learning that helps in recognizing patterns and making predictions from labelled examples. It requires a dataset with known outcomes to train the model and test its accuracy.  The accuracy of the model is estimated using Mean Squared Error (MSE) and scatter plot to observe the linearity between the predicted value and the actual value.

After careful consideration and observation of other regression models such as Linear and Logistics, we have concluded that Random Forest Regressor(RFR)  is the most suitable regression algorithm for predicting PBA slack values. RFR is an ML algorithm that predicts by combining multiple decision trees. One of the key benefits of RFR is that the usage of multiple trees improves the algorithm's stability and minimizes the variance associated with the prediction. A drawback of RFR is its tendency to overfit.

### Hyper Parameters Tuning
In order to tune hyperparameters that aid in improving the performance of the model, a module present in the sci-kit-learn library in Python called RandomizedSearchCV is used.  It usually points toward the optimal set of hyperparameters for the model through a search conducted over a randomized set of hyper parameters rather than an exhaustive search of all possible combinations of hyper parameters. Table 2 below shows the five possible set of hyper parameters that could be used for the model.

![image](https://github.com/abelmathew98/PBA-GBA/assets/50398012/004a475c-afec-493b-a7c4-74727aa60692)






