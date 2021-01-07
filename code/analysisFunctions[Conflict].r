
### simple difference estimator
### Neyman variance estimate
simpDiff <- function(datPS,covsPS,outcome='complete'){
  Y <- datPS[[outcome]]
  Z <- datPS$treatment
  est <- mean(Y[Z==1])- mean(Y[Z==0])
  Vhat <- var(Y[Z==1])/sum(Z==1)+var(Y[Z==0])/sum(Z==0)
  return(c(tauhat=est,varhat=Vhat))
}

### rebar estimate: simple difference on residuals
rebar <- function(datPS,covsPS)
  simpDiff(datPS,covsPS,outcome='residual')

## OLS LOOP with deep learning predictions as the only covariate
strat1 <- function(datPS,covsPS)
    with(datPS,
         loop_ols(complete,treatment,p_complete))

## RF LOOP with deep learning predictions alongside other covariates
strat2 <- function(datPS,covsPS)
    with(datPS,
         loop(complete,treatment,cbind(p_complete,covsPS)))

## Combine RF LOOP with covariates with OLS LOOP with deep learning predictions
strat3 <- function(datPS,covsPS)
    with(datPS,
         loop_ext(complete,treatment,covsPS,extm=p_complete))

## RF LOOP with covariates, no deep learning predictions
justCovs <- function(datPS,covsPS)
    with(datPS,
         loop(complete,treatment,covsPS))

## all the estimators, for a particular problem set
full <- function(ps,n,methods=c('simpDiff','rebar','strat1','strat3','justCovs'),seed){
    datPS <- dat[dat$problem_set==ps,]
    covsPS <- covs[dat$problem_set==ps,]

    if(!missing(n)){
      if(!missing(seed)) set.seed(seed)
      samp <- sample(1:nrow(datPS),n)
      datPS <- datPS[samp,]
      covsPS <- covsPS[samp,]
    }

    res <- sapply(methods,
                  function(FUN){
                      fun <- get(FUN)
                      fun(datPS,covsPS)
                  },simplify=FALSE)
    res <- do.call('rbind',res)
    res[,2] <- sqrt(res[,2])  ## standard error, not variance
    colnames(res) <- c('est','se')
    res <- cbind(res,improvement=1-res[,'se']/res['simpDiff','se'])
    res
}
