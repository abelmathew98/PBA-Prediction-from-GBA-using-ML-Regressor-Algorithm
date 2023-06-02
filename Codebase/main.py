# Imports 

import os
import pandas as pd
import json
import logging
import matplotlib.pyplot as plt
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestRegressor
from sklearn import metrics
import joblib

#To disable all the deprecation warnings
import shutup
shutup.please()

# Data Frame Initialization
combmaxdf = pd.DataFrame(columns=['designName', 'violated', 'pathLength','sumCap','sumFO','RVTCount','HVTCount','LVTCount','arrivalTime','RequiredTime','GBASlack','PBASlack'])
inputsmaxdf = pd.DataFrame(columns=['designName', 'violated', 'pathLength','sumCap','sumFO','RVTCount','HVTCount','LVTCount','arrivalTime','RequiredTime','GBASlack','PBASlack'])
outputmaxdf = pd.DataFrame(columns=['designName', 'violated', 'pathLength','sumCap','sumFO','RVTCount','HVTCount','LVTCount','arrivalTime','RequiredTime','GBASlack','PBASlack'])
reg2regmaxdf = pd.DataFrame(columns=['designName', 'violated', 'pathLength','sumCap','sumFO','RVTCount','HVTCount','LVTCount','arrivalTime','RequiredTime','GBASlack','PBASlack'])

# This function is used to output each of the dataframe for each path Group into csv for Model Training
def outTocsv(rootoutFile):   
    global combmaxdf,inputsmaxdf,outputmaxdf,reg2regmaxdf
    try:
        if combmaxdf.empty:
            logger.error('Error outputting to CSV : combmaxdf')
        else:
            combopath=rootoutFile+"combmaxdf.csv"
            combmaxdf.to_csv(combopath, encoding='utf-8', index=False)
    except:
        logger.error('Error outputting to CSV : combmaxdf')
    try:
        inputpath=rootoutFile+"inputsmaxdf.csv"
        inputsmaxdf.to_csv(inputpath, encoding='utf-8', index=False)
    except:
        logger.error('Error outputting to CSV : inputsmaxdf')
    try:
        outputpath=rootoutFile+"outputmaxdf.csv"
        outputmaxdf.to_csv(outputpath, encoding='utf-8', index=False)
    except:
        logger.error('Error outputting to CSV : outputsmaxdf')
    try:
        reg2regpath=rootoutFile+"reg2regmaxdf.csv"
        reg2regmaxdf.to_csv(reg2regpath, encoding='utf-8', index=False)
    except:
        logger.error('Error outputting to CSV : reg2regmaxdf')


# Sum of Capacitance from start point to end point
def capSum(Cap):
    try:
        sumCap=0.00
        for k in Cap:
            if(k):
                sumCap=sumCap+float(k)
        logger.info('Clear : Cap Sum')
        return sumCap
    except:
        logger.error('Error at Cap Sum')

# Sum of Fanout from Start Point to EndPoint
def fanOutSum(FO):
    try:
        sumFO=0.00
        for k in FO:
            if(k):
                sumFO=sumFO+float(k)
        logger.info('Clear : Fanout Sum')
        return sumFO
    except:
        logger.error('Error at FanoutSum')

# Path length from start point to end point 
def pathLengthExtractor(pathList,startPoint,endPoint):
    try:
        netcount=0
        minStartPos=10000000000
        maxEndPos=0
        for x in range(len(pathList)):
            if "(net)" in pathList[x]:
                netcount=netcount+1
            if (startPoint in pathList[x])and(x<minStartPos):
                minStartPos=x
            if (endPoint in pathList[x])and(x>maxEndPos):
                maxEndPos=x
        pathLen=maxEndPos-minStartPos-netcount+1
        logger.info('Clear : Path Length Extractor')
    except:
        logger.error('Error at Path Length Extractor')

    return pathLen


