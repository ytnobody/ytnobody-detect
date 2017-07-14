use strict;
use warnings;
use Net::Azure::CognitiveServices::Face;
use Mojolicious::Lite;

### init Face API
my $api = 'Net::Azure::CognitiveServices::Face';
$api->access_key($ENV{'FACEAPI_ACCESSKEY'});
$api->endpoint($ENV{'FACEAPI_ENDPOINT'});

### init Person Group
my $person_group_id = 'group01';
eval {
    $api->PersonGroup->create($person_group_id, name => 'person detect');
};

### fetch a status of training
any '/' => sub {
    my $c = shift;
    my $training_status = eval { $api->PersonGroup->training_status($person_group_id) };
    $c->render(json => {status => $@ || $training_status->{status}});
};

### add a person
any '/add' => sub {
    my $c = shift;
    my $name = $c->param('name');
    my $url  = $c->param('url');

    die 'name and url is required' if !$name || !$url;

    my $person = $api->Person->create($person_group_id, name => $name);
    $api->Person->add_face($person_group_id, $person->{personId}, $url);

    $api->PersonGroup->train($person_group_id);

    $c->render(json => {status => 'done'});
};

### detect persons from specified image
any '/detect' => sub {
    my $c = shift;
    my $url = $c->param('url');

    die 'url is required' if !$url;

    my $faces = $api->Face->detect($url);
    my @faceIds = map {$_->{faceId}} @$faces;
    my $ident;
    my @persons = ();
    if (scalar @faceIds > 0) {
        $ident = $api->Face->identify(
            faceIds                    => [@faceIds],
            personGroupId              => $person_group_id,
            maxNumOfCandidatesReturned => 5,
            confidenceThreshold        => 0.5
        );
        for my $candidate (@{$ident}) {
            my $person_id = $candidate->{candidates}[0]{personId};
            next if !$person_id;
            my $person = $api->Person->get($person_group_id, $person_id);
            push @persons, $person if $person;
        }
    }
    $c->render(json => {persons => [@persons]});
};

### return the application
app->start;