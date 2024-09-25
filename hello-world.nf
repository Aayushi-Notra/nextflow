/* 
*Use echo to print hello world as standard output
*/

//add a defualt value for parameter
params.greeting = "Hello World"
params.outdir = 'results'

process SAYHELLO {
    publishDir params.outdir

    input:
    val greeting

    output:
    path "${greeting}.txt"

    script:
    """
    echo '$greeting' > ${greeting}.txt
    """
}

process CONVERT_UPPER { 
    publishDir params.outdir

    input: 
    path input_file

    output:
    path "modified_${input_file}"

    script: 
    """
    cat $input_file | tr '[a-z]' '[A-Z]' > modified_${input_file}
    """
}

// This is my comment 
workflow {

    //Creating a channel 
    ch_greeting = channel.of(params.greeting)
    ch_greeting.view() 
    //getting input from the previous step and saving into a new file  
    //Emit a greeting 
    SAYHELLO(ch_greeting)
    CONVERT_UPPER(SAYHELLO.out)
}