# Initial file parsing for setting up the data frames for Model Training
def fileParsing(fileName,rootdir,designDirectoryName):
    global combmaxdf,inputsmaxdf,outputmaxdf,reg2regmaxdf
    pathgroupdict={}
    Point=[]
    Fanout=[]
    Cap=[]
    Tran=[]
    Incr=[]
    Path=[]
    HVTCount=0
    LVTCount=0
    RVTCount=0
    initialCase=1
    fileNamePath=rootdir+"/"+designDirectoryName+"/"+fileName
    try:
        timingFile=open(fileNamePath,'r')
        logger.info('Clear: Successfully read the file : %s',fileName)
    except:
        logger.error('Error Reading File')
    for line in timingFile.readlines():
        if line.strip():
            match initialCase:
                case 1 :
                    try:
                        if "-delay_type" in line: 
                            delayType=line.split(" ")[-1].strip()
                            initialCase=2
                            continue
                    except:
                        logger.error('Error, no delay Type in the file')
                case 2 :
                    if "-pba_mode" in line:
                        analysisMode='PBA'
                        initialCase=3
                        continue
                    elif "Design :" in line:
                        designName=line.split(" ")[-1].strip()
                        analysisMode='GBA'
                        initialCase=6
                        continue
                case 3 :
                    if "Design :" in line:
                        designName=line.split(" ")[-1].strip()
                        initialCase=101
                        continue

                case 101 :
                    if "Path Group:" in line:
                        pathGroup=line.split(":")[-1][1:].strip()
                        if(pathGroup=="comb"):
                            initialCase=1
                        else:
                            initialCase=102
                        continue

                case 102 : 
                    if "slack" in line:
                        pbaslack=line.split("  ")[-1].strip()
                        initialCase=103
                case 103 : 
                    if(pathGroup=="comb"):
                        if(delayType=="max"):
                            if  designName in combmaxdf['designName'].values:
                                try:
                                    combmaxdf.loc[combmaxdf["designName"] == designName, "PBASlack"] = float(pbaslack)
                                except:
                                    logger.error('PBA - Error replacing PBA values in combmaxdf')
                    if(pathGroup=="inputs"):
                        if(delayType=="max"):
                            if  designName in inputsmaxdf['designName'].values:
                                try:
                                    inputsmaxdf.loc[inputsmaxdf["designName"] == designName, "PBASlack"] = float(pbaslack)
                                except:
                                    logger.error('PBA - Error replacing PBA values in inputmaxdf')
                    if(pathGroup=="output"):
                        if(delayType=="max"):
                            if  designName in outputmaxdf['designName'].values:
                                try:
                                    outputmaxdf.loc[outputmaxdf["designName"] == designName, "PBASlack"] = float(pbaslack)
                                except:
                                    logger.error('PBA - Error replacing PBA values in outputmaxdf')
                    if(pathGroup=="reg2reg"):
                        if(delayType=="max"):
                            if  designName in reg2regmaxdf['designName'].values:
                                try:
                                    reg2regmaxdf.loc[reg2regmaxdf["designName"] == designName, "PBASlack"] = float(pbaslack)
                                except:
                                    logger.error('PBA - Error replacing PBA values in reg2regmaxdf')
                    initialCase=1

                case 6 :
                    if "Startpoint" in line:
                        startPoint=line.split(":")[-1][1:].strip()
                        startPoint=startPoint.split(" ")[0]
                        initialCase=7
                        continue
                case 7 :
                    if "Endpoint" in line:
                        endPoint=line.split(":")[-1][1:].strip()
                        endPoint=endPoint.split(" ")[0]
                        initialCase=8
                        continue
                case 8 : 
                    if "Path Group:" in line:
                        pathGroup=line.split(":")[-1][1:].strip()
                        if pathGroup=="comb":
                            initialCase=1
                        else:
                            initialCase=9

                        continue
                case 9 :
                    if ("Point" in line)and("Fanout" in line)and("Cap" in line)and("Trans" in line)and("Incr" in line)and("Path" in line):
                        initialCase=10
                        continue
                case 10 :
                    if "----------" in line:
                        initialCase=11
                        continue
                case 11 :
                    if "---------" in line:
                        initialCase=12
                        continue
                    else:
                        templine=line.split("  ")
                        tempvalue=line.split("  ")[-1]
                        Point.append(templine[1])
                        if "HVT" in templine[1]:
                            HVTCount=HVTCount+1
                        if "LVT" in templine[1]:
                            LVTCount=LVTCount+1
                        if ("RVT" in templine[1])or("SVT" in templine[1]):
                            RVTCount=RVTCount+1
                        
                        if "(net)" in line:
                            Fanout.append(tempvalue.split()[0])
                            Cap.append(tempvalue.split()[1])
                        else:
                            Fanout.append("")
                            Cap.append("")

                case 12 :
                    if "required time" in line:
                        requiredTime=line.split(" ")[-1].strip()
                        initialCase=13
                        continue
                case 13 :
                    if "arrival time" in line:
                        arrivalTime=line.split("  ")[-1].strip()
                        initialCase=14
                        continue
                case 14 :
                    if "slack" in line:
                        slack=line.split("  ")[-1].strip()
                        if "MET" in line:
                            violated=False
                        elif "VIOLATED" in line:
                            violated=True
                        initialCase=15
                        continue
                case 15 :
                    # Path Length extraction 
                    pathLength=pathLengthExtractor(Point,startPoint,endPoint)
                    # Sum of Cap 
                    sumofCap=capSum(Cap)
                    # Sum of Fanout/Product of Fanout.
                    sumofFo=fanOutSum(Fanout)

                    if(analysisMode=="GBA"):
                        if(pathGroup=="comb"):
                            if(delayType=="max"):
                                try:
                                    combmaxdf= combmaxdf.append({'designName':designName, 'violated':violated, 'pathLength':pathLength,'sumCap':sumofCap,'sumFO':sumofFo,'RVTCount':RVTCount,'HVTCount':HVTCount,'LVTCount':LVTCount,'arrivalTime':float(arrivalTime),'RequiredTime':float(requiredTime),'GBASlack':float(slack),'PBASlack':0},ignore_index = True)
                                except:
                                    logger.error('GBA - Error appending to combmaxdf')
                        if(pathGroup=="inputs"):
                            if(delayType=="max"):
                                try:
                                    inputsmaxdf= inputsmaxdf.append({'designName':designName, 'violated':violated, 'pathLength':pathLength,'sumCap':sumofCap,'sumFO':sumofFo,'RVTCount':RVTCount,'HVTCount':HVTCount,'LVTCount':LVTCount,'arrivalTime':float(arrivalTime),'RequiredTime':float(requiredTime),'GBASlack':float(slack),'PBASlack':0},ignore_index = True)
                                except:
                                    logger.error('GBA - Error appending to inputsmaxdf')                            
                        if(pathGroup=="output"):
                            if(delayType=="max"):
                                try:
                                    outputmaxdf= outputmaxdf.append({'designName':designName, 'violated':violated, 'pathLength':pathLength,'sumCap':sumofCap,'sumFO':sumofFo,'RVTCount':RVTCount,'HVTCount':HVTCount,'LVTCount':LVTCount,'arrivalTime':float(arrivalTime),'RequiredTime':float(requiredTime),'GBASlack':float(slack),'PBASlack':0},ignore_index = True)
                                except:
                                    logger.error('GBA - Error appending to outputmaxdf')
                        if(pathGroup=="reg2reg"):
                            if(delayType=="max"):
                                try:
                                    reg2regmaxdf= reg2regmaxdf.append({'designName':designName, 'violated':violated, 'pathLength':pathLength,'sumCap':sumofCap,'sumFO':sumofFo,'RVTCount':RVTCount,'HVTCount':HVTCount,'LVTCount':LVTCount,'arrivalTime':float(arrivalTime),'RequiredTime':float(requiredTime),'GBASlack':float(slack),'PBASlack':0},ignore_index = True)
                                except:
                                    logger.error('GBA - Error appending to reg2regmaxdf')
                    Point=[]
                    Fanout=[]
                    Cap=[]
                    initialCase=1
                    continue

