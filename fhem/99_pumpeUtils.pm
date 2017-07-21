package main;
use strict;
use warnings;
use POSIX;
sub
PumpeUtils_Initialize($$)
{
 my ($hash) = @_;
}

# Uhrzeiten zu denen gegossen werden soll (valide Werte: 00, 03, 06, 09, 12, 15, 18, 21)
my $morgen = "09";
my $mittag = "15";
my $abend = "18";

# Mindesttemperatur ab der zu einer Uhrzeit gegossen werden soll
my $grad_morgen = 15;
my $grad_mittag = 20;
my $grad_abend = 20;

# Maximale Regenwahrscheinlichkeit
my $regen_morgen = 50;
my $regen_mittag = 50;
my $regen_abend = 50;

my $temp_sensor = "Balkon_TX35DTH";
my $pumpe_schalter = "Pumpe_Schalter";
my $proplanta = "Wetter_PROPLANTA";
my $pushover = "pushmsg";
my $bewasserung_zeit = 60;

sub
checkPumpe(){
  my $grenzwerte = checkGrenzwerte();
  if($grenzwerte eq "0"){
    return;
  }

  Log 3, ("PumpeUtils: Starte Bewässerung");
  fhem("set pushmsg msg 'fhem' 'Starte Bewässerung für $bewasserung_zeit!' 0 ");
  fhem("set $pumpe_schalter on-for-timer $bewasserung_zeit");
}


# Überprüft, ob die gegebenen Werte erreicht sind
sub
checkGrenzwerte(){
  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
  my $uhrzeit;
  if($hour < 10){
    $uhrzeit = "0$hour";
  }
  else{
    $uhrzeit = "$hour";
  }
  Log 2, ("PumpeUtils: checkGrenzwerte um $uhrzeit");
  # Werte setzen
  my ($min_temp, $max_regen) = (0)x2;
  if($uhrzeit == $morgen){
    $min_temp = $grad_morgen;
    $max_regen = $regen_morgen;
  }
  elsif($uhrzeit == $mittag){
    $min_temp = $grad_mittag;
    $max_regen = $regen_mittag;
  }
  elsif($uhrzeit == $abend){
    $min_temp = $grad_abend;
    $max_regen = $regen_abend;
  }
  else{
    Log 2, ("PumpeUtils: Keine Beregnungszeit");
    return "0";
  }

  # Werte von Sensor und Wetter laden
  my $temp = getAktuelleTemperatur();
  my $regen = getRegenwahrscheinlichkeit($uhrzeit);
  if($temp eq "" || $regen eq ""){
    Log 2, ("PumpeUtils: Temperatur oder Regenwahrscheinlichkeit konnten nicht geladen werden (Temperatur: $temp, Regen: $regen)");
  return "0";
  }
  
  Log 2, ("PumpeUtils: Voraussetzungen für Bewässerung: \nTemperatur: $min_temp (ist: $temp)\nRegenwahrscheinlichkeit: $max_regen (ist: $regen)");
  if($min_temp < $temp && $max_regen > $regen){
    Log 2, ("PumpeUtils: Voraussetzungen für Bewässerung erfüllt");
    return "1";
  }
  else {
    Log 2, ("PumpeUtils: Voraussetzungen für Bewässerung nicht erfüllt");
    return "0";
  }
}

sub
getAktuelleTemperatur() {
  my $temp = ReadingsVal("$temp_sensor", "temperature", "");
  return $temp;
}

# Regenwahrscheinlichkeit zur gegebenen Uhrzeit
sub
getRegenwahrscheinlichkeit($) {
  my $uhrzeit = $_[0];
  my $regen = ReadingsVal("$proplanta","fc0_chOfRain$uhrzeit","");
  return $regen;
}

1;
