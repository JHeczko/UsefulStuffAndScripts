#!/usr/bin/perl

use warnings;
use strict;
use HTTP::Tiny;
use JSON qw(encode_json decode_json);
use Tie::IxHash;
use open qw(:std :utf8);
use Cwd qw(getcwd abs_path);
use File::Basename qw(dirname basename);
use File::Spec;

# ============= GLOBAL VARS =============
my %models_db = (
    1 => { name => "gemini-3-flash",        provider => "google" },
    2 => { name => "gemini-2.5-flash",      provider => "google" },
    3 => { name => "gemini-2.5-flash-lite", provider => "google" },
    4 => { name => "gemma-3-27b-it",           provider => "google" },
    5 => { name => "gemma-3-12b-it",           provider => "google" },
    6 => { name => "gemma-3-4b-it",           provider => "google" },
    7 => { name => "gemma-3-2b-it",           provider => "google" },
    8 => { name => "gemma-3-1b-it",           provider => "google" },
);

# ============================================
# HELPER FUNCTIONS
# ============================================
# read config file
sub read_config {
    my $config_path = "$ENV{HOME}/.aicode_conf/config.json";

    open my $fh, '<:encoding(UTF-8)', $config_path
        or die "Couldn't open config file: $!";

    local $/;
    my $json_text = <$fh>;
    close $fh;

    my $data = decode_json($json_text);

    tie my %ordered, 'Tie::IxHash';
    for my $key (keys %$data) {
        $ordered{$key} = $data->{$key};
    }

    return \%ordered;
}

# save config file
sub save_config {
    my ($config_data) = @_;
    my $config_path = "$ENV{HOME}/.aicode_conf/config.json";

    my $json = JSON->new->utf8->pretty;
    my $json_text = $json->encode($config_data);

    open my $fh, '>:encoding(UTF-8)', $config_path
        or die "Can't write config file: $!";
    print $fh $json_text;
    close $fh;
}

# interactive directory navigation
sub browse_files {
    my ($current_dir) = @_;
    
    clear_screen();
    # Otwieramy katalog
    opendir(my $dh, $current_dir) || die "Nie można otworzyc katalogu $current_dir: $!";
    
    # Sortujemy: najpierw katalogi, potem pliki. Pomijamy '.' (bieżący)
    my @items = sort { 
        -d "$current_dir/$a" <=> -d "$current_dir/$b" || $a cmp $b 
    } grep { $_ ne '.' } readdir($dh);
    closedir $dh;

    # Wyświetlanie listy
    print "\nDirectory: " . abs_path($current_dir) . "\n";
    print "0) [CANCEL]\n";
    
    my $index = 1;
    my %map; # Mapa numer -> nazwa pliku

    foreach my $item (@items) {
        my $full_path = "$current_dir/$item";
        my $type = -d $full_path ? "[DIR ]" : "[FILE]";
        
        # Oznaczenie katalogu nadrzędnego
        if ($item eq '..') {
            printf "%3d) [UP  ] .. (Go up)\n", $index;
        } else {
            printf "%3d) %s %s\n", $index, $type, $item;
        }
        
        $map{$index} = $item;
        $index++;
    }

    print "Choose number: ";
    my $choice = <STDIN>;
    chomp($choice);

    # Obsługa wyboru
    if ($choice eq '0') {
        return undef;
    }
    
    if (exists $map{$choice}) {
        my $selected = $map{$choice};
        my $full_path = "$current_dir/$selected";

        if (-d $full_path) {
            # REKURENCJA: Jeśli wybrano folder, wchodzimy głębiej
            return browse_files($full_path);
        } else {
            # Jeśli wybrano plik, zwracamy jego ścieżkę
            return $full_path;
        }
    } else {
        print "Invalid choice, try again.\n";
        return browse_files($current_dir);
    }
}