def predictionModel(rootoutFile):

    
    inputpath=rootoutFile+"inputsmaxdf.csv"
    outputpath=rootoutFile+"outputmaxdf.csv"
    reg2regpath=rootoutFile+"reg2regmaxdf.csv" 
    
    # Reg2Reg Model
    df_reg = pd.read_csv(reg2regpath)
    # Feature Selection/Removal
    cols_to_drop = ["designName","RequiredTime","sumFO"]
    df_reg = df_reg.drop(columns=cols_to_drop,axis=1)
    df_reg.to_csv('Clean_data_reg.csv')
    df_reg = pd.read_csv('Clean_data_reg.csv')
    cols_to_drop = ["Unnamed: 0"]
    df_reg = df_reg.drop(columns=cols_to_drop,axis=1)

    # Feature Label Split
    feat = df_reg.drop(columns=['PBASlack'],axis=1)
    label= df_reg["PBASlack"]

    metricsValreg2reg=10
    #  repeat the training process until the mean absolute error (metricsValreg2reg) is below 0.10
    while(metricsValreg2reg>0.10):
        # print(metricsValreg2reg)
        X_train, X_test, y_train, y_test = train_test_split(feat, label, test_size=0.2)
        rf2_reg = RandomForestRegressor(n_estimators = 400,min_samples_split=4,min_samples_leaf=1,max_depth=80)
        rf2_reg.fit(X_train, y_train)
        predictions = rf2_reg.predict(X_test)
        metricsValreg2reg=metrics.mean_absolute_error(y_test, predictions)

        # To understand variability in the MSE for different features and hyper parameter configurations
        # if(metricsValreg2reg<0.15):
        #     print(metricsValreg2reg)
        #     plt.scatter(y_test, predictions)
        #     plt.savefig("scatter_PG_reg2reg.jpg")

    joblib.dump(rf2_reg, "./rfbestmodel_reg2reg.joblib")
