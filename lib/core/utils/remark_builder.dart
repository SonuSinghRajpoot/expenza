/// Builds the expense remark (notes) from the expense's final field values.
///
/// The remark is a pure function of head, sub-head, cities and pax, so the
/// same expense always gets the same remark, whatever the AI returned.
///
/// Examples:
///   Travel/Flight, Delhi → Mumbai, 1 pax  → "Delhi to Mumbai flight ticket for 1 person"
///   Travel/Cab, Pune, 2 pax               → "Cab in Pune for 2 persons"
///   Accommodation/Hotel, Jaipur, 2 pax    → "Hotel stay in Jaipur for 2 persons"
///   Food/Lunch, Pune, 3 pax               → "Lunch in Pune for 3 persons"
///   Event/Printing Fee, Delhi             → "Printing Fee in Delhi"
///   Subscription/Software / App           → "Software / App subscription"
class RemarkBuilder {
  RemarkBuilder._();

  /// Heads that record a passenger / person count.
  static const Set<String> headsWithPax = {'Travel', 'Accommodation', 'Food'};

  static const Map<String, String> _travelPhrases = {
    'Flight': 'flight ticket',
    'Train': 'train ticket',
    'Bus': 'bus ticket',
    'Cab': 'cab',
    'Auto': 'auto',
    'E-Rickshaw': 'e-rickshaw',
    'Bike': 'bike',
    'Fuel': 'fuel',
    'Local': 'local conveyance',
  };

  /// Ticketed modes read "from <city>" when only one city is known.
  static const Set<String> _ticketedModes = {'Flight', 'Train', 'Bus'};

  static String build({
    required String head,
    String? subHead,
    String? fromCity,
    String? toCity,
    int? pax,
  }) {
    final from = _clean(fromCity);
    final to = _clean(toCity);
    final sub = _clean(subHead);
    final isOthers = sub == null || sub == 'Others';
    final paxSuffix = headsWithPax.contains(head) && pax != null && pax >= 1
        ? ' for $pax ${pax == 1 ? 'person' : 'persons'}'
        : '';
    final inCity = from != null ? ' in $from' : '';

    String text;
    switch (head) {
      case 'Travel':
        final phrase = isOthers ? 'travel' : (_travelPhrases[sub] ?? sub!.toLowerCase());
        final hasRoute =
            from != null && to != null && from.toLowerCase() != to.toLowerCase();
        if (hasRoute) {
          text = '$from to $to $phrase';
        } else if (from != null) {
          final preposition =
              !isOthers && _ticketedModes.contains(sub) ? 'from' : 'in';
          text = '$phrase $preposition $from';
        } else {
          text = phrase;
        }
        break;
      case 'Accommodation':
        text = '${isOthers ? 'Accommodation' : '$sub stay'}$inCity';
        break;
      case 'Food':
        text = '${isOthers ? 'Meal' : sub}$inCity';
        break;
      case 'Event':
        text = '${isOthers ? 'Event expense' : sub}$inCity';
        break;
      case 'Miscellaneous':
        text = '${isOthers ? 'Miscellaneous expense' : sub}$inCity';
        break;
      case 'Subscription':
        // Subscriptions are not tied to a place, so no city.
        text = isOthers ? 'Subscription' : '$sub subscription';
        break;
      default:
        text = '${isOthers ? head : sub}$inCity';
    }
    return _capitalize('$text$paxSuffix');
  }

  static String? _clean(String? value) {
    final t = value?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
