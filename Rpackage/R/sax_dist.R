minDist<-function(
  ### calculates dissimilarity matrix for SAX alphabet 
  alphasize##<< size of the alphabet
){
  md<-matrix(0,ncol=alphasize,nrow=alphasize);
  bp <- c(-Inf,qnorm(1:(alphasize-1)/alphasize),Inf);
  for(i in 1:alphasize){
    j=i+2;
    while(j <=alphasize){
      #print(c(i,j,bp[i+1],bp[j]));
      md[i,j]<- abs(bp[i+1]-bp[j]);
      md[j,i]<- md[i,j];
      j=j+1;
    }
  }
  return(md)
}


hsaxDist<-function(
### distance between two hSAX strings  
  x,##<< first string
  y,##<< second string
  base=hSAXbase(),##<< SAXbase object
  md##<< dissimilarity matrix for SAX alphabet
  ){
  if(class(x)=="character"){
    xi<-hSAX2int(x,base)
  }else if(class(x)=="integer"){
    xi<-x
    if(min(xi)<1|max(xi)>16){
      stop(paste('X suppose to be in range [1,',base$alphasize,']'))
    }
  }else{
    stop('X suppose to be either string or vector of integers')
  }
  if(class(y)=="character"){
    yi<-hSAX2int(y,base)
  }else if(class(y)=="integer"){
    yi<-y
    if(min(yi)<1|max(yi)>16){
      stop(paste('Y suppose to be in range [1,',base$alphasize,']'))
    }
  }else {
    stop('Y suppose to be either string or vector of integers')
  }
  minDistFun<-function(.x)md[.x[1],.x[2]];
  if(missing(md)) md<- minDist(base$alphasize);
  if(dim(xi)[2]==1&dim(yi)[2]==1){
    dist<-sqrt(sum(apply(rbind(as.vector(xi), as.vector(yi)),2,minDistFun)^2))
  }else{
    dist<-matrix(nrow=dim(xi)[2],ncol=dim(yi)[2])
    for(i in 1:dim(xi)[2]){
      for(j in 1:dim(yi)[2]){
        dist[i,j]<-sqrt(sum(apply(rbind(as.vector(xi[,i]), as.vector(yi[,j])),2,minDistFun)^2))
      }
    }
  }
  return(dist)
}

hashSAX<-function(cp,##<< signal 
  wl=16,##<< desired length of the string representation
  win=length(ts),##<< sliding window length. Signal will be represented as set of length(ts)-win+1 strings of wl characters each.
  verbose=FALSE##<< if TRUE print progress indicator
  ){
	if(!require(futile.logger)){
		stop('you need to install "futile.logger" library')
	}
	alphasize<-16
	md<- minDist(alphasize);
	saxhash<-list()
	ranlist<-data.frame(i=1,sax='sax',len=1,stringsAsFactors=FALSE)[FALSE,]
	lastS<-hSAX(cp[1:win],wl,win)[1,1]
	lastR<-1
	len<- -1
	rli<-1
	l<-length(cp)-win
	ranlist[l,]<-list(NA,NA,NA)
	for(i in 1:l){
	 wp<-cp[i:(i+win-1)]
	 h<-hSAX(wp,wl,win)[1,1]
	 if((shl<-length(saxhash[[h]]))>0){
	  saxhash[[h]][length(shl)+1]<-i
	 }else{
	  saxhash[[h]]<-list(i)
	 }
	 if(hsaxDist(h,lastS,md=md)==0){
	  len<-len+1
	  }else{
	   if(len>0){
		ranlist[rli,]<-list(lastR,lastS,len)
		rli<-rli+1
	   }
	   lastR<-i
	   lastS<-h
	   len<-0
	  }
	  if(verbose & (i %% 1000 ==0)){
	   cat(paste(i,'\n'))
	  }
	 }
	ret<-list(sax=saxhash,run=ranlist[1:rli-1,])
	class(ret)<-'saxhash'
	return(ret)
}

#library(iSAXr);sig<-rnorm(10000); hashSAX(sig,wl=10,win=36)->hs
