# install.packages("mvnfast")
library(mvnfast)

library(mvtnorm)
# Form A
itemPara_SS_A <- read.table("TestData/SpanishLit_prm_A_SS.txt")[,c(7:10)]
# item parameter transformation
names(itemPara_SS_A) <- c("b", "a1","a2","a3")
itemPara_SS_A$a <- c(itemPara_SS_A$a1[1:13], itemPara_SS_A$a2[14:25], itemPara_SS_A$a3[26:31])
itemPara_SS_A[,"b"] <- -itemPara_SS_A[,"b"]/itemPara_SS_A[,"a"]
itemPara_SS_A[,"a"] <- itemPara_SS_A[,"a"]/1.702
itemPara_SS_A$a1[1:13] <- itemPara_SS_A$a[1:13]
itemPara_SS_A$a2[14:25] <- itemPara_SS_A$a[14:25]
itemPara_SS_A$a3[26:31] <- itemPara_SS_A$a[26:31]
cormat_A <- matrix(c(1, 0.9067069, 0.6994119,
                     0.9067069, 1, 0.4891160,
                     0.6994119,0.4891160,1), nrow = 3)

corvec <- c(0.9067069, 0.6994119, 0.4891160)
strat <- c(13, 12, 6)

itemPara <- itemPara_SS_A
cormat <- cormat_A



# Form B
itemPara_SS_B <- read.table("TestData/SpanishLit_prm_B_SS.txt")[,c(7:10)]
# item parameter transformation
names(itemPara_SS_B) <- c("b", "a1","a2","a3")
itemPara_SS_B$a <- c(itemPara_SS_B$a1[1:13], itemPara_SS_B$a2[14:25], itemPara_SS_B$a3[26:31])
itemPara_SS_B[,"b"] <- -itemPara_SS_B[,"b"]/itemPara_SS_B[,"a"]
itemPara_SS_B[,"a"] <- itemPara_SS_B[,"a"]/1.702
itemPara_SS_B$a1[1:13] <- itemPara_SS_B$a[1:13]
itemPara_SS_B$a2[14:25] <- itemPara_SS_B$a[14:25]
itemPara_SS_B$a3[26:31] <- itemPara_SS_B$a[26:31]
cormat_B <- matrix(c(1, 0.9722234, 0.5602197,
                     0.9722234, 1, 0.4795721,
                     0.5602197,0.4795721,1), nrow = 3)

corvec <- c(0.9722234, 0.5602197, 0.47957210)
strat <- c(13, 12, 6)

itemPara <- itemPara_SS_B
cormat <- cormat_B




MarginalRelSSMIRT_D_MLE <- function(itemPara, cormat, strat){
  # number of factors
  numOfFactors <- length(strat)

  # num of quadratures
  numOfQuad <- 15

  # set nodes and weights
  nodes <- seq(-5, 5, length.out = numOfQuad)
  nodesM <- as.matrix(expand.grid(nodes,nodes,nodes))
  weightsUnwtd <- dmvnorm(nodesM, c(0,0,0), cormat, log=FALSE)
  nodesM <- as.data.frame(nodesM)
  nodesM$weightsWtd <- weightsUnwtd / sum(weightsUnwtd)
  names(nodesM) <- c("theta1", "theta2", 'theta3',"weightsWtd")

  # CSEM function: different return
  CSEMIRT <- function(theta, itemPara, estType){

    # return info for each theta
    if (estType == "MLE"){

      # calculate info
      itemParaInfo <- as.data.frame(Info(theta, itemPara, "MLE"))

      # calculate CSEM for each theta
      itemParaInfo$csemMLE <- sqrt(1/itemParaInfo$infoMLE)

      # return csem
      return(itemParaInfo$csemMLE)

    }else if (estType == "EAP"){

      # calculate info
      itemParaInfo <- as.data.frame(Info(theta, itemPara, "EAP"))

      # calculate CSEM for each theta
      itemParaInfo$csemEAP <- sqrt(1/itemParaInfo$infoEAP)

      # return csem
      return(itemParaInfo$csemEAP)

    }else{

      warning("csemIRT function only supports MLE and EAP estimation method!")

    }
  }

  # CSEM
  nodesM$se1 <- apply(as.data.frame(nodesM[,"theta1"]), 1, CSEMIRT, itemPara[1:13, c("b", "a")], "MLE")
  nodesM$se2 <- apply(as.data.frame(nodesM[,"theta2"]), 1, CSEMIRT, itemPara[14:25, c("b", "a")], "MLE")
  nodesM$se3 <- apply(as.data.frame(nodesM[,"theta3"]), 1, CSEMIRT, itemPara[26:31, c("b", "a")], "MLE")

  # variance of composite score
  nodesM <- transform( nodesM,
                       varC = se1^2 + se2^2  + se3^2#  + 2 *corvec[1] * se1 * se2 + 2 *corvec[2] * se1 * se3 + 2 *corvec[3] * se2 * se3
  )

  # average of error variance
  ErrorVarAvg <- sum(nodesM$varC * nodesM$weightsWtd)
  ErrorVarAvg


  # Form A
  # MLE: 3.084788
  # EAP: 3.366964

  # Form B
  # MLE: 3.286885
  # EAP: 3.33247




  # # variance of composite score
  # nodesM <- transform( nodesM,
  #                      var1 = se1^2 * weightsWtd,# + se2^2  + se3^2#  + 2 *corvec[1] * se1 * se2 + 2 *corvec[2] * se1 * se3 + 2 *corvec[3] * se2 * se3
  #                      var2 = se2^2 * weightsWtd,# + se2^2  + se3^2
  #                      var3 = se3^2 * weightsWtd# + se2^2  + se3^2
  # )
  #
  # # average of error variance
  #
  # mean(nodesM$var1) + mean(nodesM$var2) + mean(nodesM$var3)
  #
  # ErrorVarAvg <- sum(nodesM$varC * nodesM$weightsWtd)
  # ErrorVarAvg






  # marginal reliability approach
  1 - ErrorVarAvg /(ErrorVarAvg + numOfFactors + 2 *(corvec[1] + corvec[2] + corvec[3])) # var(e)/(var(e) + var(theta))

  MarginalRelSSMIRT <- (numOfFactors + 2 *(corvec[1] + corvec[2] + corvec[3]))/ (numOfFactors + 2 *(corvec[1] + corvec[2] + corvec[3]) + ErrorVarAvg)
  # 7.19

  # coefficients
  MarginalRelSSMIRT

}



