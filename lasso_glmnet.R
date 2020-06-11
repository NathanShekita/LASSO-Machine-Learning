rm(list=ls())

library("glmnet")
library(foreign)
library(tools)

setwd("C:/Documents/R_work")
file.names<-dir("C:/Documents/R_work", pattern=".dta")

#look through all files in folder, define where to save output
for(i in 1:length(file.names)) {
  
    mydata<-read.dta(file.names[i])
    thename<-file_path_sans_ext(file.names[i])
    version<-"sparse_"
    extension<-".csv"
    location<-"C:/Documents/R_work"
    filesaver<-paste(location,version,thename,extension,sep = "")
  
  #define matrix from data
  x<-as.matrix(mydata)
  #remove dependent variable
  x<-x[,-1]
  
  #matrix of dependent
  y<-as.matrix(mydata[c("oon_rate")])
  
  #Lambda obtained can vary in each iteration, so running 100 times 
  #put these into a matrix and take the average value
  lambdas = NULL
  
  for (i in 1:100)
  {
   
    fit <- cv.glmnet(x,y)
    sdlamb=data.frame(fit$lambda.1se)
    lambdas<-rbind(lambdas,sdlamb)
  }
  
  lammat<-as.matrix(lambdas)
  avgvalue=mean(lammat)
  
  #Run glmnet with chosen lambda
  cvfit <- glmnet(x,y,lambda=avgvalue)
  
  #Obtain coefficients from cvfit
  coef(cvfit)
  
  output<-as.matrix(coef(cvfit))
  
  #store output into a csv. We take all variables with nonzero coefficients
  write.csv(output, file=filesaver)
  
}





