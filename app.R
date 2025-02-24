library(shiny)
library(yaml)
library(shinyjs)
library(bslib)
library(reticulate)
library(jsonlite)

ui <- fluidPage(
  theme = bs_theme(
    version = 5, # Use Bootstrap 5
    bootswatch = "litera"
  ),
  
  tags$head(
    # Updated CSS to fix sidebar behavior
    tags$style(HTML("
    #sidebar-panel {
      min-width: 300px; /* Prevent scrunching of the sidebar */
    }

    /* Mobile: Keep sidebar at the top and remove fixed positioning */
    @media (max-width: 767px) {
      #sidebar-panel {
        position: static !important; /* Sidebar stays in document flow */
        min-width: 100% !important; /* Full width */
        margin-bottom: 20px; /* Space below sidebar */
      }
    }

    /* Tablet & larger: Use sticky positioning for smooth scrolling */
    @media (min-width: 768px) {
      #sidebar-panel {
        position: sticky;
        top: 20px; /* Keeps it visible without overlap */
        min-width: 300px !important;
        z-index: 9999;
      }

      /* Medium screens */
      .col-md-4 {
        flex: 0 0 33.3333%; /* Ensuring the column is 33% on medium screens */
      }

      /* Large screens */
      .col-lg-3 {
        flex: 0 0 25%; /* Ensuring the column is 25% on large screens */
      }
    }
  ")),
    
    # Remove JavaScript-based scrolling logic (not needed anymore)
    tags$script(HTML("
    $(document).ready(function() {
      $('#sidebar-panel').css('position', 'sticky');
      $('#sidebar-panel').css('top', '20px');
    });
  "))
  ),
  
  
  useShinyjs(),  # Enable shinyjs
  
  sidebarLayout(
    sidebarPanel(
      id = "sidebar-panel", # Make sure the sidebar has this id
      img(src = "omegasync_logo.png", 
          style = "width: 100%; height: auto; max-height: 150px; object-fit: contain;"),
      textInput("name", label = h3("Name"), value = "First Last"),
      textInput("email", label = h3("Email"), value = "Enter email address"),
      textInput("instance", label = h3("Instance Name"), value = "Name of instance"),
      textInput("source", label = h3("Source/Donator:")),
      
      fileInput("file", "Upload txt File"),
      
      # Wrap numeric inputs in a hidden div
      div(
        id = "dynamic_inputs",
        style = "display: none;",
        uiOutput("variable_selector")
      ),
      
      actionButton("submit", "Submit", disabled = TRUE, class = "btn btn-success"),
      textOutput("status")
    ),
    
    mainPanel(
      tags$head(
        tags$script(src = "https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js")
      ),
      HTML("
    <div>
      <br><br>
      <p>test</p>
      <h2>Introduction</h2>
      <p>OmegaSync provides a service to compute the maximum cut (Max-Cut) of a graph.</p>
      <p>The Max-Cut can be defined as:</p>
      <p>\\[ S^* = \\arg \\min_{S \\in [1, -1]^N} H(S) \\]</p>
      <p>Where:</p>
      <ul>
        <li>\\( S^* \\in \\mathbb{R}^N \\) is the ground state of \\( H(S) \\)</li>
        <li>\\( H(S) = -\\frac{1}{2} S^T J S \\)</li>
        <li>\\( S \\) is a spin vector, defined as \\( S = [s_1, s_2, \\dots, s_n] \\)</li>
        <li>\\( s_i \\in \\{1, -1\\} \\) represents the assignment of vertex \\( i \\) to one of the two sets (\\( S_1, S_2 \\)):
          <ul>
            <li>\\( s_i = 1 \\) if \\( i \\in S_1 \\)</li>
            <li>\\( s_i = -1 \\) if \\( i \\in S_2 \\)</li>
          </ul>
        </li>
        <li>\\( J \\) denotes the presence of an edge</li>
      </ul>

      <img src='fig1.png' alt='Introduction diagram' style='display:block; margin:auto; width:80%;' />

      <h2>OmegaSync integrates two computational methods</h2>
      
      <h3>1. Population Annealing Monte Carlo (PAMC)</h3>
      <p>
        Population Annealing is a Markov Chain Monte Carlo variant that operates by simulating many independent solutions (or \"replicas\") in parallel, iterating through multiple stages to refine and converge toward the optimal solution [1].
      </p>
      
      <h3>2. Energy Minimization Inspired by Coupled Oscillators</h3>
      <p>
        A physics-inspired computational approach that maps optimization problems onto the dynamics of coupled oscillators, allowing for efficient exploration of the solution space. The continuous-time dynamics of the coupled oscillator system can be expressed mathematically as:
      </p>
      <p>\\[
        \\frac{d \\phi_i}{dt} = -A_c \\sum_{j=1, j \\neq i}^N J_{ij} \\sin(\\phi_i(t) - \\phi_j(t)) - A_s \\sin(2\\phi_i(t))
      \\]</p>
      
      <h5>Parameters that Govern Oscillator Behavior</h5>
      <p>The solver requires specific parameters as input to govern the behavior of the oscillators in the system. These parameters set the dynamics of the system and influence how the solver explores the solution space. Below is a description of the key parameters:</p>
      <ul>
        <li><b><i>A<sub>s</sub></i>:</b> Sets the strength of coupling from the sub-harmonic injection locking signal.</li>
        <li><b><i>A<sub>c</sub></i>:</b> Sets the strength of coupling between oscillators.</li>
        <li><b><i>tstop</i> (Time Stop):</b> Determines the total simulation time for the oscillator dynamics. Longer ‘<i>tstop</i>’ values allow the solver to perform more iterations, providing greater opportunities to refine solutions but at the cost of increased computation time.</li>
      </ul>
      
      <h5>Resource Parameters</h5>
      <p>In addition to the oscillator dynamics, the solver requires parameters that define the computational resources and the granularity of the solution search.</p>
      <ul>
        <li><b>Replica:</b>
          <ul>
            <li><b>Definition:</b> Specifies the number of independent solver runs for the given problem.</li>
            <li><b>Role:</b> Each replica starts from a different initial configuration, ensuring broader exploration of the solution space. More trials increase the probability of finding the global optimum. Note that the increase in the number of replicas will increase the computational resources used along with the time-to-compute. For this version, we set it by default to 512.</li>
          </ul>
        </li>
      </ul>

      <img src='fig2.png' alt='Introduction diagram' style='display:block; margin:auto; width:80%;' />

      <h2>Input File Format</h2>
      <h5>Example Format (what the .txt file should include):</h5>
      <pre>
4 4 5
2 1 1
3 1 1
3 2 1
4 2 1
4 3 1
      </pre>

      <h5>Matrix Size and Number of Entries</h5>
      <p>
        The first line specifies the matrix dimensions and the number of non-zero entries: 
        Example: <code>4 4 5</code> means the matrix has 4 rows and 4 columns with 5 non-zero entries on the upper half matrix. 
        Make sure the matrix is symmetrical in nature.
      </p>

      <h5>Data Lines</h5>
      <p>
        Each subsequent line represents a non-zero entry in the format: <code>i j value</code>, 
        where <code>i</code> is a row number, <code>j</code> is a column number, and <code>value</code> is a non-zero edge weight.
        
        The equivalent matrix corresponding to the example is shown below: 
      </p>

      <img src='fig3.png' alt='Introduction diagram' style='display:block; margin:auto; width:80%;' />

      <p>
        Please refer to <a href='https://networkrepository.com/mtx-matrix-market-format.html' target='_blank'>
          MTX Matrix Market Format
        </a> for further information.
      </p>

      <div style='text-align: center; margin-top: 20px;'>
        <a class='btn btn-primary' href='sample_txt.txt' download>Download Example txt File</a>
      </div>

      <h2>Instructions for Uploading the Input File</h2>
      <ul>
        <li><b>Upload a Valid .txt File:</b> Make sure the input file is described in an edge list format as mentioned above.</li>
        <li><b>Graph Validation Process:</b>
          <ul>
            <li>Matrix Size: The first line of the file must specify the number of nodes and edges accurately. Any mismatch between the declared values and actual data will result in an error.</li>
            <li>Non-Zero Weights: Edges with zero weight are invalid and will trigger a validation error.</li>
            <li>Duplicate Edges: Edges between the same pair of nodes with identical weights should appear only once in the file.</li>
            <li>Undirected Graph Format: For undirected graphs, an edge like (1, 2) should not also appear as (2, 1).</li>
            <li>Self-Loops: Edges where both endpoints are the same (e.g., <code>1 1 3</code>) are generally invalid unless specifically required.</li>
            <li>Valid Data Types: All node identifiers and edge weights must be numeric.</li>
          </ul>
        </li>
        <li><b>Submission and Job Queueing:</b> Once your file passes the validation check, you can proceed to submit your task. Upon submission, your job will be queued for processing.</li>
        <li><b>Email Notification:</b> Once the job is completed, you will receive an email with the output and solution.</li>
      </ul>
    
    <footer style='margin-top: 20px; font-size: 12px; text-align: left; background-color: yellow; line-height: 1;'>
      <p>Disclaimer 1: The data is stored temporarily for computation and emailing results, then securely deleted to ensure privacy.</p>
      <p>Disclaimer 2: The designers of OmegaSync take no responsibility for the accuracy of the solution.</p>
    </footer>
    
      <h2>References</h2>
      <p>
        [1] Wang, W., Machta, J., & Katzgraber, H. G. (2015). Population annealing: Theory and application in spin glasses. 
        <i>Physical Review E</i>, 92(6), 063307.
      </p>
    </div>
  "
      )
    )
  )
)

server <- function(input, output, session) {
  
  useShinyjs()
  
  
  
  # Reactive to track submission and file state
  submission_done <- reactiveVal(FALSE)
  current_file <- reactiveVal(NULL)
  validation_passed <- reactiveVal(FALSE)  # Initialize validation_passed
  
  # Function to validate all required inputs
  validateInputs <- reactive({
    all(
      !is.null(input$name) && input$name != "" && input$name != "First Last",
      !is.null(input$email) && input$email != "" && input$email != "Enter email address",
      !is.null(input$instance) && input$instance != "" && input$instance != "Name of instance",
      !is.null(input$file) 
    )
  })
  
  # Enable or disable the submit button dynamically
  observe({
    if (validateInputs()) {
      enable("submit")
    } else {
      disable("submit")
    }
  })
  
  # JavaScript for resetting placeholders on focus/blur
  runjs("$('#name').focus(function() { if ($(this).val() == 'First Last') $(this).val(''); });
         $('#name').blur(function() { if ($(this).val() == '') $(this).val('First Last'); });
         $('#email').focus(function() { if ($(this).val() == 'Enter email address') $(this).val(''); });
         $('#email').blur(function() { if ($(this).val() == '') $(this).val('Enter email address'); });
         $('#instance').focus(function() { if ($(this).val() == 'Name of instance') $(this).val(''); });
         $('#instance').blur(function() { if ($(this).val() == '') $(this).val('Name of instance'); });")
  
  # Monitor file input and update reactive state
  observeEvent(input$file, {
    if (!is.null(input$file)) {
      shinyjs::show("dynamic_inputs")
      current_file(input$file)  # Update the current file state
      submission_done(FALSE)    # Reset submission state for a new file
      
      # **Load and execute Python script ONLY after file is uploaded**
      tryCatch({
        uploaded_file <- input$file$datapath  # The file path on the server
        python_script <- "/srv/shiny-server/input_file_to_mtx.py"
        command <- paste("/usr/bin/python3.10", python_script, uploaded_file)
        
        # Call the Python function after file is uploaded
        json_data <- system(command, intern = TRUE)
        
        parsed_data <- fromJSON(json_data, simplifyVector = FALSE)
        
        # Ensure the first element remains a string and subsequent elements are numeric
        parsed_data <- lapply(seq_along(parsed_data), function(i) {
          if (i == 1) {
            return(parsed_data[[i]])  # Keep the first element (string)
          } else {
            return(as.numeric(parsed_data[[i]]))  # Convert the rest to numeric
          }
        })
        
        
        # Check the result
        message=parsed_data[1]
        Ac=parsed_data[2]
        As=parsed_data[3]
        
        
        # Check for validation based on Python script output
        validation_passed_value <- any(grepl("The .mtx file passed all validation checks.", message))
        validation_passed(validation_passed_value)  # Update validation_passed
        
        # If validation passed, show the success message and render numeric inputs
        if (validation_passed_value) {
          output$variable_selector <- renderUI({
            req(input$file)  # Ensure the file input is available
            
            tagList(
              #numericInput("Ac", label = HTML("<i>Ac</i>"), value = Ac, min = 8.0, max = 22.0, step = 1.0),
              #numericInput("As", label = HTML("<i>As</i>"), value = As, min = 5.0, max = 12.0, step = 1.0)
            )
          })
          
          # Show the result in a modal with scrollable content
          result_message <- paste(input$file$name, "has been processed.", "<br><br>", 
                                  paste(message, collapse = "<br>"))
          
          showModal(modalDialog(
            title = "Python Script Output",
            HTML(result_message),  # Render the message with <br> tags properly
            style = "max-height: 400px; overflow-y: auto; white-space: normal; word-wrap: break-word; word-break: break-word; overflow-x: hidden; display: block; padding: 10px; background-color: #f7f7f7;",
            easyClose = TRUE,
            footer = modalButton("Close")
          ))
          
        } else {
          # If validation fails, show the error modal
          showModal(modalDialog(
            title = "Validation Failed",
            HTML(paste("The .mtx file did not pass validation. Please check the file and try again.<br><br>", 
                       paste(message, collapse = "<br>"))),
            easyClose = TRUE,
            footer = modalButton("Close")
          ))
          
          # Reset the file input and hide the dynamic inputs
          reset("file")
          shinyjs::hide("dynamic_inputs")
          current_file(NULL)
          submission_done(TRUE)  # Keep submission state as "done"
        }
        
      }, error = function(e) {
        # Handle Python execution errors
        showModal(modalDialog(
          title = "Error",
          paste("Failed to execute Python script:", e$message),
          easyClose = TRUE,
          footer = modalButton("Close")
        ))
      })
      
    } else {
      shinyjs::hide("dynamic_inputs")
      current_file(NULL)        # Clear the file state
    }
  })
  
  # Email format validation
  validate_email_format <- function(email) {
    grepl("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", email)
  }
  
  # Show inputs upon file upload
  observeEvent(input$file, {
    if (!is.null(input$file) && validation_passed()) {
      shinyjs::show("dynamic_inputs")
    } else {
      shinyjs::hide("dynamic_inputs")
    }
  })
  
  # Handle the submit button click
  observeEvent(input$submit, {
    disable("submit")  # Disable the button immediately to avoid duplicate submissions
    shinyjs::hide("dynamic_inputs")  # Hide the dynamic inputs
    
    # Validate email format
    if (!validate_email_format(input$email)) {
      showModal(modalDialog(
        title = "Error",
        "The email address provided is not in a valid format. Please correct it and try again.",
        easyClose = TRUE,
        footer = modalButton("Close")
      ))
      
      # Reset the file input after invalid email
      reset("file")  # Reset the file input
      current_file(NULL)  # Clear the current file state
      return()
    }
    
    # Validate that a file is available
    if (is.null(current_file())) {
      showModal(modalDialog(
        title = "Error",
        "No file uploaded. Please upload a valid file before submitting.",
        easyClose = TRUE,
        footer = modalButton("Close")
      ))
      return()
    }
    
    # Create output directory and generate file name
    current_date <- gsub("[-: ]", "", format(Sys.time(), "%Y-%m-%d %H:%M:%S"))
    safe_name <- gsub("[^A-Za-z0-9]", "_", input$name)
    safe_instance <- gsub("[^A-Za-z0-9]", "_", input$instance)
    file_name <- paste0(safe_name, "_", safe_instance, "_", current_date, ".yml")
    output_dir <- "/srv/shiny-server/yaml_files"
    if (!dir.exists(output_dir)) dir.create(output_dir)
    file_path <- file.path(output_dir, file_name)
    
    # Create YAML content
    yaml_content <- list(
      user_info = list(
        name = input$name,
        email = input$email,
        instance_name = input$instance,
        source = input$source,
        date_time = as.character(current_date)
      ),
      data = read.csv2(current_file()$datapath, header = FALSE),
      slurm_params = list(
        time = "72:00:00",
        nodes = as.integer(16),
        memory = "512GB",
        partition = "parallel",
        account = "account",
        ntaskpernode = as.integer(32)
      ),
      additional_params = list(
        Ac = as.numeric(input$Ac),
        As = as.numeric(input$As),
        trial = as.integer(512)
      )
    )
    
    # Attempt to write YAML
    tryCatch({
      write_yaml(yaml_content, file_path)
      
      showModal(modalDialog(
        title = "Job Submitted",
        paste("Job submitted successfully! Results will be sent to", input$email),
        easyClose = TRUE,
        footer = modalButton("Close")
      ))
      
      # Reset inputs and submission state
      updateTextInput(session, "name", value = "First Last")
      updateTextInput(session, "email", value = "Enter email address")
      updateTextInput(session, "instance", value = "Name of instance")
      updateTextInput(session, "source", value = "")
      reset("file")  # Visually reset the file input
      current_file(NULL)  # Clear the file state
      submission_done(TRUE)  # Mark submission as done
    }, error = function(e) {
      showModal(modalDialog(
        title = "Error",
        paste("Failed to submit the job:", e$message),
        easyClose = TRUE,
        footer = modalButton("Close")
      ))
    })
  })
}

shinyApp(ui, server)

