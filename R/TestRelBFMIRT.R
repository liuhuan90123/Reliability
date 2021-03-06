library(LaplacesDemon)
library(profvis)
source("R/NormalQuadraPoints.R")
source("R/LordWingersky.R")
library(mvtnorm)


######## BI-Factor Full Approach 2 ------------------------------------


# read item parameters from txt file
itemPara_BF <- read.table("TestData/SpanishLit_prm_A_BF.txt")[,c(7:11)]
# itemPara_BF <- read.table("TestData/SpanishLit_prm_B_BF.txt")[,c(7:11)]

# read conversion tables
convTable_A <- read.csv("TestData/conversion_table_Form A.csv")
convTable_A <- convTable_A[1:32, c("RawScore", "roundedSS")]
names(convTable_A) <- c("y","roundedSS")
convTable <- convTable_A


# convTable_B <- read.csv("TestData/conversion_table_Form B.csv")
# convTable_B <- convTable_B[1:32, c("RawScore", "roundedSS")]
# names(convTable_B) <- c("y","roundedSS")
# convTable <- convTable_B


strat <- c(13, 12, 6)

names(itemPara_BF) <- c("b", "ag","a1","a2", "a3") # ag is primary
itemPara_BF$ai <- c(itemPara_BF$a1[1:13], itemPara_BF$a2[14:25], itemPara_BF$a3[26:31])

# num of items
numOfItem <- nrow(itemPara_BF)

# num of quadratures
numOfQuad <- 11


# set nodes ranging from -4 to 4
nodes <- seq(-4, 4, length.out = numOfQuad)
nodesM <- as.matrix(expand.grid(nodes,nodes,nodes, nodes))
weightsUnwtd <- dmvnorm(nodesM, c(0,0,0,0), diag(4), log=FALSE) # 41^3
nodesM <- as.data.frame(nodesM)
nodesM$weightsWtd <- weightsUnwtd / sum(weightsUnwtd)

itemPara1 <- itemPara_BF[1:13,c("b", "ag", "ai")]
itemPara2 <- itemPara_BF[14:25,c("b", "ag", "ai")]
itemPara3 <- itemPara_BF[26:31,c("b", "ag", "ai")]


# itemPara <- itemPara1

FX_BF <- function(itemPara){

  NormalQuadraPoints <- function(n){

    # set nodes ranging from -4 to 4
    nodes <- seq(-4, 4, length.out = n)

    # unnormalized weights
    weightsUnwtd <- sapply(nodes, FUN = function(x) dnorm(x))

    # normalized weightes
    weightsWtd <- weightsUnwtd / sum(weightsUnwtd)

    # return nodes and normalized weights
    return(list("nodes" = nodes, "weights" = weightsWtd))

  }

  # transform item parameters to the logistic metric
  names(itemPara) <- c("b", "ag", "ai")

  # num of items
  numOfItem <- nrow(itemPara)

  # num of quadratures
  # numOfQuad <- numOfQuad^2

  # weights and nodes
  quadPoints <- expand.grid(NormalQuadraPoints(numOfQuad)$nodes, NormalQuadraPoints(numOfQuad)$nodes)

  # quadPoints <- nodes

  # replicate item parameter and theta
  itemParaRep <-itemPara[rep(seq_len(numOfItem), each = numOfQuad^2),]
  itemParaRep$thetag <- rep(quadPoints[,c(1)], each = 1, length.out = numOfQuad^2*numOfItem)
  itemParaRep$thetai <- rep(quadPoints[,c(2)], each = 1, length.out = numOfQuad^2*numOfItem)

  # calculate information by theta
  itemParaRep <- within(itemParaRep, {
    P = 0 + (1 - 0) / (1 + exp(-(ag*thetag + ai*thetai - b)))
    Q = 1 - P
    PQ = P * Q
    # info = 1.702**2 * a**2 * P * Q
  })

  # order by theta
  itemParaRep <- itemParaRep[order(itemParaRep$thetag,itemParaRep$thetai),]

  # define matrix of marginal distribution of theta
  fxTheta <- matrix(NA, nrow = numOfQuad^2, ncol = numOfItem + 1) # 41 num of quadratures, 41 num of raw sxores

  # for loop to calculate fxTheta
  for (i in 1:numOfQuad^2){

    probs <- matrix(c(itemParaRep[(1 + numOfItem * (i - 1)):(numOfItem * i),]$P),
                    nrow = numOfItem, ncol = 1, byrow = FALSE)

    fxTheta[i, ] <- LordWingersky(probs)$probability

  }

  # transform to data frame
  fxTheta <- as.data.frame(fxTheta)

  fxTheta

}


# fxtheta distribution
fxTheta1 <- FX_BF(itemPara1)
fxTheta2 <- FX_BF(itemPara2)
fxTheta3 <- FX_BF(itemPara3)

names(fxTheta1) <- c(0:strat[1])
names(fxTheta2) <- c(0:strat[2])
names(fxTheta3) <- c(0:strat[3])



# for loop
tau <- c()
errvar <- c()
fyDistMat <- matrix(NA,numOfQuad^4,32)

