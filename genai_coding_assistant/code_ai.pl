#!/usr/bin/perl

use warnings;
use strict;
use HTTP::Tiny;
use JSON qw(encode_json decode_json);
use open qw(:std :utf8);

# ============= GLOBAL VARS =============
# Główna baza modeli z podziałem na dostawców
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

# ============= PRINT's =============
sub clear_screen{
    print "\033[2J";    #clear the screen
    print "\033[0;0H"; #jump to 0,0
}

sub show_menu {
    clear_screen();
    print "\n===============================\n";
    print "   GenAI Developer Assistant\n";
    print "===============================\n";
    print "1) Ask Gemini a question\n";
    print "2) Analyze source code file\n";
    print "3) Analyze project directory\n";

    print "\n";
    print "9) Settings\n";
    print "0) Exit\n";
    print "Choose an option: ";
};

sub show_option_menu {
    clear_screen();
    print "\n----------------------------\n";
    print "   Setting menu\n";
    print "----------------------------\n";
    print "1) Check API KEY's\n";
    print "2) Set API KEY's\n";
    print "3) Select model\n";
    print "4) Show current model\n";

    
    print "\n";
    print "0) Exit\n";
    print "Choose an option: ";
}

sub type_to_continue{
    print "\nType in anything to continue...";
    my $contine = <STDIN>;
}

# ============= API's =============
sub gemini_prompt {
    my ($prompt, $model,$dummy) = @_;
    my $system_info = "You are a profesional programmer and coding expert.";

    if($dummy eq 1){
        return $prompt;
    }

    my $api_key = $ENV{GEMINI_API_KEY}
        or die "GEMINI_API_KEY not set\n";

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

# ============= ASK QUESTION HANDLER =============
sub ask_question {
    print "Ask a question: ";
    my $prompt_text = <STDIN>;
    my $prompt_text = $prompt_text . "\n(NOTE: Please make the answear terminal friendly(cuz answear will be shown in terminal, so no .md format). And also please no intro, go to the answear immediently.)";
    my $config = read_config();
    my $model = $config->{model};
    my $response = gemini_prompt($prompt_text, $model, 0);
    print $response;
    print "\n=========END============";
    type_to_continue();
}

# ============= SOURCE FILE ANALIZER HANDLER =============
sub analyze_file{
    
}

sub analyze_directory{

}

# ============= SETTING HANDLER =============
sub read_config (){
    my $config_path = "./aicode_conf/config.json";

    my $FILE;
    open($FILE, '<', $config_path) or die "Couldnt open the config file";

    my $file_context = "";
    while(my $line = <$FILE>){
        $file_context = $file_context . $line;
    }

    return decode_json($file_context);
}

sub save_config {
    my ($config_data) = @_;
    my $config_path = "./aicode_conf/config.json";

    my $json_text = JSON->new->pretty->encode($config_data);

    open(my $FILE, '>', $config_path) or die "Nie można otworzyć pliku do zapisu: $!";
    print $FILE $json_text;
    close($FILE);
}

sub show_keys {
    my $gemini_api = $ENV{GEMINI_API_KEY} or "";    
    my $openai_api = $ENV{OPENAI_API_KEY} or "";
    print("Please remember to store them as ENVIRONMENT VARIABLES:\n\t-GEMINI API KEY: $gemini_api\n\t-OPENAI API KEY: $openai_api\n");  
    type_to_continue();
} 

sub set_keys {
    my $key = <STDIN>;
    chomp($key);

    my $config = read_config();
    $config->{"gemini-api-key"} = $key;
    save_config($config);
}

sub set_model {
    print "=== DOSTEPNE MODELE ===\n";
    
    foreach my $id (sort { $a <=> $b } keys %models_db) {
        my $m = $models_db{$id};
        printf("%d) %-25s [%s]\n", $id, $m->{name}, uc($m->{provider}));
    }
    
    print "\nWybierz numer modelu: ";
    my $choice = <STDIN>;
    chomp($choice);

    if (exists $models_db{$choice}) {
        my $selected = $models_db{$choice};
        
        print "Wybrano: $selected->{name} ($selected->{provider})\n";
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
        print "Błędny wybór!\n";
        type_to_continue();
    }
}

sub curr_model{
    my $config = read_config();
    print("====== [CURRENT MODEL] ======\nCurrent model is $config->{model}, from $config->{type}.\n");
    type_to_continue();
    show_option_menu();
}

sub settings_menu{
    my %actions_menu = (
    1 => \&show_keys,
    2 => \&set_keys,
    3 => \&set_model,
    4 => \&curr_model,
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

# ============= EXITING HANDLER =============
sub exit_program {
    print "Goodbye!\n";
    exit 0;
}


# ============= MAIN =============
my %actions = (
    1 => \&ask_question,
    2 => \&analyze_file,
    3 => \&analyze_directory,
    9 => \&settings_menu,
    0 => \&exit_program,
);

while (1) {
    show_menu();
    chomp(my $choice = <STDIN>);

    if (exists $actions{$choice}) {
        $actions{$choice}->();
    } else {
        print "Invalid option. Try again.\n";
        type_to_continue();
    }
}