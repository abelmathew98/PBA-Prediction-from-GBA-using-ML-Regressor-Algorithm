import os
import re
import pandas as pd

def fileParsing(fileName,rootdir,designDirectoryName):
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
#     fileName="pba_period8_fir.timing_setup.rpt"
    initialCase=1
    fileNamePath=rootdir+"/"+designDirectoryName+"/"+fileName
#     print(fileNamePath)
    timingFile=open(fileNamePath,'r')

    for line in timingFile.readlines():
        if line.strip():
    #         print(line)
            match initialCase:
                case 1 : 
                    if "-path_type" in line:
                        pathType=line.split(" ")[-1].strip()
                        HVTCount=0
                        LVTCount=0
                        RVTCount=0
                        initialCase=2
                        continue
                case 2 :
                    if "-delay_type" in line: 
                        delayType=line.split(" ")[-1].strip()
                        initialCase=3
                        continue
                case 3 :
                    if "-max_path" in line:
                        maxPath=line.split(" ")[-1].strip()
        #                 print(maxPath)
                        initialCase=4
                        continue
                case 4 :
                    if "-pba_mode" in line:
                        analysisMode='PBA'
                        initialCase=5
                        continue

                    elif "Design :" in line:
                        designName=line.split(" ")[-1].strip()
                        analysisMode='GBA'
                        initialCase=6
                        continue
                case 5 :
                    if "Design :" in line:
                        designName=line.split(" ")[-1].strip()
                        initialCase=6
                        continue

                case 6 :
                    if "Startpoint" in line:
                        startPoint=line.split(":")[-1][1:].strip()
                        initialCase=7
                        continue
                case 7 :
                    if "Endpoint" in line:
                        endPoint=line.split(":")[-1][1:].strip()
        #                 print(endPoint)
                        initialCase=8
                        continue
                case 8 : 
                    if "Path Group:" in line:
                        pathGroup=line.split(":")[-1][1:].strip()
        #                 print(pathGroup)
                        initialCase=9
                        continue
                case 9 :
                    if ("Point" in line)and("Fanout" in line)and("Cap" in line)and("Trans" in line)and("Incr" in line)and("Path" in line):
    #                     print("it hit here")
                        initialCase=10
                        continue
                case 10 :
                    if "----------" in line:
    #                     print("here also")
    #                     print(line)
                        initialCase=11
                        continue
                case 11 :
                    if "---------" in line:
                        initialCase=12
                        continue
                    else:
    #                     print(line)
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
    #                         print(tempvalue.split())
                            Fanout.append(tempvalue.split()[0])
                            Cap.append(tempvalue.split()[1])
                            Tran.append("")
                            Incr.append("")
                            Path.append("")
                        else:
                            Fanout.append("")
                            Cap.append("")
                            templist=tempvalue.replace("r","").replace("f","").replace("&","").replace("*","").replace("\n","").split(" ")
                            templist=[x for x in templist if x]

    #                         print(len(templist))
    #                         print(tempvalue.replace("r","").replace("f","").replace("&","").replace("*","").replace("\n","").split(" "))
                            if(len(templist)==3):
                                Tran.append(templist[-3])
                                Incr.append(templist[-2])
                                Path.append(templist[-1])
                            elif(len(templist)==2):
                                Tran.append("")
                                Incr.append(templist[-2])
                                Path.append(templist[-1])   
                            elif(len(templist)==1):
                                Tran.append("")
                                Incr.append("")
                                Path.append(templist[-1])
    #                     print("\n")
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
                    timingData={"Path Element":Point,"Fanout":Fanout,"Capacitance":Cap,"Increment":Incr,"Path":Path}
                    df=pd.DataFrame(timingData)           
                    trialdict={"pathType":pathType,"delayType":delayType,"maxPath":maxPath,"designName":designName,"analysisMode":analysisMode,"startPoint":startPoint,"endPoint":endPoint,"pathGroup":pathGroup,"requiredTime":requiredTime,"arrivalTime":arrivalTime,"slack":slack,"violated":violated,"PathDetails":df,"HVTs":HVTCount,"LVTs":LVTCount,"RVTs":RVTCount}
                    pathgroupdict[pathGroup]=trialdict       
                    Point=[]
                    Fanout=[]
                    Cap=[]
                    Tran=[]
                    Incr=[]
                    Path=[] 
                    initialCase=1
                    continue
    return pathgroupdict




def main():
    print("Hello World!")
    finaldict={}
    rootdir = "/Users/abelmathew/Desktop/Semester 2/VDA2/Project/Files"
    for folders in os.listdir(rootdir):
        a={}
        dummydict_pba={}
        dummydict_gba={}
        dummydict_design={}
    #     print(dummydict_design)
        if(os.path.exists(os.path.join(rootdir,folders))):
            if not folders.startswith("."):       
                for files in os.listdir(os.path.join(rootdir,folders)):
                    if not files.startswith("."):
                        designdirName=folders
    #                     print(designdirName)
                        a[files]=fileParsing(files,rootdir,designdirName)
                        print("hello")
    #     print(a)
                for key in a:
                    # a[key]['reg2reg']['analysisMode'] ==gba
                    if("gba" in key):
                        if("setup" in key):
                            # a[key]['reg2reg']['delayType']== max for set up
                            dummydict_gba["Setup"]=a[key]
                        elif("hold" in key):
                            # a[key]['reg2reg']['delayType']== min for hold
                            dummydict_gba["Hold"]=a[key]

                    if("pba" in key):
                        if("setup" in key):
                            dummydict_pba["Setup"]=a[key]
                        elif("hold" in key):
                            dummydict_pba["Hold"]=a[key]
    #     print(designdirName,dummydict_gba)
                dummydict_design["GBA"]=dummydict_gba
                dummydict_design["PBA"]=dummydict_pba
                finaldict[designdirName]=dummydict_design
                print(designdirName,dummydict_design)


if __name__ == "__main__":
    main()