# Input Prediction Model
    df_inp = pd.read_csv(inputpath)
    cols_to_drop = ["designName","RequiredTime","sumFO"]
    df_inp = df_inp.drop(columns=cols_to_drop,axis=1)
    df_inp.to_csv('Clean_data_inp.csv')
    df_inp = pd.read_csv('Clean_data_inp.csv')
    cols_to_drop = ["Unnamed: 0"]
    df_inp = df_inp.drop(columns=cols_to_drop,axis=1)
    feat = df_inp.drop(columns=['PBASlack'],axis=1)
    label= df_inp["PBASlack"]

    metricsValinp=10
    #  repeat the training process until the mean absolute error (metricsValreg2reg) is below 0.10
    while(metricsValinp>0.10):
        # print(metricsValinp)
        X_train, X_test, y_train, y_test = train_test_split(feat, label, test_size=0.2)
        rf2_inp = RandomForestRegressor(n_estimators = 400,min_samples_split=4,min_samples_leaf=1,max_depth=80)
        rf2_inp.fit(X_train, y_train)
        predictions = rf2_inp.predict(X_test)
        metricsValinp=metrics.mean_absolute_error(y_test, predictions)
        # if(metricsValinp<0.15):
        #     plt.scatter(y_test, predictions)
        #     plt.savefig("scatter_PG_inputs.jpg")
    
    # Save the trained Reg2Reg model to a joblib file
    # joblib.dump(rf2_inp, "./rfbestmodel_inputs.joblib")