# read file content with character limit
sub read_file_content {
    my ($path) = @_;
    
    # Otwieramy plik
    open(my $fh, '<', $path) or die "Nie mozna otworzyc pliku $path: $!";
    
    # Slurping - wczytujemy calosc
    local $/; 
    my $content = <$fh>;
    close($fh);

    my $config = read_config();
    my $context_window = $config->{"context-window"} // -1;

    my $total_len = length($content);
    my @chunks = ();

    # Obsluga pustego pliku
    return ("") if ($total_len == 0);

    # LOGIKA PODZIALU:
    # Jesli context_window jest równe -1, nie dzielimy pliku (jeden batch)
    if ($context_window == -1) {
        push @chunks, $content;
    } 
    else {
        # Standardowe dzielenie na batche
        my $offset = 0;
        while ($offset < $total_len) {
            my $part = substr($content, $offset, $context_window);
            push @chunks, $part;
            $offset += $context_window;
        }
    }

    # Informacja diagnostyczna
    if (scalar(@chunks) > 1) {
        print "\n[INFO] File exceeds limit. Split into " . scalar(@chunks) . " batches.\n";
    } elsif ($context_window == -1) {
        print "\n[INFO] Loaded entire file (" . $total_len . " characters).\n";
    }

    return @chunks;
}

# ============================================
# PRINT FUNCTIONS
# ============================================
# clear screen
sub clear_screen{
    print "\033[2J";    #clear the screen
    print "\033[0;0H"; #jump to 0,0
}

# show main menu
sub show_menu {
    clear_screen();
    print "\n===============================\n";
    print "   GenAI Developer Assistant\n";
    print "===============================\n";
    print "1) Ask Gemini a question\n";
    print "2) Debug code\n";
    print "3) Refactor code\n";
    print "4) Comment code\n";
    print "5) Modify code\n";

    print "\n";
    print "8) Help\n";
    print "9) Settings\n";
    print "0) Exit\n";
    print "Choose an option: ";
}

# show settings menu
sub show_option_menu {
    clear_screen();
    print "\n----------------------------\n";
    print "   Setting menu\n";
    print "----------------------------\n";
    print "1) Check API KEY's\n";
    print "2) Set API KEY's\n";
    print "3) Select model\n";
    print "4) Show current model\n";
    print "5) Set context window length\n";

    
    print "\n";
    print "0) Exit\n";
    print "Choose an option: ";
}

# prompt to continue
sub type_to_continue{
    print "\nType in anything to continue...";
    my $contine = <STDIN>;
}

# ============================================
# API FUNCTIONS
# ============================================
# send prompt to Gemini API
sub gemini_prompt{
    my ($prompt, $model, $dummy) = @_;
    my $config = read_config();
    my $system_info = $config->{"sys-info-prompt"};

    if($dummy eq 1){
        return $prompt;
    }

    my $api_key;

    if(defined $ENV{'GEMINI_API_KEY'}){
        $api_key = $ENV{GEMINI_API_KEY};
    } else{
        $api_key = $config->{'gemini-api-key'};
        if ($api_key eq ""){
            print("No gemini API key defined, please go to ~/.aicode_conf/config.json or set it via settings\n");
            exit 1;
        };
    }

    my $ua = HTTP::Tiny->new(
        verify_SSL => 1,
    );

    my $payload;
    
    if ($model =~ /gemma/i) {
        $payload = {
            contents => [{
                parts => [{ text => "Instruction: $system_info\nQuestion: $prompt" }]
            }]
        };
    } else {
        $payload = {
            system_instruction => { parts => [{ text => $system_info }] },
            contents => [{ parts => [{ text => $prompt }] }]
        };
    }

    my $res = $ua->request(
        'POST',
        "https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent",
        {
            headers => {
                'x-goog-api-key' => $api_key,
                'Content-Type'  => 'application/json',
            },
            content => encode_json($payload),
        }
    );

    unless ($res->{success}) {

        my $msg = "Unknown error";

        eval {
            my $err = decode_json($res->{content});
            if (exists $err->{error}{message}) {
                $msg = $err->{error}{message};
            }
        };

        print "=======ERROR========\nGemini API error ($res->{status}): $msg\n";
        return "";
    }

    my $data = decode_json($res->{content});

    my $answer = $data->{candidates}[0]{content}{parts}[0]{text};

    return $answer;
}

