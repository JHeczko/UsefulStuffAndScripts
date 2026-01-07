#!/usr/bin/perl

use warnings;
use strict;
use HTTP::Tiny;
use JSON qw(encode_json decode_json);
use open qw(:std :utf8);
use Cwd qw(getcwd abs_path);
use File::Basename;


# ============= GLOBAL VARS =============
my %models_db = (
    1 => { name => "gemini-3-flash",        provider => "google" },
    2 => { name => "gemini-2.5-flash",      provider => "google" },
    3 => { name => "gemini-2.5-flash-lite", provider => "google" },
    4 => { name => "gemma-3-27b-it",           provider => "google" },
    5 => { name => "gemma-3-12b-it",           provider => "google" },
    6 => { name => "gemma-3-4b-it",           provider => "google" },
    7 => { name => "gemma-3-2b-it (maybe not avaible)",           provider => "google" },
    8 => { name => "gemma-3-1b-it",           provider => "google" },
);
my $context_window = 12000; 

# ============= HELP FUNCS =============
sub append_history{

}

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
    print "2) Debug(try to :D) source code file\n";
    print "3) Refactor source code file\n";

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

# ============= ASK QUESTION HANDLER =============
sub ask_question {
    my $config = read_config();
    
    print "Ask a question: ";
    my $prompt_text = <STDIN>;
    my $prompt_text = $prompt_text . $config->{"ask-prompt"};
    my $model = $config->{model};
    my $response = gemini_prompt($prompt_text, $model, 0);
    print $response;
    print "\n=========END============";
    type_to_continue();
}

# ============= DEBUGGER HANDLER =============
sub debug_file {
    print "\n=== DEBUGGER MODE ===\n";
    print "Wybierz plik do analizy bledow:\n";

    # 1. Wybór pliku
    my $file_path = browse_files("."); # Startujemy w obecnym katalogu
    return unless $file_path;          # Jeśli użytkownik anulował

    # 2. Wczytanie treści z limitem
    my $content = read_file_content($file_path);
    
    # 3. Tu wstawiasz swoją logikę prompta
    print "\n[INFO] Wczytano plik: $file_path (" . length($content) . " znakow)\n";
    print "Generowanie promptu debugowania...\n";
    
    # my $prompt = "Znajdź błędy w tym kodzie:\n$content";
    # gemini_prompt($prompt, ...);

    type_to_continue();
}

# ============= REFACTORER HANDLER =============
sub refactor_file {
    print "\n=== REFACTOR MODE ===\n";
    print "Wybierz plik do refaktoryzacji:\n";

    # 1. Wybór pliku
    my $file_path = browse_files("."); 
    return unless $file_path;

    # 2. Wczytanie treści z limitem
    my $content = read_file_content($file_path);

    # 3. Tu wstawiasz swoją logikę prompta
    print "\n[INFO] Wczytano plik: $file_path (" . length($content) . " znakow)\n";
    print "Generowanie promptu refaktoryzacji...\n";

    # my $prompt = "Zrób refactor tego kodu:\n$content";

    type_to_continue();
}

# ============================================
# FUNKCJE POMOCNICZE (HELPERY)
# ============================================

# Interaktywna nawigacja po katalogach
sub browse_files {
    my ($current_dir) = @_;
    
    # Otwieramy katalog
    opendir(my $dh, $current_dir) || die "Nie można otworzyc katalogu $current_dir: $!";
    
    # Sortujemy: najpierw katalogi, potem pliki. Pomijamy '.' (bieżący)
    my @items = sort { 
        -d "$current_dir/$a" <=> -d "$current_dir/$b" || $a cmp $b 
    } grep { $_ ne '.' } readdir($dh);
    closedir $dh;

    # Wyświetlanie listy
    print "\nKatalog: " . abs_path($current_dir) . "\n";
    print "0) [ANULUJ]\n";
    
    my $index = 1;
    my %map; # Mapa numer -> nazwa pliku

    foreach my $item (@items) {
        my $full_path = "$current_dir/$item";
        my $type = -d $full_path ? "[DIR ]" : "[FILE]";
        
        # Oznaczenie katalogu nadrzędnego
        if ($item eq '..') {
            printf "%3d) [UP  ] .. (Wyjdz wyzej)\n", $index;
        } else {
            printf "%3d) %s %s\n", $index, $type, $item;
        }
        
        $map{$index} = $item;
        $index++;
    }

    print "Wybierz numer: ";
    my $choice = <STDIN>;
    chomp($choice);

    # Obsługa wyboru
    if ($choice eq '0') {
        return undef; # Anulowanie
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
        print "Bledny wybor, sprobuj ponownie.\n";
        return browse_files($current_dir);
    }
}

# Wczytywanie pliku z limitem znaków
sub read_file_content {
    my ($path) = @_;
    
    open(my $fh, '<', $path) or die "Nie mozna otworzyc pliku $path: $!";
    
    # Wczytujemy cały plik do zmiennej
    local $/; 
    my $content = <$fh>;
    close($fh);

    my $len = length($content);

    # Sprawdzamy limit context window
    if ($len > $context_window && $context_window > 0) {
        print "\n[WARN] Plik jest za duzy ($len znakow). Przycinam do $context_window znakow.\n";
        $content = substr($content, 0, $context_window);
        $content .= "\n... [TRUNCATED DUE TO CONTEXT LIMIT] ...";
    }

    return $content;
}

# ============= SETTING HANDLER =============
sub read_config (){
    # my $config_path = "./aicode_conf/config.json";
    my $config_path = $ENV{"HOME"} . "/.aicode_conf/config.json";


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
    my $config_path = $ENV{"HOME"} . "/.aicode_conf/config.json";
    
    my $json_text = JSON->new->pretty->encode($config_data);

    open(my $FILE, '>', $config_path) or die "Nie można otworzyć pliku do zapisu: $!";
    print $FILE $json_text;
    close($FILE);
}

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

sub set_keys {
    print "\n--- ZARZADZANIE KLUCZAMI API ---\n";
    print "1) Ustaw Gemini API Key (Google)\n";
    print "2) Ustaw OpenAI API Key\n";
    print "Wybierz opcje: ";

    my $option = <STDIN>;
    chomp($option);

    my $config = read_config();

    if ($option eq "1") {
        print "Wprowadz klucz dla Gemini: ";
        my $key = <STDIN>;
        chomp($key);
        
        if ($key ne "") {
            $config->{"gemini-api-key"} = $key;
            print "Klucz Gemini zostal zapisany.\n";
            type_to_continue();
        } else {
            return;
        }

    } elsif ($option eq "2") {
        print "Wprowadz klucz dla OpenAI: ";
        my $key = <STDIN>;
        chomp($key);

        if ($key ne "") {
            $config->{"openai-api-key"} = $key;
            print "Klucz OpenAI zostal zapisany.\n";
            type_to_continue();
        } else {
            return;
        }

    } else {
        return;
    }

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
    2 => \&debug_file,
    3 => \&refactor_file,
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