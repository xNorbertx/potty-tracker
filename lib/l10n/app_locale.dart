import 'package:flutter/widgets.dart';

enum AppLanguage {
  english('en', 'English'),
  swedish('sv', 'Svenska'),
  dutch('nl', 'Nederlands');

  const AppLanguage(this.code, this.nativeName);
  final String code;
  final String nativeName;

  Locale get locale => Locale(code);

  static AppLanguage fromCode(String? code) => AppLanguage.values.firstWhere(
        (language) => language.code == code,
        orElse: () => AppLanguage.english,
      );
}

class AppLocale extends InheritedWidget {
  const AppLocale({super.key, required this.language, required super.child});

  final AppLanguage language;

  static AppLanguage languageOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppLocale>()?.language ??
      AppLanguage.english;

  static String text(BuildContext context, String key, {Map<String, String> args = const {}}) {
    return localized(languageOf(context), key, args: args);
  }

  static String localized(AppLanguage language, String key,
      {Map<String, String> args = const {}}) {
    var value = _translations[language.code]?[key] ??
        _translations['en']![key] ??
        key;
    for (final entry in args.entries) {
      value = value.replaceAll('{${entry.key}}', entry.value);
    }
    return value;
  }

  @override
  bool updateShouldNotify(AppLocale oldWidget) => language != oldWidget.language;
}

extension AppLocaleContext on BuildContext {
  AppLanguage get appLanguage => AppLocale.languageOf(this);
  String tr(String key, {Map<String, String> args = const {}}) =>
      AppLocale.text(this, key, args: args);
}

