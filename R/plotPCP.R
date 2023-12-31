#' @title Plot static parallel coordinate plots
#' 
#' @description Plot static parallel coordinate plots onto side-by-side boxplot
#' of whole dataset.
#' 
#' @param data DATA FRAME | Read counts
#' @param dataMetrics LIST | Differential expression metrics; If both geneList 
#' and dataMetrics are NULL, then no genes will be overlaid onto the
#' side-by-side boxplot; default NULL
#' @param dataSE SUMMARIZEDEXPERIMENT | Summarized experiment format that
#' can be used in lieu of data and dataMetrics; default NULL
#' @param geneList CHARACTER ARRAY | List of gene IDs to be drawn onto the 
#' scatterplot matrix of all data. If this parameter is defined, these will be 
#' the overlaid genes to be drawn. After that, dataMetrics, threshVar, and 
#' threshVal will be considered for overlaid genes. If both geneList and 
#' dataMetrics are NULL, then no genes will be overlaid onto the side-by-side 
#' boxplot; default NULL
#' @param threshVar CHARACTER STRING | Name of column in dataMetrics object
#' that is used to threshold significance; default "FDR"
#' @param threshVal INTEGER | Maximum value to threshold significance from 
#' threshVar object; default 0.05
#' @param lineSize INTEGER | Line width of parallel coordinate lines;
#' default 0.1
#' @param lineColor CHARACTER STRING | Color of parallel coordinate lines; 
#' default "orange"
#' @param vxAxis BOOLEAN [TRUE | FALSE] | Flip x-axis text labels to vertical 
#' orientation; default FALSE
#' @param outDir CHARACTER STRING | Output directory to save all plots; default 
#' tempdir()
#' @param saveFile BOOLEAN [TRUE | FALSE] | Save file to outDir; default TRUE
#' @param hover BOOLEAN [TRUE | FALSE] | Allow to hover over points to identify 
#' IDs; default FALSE
#' @importFrom dplyr filter select %>%
#' @importFrom GGally ggpairs wrap
#' @importFrom ggplot2 ggplot aes_string aes geom_point xlim ylim geom_hex 
#' coord_cartesian xlab ylab geom_ribbon geom_boxplot geom_line geom_abline 
#' theme_gray ggtitle
#' @importFrom grDevices jpeg dev.off
#' @importFrom hexbin hexbin hcell2xy
#' @importFrom htmlwidgets onRender
#' @importFrom plotly plotlyOutput ggplotly renderPlotly layout
#' @importFrom shiny verbatimTextOutput fluidPage reactive renderPrint shinyApp
#' @importFrom stats lm predict cutree dist hclust
#' @importFrom tidyr gather
#' @importFrom utils str
#' @importFrom utils combn
#' @importFrom stats setNames
#' @return List of n elements of parallel coordinate plots, where n is the
#' number of treatment pair combinations in the data object. The background of
#' each plot is a side-by-side boxplot of the full data object, and the
#' parallel coordinate lines on each plot are the subset of genes determined to
#' be superimposed through the dataMetrics or geneList parameter. If the
#' saveFile parameter has a value of TRUE, then each parallel coordinate plot
#' is saved to the location specified in the outDir parameter as a JPG file.
#' @export
#' @examples
#' # The first set of four examples use data and dataMetrics
#' # objects as input. The last set of four examples create the same plots now
#' # using the SummarizedExperiment (i.e. dataSE) object input.
#' 
#' # Example 1: Plot the side-by-side boxplots of the whole dataset without 
#' # overlaying any metrics data by keeping the dataMetrics parameter its
#' # default value of NULL.
#' 
#' data(soybean_ir_sub)
#' soybean_ir_sub[,-1] = log(soybean_ir_sub[,-1] + 1)
#' ret <- plotPCP(data = soybean_ir_sub, saveFile = FALSE)
#' ret[[1]]
#' 
#' # Example 2: Overlay genes with FDR < 1e-4 as orange parallel coordinate
#' # lines.
#' 
#' data(soybean_ir_sub_metrics)
#' ret <- plotPCP(data = soybean_ir_sub, dataMetrics = soybean_ir_sub_metrics, 
#'     threshVal = 1e-4, saveFile = FALSE)
#' ret[[1]]
#' 
#' # Example 3: Overlay the ten most significant genes (lowest FDR values) as 
#' # blue parallel coordinate lines.
#' 
#' geneList = soybean_ir_sub_metrics[["N_P"]][1:10,]$ID
#' ret <- plotPCP(data = soybean_ir_sub, geneList = geneList, lineSize = 0.3, 
#'     lineColor = "blue", saveFile = FALSE)
#' ret[[1]]
#' 
#' # Example 4: Repeat this same procedure, only now set the hover parameter to 
#' # TRUE to allow us to hover over blue parallel coordinate lines and
#' # determine their individual IDs.
#' 
#' ret <- plotPCP(data = soybean_ir_sub, geneList = geneList, lineSize = 0.3, 
#'     lineColor = "blue", saveFile = FALSE, hover = TRUE)
#' ret[[1]]
#' 
#' # Below are the same four examples, only now using the
#' # SummarizedExperiment (i.e. dataSE) object as input.
#' 
#' # Example 1: Plot the side-by-side boxplots of the whole dataset without 
#' # overlaying any metrics. We prevent overlaying metrics by setting the
#' # rowData() to NULL.
#' 
#' \dontrun{
#' data(se_soybean_ir_sub)
#' se_soybean_ir_sub[,-1] <- log(se_soybean_ir_sub[,-1]+1)
#' se_soybean_ir_sub_nm <- se_soybean_ir_sub
#' rowData(se_soybean_ir_sub_nm) <- NULL
#' ret <- plotPCP(dataSE = se_soybean_ir_sub_nm, saveFile = FALSE)
#' ret[[1]]
#' }
#' 
#' \dontrun{
#' # Example 2: Overlay genes with FDR < 1e-4 as orange parallel coordinate
#' # lines.
#' 
#' ret <- plotPCP(dataSE = se_soybean_ir_sub, threshVal = 1e-4,
#'     saveFile = FALSE)
#' ret[[1]]
#' }
#' 
#' # Example 3: Overlay the ten most significant genes (lowest FDR values) as 
#' # blue parallel coordinate lines.
#' 
#' \dontrun{
#' geneList <- as.data.frame(rowData(se_soybean_ir_sub)) %>%
#'     arrange(N_P.FDR) %>% filter(row_number() <= 10)
#' geneList <- geneList[,1]
#' ret <- plotPCP(dataSE = se_soybean_ir_sub, geneList = geneList,
#'     lineSize = 0.3, lineColor = "blue", saveFile = FALSE)
#' ret[[1]]
#' }
#' 
#' # Example 4: Repeat this same procedure, only now set the hover parameter to 
#' # TRUE to allow us to hover over blue parallel coordinate lines and
#' # determine their individual IDs.
#' 
#' \dontrun{
#' ret <- plotPCP(data = soybean_ir_sub, geneList = geneList, lineSize = 0.3, 
#'     lineColor = "blue", saveFile = FALSE, hover = TRUE)
#' ret[[1]]
#' }
#' 