# Output Prediction Model
    df_out = pd.read_csv(outputpath)
    cols_to_drop = ["designName","RequiredTime","sumFO"]
    df_out = df_out.drop(columns=cols_to_drop,axis=1)
    df_out.to_csv('Clean_data_out.csv')
    df_out = pd.read_csv('Clean_data_out.csv')
    cols_to_drop = ["Unnamed: 0"]
    df_out = df_out.drop(columns=cols_to_drop,axis=1)
    feat = df_out.drop(columns=['PBASlack'],axis=1)
    label= df_out["PBASlack"]

    metricsValout=10
    #  repeat the training process until the mean absolute error (metricsValreg2reg) is below 0.10
    while(metricsValout>0.10):
        # print(metricsValout)
        X_train, X_test, y_train, y_test = train_test_split(feat, label, test_size=0.2)
        rf2_out = RandomForestRegressor(n_estimators = 400,min_samples_split=4,min_samples_leaf=1,max_depth=80)
        rf2_out.fit(X_train, y_train)
        predictions = rf2_out.predict(X_test)
        metricsValout=metrics.mean_absolute_error(y_test, predictions)
        # if(metricsValout<0.15):
        #     plt.scatter(y_test, predictions)
        #     plt.savefig("scatter_PG_output.jpg")
    # joblib.dump(rf2_out, "./rfbestmodel_output.joblib")
    