const _translations = <String, Map<String, String>>{
  'en': {
    'appName': 'Potty Tracker', 'accountSettings': 'Account settings',
    'account': 'Account', 'yourName': 'Your name', 'name': 'Name',
    'language': 'Language', 'chooseLanguage': 'Choose language',
    'languageUpdated': 'Language updated.', 'nameUpdated': 'Name updated.', 'edit': 'Edit', 'changePassword': 'Change password',
    'passwordHelp': 'Update the password you use to sign in.',
    'currentPassword': 'Current password', 'newPassword': 'New password',
    'confirmPassword': 'Confirm new password', 'savePassword': 'Save password',
    'passwordChanged': 'Password changed.', 'dangerZone': 'Danger zone',
    'deleteAccount': 'Delete account', 'deleteAccountQuestion': 'Delete account?',
    'deleteAccountHelp': 'Permanently delete your account and relevant baby data.',
    'cancel': 'Cancel', 'save': 'Save', 'done': 'Done', 'delete': 'Delete',
    'addBaby': 'Add a baby', 'babyName': "Baby's name", 'yourBabies': 'Your babies',
    'addAnotherBaby': 'Add another baby', 'joinSharedBaby': 'Join a shared baby',
    'joinBaby': 'Join baby', 'inviteCode': 'Invite code',
    'inviteInvalid': 'Invite code not found or already used.',
    'inviteCaregiver': 'Invite a caregiver', 'copyCode': 'Copy code',
    'inviteCopied': 'Invite code copied.', 'caregivers': 'Caregivers',
    'caregiver': 'Caregiver {number}', 'you': 'You', 'exportPdf': 'Export diary PDF',
    'exportingPdf': 'Preparing PDF...', 'exportSummary': 'Export diary summary',
    'chooseExportPeriod': 'Choose the period to include in the PDF.',
    'lastWeek': 'Last week', 'last2Weeks': 'Last 2 weeks', 'lastMonth': 'Last month',
    'diaryAtAGlance': 'Diary at a glance', 'totalLogs': 'Total logs',
    'thisWeek': 'This week', 'mostRecentLog': 'Most recent log',
    'openDiary': "Open {name}'s diary", 'logPoop': 'Log Poop',
    'editPoopLog': 'Edit Poop Log', 'logAPoop': 'Log a Poop',
    'date': 'Date', 'time': 'Time', 'notesOptional': 'Notes (optional)',
    'observations': 'Any observations...', 'saveChanges': 'Save Changes',
    'saveEntry': 'Save Entry', 'selectConsistency': 'Please select a consistency type',
    'entryUpdated': 'Poop entry updated!', 'entrySaved': 'Poop entry saved!',
    'consistency': 'Consistency', 'size': 'Size', 'colorOptional': 'Colour (optional)',
    'selectColor': 'Select colour from baby poo guide',
    'hard': 'Hard/Pellets', 'formed': 'Formed', 'pasty': 'Pasty',
    'soft': 'Soft/Mushy', 'watery': 'Watery/Runny',
    'small': 'Small', 'medium': 'Medium', 'large': 'Large',
    'yellow': 'Yellow / mustard', 'brown': 'Brown', 'green': 'Green',
    'orange': 'Orange', 'red': 'Red', 'paleWhite': 'Pale / white', 'black': 'Black',
    'deleteEntryQuestion': 'Delete entry?', 'deleteEntryHelp': 'This will permanently delete this poop entry.',
    'signOut': 'Sign out', 'noEntries': 'No entries for this day', 'tapToLog': 'Tap 💩 to log one!', 'noBabies': 'No babies yet',
    'noBabiesHelp': 'Add a baby to start their poop diary.',
    'joinWithCode': 'Have an invite code? Join a shared baby',
    'welcome': 'Welcome to Potty Tracker', 'whatCallYou': 'What should we call you?',
    'nameOnLogs': 'Your name will appear on poop logs you add.', 'continue': 'Continue',
    'email': 'Email', 'password': 'Password', 'signIn': 'Sign In', 'register': 'Register',
    'welcomeBack': 'Welcome back!', 'needAccount': "Don't have an account? Register",
    'dailyActivity': 'Daily activity', 'poopsPerDay': 'Poops per day',
    'pdfSummary': '{name} - Diary summary', 'consistencyTitle': 'Consistency',
    'sizeTitle': 'Size', 'colorTitle': 'Color', 'notAvailable': 'n/a',
    'generatedBy': 'Generated by Potty Tracker on {date}.',
  },
  'sv': {
    'appName': 'Pottspåraren', 'accountSettings': 'Kontoinställningar', 'account': 'Konto',
    'yourName': 'Ditt namn', 'name': 'Namn', 'language': 'Språk', 'chooseLanguage': 'Välj språk',
    'languageUpdated': 'Språket har uppdaterats.', 'nameUpdated': 'Namnet har uppdaterats.', 'edit': 'Redigera', 'changePassword': 'Byt lösenord',
    'passwordHelp': 'Uppdatera lösenordet du använder för att logga in.',
    'currentPassword': 'Nuvarande lösenord', 'newPassword': 'Nytt lösenord', 'confirmPassword': 'Bekräfta nytt lösenord',
    'savePassword': 'Spara lösenord', 'passwordChanged': 'Lösenordet har ändrats.', 'dangerZone': 'Riskzon',
    'deleteAccount': 'Radera konto', 'deleteAccountQuestion': 'Radera konto?',
    'deleteAccountHelp': 'Radera ditt konto och relevanta babydatum permanent.', 'cancel': 'Avbryt', 'save': 'Spara', 'done': 'Klar', 'delete': 'Radera',
    'addBaby': 'Lägg till ett barn', 'babyName': 'Barnets namn', 'yourBabies': 'Dina barn', 'addAnotherBaby': 'Lägg till ett barn till',
    'joinSharedBaby': 'Gå med i ett delat barn', 'joinBaby': 'Gå med', 'inviteCode': 'Inbjudningskod', 'inviteInvalid': 'Inbjudningskoden finns inte eller har redan använts.',
    'inviteCaregiver': 'Bjud in en vårdnadshavare', 'copyCode': 'Kopiera kod', 'inviteCopied': 'Inbjudningskoden kopierades.', 'caregivers': 'Vårdnadshavare', 'caregiver': 'Vårdnadshavare {number}', 'you': 'Du',
    'exportPdf': 'Exportera dagbok som PDF', 'exportingPdf': 'Förbereder PDF...', 'exportSummary': 'Exportera dagbokssammanfattning', 'chooseExportPeriod': 'Välj perioden som ska ingå i PDF:en.',
    'lastWeek': 'Senaste veckan', 'last2Weeks': 'Senaste 2 veckorna', 'lastMonth': 'Senaste månaden', 'diaryAtAGlance': 'Dagboken i korthet', 'totalLogs': 'Totalt antal loggar', 'thisWeek': 'Denna vecka', 'mostRecentLog': 'Senaste logg', 'openDiary': 'Öppna {name}s dagbok', 'logPoop': 'Logga bajs', 'editPoopLog': 'Redigera bajslogg', 'logAPoop': 'Logga bajs',
    'date': 'Datum', 'time': 'Tid', 'notesOptional': 'Anteckningar (valfritt)', 'observations': 'Några observationer...', 'saveChanges': 'Spara ändringar', 'saveEntry': 'Spara logg', 'selectConsistency': 'Välj en konsistenstyp', 'entryUpdated': 'Bajsposten uppdaterades!', 'entrySaved': 'Bajsposten sparades!',
    'consistency': 'Konsistens', 'size': 'Storlek', 'colorOptional': 'Färg (valfritt)', 'selectColor': 'Välj färg från bajsguiden', 'hard': 'Hård/kulor', 'formed': 'Formad', 'pasty': 'Degig', 'soft': 'Mjuk/grötig', 'watery': 'Vattnig/rinnig', 'small': 'Liten', 'medium': 'Mellan', 'large': 'Stor', 'yellow': 'Gul/senapsgul', 'brown': 'Brun', 'green': 'Grön', 'orange': 'Orange', 'red': 'Röd', 'paleWhite': 'Blek/vit', 'black': 'Svart',
    'deleteEntryQuestion': 'Radera post?', 'deleteEntryHelp': 'Detta raderar denna bajspost permanent.', 'signOut': 'Logga ut', 'noEntries': 'Inga poster för denna dag', 'tapToLog': 'Tryck på 💩 för att logga en!', 'noBabies': 'Inga barn ännu', 'noBabiesHelp': 'Lägg till ett barn för att starta bajsdagboken.', 'joinWithCode': 'Har du en inbjudningskod? Gå med i ett delat barn',
    'welcome': 'Välkommen till Pottspåraren', 'whatCallYou': 'Vad ska vi kalla dig?', 'nameOnLogs': 'Ditt namn visas på bajsloggar du lägger till.', 'continue': 'Fortsätt', 'email': 'E-post', 'password': 'Lösenord', 'signIn': 'Logga in', 'register': 'Registrera', 'welcomeBack': 'Välkommen tillbaka!', 'needAccount': 'Har du inget konto? Registrera dig',
    'dailyActivity': 'Daglig aktivitet', 'poopsPerDay': 'Bajs per dag', 'pdfSummary': '{name} - Dagbokssammanfattning', 'consistencyTitle': 'Konsistens', 'sizeTitle': 'Storlek', 'colorTitle': 'Färg', 'notAvailable': 'ej angivet', 'generatedBy': 'Skapad av Pottspåraren den {date}.',
  },
  'nl': {
    'appName': 'Potty Tracker', 'accountSettings': 'Accountinstellingen', 'account': 'Account', 'yourName': 'Jouw naam', 'name': 'Naam', 'language': 'Taal', 'chooseLanguage': 'Kies taal', 'languageUpdated': 'Taal bijgewerkt.', 'nameUpdated': 'Naam bijgewerkt.', 'edit': 'Bewerken', 'changePassword': 'Wachtwoord wijzigen', 'passwordHelp': 'Werk het wachtwoord bij waarmee je inlogt.', 'currentPassword': 'Huidig wachtwoord', 'newPassword': 'Nieuw wachtwoord', 'confirmPassword': 'Bevestig nieuw wachtwoord', 'savePassword': 'Wachtwoord opslaan', 'passwordChanged': 'Wachtwoord gewijzigd.', 'dangerZone': 'Gevarenzone', 'deleteAccount': 'Account verwijderen', 'deleteAccountQuestion': 'Account verwijderen?', 'deleteAccountHelp': 'Verwijder je account en relevante babygegevens permanent.', 'cancel': 'Annuleren', 'save': 'Opslaan', 'done': 'Klaar', 'delete': 'Verwijderen',
    'addBaby': 'Baby toevoegen', 'babyName': 'Naam van de baby', 'yourBabies': 'Jouw baby’s', 'addAnotherBaby': 'Nog een baby toevoegen', 'joinSharedBaby': 'Deelnemen aan een gedeelde baby', 'joinBaby': 'Deelnemen', 'inviteCode': 'Uitnodigingscode', 'inviteInvalid': 'Uitnodigingscode niet gevonden of al gebruikt.', 'inviteCaregiver': 'Verzorger uitnodigen', 'copyCode': 'Code kopiëren', 'inviteCopied': 'Uitnodigingscode gekopieerd.', 'caregivers': 'Verzorgers', 'caregiver': 'Verzorger {number}', 'you': 'Jij',
    'exportPdf': 'Dagboek als PDF exporteren', 'exportingPdf': 'PDF voorbereiden...', 'exportSummary': 'Dagboeksamenvatting exporteren', 'chooseExportPeriod': 'Kies de periode voor de PDF.', 'lastWeek': 'Afgelopen week', 'last2Weeks': 'Afgelopen 2 weken', 'lastMonth': 'Afgelopen maand', 'diaryAtAGlance': 'Dagboek in één oogopslag', 'totalLogs': 'Totaal logs', 'thisWeek': 'Deze week', 'mostRecentLog': 'Meest recente log', 'openDiary': 'Open dagboek van {name}', 'logPoop': 'Poep loggen', 'editPoopLog': 'Poep-log bewerken', 'logAPoop': 'Poep loggen',
    'date': 'Datum', 'time': 'Tijd', 'notesOptional': 'Notities (optioneel)', 'observations': 'Opmerkingen...', 'saveChanges': 'Wijzigingen opslaan', 'saveEntry': 'Log opslaan', 'selectConsistency': 'Kies een consistentie', 'entryUpdated': 'Poep-log bijgewerkt!', 'entrySaved': 'Poep-log opgeslagen!', 'consistency': 'Consistentie', 'size': 'Grootte', 'colorOptional': 'Kleur (optioneel)', 'selectColor': 'Kies kleur uit de babypoepgids', 'hard': 'Hard/keutels', 'formed': 'Gevormd', 'pasty': 'Papachtig', 'soft': 'Zacht/papperig', 'watery': 'Waterig/dun', 'small': 'Klein', 'medium': 'Middel', 'large': 'Groot', 'yellow': 'Geel/musterd', 'brown': 'Bruin', 'green': 'Groen', 'orange': 'Oranje', 'red': 'Rood', 'paleWhite': 'Bleek/wit', 'black': 'Zwart',
    'deleteEntryQuestion': 'Log verwijderen?', 'deleteEntryHelp': 'Dit verwijdert deze poep-log permanent.', 'signOut': 'Uitloggen', 'noEntries': 'Geen logs voor deze dag', 'tapToLog': 'Tik op 💩 om er een te loggen!', 'noBabies': 'Nog geen baby’s', 'noBabiesHelp': 'Voeg een baby toe om het poepdagboek te starten.', 'joinWithCode': 'Heb je een uitnodigingscode? Deelnemen aan een gedeelde baby', 'welcome': 'Welkom bij Potty Tracker', 'whatCallYou': 'Hoe zullen we je noemen?', 'nameOnLogs': 'Je naam verschijnt bij poep-logs die je toevoegt.', 'continue': 'Doorgaan', 'email': 'E-mail', 'password': 'Wachtwoord', 'signIn': 'Inloggen', 'register': 'Registreren', 'welcomeBack': 'Welkom terug!', 'needAccount': 'Nog geen account? Registreren',
    'dailyActivity': 'Dagelijkse activiteit', 'poopsPerDay': 'Poepen per dag', 'pdfSummary': '{name} - Dagboeksamenvatting', 'consistencyTitle': 'Consistentie', 'sizeTitle': 'Grootte', 'colorTitle': 'Kleur', 'notAvailable': 'n.v.t.', 'generatedBy': 'Gegenereerd door Potty Tracker op {date}.',
  },
};
