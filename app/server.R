#
# This is the server logic of a Shiny web application. You can run the 
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#

require(XML)
library(plyr)
library(dplyr)
library(DT)
library(shiny)

txt2table<-function(infile){
  infile %>% read.table(header = T,sep="\t",check.names = F) %>%
    mutate(`Cluster ID`=paste("<a href=\"pages/", `Cluster ID`,".html\">",`Cluster ID`,"</a>",sep = "")) %>%
    DT::datatable(escape = FALSE,extensions = c('Responsive','Buttons'), 
                  options = list(
                    dom = 'Bfrtip',
                    buttons = c('copy', 'csv', 'excel', 'pdf', 'print'),
                    pageLength = 50
                    #deferRender = TRUE,
                    #scrollY = 400,
                    #scrollX = TRUE,
                    #scroller = TRUE,
                    #autoWidth = TRUE,
                    #columnDefs = list(list(width = '10%', targets = list(2,3,5,6)))
		    #columnDefs = list(list(targets = "_all",render = JS("function(data, type, row, meta) {","return type === 'display' && data.length > 20 ?","'<span title=\"' + data + '\">' + data.substr(0, 20) + '...</span>' : data;","}")))
                  ),
                  rownames=F
    )
}

# Define server logic
shinyServer(function(input, output, session) {
  
  custom_db <- c("Tailspike proteins","Tailspike genes")
  custom_db_path <- c("data/tailspike.fa","data/tailspike_nt.fa")
  
  output$Ec<-DT::renderDataTable(txt2table("data/Escherichia_coli_Shigella.txt"))
  output$K<-DT::renderDataTable(txt2table("data/Klebsiella.txt"))
  output$S<-DT::renderDataTable(txt2table("data/Salmonella.txt"))
  output$A<-DT::renderDataTable(txt2table("data/Acinetobacter.txt"))
  output$Pa<-DT::renderDataTable(txt2table("data/Pseudomonas_aeruginosa.txt"))
  
  blastresults <- eventReactive(input$blast, {
    
    #gather input and set up temp file
    query <- input$query
    tmp <- tempfile(fileext = ".fa")
    
    #if else chooses the right database
    if (input$db == custom_db[1]){
      db <- custom_db_path[1]
    } else if (input$db == custom_db[2]){
      db <- custom_db_path[2]
    }
    
    #this makes sure the fasta is formatted properly
    if (startsWith(query, ">")){
      writeLines(query, tmp)
    } else {
      writeLines(paste0(">Query\n",query), tmp)
    }
    
    #calls the blast
    data <- system(paste0(input$program," -query ",tmp," -db ",db," -evalue ",input$eval," -outfmt 5 -max_hsps 1 -max_target_seqs 10 "), intern = T)
    xmlParse(data)
  }, ignoreNULL= T)
  
  #Now to parse the results...
  parsedresults <- reactive({
    if (is.null(blastresults())){}
    else {
      xmltop = xmlRoot(blastresults())
      
      #the first chunk is for multi-fastas
      results <- xpathApply(blastresults(), '//Iteration',function(row){
        query_ID <- getNodeSet(row, 'Iteration_query-def') %>% sapply(., xmlValue)
        hit_IDs <- getNodeSet(row, 'Iteration_hits//Hit//Hit_def') %>% sapply(., xmlValue)
        hit_length <- getNodeSet(row, 'Iteration_hits//Hit//Hit_len') %>% sapply(., xmlValue)
        Hsp_query_from<-getNodeSet(row, 'Iteration_hits//Hit//Hit_hsps//Hsp//Hsp_query-from') %>% sapply(., xmlValue)
        Hsp_query_to<-getNodeSet(row, 'Iteration_hits//Hit//Hit_hsps//Hsp//Hsp_query-to') %>% sapply(., xmlValue)
        Hsp_hit_from<-getNodeSet(row, 'Iteration_hits//Hit//Hit_hsps//Hsp//Hsp_hit-from') %>% sapply(., xmlValue)
        Hsp_hit_to<-getNodeSet(row, 'Iteration_hits//Hit//Hit_hsps//Hsp//Hsp_hit-to') %>% sapply(., xmlValue)
        bitscore <- getNodeSet(row, 'Iteration_hits//Hit//Hit_hsps//Hsp//Hsp_bit-score') %>% sapply(., xmlValue)
        eval <- getNodeSet(row, 'Iteration_hits//Hit//Hit_hsps//Hsp//Hsp_evalue') %>% sapply(., xmlValue)
        #cbind(query_ID,hit_IDs,hit_length,bitscore,eval)
        cbind(query_ID,hit_IDs,hit_length,Hsp_query_from,Hsp_query_to,Hsp_hit_from,Hsp_hit_to,bitscore,eval)
      })
      #this ensures that NAs get added for no hits
      results <-  rbind.fill(lapply(results,function(y){as.data.frame((y),stringsAsFactors=FALSE)}))
    }
  })
  
  #makes the datatable
  output$blastResults <- renderDataTable({
    if (is.null(blastresults())){
    } else {
      parsedresults()
    }
  }, selection = 'single',
  extensions = c('Buttons'), 
  options = list(
    dom = 'Bfrtip',
    buttons = c('copy', 'csv', 'excel', 'pdf', 'print'),
    pageLength = 10
  )
  )
  
  #this chunk gets the alignemnt information from a clicked row
  output$clicked <- renderTable({
    if(is.null(input$blastResults_rows_selected)){}
    else{
      xmltop = xmlRoot(blastresults())
      clicked = input$blastResults_rows_selected
      
#      tableout<- data.frame(parsedresults()[clicked,]) %>% mutate(hit_IDs=paste(hit_IDs,"(<a href=\"pages/",hit_IDs,".html\">",hit_IDs,"</a>)",sep = ""))
      tab <- data.frame(parsedresults()[clicked,])
      tab <- cbind(tab, data.frame(do.call("rbind", strsplit(as.character(tab$hit_IDs), "|", fixed = TRUE))))
      tableout <- tab %>% mutate(hit_IDs=paste(X1, "|<a href=\"pages/", X2, ".html\">", X2, "</a>", sep="")) %>% select(-X1,-X2)
      
      tableout <- t(tableout)
      names(tableout) <- c("")
      rownames(tableout) <- c("Query ID","Hit ID", "Length", "query_from","query_to","hit_from","hit_to","Bit Score", "e-value")
      colnames(tableout) <- NULL
      data.frame(tableout)
    }
  },rownames =T,colnames =F,sanitize.text.function = function(x) x)
  
  #this chunk makes the alignments for clicked rows
  output$alignment <- renderText({
    if(is.null(input$blastResults_rows_selected)){}
    else{
      xmltop = xmlRoot(blastresults())
      
      clicked = input$blastResults_rows_selected
      
      #loop over the xml to get the alignments
      align <- xpathApply(blastresults(), '//Iteration',function(row){
        top <- getNodeSet(row, 'Iteration_hits//Hit//Hit_hsps//Hsp//Hsp_qseq') %>% sapply(., xmlValue)
        mid <- getNodeSet(row, 'Iteration_hits//Hit//Hit_hsps//Hsp//Hsp_midline') %>% sapply(., xmlValue)
        bottom <- getNodeSet(row, 'Iteration_hits//Hit//Hit_hsps//Hsp//Hsp_hseq') %>% sapply(., xmlValue)
        rbind(top,mid,bottom)  
      })
      
      #split the alignments every 80 carachters to get a "wrapped look"
      alignx <- do.call("cbind", align)
      splits <- strsplit(gsub("(.{80})", "\\1,", alignx[1:3,clicked]),",") 
      
      #paste them together with returns '\n' on the breaks
      split_out <- lapply(1:length(splits[[1]]),function(i){
        rbind("\n",paste0("Q- ",splits[[1]][i],"\n"),paste0("M- ",splits[[2]][i],"\n"),paste0("H- ",splits[[3]][i],"\n"))
      })
      unlist(split_out)
    }
  })
  
})

