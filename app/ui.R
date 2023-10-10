#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
# 
#    http://shiny.rstudio.com/
#

library(shiny)
library(shinythemes)
library(DT)

PAGE_TITLE <- "TailSpikeDB"
custom_db <- c("Tailspike proteins","Tailspike genes")

# Define UI for application that draws a histogram
shinyUI(fluidPage(
  theme = shinytheme("cerulean"),
  tags$head(
    tags$style(HTML("
                    #title {background: linear-gradient(to bottom, #396787 0%, #60AEE4 0%, #EDFBFF 100%);}
                    body {font-size:15px}"))
    ),
  
  titlePanel(
    windowTitle = PAGE_TITLE, 
    title =div(id="title",img(src = "image/tailspikeDB.png",height = 120,style = "margin:40px 100px;"))),
  
  fluidRow(
    
    column(10, offset = 1,
           navbarPage(
             position="static-top",
             title="",
             tabPanel("About tailspike proteins",includeHTML("about.html")),
             tabPanel(em("Escherichia coli/Shigella"),DT::dataTableOutput("Ec")),
             tabPanel(em("Klebsiella"),DT::dataTableOutput("K")),
             tabPanel(em("Salmonella"),DT::dataTableOutput("S")),
             tabPanel(em("Acinetobacter"),DT::dataTableOutput("A")),
             tabPanel(em("P. aeruginosa"),DT::dataTableOutput("Pa")),
             tabPanel("BLAST",
                      tagList(
                        tags$head(
                          tags$link(rel="stylesheet", type="text/css",href="css/style.css"),
                          tags$script(type="text/javascript", src = "js/busy.js")
                        )
                      ),
                      
                      #This block gives us all the inputs:
                      mainPanel(
                        headerPanel('Blast'),
                        textAreaInput('query', 'Input sequence:', value = "", placeholder = "", width = "1000", height="200px"),
                        selectInput("db", "Database:", choices=c(custom_db), width="200px"),
                        selectInput("program", "Program:", choices=c("blastp","blastn","blastx","tblastn","tblastx"), width="100px"),
                        numericInput("eval", "e-value:", value=1e-4,min =0,max=10, width="120px"),
                        actionButton("blast", "BLAST!")
                      ),
                      
                      #this snippet generates a progress indicator for long BLASTs
                      div(class = "busy",  
                          p("Calculation in progress.."), 
                          img(src="https://i.stack.imgur.com/8puiO.gif", height = 100, width = 100,align = "center")
                      ),
                      
                      #Basic results output
                      mainPanel(
                        h4("Results"),
                        DT::dataTableOutput("blastResults"),
                        p("Alignment:", tableOutput("clicked")),
                        verbatimTextOutput("alignment")
                      )
             )
           )
    ),
    #column(1 ,includeHTML("search.html"))
  ),
  
  fluidRow(includeHTML("footer.html"))
    )
  
)