# Predict PBA values from the test files. Similar to MAIN file parser
def PredictValuefromGBA(fileNamePathPBA,fileNamePathGBA):
    inputspred = pd.DataFrame(columns=[ 'violated', 'pathLength','sumCap','sumFO','RVTCount','HVTCount','LVTCount','arrivalTime','RequiredTime','GBASlack','PBASlack'])
    outputpred = pd.DataFrame(columns=[ 'violated', 'pathLength','sumCap','sumFO','RVTCount','HVTCount','LVTCount','arrivalTime','RequiredTime','GBASlack','PBASlack'])
    reg2regpred = pd.DataFrame(columns=[ 'violated', 'pathLength','sumCap','sumFO','RVTCount','HVTCount','LVTCount','arrivalTime','RequiredTime','GBASlack','PBASlack'])
    Point=[]
    Fanout=[]
    Cap=[]
    HVTCount=0
    LVTCount=0
    RVTCount=0
    initialCase=1
    actualval={}
    try:
        timingFileGBA=open(fileNamePathGBA,'r')
        logger.info('Clear: Successfully read the file  IN PATH: %s',fileNamePathGBA)
    except:
        logger.error('Error Reading GBA File for test case')


    try:
        timingFilePBA=open(fileNamePathPBA,'r')
        logger.info('Clear: Successfully read the file  IN PATH: %s',fileNamePathPBA)
    except:
        logger.error('Error Reading GBA File for test case')

    for line in timingFilePBA.readlines():
        if line.strip():
            match initialCase:
                case 1:
                    if "-pba_mode" in line:
                        analysisMode='PBA'
                        initialCase=101
                        continue
                case 101 :
                    if "Path Group:" in line:
                        pathGroup=line.split(":")[-1][1:].strip()
                        if(pathGroup=="comb"):
                            initialCase=1
                        else:
                            initialCase=102
                        continue
                case 102 : 
                    if "slack" in line:
                        pbaslack=line.split("  ")[-1].strip()
                        initialCase=103
                case 103 :
                    if(pathGroup=="inputs"):
                        actualval["inputs"]=float(pbaslack)
                    if(pathGroup=="output"):
                        actualval["output"]=float(pbaslack)
                    if(pathGroup=="reg2reg"):
                        actualval["reg2reg"]=float(pbaslack)
                    initialCase=1      


    for line in timingFileGBA.readlines():
        if line.strip():
            match initialCase:
                case 1 :
                    try:
                        if "-delay_type" in line: 
                            delayType=line.split(" ")[-1].strip()
                            initialCase=6
                            continue
                    except:
                        logger.error('Error, no delay Type in the file')
                case 6 :
                    if "Startpoint" in line:
                        startPoint=line.split(":")[-1][1:].strip()
                        startPoint=startPoint.split(" ")[0]
                        initialCase=7
                        continue
                case 7 :
                    if "Endpoint" in line:
                        endPoint=line.split(":")[-1][1:].strip()
                        endPoint=endPoint.split(" ")[0]
                        initialCase=8
                        continue
                case 8 : 
                    if "Path Group:" in line:
                        pathGroup=line.split(":")[-1][1:].strip()
                        if pathGroup=="comb":
                            initialCase=1
                        else:
                            initialCase=9

                        continue
                case 9 :
                    if ("Point" in line)and("Fanout" in line)and("Cap" in line)and("Trans" in line)and("Incr" in line)and("Path" in line):
                        initialCase=10
                        continue
                case 10 :
                    if "----------" in line:
                        initialCase=11
                        continue
                case 11 :
                    if "---------" in line:
                        initialCase=12
                        continue
                    else:
                        templine=line.split("  ")
                        tempvalue=line.split("  ")[-1]
                        Point.append(templine[1])
                        if "HVT" in templine[1]:
                            HVTCount=HVTCount+1
                        if "LVT" in templine[1]:
                            LVTCount=LVTCount+1
                        if ("RVT" in templine[1])or("SVT" in templine[1]):
                            RVTCount=RVTCount+1

                        if "(net)" in line:
                            Fanout.append(tempvalue.split()[0])
                            Cap.append(tempvalue.split()[1])
                        else:
                            Fanout.append("")
                            Cap.append("")

                case 12 :
                    if "required time" in line:
                        requiredTime=line.split(" ")[-1].strip()
                        initialCase=13
                        continue
                case 13 :
                    if "arrival time" in line:
                        arrivalTime=line.split("  ")[-1].strip()
                        initialCase=14
                        continue
                case 14 :
                    if "slack" in line:
                        slack=line.split("  ")[-1].strip()
                        if "MET" in line:
                            violated=False
                        elif "VIOLATED" in line:
                            violated=True
                        initialCase=15
                        continue
                case 15 :
                    # Path Length extraction 
                    pathLength=pathLengthExtractor(Point,startPoint,endPoint)
                    # Sum of Cap 
                    sumofCap=capSum(Cap)
                    # Sum of Fanout/Product of Fanout.
                    sumofFo=fanOutSum(Fanout)
                    if(pathGroup=="inputs"):
                        try:
                            inputspred= inputspred.append({'violated':violated, 'pathLength':pathLength,'sumCap':sumofCap,'sumFO':sumofFo,'RVTCount':RVTCount,'HVTCount':HVTCount,'LVTCount':LVTCount,'arrivalTime':float(arrivalTime),'RequiredTime':float(requiredTime),'GBASlack':float(slack),'PBASlack':0},ignore_index = True)
                        except:
                            logger.error('GBA - Error appending to inputspred')

                    if(pathGroup=="output"):
                        try:
                            outputpred= outputpred.append({'violated':violated, 'pathLength':pathLength,'sumCap':sumofCap,'sumFO':sumofFo,'RVTCount':RVTCount,'HVTCount':HVTCount,'LVTCount':LVTCount,'arrivalTime':float(arrivalTime),'RequiredTime':float(requiredTime),'GBASlack':float(slack),'PBASlack':0},ignore_index = True)
                        except:
                            logger.error('GBA - Error appending to outputpred')

                    if(pathGroup=="reg2reg"):
                        try:
                            reg2regpred= reg2regpred.append({'violated':violated, 'pathLength':pathLength,'sumCap':sumofCap,'sumFO':sumofFo,'RVTCount':RVTCount,'HVTCount':HVTCount,'LVTCount':LVTCount,'arrivalTime':float(arrivalTime),'RequiredTime':float(requiredTime),'GBASlack':float(slack),'PBASlack':0},ignore_index = True)
                        except:
                            logger.error('GBA - Error appending to reg2regpred')

                    Point=[]
                    Fanout=[]
                    Cap=[]
                    initialCase=1
                    continue

    # load all three models
    # Predict the output
    # Find divergence in the prediction
    try:
        cols_to_drop = ["RequiredTime","sumFO","PBASlack"]
        inputrf= joblib.load("./random_forest_bestmodel_inputs.joblib")

        inputspred = inputspred.drop(columns=cols_to_drop,axis=1)
        predictioninput = inputrf.predict(inputspred)
        print("   ")
        print("Predicted PBA Input Slack value: " + str(predictioninput[0]) + " Actual PBA Input Slack value: " +str(actualval['inputs']))
        dev_inp=abs((predictioninput[0]-actualval['inputs'])/actualval['inputs'])*100
        print("Deviation in Predicting PBA Input slack value " + str(round(dev_inp, 2))+"%")
        print("   ")
        outputrf= joblib.load("./random_forest_bestmodel_output.joblib")
        outputpred = outputpred.drop(columns=cols_to_drop,axis=1)
        predictionoutput = outputrf.predict(outputpred)
        print("   ")
        print("Predicted PBA Output Slack value: " + str(predictionoutput[0]) + " Actual PBA Output Slack value: " +str(actualval['output']))
        dev_out=abs((predictionoutput[0]-actualval['output'])/actualval['output'])*100
        print("Deviation in Predicting PBA Output slack value " + str(round(dev_out, 2))+"%")

        reg2regrf= joblib.load("./random_forest_bestmodel_reg2reg.joblib")
        reg2regpred = reg2regpred.drop(columns=cols_to_drop,axis=1)
        predictionreg2reg = reg2regrf.predict(reg2regpred)
        print("   ")
        print("Predicted  PBA Reg2Reg Slack value: " + str(predictionreg2reg[0]) + " Actual PBA Reg2Reg Slack value: " +str(actualval['reg2reg']))
        dev_reg2reg=abs((predictionreg2reg[0]-actualval['reg2reg'])/actualval['reg2reg'])*100
        print("Deviation in Predicting PBA Reg2Reg  slack value " + str(round(dev_reg2reg, 2))+"%")
        logger.info('Prediction: Successful')
    except:
        logger.error('Error Predicting Value !!')