# ============================================
# HANDLERS
# ============================================
# handle ask question
sub ask_question {
    my $config = read_config();
    
    print "Ask a question: ";
    my $prompt_text = <STDIN>;
    $prompt_text = $prompt_text . $config->{"ask-prompt"};
    my $model = $config->{model};
    my $response = gemini_prompt($prompt_text, $model, 0);
    print $response;
    print "\n=========END============";
    type_to_continue();
}

# handle debug file
sub debug_file {
    print "\n=== DEBUGGER MODE ===\n";
    print "Select file to analyze for bugs:\n";
    type_to_continue();
    
    my $config = read_config();
    my $prompt = $config->{"debug-prompt"};
    my $model = $config->{"model"};

    # loading a file
    my $file_path = browse_files(".");
    return unless $file_path;

    my @batches = read_file_content($file_path);
    
    my $batch_number = 1;
    my $total_batches = scalar(@batches);

    # Getting explonation of bug
    print "Please specify the bug: ";
    my $bug_explonation = <STDIN>;
    chomp($bug_explonation);

    foreach my $content_part (@batches) {
        print "\n--- Processing part $batch_number of $total_batches ---\n";

        $prompt = $prompt . "\n(This is part $batch_number/$total_batches of code)\n[BUG EXPLONATION]: $bug_explonation\n[CODE WITH BUG]:\n$content_part";

        my $response = gemini_prompt($prompt, $model, 0);
        print $response;

        $batch_number++;
    }

    type_to_continue();
}

# handle refactor file
sub refactor_file {
    print "\n=== REFACTOR MODE ===\n";
    print "Select file to refactor:\n";
    type_to_continue();

    my $config = read_config();
    my $prompt = $config->{"refactor-prompt"};
    my $model = $config->{"model"};

   # wybor pliku
    my $file_path = browse_files(".");
    return unless $file_path;

    my $dir  = dirname($file_path);
    my $base = basename($file_path);

    print "Give new file name (default: ${base}_refactored): ";
    my $new_input = <STDIN>;
    chomp $new_input;

    my $new_file_path;

    if ($new_input eq "") {
        # ENTER -> ten sam katalog
        $new_file_path = File::Spec->catfile(
            $dir,
            "${base}_refactored"
        );
    }  else {
        $new_file_path = File::Spec->catfile(
            $dir,
            $new_input
        );
    }

    my @batches = read_file_content($file_path);
    
    my $batch_number = 1;
    my $total_batches = scalar(@batches);

    open my $OUT, '>:encoding(UTF-8)', $new_file_path or die "Can't create output file $new_file_path: $!";

    foreach my $content_part (@batches) {
        print "\n--- Processing part $batch_number of $total_batches ---\n";
        
        $prompt = $prompt . "\n(This is part $batch_number/$total_batches of code)\n\n[CODE TO REFACTOR]:\n$content_part";

        my $response = gemini_prompt($prompt, $model, 0);

        unless (defined $response && $response ne "") {
            warn "[WARNING] Empty response for batch $batch_number\n";
            next;
        }

        print $OUT "\n";
        print $OUT $response;
        print $OUT "\n";

        $batch_number++;
    }
    
    print("Done, processed entire file and saved to $new_file_path");
    type_to_continue();
}