# 0.7045


############# verification of SS MIRT marginal MLE ----------------------------------------------
# Form A
itemPara_SS_A <- read.table("TestData/SpanishLit_prm_A_SS.txt")[,c(7:10)]
cormat_A <- matrix(c(1, 0.9067069, 0.6994119,
                     0.9067069, 1, 0.4891160,
                     0.6994119,0.4891160,1), nrow = 3)
strat <- c(13, 12, 6)
# item parameter transformation
names(itemPara_SS_A) <- c("b", "a1","a2","a3")
itemPara_SS_A$a <- c(itemPara_SS_A$a1[1:13], itemPara_SS_A$a2[14:25], itemPara_SS_A$a3[26:31])
itemPara_SS_A[,"b"] <- -itemPara_SS_A[,"b"]/itemPara_SS_A[,"a"]
itemPara_SS_A[,"a"] <- itemPara_SS_A[,"a"]/1.702
itemPara_SS_A$a1[1:13] <- itemPara_SS_A$a[1:13]
itemPara_SS_A$a2[14:25] <- itemPara_SS_A$a[14:25]
itemPara_SS_A$a3[26:31] <- itemPara_SS_A$a[26:31]


thetaM <- rmvn(n=1000, c(0,0,0), cormat_A)


# factor 1
thetaq <- thetaM[,1]
itemPara <- itemPara_SS_A[1:13, c("b", "a")]

prob3PL <- function(D, theta, a, b){
  0 + (1 - 0) / (1 + exp(-D * a * (theta - b)))
}

gen3PL <- function(itemPara, I, thetaq){

  J <- nrow(itemPara)
  resp <- matrix(nrow = I, ncol = J)
  prob <- matrix(nrow = I, ncol = J)
  gamma <- matrix(runif(n = I*J, min = 0, max = 1), nrow = I, ncol = J)

  for (i in 1:I){
    for(j in 1:J){
      prob[i, j] <- prob3PL(D = 1.702, thetaq[i], itemPara[j,"a"], itemPara[j, "b"])
    }
  }
  resp <- ifelse(prob > gamma, 1, 0)
  return(resp)
}

resp1 <- gen3PL(itemPara_SS_A[1:13, c("b", "a")], 1000, thetaM[,1])
resp1


resp2 <- gen3PL(itemPara_SS_A[14:25, c("b", "a")], 1000, thetaM[,2])
resp2

resp3 <- gen3PL(itemPara_SS_A[26:31, c("b", "a")], 1000, thetaM[,3])
resp3



resp <- cbind(resp1, resp2, resp3)

# write.table(resp, "resp.txt", row.names = F, col.names = F)