def main(rootdirGBA,rootdirPBA):

    logger.info('GBA - FileParsing inside the path : %s',rootdirGBA)
    for folders in os.listdir(rootdirGBA):
        a={}
        if(os.path.exists(os.path.join(rootdirGBA,folders))):
            if not folders.startswith("."):       
                for files in os.listdir(os.path.join(rootdirGBA,folders)):
                    if not files.startswith("."):
                        logger.info('GBA - file %s',files)
                        designdirName=folders
                        a[files]=fileParsing(files,rootdirGBA,designdirName)

    logger.info('PBA - FileParsing inside the path : %s',rootdirGBA)
    for folders in os.listdir(rootdirPBA):
        a={}
        if(os.path.exists(os.path.join(rootdirPBA,folders))):
            if not folders.startswith("."):       
                for files in os.listdir(os.path.join(rootdirPBA,folders)):
                    if not files.startswith("."):
                        logger.info('PBA - file %s',files)
                        designdirName=folders
                        a[files]=fileParsing(files,rootdirPBA,designdirName)


if __name__ == "__main__":
    logger = logging.getLogger('abelmathew98')
    logger.setLevel(logging.INFO)
    logging.basicConfig(filename='PBA_GBA.log', filemode='w', format='%(name)s - %(levelname)s - %(message)s')
    logger.info('START : Log start')
    logger.info('Reading Parameters from Jsonfile')
    try:
        # Paths to files and folders are stored in parameters.json
        jsonFile=open("parameters.json")
        jsonData = json.load(jsonFile)
        rootdirGBA = jsonData['GBAPath']
        rootdirPBA = jsonData['PBAPath']
        rootoutFile = jsonData['OutfilePath']
        logger.info('Successfully read Parameters from Jsonfile')
    except:
        logger.error('json file %s throws Error',"parameters.json")
    main(rootdirGBA,rootdirPBA)
    outTocsv(rootoutFile)
    pbapredictpath=jsonData['pbapredictpath']
    gbapredictpath=jsonData['gbapredictpath']
    predictionModel(rootoutFile)

    PredictValuefromGBA(pbapredictpath,gbapredictpath)
    logger.info('END : Log end')