# handle comment file
sub comment_file{
    print "\n=== COMMENT MODE ===\n";
    print "Select file to add comments:\n";
    type_to_continue();

    my $config = read_config();
    my $prompt = $config->{"comment-prompt"};
    my $model = $config->{"model"};

   # wybor pliku
    my $file_path = browse_files(".");
    return unless $file_path;

    my $dir  = dirname($file_path);
    my $base = basename($file_path);

    print "Give new file name (default: ${base}_commented): ";
    my $new_input = <STDIN>;
    chomp $new_input;

    my $new_file_path;

    if ($new_input eq "") {
        # ENTER -> ten sam katalog
        $new_file_path = File::Spec->catfile(
            $dir,
            "${base}_commented"
        );
    }  else {
        $new_file_path = File::Spec->catfile(
            $dir,
            $new_input
        );
    }

    my @batches = read_file_content($file_path);
    
    my $batch_number = 1;
    my $total_batches = scalar(@batches);

    open my $OUT, '>:encoding(UTF-8)', $new_file_path or die "Can't create output file $new_file_path: $!";

    foreach my $content_part (@batches) {
        print "\n--- Processing part $batch_number of $total_batches ---\n";
        
        $prompt = $prompt . "\n(This is part $batch_number/$total_batches of code)\n[CODE TO COMMENT]:\n$content_part";

        my $response = gemini_prompt($prompt, $model, 0);

        unless (defined $response && $response ne "") {
            warn "[WARNING] Empty response for batch $batch_number\n";
            next;
        }

        print $OUT "\n";
        print $OUT $response;
        print $OUT "\n";

        $batch_number++;
    }
    
    print("Done, processed entire file and saved to $new_file_path");
    type_to_continue();
}

# handle modify file
sub modify_file{
    print "\n=== MODIFY MODE ===\n";
    print "Select file to modify:\n";
    type_to_continue();

    my $config = read_config();
    my $prompt = $config->{"modify-prompt"};
    my $model = $config->{"model"};

   # wybor pliku
    my $file_path = browse_files(".");
    return unless $file_path;

    my $dir  = dirname($file_path);
    my $base = basename($file_path);

    print "Give new file name (default: ${base}_modified): ";
    my $new_input = <STDIN>;
    chomp $new_input;

    my $new_file_path;

    if ($new_input eq "") {
        # ENTER -> ten sam katalog
        $new_file_path = File::Spec->catfile(
            $dir,
            "${base}_modified"
        );
    }  else {
        $new_file_path = File::Spec->catfile(
            $dir,
            $new_input
        );
    }

    # getting user instructions
    print "Please specify what to do with code: ";
    my $user_instructions = <STDIN>;
    chomp($user_instructions);

    my @batches = read_file_content($file_path);
    
    my $batch_number = 1;
    my $total_batches = scalar(@batches);

    open my $OUT, '>:encoding(UTF-8)', $new_file_path or die "Can't create output file $new_file_path: $!";

    foreach my $content_part (@batches) {
        print "\n--- Processing part $batch_number of $total_batches ---\n";
        
        $prompt = $prompt . "\n(This is part $batch_number/$total_batches of code)\n[INSTRUCTIONS]: $user_instructions\n[CODE TO MODIFY]:\n$content_part";

        my $response = gemini_prompt($prompt, $model, 0);

        unless (defined $response && $response ne "") {
            warn "[WARNING] Empty response for batch $batch_number\n";
            next;
        }

        print $OUT "\n";
        print $OUT $response;
        print $OUT "\n";

        $batch_number++;
    }
    
    print("Done, processed entire file and saved to $new_file_path");
    type_to_continue();
}

# ============================================
# SETTINGS HANDLERS
# ============================================
# show API keys
sub show_keys {
    my $config = read_config();
    my $gemini_api;
    my $openai_api;

    if(defined $ENV{GEMINI_API_KEY}){
        $gemini_api = $ENV{GEMINI_API_KEY};
    } else{
        $gemini_api = $config->{'gemini-api-key'};
    }

    if(defined $ENV{OPENAI_API_KEY}){
        $openai_api = $ENV{OPENAI_API_KEY};
    } else{
        $openai_api = $config->{'openai-api-key'};
    }
    print("Please remember to store them as ENVIRONMENT VARIABLES:\n\t-GEMINI API KEY: $gemini_api\n\t-OPENAI API KEY: $openai_api\n");  
    type_to_continue();
} 