plotPCP = function(data, dataMetrics = NULL, dataSE=NULL, geneList = NULL,
    threshVar = "FDR", threshVal = 0.05, lineSize = 0.1,
    lineColor = "orange", vxAxis=FALSE, outDir=tempdir(), saveFile=TRUE,
    hover=FALSE){

if (is.null(dataSE) && is.null(data)){
    helperTestHaveData()
}

if (!is.null(dataSE)){
    #Reverse engineer data
    data <- helperGetData(dataSE)
    
    if (ncol(rowData(dataSE))>0){
        #Reverse engineer dataMetrics
        reDataMetrics <- as.data.frame(rowData(dataSE))
        dataMetrics <- lapply(split.default(reDataMetrics[-1], 
        sub("\\..*", "",names(reDataMetrics[-1]))), function(x)
        cbind(reDataMetrics[1], setNames(x, sub(".*\\.", "", names(x)))))
        for (k in seq_len(length(dataMetrics))){
            colnames(dataMetrics[[k]])[1] = "ID"   
        }
    }
}
    
# Check that input parameters fit required formats
helperTestData(data)
if (is.null(geneList) && !is.null(dataMetrics)){
    helperTestDataMetrics(data, dataMetrics, threshVar)
}

key <- val <- ID <- Sample <- Count <- NULL
myPairs <- helperMakePairs(data)[["myPairs"]]
colGroups <- helperMakePairs(data)[["colGroups"]]
cols.combn <- combn(myPairs, 2, simplify = FALSE) ### ADDED
ifelse(!dir.exists(outDir), dir.create(outDir), FALSE)

ret <- lapply(cols.combn, function(x){
    group1 = x[1]
    group2 = x[2]
    datSel <- cbind(ID=data$ID, data[,which(colGroups %in%
    c(group1, group2))])
    datSel$ID <- as.character(datSel$ID)
    boxDat <- datSel %>% gather(key, val, -c(ID))
    colnames(boxDat) <- c("ID", "Sample", "Count")
    userOrder <- unique(boxDat$Sample)
    boxDat$Sample <- as.factor(boxDat$Sample)
    levels(boxDat$Sample) <- userOrder
    
    if (!is.null(geneList)){
        pcpDat <- datSel[which(datSel$ID %in% geneList),]
        pcpDat2 <- pcpDat %>% gather(key, val, -c(ID))
        colnames(pcpDat2) <- c("ID", "Sample", "Count")
        p <- ggplot(boxDat, aes_string(x = 'Sample', y = 'Count')) +
        geom_boxplot() + geom_line(data=pcpDat2, aes_string(x = 'Sample',
        y = 'Count', group = 'ID'), size = lineSize, color = lineColor)
        
        if (vxAxis == TRUE){
            p <- p + theme(axis.text.x = element_text(angle=90, hjust=1))
        }
        
        if (hover == TRUE){
            gP <- ggplotly(p)
            gP[["x"]][["data"]][[1]][["hoverinfo"]] <- "none"  
            oldText = gP[["x"]][["data"]][[2]][["text"]]
            newText = unlist(lapply(oldText, function(x)
            strsplit(trimws(strsplit(x, ":")[[1]][2]), "<br")[[1]][1]))
            gP[["x"]][["data"]][[2]][["text"]] <- newText
        }
    }
    else if(!is.null(dataMetrics)){
        rowDEG1 <- which(dataMetrics[[paste0(group1,"_",group2)]]
        [threshVar] < threshVal)
        rowDEG2 <- which(dataMetrics[[paste0(group2,"_",group1)]]
        [threshVar] < threshVal)
        rowDEG <- c(rowDEG1, rowDEG2)
        degID1 <- dataMetrics[[paste0(group1,"_",group2)]][rowDEG,]$ID
        degID2 <- dataMetrics[[paste0(group2,"_",group1)]][rowDEG,]$ID
        degID <- c(as.character(degID1), as.character(degID2))
        pcpDat <- datSel[which(datSel$ID %in% degID),]
        pcpDat2 <- pcpDat %>% gather(key, val, -c(ID))
        colnames(pcpDat2) <- c("ID", "Sample", "Count")
        p <- ggplot(boxDat, aes_string(x = 'Sample', y = 'Count')) +
        geom_boxplot() + geom_line(data=pcpDat2, aes_string(x = 'Sample',
        y = 'Count', group = 'ID'), size = lineSize, color = lineColor)
        
        if (vxAxis == TRUE){
            p <- p + theme(axis.text.x = element_text(angle=90, hjust=1))
        }
        
        if (hover == TRUE){
            gP <- ggplotly(p)
            gP[["x"]][["data"]][[1]][["hoverinfo"]] <- "none"  
            oldText = gP[["x"]][["data"]][[2]][["text"]]
            newText = unlist(lapply(oldText, function(x)
            strsplit(trimws(strsplit(x, ":")[[1]][2]), "<br")[[1]][1]))
            gP[["x"]][["data"]][[2]][["text"]] <- newText
        }
        
    }else{
        p <- ggplot(boxDat, aes_string(x = 'Sample', y = 'Count')) +
        geom_boxplot()
        
        if (vxAxis == TRUE){
            p <- p + theme(axis.text.x = element_text(angle=90, hjust=1))
        }
    }
    if (saveFile == TRUE){
        fileName = paste0(outDir, "/", group1, "_", group2, "_deg_pcp_",
        threshVal, ".jpg")
        jpeg(filename=fileName, height=900, width=900)
        print(p)
        dev.off()
    }
    if (hover ==FALSE){
        return(list(plot = p, name = paste0(group1, "_", group2)))
    }
    else{
        return(list(plot = gP, name = paste0(group1, "_", group2)))       
    }
})
retPlots <- lapply(ret, function(x) {x$plot})
retNames <- lapply(ret, function(x) {x$name})
names(retPlots) <- retNames
invisible(retPlots)
}
