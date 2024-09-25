/*writing a workflow where it creates 
1) two output files 
2) converts the input from one output file to upper case 
*/ 

process NAMES {
    publishDir 'testing'  

    input: 
    val greeting
    val intro

    output:
    path 'first_file.txt', emit: hello 
    path 'name.txt', emit: convert

    shell:
    """
    echo '$greeting' > first_file.txt
    echo '$intro' > name.txt
    """    
}

process CONVERT_UP {
    publishDir 'testing'
    input:
    path input_txt

    output:
    path 'converted.txt'

    shell:
    """
    cat '$input_txt' | tr '[a-z]' '[A-Z]' > converted.txt
    """
}

workflow {
    ch_greeting = channel.of("Good evening everyone!")
    ch_intro = channel.of("My name is Aayushi")

    // Run the NAMES process
    NAMES(ch_greeting, ch_intro)

    // Pass the output of NAMES (name.txt) directly to CONVERT_UP
    CONVERT_UP(NAMES.out.convert)
}