# set API keys
sub set_keys {
    print "\n--- MANAGE API KEYS ---\n";
    print "1) Set Gemini API Key (Google)\n";
    print "2) Set OpenAI API Key\n\n";
    print "0) Exit\n";
    print "Choose option: ";

    my $option = <STDIN>;
    chomp($option);

    my $config = read_config();

    if ($option eq "1") {
        print "Enter key for Gemini: ";
        my $key = <STDIN>;
        chomp($key);
        
        if ($key ne "") {
            $config->{"gemini-api-key"} = $key;
            print "Gemini key has been saved.\n";
            type_to_continue();
        } else {
            return;
        }

    } elsif ($option eq "2") {
        print "Enter key for OpenAI: ";
        my $key = <STDIN>;
        chomp($key);

        if ($key ne "") {
            $config->{"openai-api-key"} = $key;
            print "OpenAI key has been saved.\n";
            type_to_continue();
        } else {
            return;
        }

    } else {
        return;
    }

    save_config($config);
}

# set model
sub set_model {
    print "=== AVAILABLE MODELS ===\n";
    
    foreach my $id (sort { $a <=> $b } keys %models_db) {
        my $m = $models_db{$id};
        printf("%d) %-25s [%s]\n", $id, $m->{name}, uc($m->{provider}));
    }
    
    print "\nChoose model number: ";
    my $choice = <STDIN>;
    chomp($choice);

    if (exists $models_db{$choice}) {
        my $selected = $models_db{$choice};
        
        print "Selected: $selected->{name} ($selected->{provider})\n";
        type_to_continue();
        if ($selected->{provider} eq "google") {
            my $type="google";
        } elsif ($selected->{provider} eq "openai") {
            my $type="google";
        }


        my $config = read_config();
        $config->{model} = $selected->{name};
        $config->{type} = $selected->{provider};
        save_config($config);

    } else {
        print "Invalid choice!\n";
        type_to_continue();
    }
}

# set context window length
sub set_context_window_length {
    my $config = read_config();
    
    my $current_val = $config->{"context-window"};

    print "\n--- SETTING CONTEXT WINDOW LENGTH ---";
    if($current_val == -1){
        print "\nCurrent length: no limit";
    }else{
        print "\nCurrent length: $current_val characters";
    }
    print "\nEnter new length (digits only): ";

    my $input = <STDIN>;
    chomp($input);

    if ($input eq "") {
        print "Cancelled. Kept old value.\n";
        type_to_continue();
        return;
    }

    if ($input =~ /^\d+$/ || $input == -1) {
        $config->{"context-window"} = int($input);
        save_config($config);
        print "Success! New window length is: $input characters.\n";
        type_to_continue();
    } else {
        print "Error: Entered value '$input' is not a valid number!\n";
        type_to_continue();
    }
}

# show current model
sub curr_model{
    my $config = read_config();
    print("====== [CURRENT MODEL] ======\nCurrent model is $config->{model}, from $config->{type}.\n");
    type_to_continue();
    show_option_menu();
}

# settings menu loop
sub settings_menu{
    my %actions_menu = (
    1 => \&show_keys,
    2 => \&set_keys,
    3 => \&set_model,
    4 => \&curr_model,
    5 => \&set_context_window_length,
    );

    my $option;
    
    show_option_menu();
    chomp($option = <STDIN>);
    
    while($option != 0){
        if (exists $actions_menu{$option}) {
            $actions_menu{$option}->();
        } else {
            print "Invalid option. Try again.\n";
            type_to_continue();
        }

        show_option_menu();
        chomp($option = <STDIN>);
    }
}

