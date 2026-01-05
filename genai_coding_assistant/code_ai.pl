#!/usr/bin/perl


use HTTP::Tiny;
use JSON qw(encode_json decode_json);

# ============= PRINT's =============
sub show_menu {
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
    print "\n----------------------------\n";
    print "   Setting menu\n";
    print "----------------------------\n";
    print "1) Check API KEY's\n";
    print "2) Select model\n";
    
    print "\n";
    print "0) Exit\n";
    print "Choose an option: ";
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

    my $payload = {
        system_instruction => {
            parts => [
                {
                    text => $system_info
                }
            ]
        },
        contents => [
            {
                parts => [
                    {
                        text => $prompt
                    }
                ]
            }
        ]
    };

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

        die "=======ERROR========\nGemini API error ($res->{status}): $msg\n";
    }

    my $data = decode_json($res->{content});

    my $answer = $data->{candidates}[0]{content}{parts}[0]{text};

    return $answer;
}

# ============= ASK QUESTION HANDLER =============
sub ask_question {
    print "Ask a question: ";
    my $prompt_text = <STDIN>;
    my $prompt_text = $prompt_text . "\n
    (NOTE: Please make the answear terminal friendly(cuz answear will be shown in terminal, so maybe no .md format). And also please no intro, go to the answear immediently.)";
    my $model = "gemini-2.5-flash";
    my $response = gemini_prompt($prompt_text, $model, 1);
    print $response;

    print "\n=========END============\nType in anything to continue...";
    my $contine = <STDIN>;
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

sub select_model{
    while 
}

sub settings_menu{
    show_option_menu();
    chomp(my $option = <STDIN>);

    while(1){
        if($option eq 1){
            my $gemini_api = $ENV{GEMINI_API_KEY} or "";
            my $openai_api = $ENV{OPENAI_API_KEY} or "";
            print("Please remember to store them as ENVIRONMENT VARIABLES:\n\t-GEMINI API KEY: $gemini_api\n\t-OPENAI API KEY: $openai_api\n");
        }elsif($option eq 2){
        }elsif($option eq 0){
            return;
        };
        show_option_menu();
        chomp($option = <STDIN>);
    }
}

# ============= EXITING HANDLER =============
sub exit_program {
    print "Goodbye!\n";
    exit 0;
}

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
    }
}