# SS
nodesMSS <- nodesM


tauSS <- c()
errvarSS <- c()
fySSDistMat <- matrix(NA,numOfQuad^4,32)



n <- 0

for (g in 1:numOfQuad){
  for (k in 1:numOfQuad){
    for (j in 1:numOfQuad){
      for (i in 1:numOfQuad){
        # index
        n <- n+1


        # i <- j <- k <- g <- 1 # test
        # n <- 1 # test

        # fx distribution
        fx1 <- t(fxTheta1[11*(g-1)+i,])
        fx2 <- t(fxTheta2[11*(g-1)+j,])
        fx3 <- t(fxTheta3[11*(g-1)+k,])

        xSum <- expand.grid(rownames(fx1), rownames(fx2), rownames(fx3))
        names(xSum) <- c("x1", "x2", "x3")

        fxSum <- expand.grid(fx1, fx2, fx3)
        names(fxSum) <- c("fx1", "fx2", "fx3")

        fxThetaSum <- cbind(fxSum, xSum)

        fxThetaSum$x1 <- as.numeric(as.character(fxThetaSum$x1))
        fxThetaSum$x2 <- as.numeric(as.character(fxThetaSum$x2))
        fxThetaSum$x3 <- as.numeric(as.character(fxThetaSum$x3))

        # fy distribution
        fxThetaSum$y <- fxThetaSum$x1 + fxThetaSum$x2 + fxThetaSum$x3
        fxThetaSum$wty <- fxThetaSum$fx1 * fxThetaSum$fx2 * fxThetaSum$fx3
        fy <- fxThetaSum[,c("y", "wty")]
        fyDist <- aggregate(fy$wty, by=list(Category=fy$y), FUN=sum)
        names(fyDist) <- c("y", "wts")

        # weighted mean of Obs Y (true y) and variance of Obs Y
        weightedMean <- sum(fyDist$y * fyDist$wts)/sum(fyDist$wts)
        varianceY <- sum(fyDist$wts * (fyDist$y - weightedMean)^2)

        # save results
        tau[n] <- weightedMean
        errvar[n] <- varianceY
        fyDistMat[n,] <- t(fyDist$wts)

        # SS

        fySSDist <- merge(fyDist, convTable, by = "y")

        # weighted mean of Obs Y (true y) and variance of Obs Y
        weightedMeanSS <- sum(fySSDist$roundedSS * fySSDist$wts)/sum(fySSDist$wts)
        varianceYSS <- sum(fySSDist$wts * (fySSDist$roundedSS - weightedMeanSS)^2)

        # store results
        tauSS[n] <- weightedMeanSS
        errvarSS[n] <- varianceYSS
        fySSDistMat[n,] <- t(fySSDist$wts)


      }
    }
  }
}


nodesM$tau <- tau
nodesM$errvar <- errvar
nodesM[,8:39] <- fyDistMat


#SS
nodesMSS$tauSS <- tauSS
nodesMSS$errvarSS <- errvarSS
nodesMSS[,8:39] <- fySSDistMat



# sum of error variance
varianceError <- sum(nodesM$weightsWtd * nodesM$errvar)
varianceErrorSS <- sum(nodesMSS$weightsWtd * nodesMSS$errvarSS)

# sum of observed score variance
fyThetaWeighted <- apply(nodesM[,8:(8 + numOfItem)], 2, function(x) x * nodesM[,"weightsWtd"])
fySSThetaWeighted <- apply(nodesMSS[,8:(8 + numOfItem)], 2, function(x) x * nodesMSS[,"weightsWtd"])

# sum weighted distribution
fyObsDist <- as.data.frame(matrix(colSums(fyThetaWeighted[,1:(1 + numOfItem)]), nrow = (1 + numOfItem), ncol = 1))
fyObsDist$y <- c(0:numOfItem) # test
names(fyObsDist) <- c("wts", "y")

fySSObsDist <- as.data.frame(matrix(colSums(fySSThetaWeighted[,1:(1 + numOfItem)]), nrow = (1 + numOfItem), ncol = 1))
fySSObsDist$roundedSS <- convTable$roundedSS # test
names(fySSObsDist) <- c("wts", "roundedSS")

# weighted mean of Obs Y
weightedMean <- sum(fyObsDist$y * fyObsDist$wts)/sum(fyObsDist$wts)
weightedMeanSS <- sum(fySSObsDist$roundedSS * fySSObsDist$wts)/sum(fySSObsDist$wts)

# variance of Obs Y
varianceObsY <- sum(fyObsDist$wts * (fyObsDist$y - weightedMean)^2)
varianceObsYSS <- sum(fySSObsDist$wts * (fySSObsDist$roundedSS - weightedMeanSS)^2)


# MIRT test reliability
TestRelBFMIRT <- 1 - varianceError/varianceObsY
TestRelBFMIRTSS <- 1 - varianceErrorSS/varianceObsYSS

varianceError
varianceObsY
TestRelBFMIRT

varianceErrorSS
varianceObsYSS
TestRelBFMIRTSS