# ============================================
# HELP HANDLER
# ============================================
# show help
sub show_help{
    print <<'HELP';
GenAI Code Assistant Help
=========================

This is a command-line tool that integrates with Google's Gemini AI models to assist with coding tasks. It allows users to ask questions, debug code, refactor code, add comments, and modify code using AI-generated responses. The tool supports batching large files based on a configurable context window.

Main Features
-------------
- Ask a Question: Prompt Gemini with a custom question and receive a direct response.
- Debug Code: Analyze a selected file for bugs, optionally with user-specified bug details, and get explanations and fixes.
- Refactor Code: Refactor a selected file to improve structure and readability while preserving functionality, saving to a new file.
- Comment Code: Add comments to a selected file explaining functions and complex syntax, saving to a new file.
- Modify Code: Modify a selected file based on user instructions, saving to a new file.

Settings Menu
-------------
- Check API Keys: Display current API keys (prioritizing environment variables over config).
- Set API Keys: Update Gemini or OpenAI API keys in the config.
- Select Model: Choose from a list of available models (currently Google Gemini variants).
- Show Current Model: Display the currently selected model and provider.
- Set Context Window Length: Configure the maximum characters per batch for file processing (-1 disables batching, loading the whole file).

Configuration
-------------
The config file is located at ~/.aicode_conf/config.json. It stores API keys, selected model, prompts, and context window settings. API keys can also be set via environment variables (GEMINI_API_KEY or OPENAI_API_KEY).

The context window limits file reading to batches of the specified character length to manage large files. If set to -1, the entire file is loaded without batching.

Example Config File
-------------------
{
   "model" : "gemma-3-1b-it",
   "type" : "google",
   "gemini-api-key" : "YOUR_API_KEY",
   "openai-api-key" : "YOUR_API_KEY",
   "sys-info-prompt": "You are a professional programmer and coding expert. You write precise, technical answers. You strictly follow all instructions and constraints given by the user. You do not add unnecessary explanations or introductions.",
   "ask-prompt": "Answer directly and concisely. Do not add any introduction or summary. Do not use markdown or formatting symbols. The output must be plain, terminal-friendly text only.",
   "debug-prompt": "You will receive source code (either complete or split into parts). Your task is to identify bugs or incorrect behavior(sometimes user will specify the problem to solve, focus on it). For each issue: specify the exact line number, explain why it is wrong, and provide a corrected full line or code block. Be precise and technical. Do not add introductions. Do not use markdown. Output must be terminal-friendly plain text.",
   "refactor-prompt": "You will receive source code (either complete or split into parts). Refactor the code while preserving its exact behavior. Improve structure, readability, and eliminate code smells where possible. Do not change functionality. Do not add comments or explanations. Do not add any introduction. Do not use markdown or formatting symbols. The output must be code only, ready to paste directly into a file.",
   "comment-prompt":"You will receive source code (either complete or split into parts). Add comments inside a code, explainign what every function does. If there is complicated syntax, explain it too. Do not change the behavior of the code(do not refactor it, only add comments). Do not add any introduction. Do not use markdown or formatting symbols. The output must be code only, ready to paste directly into a file.",
   "modify-prompt": "You will receive source code (either complete or split into parts). Please modify the given code, following given instruction below. Do not add any introduction. Do not use markdown or formatting symbols. The output must be code only, ready to paste directly into a file.",
   "context-window" : -1
}

HELP
    type_to_continue();
}

# ============================================
# EXIT HANDLER
# ============================================
# exit program
sub exit_program {
    print "Goodbye!\n";
    exit 0;
}

# ============================================
# MAIN
# ============================================
# check for help argument
if (@ARGV == 1 && ($ARGV[0] eq '-h' || $ARGV[0] eq '--help')) {
    show_help();
    exit 0;
}

# main loop
my %actions = (
    1 => \&ask_question,
    2 => \&debug_file,
    3 => \&refactor_file,
    4 => \&comment_file,
    5 => \&modify_file,
    8 => \&show_help,
    9 => \&settings_menu,
    0 => \&exit_program,
);


while (1) {
    show_menu();
    chomp(my $choice = <STDIN>);
    if($choice eq ""){
        $choice = 0;
    }

    if (exists $actions{$choice}) {
        $actions{$choice}->();
    } else {
        print "Invalid option. Try again.\n";
        type_to_continue();
    }
}