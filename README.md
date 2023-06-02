# Prediction PBA Slack values from GBA Slack values using Machine Learning Regressor Algorithm
## Directory Structure <br />
```bash
├── RTL2GDSScripts
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
├── README.txt
├── README.md
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

The following is a concise definition for the hyperparameters that are tuned. n_est is the number of trees, min_sample_split is the minimum number of data points allowed in a node before splitting, min_sample_leaf is the minimum number of data points allowed in a leaf node, max_features is the maximum number of features considered when splitting a node, and max_depth is the maximum number of levels in each decision tree.

The final set of hyperparameter configuration was n_est as 400, min_sample_split as 4 , min_sample_leaf as 1 ,max_features as auto and max_depth of 80. A detailed analysis of the variation in MSE for these 6 sets of hyper parameter configuration is provided in the results section.


### Data Fitting and Prediction
Once the model is set up with the right hyperparameters, the data extracted from the GBA/PBA files are fit into the model. A testing set is used to evaluate the model and if it is below the threshold of the expected MSE, the model is saved for future predictions. Three separate models are created for prediction PBA slack for the paths inputs, outputs and reg2reg, respectively.

## STAGE 3: PBA SLACK PREDICTION 
<p align="center">
  <img width="580" alt="image" src="https://github.com/abelmathew98/PBA-GBA/assets/50398012/1b4d509c-00d8-41fc-ad56-47ea66147811">
  <br />
</p>

### GBA File Parser
Another GBA report is generated after an RTL2GDS flow and fed as an input to the file parser to extract the features required (X_TestData) for predicting PBA slack values.

### Model Selection And Prediction
The corresponding model for prediction is chosen based on the path group for which PBA slack is expected (except for the combinational path). To ensure accuracy, the predicted value is compared to the actual value from the PBA file.

## ISSUES FACED
As the timing files needed to be generated for each design, the RTL2GDS flow had to be done for all designs. As this is a time-consuming process, we were not able to run as many designs as we expected. Also, since each design needs its own customization, there were issues during different stages of the flow.

## Results
### Hyper Parameter vs. MSE 
The different sets of hyperparameters mentioned in the implementation section are matched against the average MSE values corresponding to it over 5 runs. These are run for the reg2reg PBA slack prediction model. There are possibilities where one set might be better than the other when run, but we have decided to go with the best one we’ve got. These are best-case scenarios for the model shown in Figure below.

<p align="center">
  <img width="840" alt="image" src="https://github.com/abelmathew98/PBA-GBA/assets/50398012/28659230-9e6b-4a48-b1de-7f5482a76e6f">
</p>

### Ablation Study
In total, there are 10 features that are taken into consideration when extracting from the PBA/GBA reports. The model is trained and tested by removing one feature at a time. In general, an ablation study is a set of experiments in which components of a machine learning system are removed/replaced in order to measure the impact of these components on the performance of the system. This is to check the independency of each feature from predicting the PBA slack. To rephrase, we  seek out which features are not required for training. The MSE values in each instance is as shown in the graph below. For ease of representation, we are using the Hyper parameter set 6 (n_estimators = 400, min_samples_split=4, max_features =auto, min_samples_leaf=1, max_depth=80). Through this analysis, it becomes a little bit more clear about which features are selected during the feature selection process. The average of over 100 model Training MSE values is represented in the gigure below. We are omitting the analysis where there are two features removed from the feature list since it is a little bit more complicated to represent and run due to the number of possible combinations.

<p align="center">
  <img width="840" alt="image" src="https://github.com/abelmathew98/PBA-GBA/assets/50398012/9f4a558c-7644-4326-9a61-a39afe638d5e">
</p>

The smaller value in this analysis would mean that the feature is closer to independence from predicting the PBA Slack value. Hence, we removed RequiredTime and SumFO from the dataframe that is passed onto training the model.

### Scatter Plot for different models
Another metric used to analyze the model's efficiency is visually observing the scatter plot of the three models. The following three figures show the scatter plot accumulated for models with less than 0.15 MSE value for each path group model. This is, as mentioned before, the best possible case. The closer the values are to the x=y part of the graph, the better the prediction model.

<p align="center">
<img width="840" alt="image" src="https://github.com/abelmathew98/PBA-GBA/assets/50398012/0c179d91-388b-499c-9019-e3d119225fca">
</p>

<p align="center">
<img width="840" alt="image" src="https://github.com/abelmathew98/PBA-GBA/assets/50398012/deef5a30-501e-4d66-9d66-f3e22404021b">
</p>

<p align="center">
  <img width="840" alt="image" src="https://github.com/abelmathew98/PBA-GBA/assets/50398012/72b55238-0228-46a3-af1f-3c5a02f5fa71">
</p>

The output from the code for the open-source design [9], PIPO, is shown in the figure below.
<p align="center">
<img width="734" alt="image" src="https://github.com/abelmathew98/PBA-GBA/assets/50398012/2e9760dd-8908-45f4-938b-2791b8fbe6c0">
</p>

The high deviation in the predicted slack is due to low number of PBA-GBA reports used for training. The expectation was to have a deviation of less than 15%, and only reg2reg path slack is within that range. In most cases, it is required to find a less pessimistic value for the reg2reg path, we can say that the main goal of the project is achieved.  Only one design’s PBA slack value for the different paths is predicted because the other 19 are used for training the model.

## Future Work
The lack of data sets and the quality of the designs for which PBA/GBA slack was obtained is one of the main features of the project to be improved. The PBA-GBA deviation for most of the designs that we have used is in the range of 10-18 seconds. But in most of the industry-based designs, the PBA-GBA deviation is around 10-15ps which is around 1000 times larger than the use case we had in the project. 

In terms of future work, we would like to do the following: -
  1.	Increase the size of the dataset used for training the model
  2.	Increase the PBA-GBA divergence of the designs used for training the model
      a.	This would mean that we could move towards using designs that have at least 200k gates and flops.
  3.	Write an ML model from scratch with neural networks in order to customize the hyperparameters at a neural network level. 

## Conclusion
With this project, we are proposing an ML-based solution to address the PBA-GBA runtime accuracy issue in STA. An ML model was developed using Random Forest Regressor and trained with open source and proprietary designs of our classmates. We have used Synopsys 32nm Free PDK and the Synopsys tools Design Compiler, IC Compiler II, and PrimeTime to implement the designs. We have used a total of 20 designs (19+1), and the model predictions have a best-case PBA slack value of 5.63% MSE. Since we did not have enough datasets to train, the divergence is more. In the future, we would like to train the model with more designs to reach the desired accuracy of <15% MSE. This can help avoid overdesigning and make use of the small design margin for the latest designs.

## Reference

[1].	 A. B. Kahng, U. Mallappa and L. Saul, "Using Machine Learning to Predict Path- Based Slack from Graph-Based Timing Analysis," 2018 IEEE 36th International Conference on Computer Design (ICCD), Orlando, FL, USA, 2018, pp. 603-612, doi: 10.1109/ICCD.2018.00096. 
<br />
[2].	A. B. Kahng, S. Kang, H. Lee, S. Nath and J. Wadhwani, "Learning-based approx- imation of interconnect delay and slew in signoff timing tools," 2013 ACM/IEEE International Workshop on System Level Interconnect Prediction (SLIP), Austin, TX, USA, 2013, pp. 1-8, doi: 10.1109/SLIP.2013.6681682. 
<br />
[3].	T. -w. Huang and M. D. F. Wong, "On fast timing closure: speeding up incremental path-based timing analysis with mapreduce," 2015 ACM/IEEE International Work- shop on System Level Interconnect Prediction (SLIP), San Francisco, CA, USA, 2015, pp. 1-6, doi: 10.1109/SLIP.2015.7171710. 
<br />
[4].	J. Bhasker and R. Chadha, (2011) Static timing analysis for nanometer designs: A practical approach. New York: Springer. [5] PrimeTime U-2022.12 User Guide and Documentation Available: https://www.solvnet.synopsys.com/ [Accessed March 1, 2023] 
<br />
[5].	Synopsys Inc. Available: https://www.synopsys.com/ [Accessed March 1, 2023] 
<br />
[6].	OpenCores. Available: https://opencores.org/ [Accessed March 1, 2023] 
<br />
[7].	R. Molina, “EDA Vendors Should Improve The Runtime Performance Of Path-Based Analysis”, Electronic Design, May 10, 2013. [Online], Available: https://www.electronicdesign.com/technologies/eda/article/21796368/eda- vendors-should-improve-the-runtime-performance-of-pathbased-analysis [Accessed March 1, 2023] 
<br />
[8].	Hyperparameter Tuning the Random Forest in Python using Scikit. Available: 
https://towardsdatascience.com/hyperparameter-tuning-the-random-forest-in-python-using-scikit-learn-28d2aa77dd74/ [Accessed May 10, 2023]
<br />
[9].	GitHub. Available: https://www.github.com/ [Accessed May 10, 2023]

## Colleague/Collaborator/Advisor Information
Advisor :  Prof. Sachin S Sapatnekar ,University of Minnesota
<br />
Colleague/Collaborator : Sreelakshmi Pramila Devi Vinod (vinod11@umn.edu)
<br />

